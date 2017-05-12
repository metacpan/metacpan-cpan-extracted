/*
 * $Id: qmailrem.c,v 1.2 2005/01/05 21:23:01 rsandberg Exp $
 */

#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include "sig.h"
#include "stralloc.h"
#include "substdio.h"
#include "subfd.h"
#include "scan.h"
#include "case.h"
#include "error.h"
#include "dns.h"
#include "alloc.h"
#include "quote.h"
#include "ip.h"
#include "ipalloc.h"
#include "ipme.h"
#include "gen_alloc.h"
#include "gen_allocdefs.h"
#include "str.h"
#include "now.h"
#include "exit.h"
#include "constmap.h"
#include "tcpto.h"
#include "readwrite.h"
#include "timeoutconn.h"
#include "timeoutread.h"
#include "timeoutwrite.h"
#include "qmailrem.h"

#define HUGESMTPTEXT 5000

#define PORT_SMTP 25 /* silly rabbit, /etc/services is for users */
unsigned long port = PORT_SMTP;

GEN_ALLOC_typedef(saa,stralloc,sa,len,a)
GEN_ALLOC_readyplus(saa,stralloc,sa,len,a,i,n,x,10,saa_readyplus)
static stralloc sauninit = {0};

stralloc helohost = {0};
stralloc host = {0};
stralloc sender = {0};
stralloc report = {0};

saa reciplist = {0};

struct ip_address partner;

void out(s) char *s; { if (!stralloc_cats(&report,s)) _exit(1); }
void zero() { if (!stralloc_0(&report)) _exit(1); }
void delimit() { if (!stralloc_cats(&report,"<ENDREPORT/>")) _exit(1); }
void zerodie() { zero(); }
void outsafe(sa) stralloc *sa; { int i; char ch;
for (i = 0;i < sa->len;++i) {
ch = sa->s[i]; if (ch < 33) ch = '?'; if (ch > 126) ch = '?';
if (!stralloc_append(&report,&ch)) _exit(1); } }

void temp_nomem() { _exit(1); }
void temp_oserr() { out("Z\
System resources temporarily unavailable. (#4.3.0)\n"); zerodie(); }
void temp_noconn() { out("Z\
Sorry, I wasn't able to establish an SMTP connection. (#4.4.1)\n"); zerodie(); }
void temp_dnscanon() { out("Z\
CNAME lookup failed temporarily. (#4.4.3)\n"); zerodie(); }
void temp_dns() { out("Z\
Sorry, I couldn't find any host by that name. (#4.1.2)\n"); zerodie(); }
void perm_dns() { out("D\
Sorry, I couldn't find any host named ");
outsafe(&host);
out(". (#5.1.2)\n"); zerodie(); }
void perm_nomx() { out("D\
Sorry, I couldn't find a mail exchanger or IP address. (#5.4.4)\n");
zerodie(); }
void perm_ambigmx() { out("D\
Sorry. Although I'm listed as a best-preference MX or A for that host,\n\
it isn't in my control/locals file, so I don't treat it as local. (#5.4.6)\n");
zerodie(); }

void outhost()
{
  char x[IPFMT];
  if (!stralloc_catb(&report,x,ip_fmt(x,&partner))) _exit(1);
}

int flagcritical = 0;

void dropped() {
  out("ZConnected to ");
  outhost();
  out(" but connection died. ");
  if (flagcritical) out("Possible duplicate! ");
  out("(#4.4.2)\n");
  zerodie();
}

int timeoutconnect = 60;
int smtpfd;
int timeout = 180;

int saferead(fd,buf,len) int fd; char *buf; int len;
{
  int r;
  r = timeoutread(timeout,smtpfd,buf,len);
  if (r <= 0)
  {
      dropped();
      errno = -999;
      r = -1;
  }
  return r;
}
int safewrite(fd,buf,len) int fd; char *buf; int len;
{
  int r;
  r = timeoutwrite(timeout,smtpfd,buf,len);
  if (r <= 0)
  {
      dropped();
      errno = -999;
      r = -1;
  }
  return r;
}

char smtptobuf[1024];
substdio smtpto = SUBSTDIO_FDBUF(safewrite,-1,smtptobuf,sizeof smtptobuf);
char smtpfrombuf[128];
substdio smtpfrom = SUBSTDIO_FDBUF(saferead,-1,smtpfrombuf,sizeof smtpfrombuf);

stralloc smtptext = {0};

unsigned long dropped_fatal = -9987;

int get(ch)
char *ch;
{
  if (substdio_get(&smtpfrom,ch,1) < 0) return 0;
  if (*ch != '\r')
    if (smtptext.len < HUGESMTPTEXT)
     if (!stralloc_append(&smtptext,ch)) _exit(1);
  
  return 1;
}

unsigned long smtpcode()
{
  unsigned char ch;
  unsigned long code;

  if (!stralloc_copys(&smtptext,"")) _exit(1);

  if (!get(&ch)) return dropped_fatal; code = ch - '0';
  if (!get(&ch)) return dropped_fatal; code = code * 10 + (ch - '0');
  if (!get(&ch)) return dropped_fatal; code = code * 10 + (ch - '0');
  for (;;) {
    if (!get(&ch)) return dropped_fatal;
    if (ch != '-') break;
    while (ch != '\n') if (!get(&ch)) return dropped_fatal;
    if (!get(&ch)) return dropped_fatal;
    if (!get(&ch)) return dropped_fatal;
    if (!get(&ch)) return dropped_fatal;
  }
  while (ch != '\n') if (!get(&ch)) return dropped_fatal;

  return code;
}

void outsmtptext()
{
  int i; 
  if (smtptext.s) if (smtptext.len) {
    out("Remote host said: ");
    for (i = 0;i < smtptext.len;++i)
      if (!smtptext.s[i]) smtptext.s[i] = '?';
    if (!stralloc_catb(&report,smtptext.s,smtptext.len)) _exit(1);
    smtptext.len = 0;
  }
}

void quit(prepend,append)
char *prepend;
char *append;
{
  substdio_putsflush(&smtpto,"QUIT\r\n");
  /* waiting for remote side is just too ridiculous */
  out(prepend);
  outhost();
  out(append);
  out(".\n");
  outsmtptext();
  zerodie();
}

int blast(char *data)
{
  int end = 0;

  for (;;) {
    if (!*data) break;
    if (*data == '.')
      if (substdio_put(&smtpto,".",1) < 0) return 0;
    while (*data != '\n') {
      if (*data == '\r')
      {
          if (*(++data) == '\n') 
              break;
          else
              data--;
      }
      if (substdio_put(&smtpto,data,1) < 0) return 0;
      data++;
      if (!*data)
      {
          end = 1;
          break;
      }
    }
    if (substdio_put(&smtpto,"\r\n",2) < 0) return 0;
    if (!end) data++;
  }

  flagcritical = 1;
  if (substdio_put(&smtpto,".\r\n",3) < 0) return 0;
  if (substdio_flush(&smtpto) < 0) return 0;
  return 1;
}

int smtp(char *data)
{
  unsigned long code;
  int flagbother;
  int i;
 
  if (smtpcode() != 220) { quit("ZConnected to "," but greeting failed"); return; }
 
  if (substdio_puts(&smtpto,"HELO ") < 0) return;
  if (substdio_put(&smtpto,helohost.s,helohost.len) < 0) return;
  if (substdio_puts(&smtpto,"\r\n") < 0) return;
  if (substdio_flush(&smtpto) < 0) return;
  if (smtpcode() != 250) { quit("ZConnected to "," but my name was rejected"); return; }
 
  if (substdio_puts(&smtpto,"MAIL FROM:<") < 0) return;
  if (substdio_put(&smtpto,sender.s,sender.len) < 0) return;
  if (substdio_puts(&smtpto,">\r\n") < 0) return;
  if (substdio_flush(&smtpto) < 0) return;
  code = smtpcode();
  if (code == dropped_fatal) return;
  if (code >= 500) { quit("DConnected to "," but sender was rejected"); return; }
  if (code >= 400) { quit("ZConnected to "," but sender was rejected"); return; }
 
  flagbother = 0;
  for (i = 0;i < reciplist.len;++i) {
    if (substdio_puts(&smtpto,"RCPT TO:<") < 0) return;
    if (substdio_put(&smtpto,reciplist.sa[i].s,reciplist.sa[i].len) < 0) return;
    if (substdio_puts(&smtpto,">\r\n") < 0) return;
    if (substdio_flush(&smtpto) < 0) return;
    code = smtpcode();
    if (code == dropped_fatal) return;
    if (code >= 500) {
      out("h"); outhost(); out(" does not like recipient.\n");
      outsmtptext(); delimit();
    }
    else if (code >= 400) {
      out("s"); outhost(); out(" does not like recipient.\n");
      outsmtptext(); delimit();
    }
    else {
      out("r"); delimit();
      flagbother = 1;
    }
  }
  if (!flagbother) { quit("DGiving up on ",""); return; }
 
  if (substdio_putsflush(&smtpto,"DATA\r\n") < 0) return;
  code = smtpcode();
  if (code == dropped_fatal) return;
  if (code >= 500) { quit("D"," failed on DATA command"); return; }
  if (code >= 400) { quit("Z"," failed on DATA command"); return; }
 
  if (!blast(data)) return;
  code = smtpcode();
  if (code == dropped_fatal) return;
  flagcritical = 0;
  if (code >= 500) { quit("D"," failed after I sent the message"); return; }
  if (code >= 400) { quit("Z"," failed after I sent the message"); return; }
  quit("K"," accepted message");
}

stralloc canonhost = {0};
stralloc canonbox = {0};

int addrmangle(saout,s,flagalias,flagcname)
stralloc *saout; /* host has to be canonical, box has to be quoted */
char *s;
int *flagalias;
int flagcname;
{
  int j;
 
  *flagalias = flagcname;
 
  j = str_rchr(s,'@');
  if (!s[j]) {
    if (!stralloc_copys(saout,s)) temp_nomem();
  }
  if (!stralloc_copys(&canonbox,s)) temp_nomem();
  canonbox.len = j;
  if (!quote(saout,&canonbox)) temp_nomem();
  if (!stralloc_cats(saout,"@")) temp_nomem();
 
  if (!stralloc_copys(&canonhost,s + j + 1)) temp_nomem();
  if (flagcname)
    switch(dns_cname(&canonhost)) {
      case 0: *flagalias = 0; break;
      case DNS_MEM: temp_nomem(); return 0;
      case DNS_SOFT: temp_dnscanon(); return 0;
      case DNS_HARD: ; /* alias loop, not our problem */
    }

  if (!stralloc_cat(saout,&canonhost)) temp_nomem();
  return 1;
}

char *cleanup(ipalloc *ip,char *msg)
{
    alloc_free(ip->ix);
    alloc_free(helohost.s);
    alloc_free(host.s);
    alloc_free(sender.s);
    alloc_free(smtptext.s);
    alloc_free(canonhost.s);
    alloc_free(canonbox.s);
    alloc_free(reciplist.sa);
    reciplist.sa = 0;
    return msg;
}

/* Can only specify 1 recipient :<> See Life With Qmail (advanced topics) for why multiple recips are not generally a good idea anyway */
/* Return "-1" if function was invoked improperly */
char  *mail(char *addrhost, char *mailfrom, char *mailto, char *data, char *helo, int tout, int toutconnect)
{
  ipalloc ip = {0};
  int i;
  unsigned long random;
  char *recips[] = { mailto, 0 };
  unsigned long prefme;
  int flagallaliases;
  int flagalias;
  char *relayhost;
 
  helohost = sauninit;
  host = sauninit;
  sender = sauninit;
  report = sauninit;
  reciplist.len = 0;
  reciplist.sa = 0;

  flagcritical = 0;

  timeout = tout;
  timeoutconnect = toutconnect;

  smtptobuf[0] = 0;
  /* smtpto = SUBSTDIO_FDBUF(safewrite,-1,smtptobuf,sizeof smtptobuf); */
  smtpfrombuf[0] = 0;
  /* smtpfrom = SUBSTDIO_FDBUF(saferead,-1,smtpfrombuf,sizeof smtpfrombuf); */

  smtptext = sauninit;
  canonhost = sauninit;
  canonbox = sauninit;

  sig_pipeignore();
  if (!*addrhost || !*mailfrom || !*mailto || !*data) return "-1";
 
  if (!stralloc_copys(&host,addrhost)) temp_nomem();
  if (!stralloc_copys(&helohost,helo)) temp_nomem();
 
  relayhost = 0;

  if (!addrmangle(&sender,mailfrom,&flagalias,0)) return cleanup(&ip,report.s);
 
  if (!saa_readyplus(&reciplist,0)) temp_nomem();
  if (ipme_init() != 1)
  {
      temp_oserr();
      return cleanup(&ip,report.s);
  }
 
  flagallaliases = 1;
  i=0;
  while (recips[i]) {
    if (!saa_readyplus(&reciplist,1)) temp_nomem();
    reciplist.sa[reciplist.len] = sauninit;
    if (!addrmangle(reciplist.sa + reciplist.len,recips[i],&flagalias,!relayhost)) return cleanup(&ip,report.s);
    if (!flagalias) flagallaliases = 0;
    ++reciplist.len;
    i++;
  }

 
  random = now() + (getpid() << 16);
  switch (relayhost ? dns_ip(&ip,&host) : dns_mxip(&ip,&host,random)) {
    case DNS_MEM: temp_nomem();
    case DNS_SOFT: temp_dns(); return cleanup(&ip,report.s);
    case DNS_HARD: perm_dns(); return cleanup(&ip,report.s);
    case 1:
      if (ip.len <= 0)
      {
          temp_dns();
          return cleanup(&ip,report.s);
      }
  }
 
  if (ip.len <= 0)
  {
      perm_nomx();
      return cleanup(&ip,report.s);
  }
 
  prefme = 100000;
  for (i = 0;i < ip.len;++i)
    if (ipme_is(&ip.ix[i].ip))
      if (ip.ix[i].pref < prefme)
        prefme = ip.ix[i].pref;
 
  if (relayhost) prefme = 300000;
  if (flagallaliases) prefme = 500000;
 
  for (i = 0;i < ip.len;++i)
    if (ip.ix[i].pref < prefme)
      break;
 
  if (i >= ip.len)
  {
    perm_ambigmx();
    return cleanup(&ip,report.s);
  }
 
  for (i = 0;i < ip.len;++i) if (ip.ix[i].pref < prefme) {
    if (tcpto(&ip.ix[i].ip)) continue;
 
    smtpfd = socket(AF_INET,SOCK_STREAM,0);
    if (smtpfd == -1)
    {
        temp_oserr();
        return cleanup(&ip,report.s);
    }
 
    if (timeoutconn(smtpfd,&ip.ix[i].ip,(unsigned int) port,timeoutconnect) == 0) {
      tcpto_err(&ip.ix[i].ip,0);
      partner = ip.ix[i].ip;
      smtp(data);
      close(smtpfd);
      return cleanup(&ip,report.s);
    }
    tcpto_err(&ip.ix[i].ip,errno == error_timeout);
    close(smtpfd);
  }
  
  temp_noconn();
  return cleanup(&ip,report.s);
}

