/* ftpparse.c, ftpparse.h: library for parsing FTP LIST responses
 *
 * Written by Uwe Ohse, 2002-07-12. 
 * Strongly influences by Daniel J. Bernsteins ftpparse.c.
 *
 * placed in the public domain.
 */

/* 
 * Currently covered:
 * EPLF.
 * UNIX ls, with or without gid.
 * different Windows and DOS FTP servers.
 * VMS, but not CMS.
 * NetPresenz (Mac).
 * NetWare.
 */

#include <time.h> /* gmtime, time_t, time() */
#include "ftpparse.h"
#include "bailout.h"
#include "str.h"
#include "case.h"
#include "utcdate2tai.h"

static int my_byte_equal(const char *s, unsigned int n, const char *t)
{
  unsigned int i;
  for (i=0;i<n;i++)
    if (s[i]!=t[i]) return 0;
  return 1;
}
static int 
fix_year(unsigned long *year)
{
  if (*year<70) *year+=2000;
  else if (*year<100) *year+=1900;
  else if (*year<1970) return 0;
  return 1;
}

/* scan_ulong with bound-check */
static unsigned int
get_ulong(const char *p, unsigned int len, unsigned long *ul)
{
  unsigned long u=0;
  unsigned int i;
  for (i=0;i<len;i++) {
    if (p[i]>'9' || p[i]<'0')
      break;
    u*=10;
    u+=p[i]-'0';
  }
  *ul=u;
  return i;
}
static unsigned int
get_uint64(const char *p, unsigned int len, uint64 *ul)
{
  uint64 u=0;
  unsigned int i;
  for (i=0;i<len;i++) {
    if (p[i]>'9' || p[i]<'0')
      break;
    u*=10;
    u+=p[i]-'0';
  }
  *ul=u;
  return i;
}


/* UNIX ls does not show the year for dates in the last six months. */
/* So we have to guess the year. */
/* Apparently NetWare uses ``twelve months'' instead of ``six months''; ugh. */
/* Some versions of ls also fail to show the year for future dates. */
static long 
guess_year(unsigned long month,unsigned long day)
{
  static long this_year;
  static struct tai yearstart;
  struct tai x;
  struct tai now;
  tai_now(&now);

  if (!this_year) {
    struct tai n;
    tai_now(&n);
    this_year=1970;
    while (1) {
      utcdate2tai(&yearstart,this_year+1,0,1,0,0,0);
      if (tai_less(&n,&yearstart)) break;
      this_year++;
    }
  }
  utcdate2tai(&x,this_year,month,day,0,0,0);
  if (tai_less(&now,&x))
    return this_year-1;
  return this_year;
}



static int
getmod (struct tai *t, const char *p, unsigned int l)
{
  unsigned int i;
  unsigned long year,mon,day,hour,min,sec;

  year=mon=day=hour=min=sec=0;

  if (l<14) return 0;

  for (i = 0; i < l; i++) {
    unsigned int u;
    if (p[i]<'0' || p[i]>'9') return 0;
    u = (p[i] - '0');
      
    switch (i) {
    case 0:
    case 1:
    case 2:
    case 3:
      year *= 10;
      year += u;
      break;
    case 4:
    case 5:
      mon *= 10;
      mon += u;
      break;
    case 6:
    case 7:
      day *= 10;
      day += u;
      break;
    case 8:
    case 9:
      hour *= 10;
      hour += u;
      break;
    case 10:
    case 11:
      min *= 10;
      min += u;
      break;
    case 12:
    case 13:
      sec *= 10;
      sec += u;
      break;
    }
  }

  utcdate2tai(t,year,mon-1,day,hour,min,sec);
  return 1;
}


static const char *months[12] =
{
  "jan","feb","mar","apr","may","jun","jul","aug","sep","oct","nov","dec"
} ;

static int get_month(char *buf, unsigned int len)
{
  int i;
  if (len < 3) return -1;
#define CMP(x) \
    (months[i][x]==buf[x] || months[i][x]==buf[x]+32)

  for (i = 0;i < 12;++i)
    if (CMP(0) && CMP(1) && CMP(2))
      return i;
  return -1;
}

/* see http://cr.yp.to/ftp/list/eplf.html */
static int 
parse_eplf(struct ftpparse *f, char *buf, unsigned int len)
{
  unsigned int start,pos;
  unsigned long ul;
  if (buf[0]!='+') return 0;

  start=1;
  for (pos = 1;pos < len;pos++) {
    if ('\t'==buf[pos]) {
      f->name=buf+pos+1;
      f->namelen=len-pos-1;
      if (!f->namelen) return 0; /* huh? */
      f->format=FTPPARSE_FORMAT_EPLF;
      return 1;
    }
    if (',' != buf[pos])
      continue;
    switch(buf[start]) {
    case '/': f->flagtrycwd=1; break;
    case 'r': f->flagtryretr=1; break;
    case 's': 
      if (pos-start-1==0) return 0;
      if (get_uint64(buf+start+1,pos-start-1,&f->size)
	  !=pos-start-1) return 0;
      f->sizetype=FTPPARSE_SIZE_BINARY;
      break;
    case 'm':
      if (pos-start-1==0) return 0;
      if (get_ulong(buf+start+1,pos-start-1,&ul)!=pos-start-1) return 0;
      tai_unix(&f->mtime,ul);
      f->mtimetype = FTPPARSE_MTIME_LOCAL;
      break;
    case 'i':
      /* refuse zero bytes length ids */
      if (pos-start-1==0) return 0;
      f->idtype = FTPPARSE_ID_FULL;
      f->id=buf+start+1;
      f->idlen=pos-start-1;
      break;
    }
    start=pos+1;
  }
  return 0;
}

static int scan_time(const char *buf, const unsigned int len,
  unsigned long *h, unsigned long *m, unsigned long *s, int *type)
{
/* 11:48:54 */
/* 01:48:54 */
/*  1:48:54 */
/* 11:48 */
/* 11:48PM */
/* 11:48AM */
/* 11:48:54PM */
/* 11:48:54AM */
  unsigned int x;
  unsigned int y;
  *h=*m=*s=0;

  x=get_ulong(buf,len,h);
  if (len==x) return 0;
  if (!x || x>2) return 0;

  if (':' != buf[x]) return 0;
  if (len==++x) return 0;

  y=get_ulong(buf+x,len-x,m);
  if (y!=2) return 0;
  x+=y;

  if (x!=len && ':' == buf[x]) {
    if (len==++x) return 0;

    y=get_ulong(buf+x,len-x,s);
    if (y!=2) return 0;
    x+=y;
    *type=FTPPARSE_MTIME_REMOTESECOND;
  } else
    *type=FTPPARSE_MTIME_REMOTEMINUTE;

  if (x!=len && ('A' == buf[x] || 'P' == buf[x])) {
    if ('P' == buf [x])
      *h+=12;
    x++;
    if (len==x) return 0;
    if ('M' != buf[x]) return 0;
    x++;
    if (len==x) return 0;
  }
  if (len==x || buf[x]==' ') return x;
  return 0;
}

/* 04-27-00  09:09PM       <DIR>          licensed */
/* 07-18-00  10:16AM       <DIR>          pub */
/* 04-14-00  03:47PM                  589 readme.htm */
/* note the mon-day-year! */
static int 
parse_msdos(struct ftpparse *f, char *buf, unsigned int len)
{
  unsigned int pos,start;
  unsigned int state;
  unsigned long mon;
  unsigned long day;
  unsigned long year;
  unsigned long hour;
  unsigned long min;
  unsigned long sec;
  int mtimetype;
  unsigned int x;
  uint64 size=0;
  unsigned int flagtrycwd=0;
  unsigned int flagtryretr=0;
  int maxspaces=0; /* to keep leading spaces before dir/file name */

  for (state=start=pos=0;pos<len;pos++) {
    switch(state) {
    case 0: /* month */
      if ('-'==buf[pos]) {
	state++;
	if (pos==start) return 0;
	if (get_ulong(buf+start,pos-start,&mon)!=pos-start) return 0;
	start=pos+1;
      }
      break;
    case 1: /* day */
      if ('-'==buf[pos]) {
	state++;
	if (pos==start) return 0;
	if (get_ulong(buf+start,pos-start,&day)!=pos-start) return 0;
	start=pos+1;
      }
      break;
    case 2: /* year */
      if (' '==buf[pos]) {
	state++;
	if (pos-start!=2 && pos-start!=4) return 0;
	if (get_ulong(buf+start,pos-start,&year)!=pos-start) return 0;
	start=pos+1;
	if (!fix_year(&year)) return 0;
      }
      break;
    case 3: /* spaces */
      if (' ' == buf[pos]) continue;
      state++;
      start=pos;
      /* FALL THROUGH */
    case 4: /* time */
      x=scan_time(buf+start,len-pos,&hour,&min,&sec,&mtimetype);
      if (!x) return 0;
      pos+=x;
      if (pos==len) return 0;
      state++;
      break;
    case 5: /* spaces */
      if (' ' == buf[pos]) continue;
      state++;
      start=pos;
      /* FALL THROUGH */
    case 6: /* <DIR> or length */
      if (' ' == buf[pos]) {
	if (get_uint64(buf+start,pos-start,&size)!=pos-start) {
	  if (pos-start < 5
	  || !my_byte_equal(buf+start,5,"<DIR>"))
	    return 0;
	  flagtrycwd=1;
	  maxspaces=10;
	} else {
	  flagtryretr=1;
	  maxspaces=1;
	}
	state++;
	start=pos;
      }
      break;
    case 7: /* spaces */
      if (' ' == buf[pos])
	if (--maxspaces)
	  continue;
      state++;
      start=pos;
      /* FALL THROUGH */
    case 8: /* file / dir name */
      f->name=buf+start;
      f->namelen=len-pos;
      f->flagtrycwd=flagtrycwd;
      f->flagtryretr=flagtryretr;
      f->mtimetype=mtimetype;
      if (flagtryretr) {
	f->size=size;
	f->sizetype=FTPPARSE_SIZE_BINARY;
      }
      if (!fix_year(&year)) return 0;
      utcdate2tai(&f->mtime,year,mon-1,day,hour,min,sec);
      return 1;
    }
  }
  return 0;
}

#define MAXWORDS 10
static unsigned int 
dosplit(char *buf, int len, char *p[], int l[])
{
  unsigned int count=0;
  int inword=0;
  int pos;
  int start;
  for (pos=start=0;pos<len;pos++) {
    if (inword) {
      if (' ' == buf[pos]) {
	inword=0;
	l[count++]=pos-start;
	if (count==MAXWORDS) {
	  l[count-1]=len-start;
	  break;
	}
      }
    } else {
      if (' ' != buf[pos]) {
	inword=1;
	start=pos;
	p[count]=buf+pos;
      }
    }
  }
  if (inword) {
    l[count]=buf+pos-p[count];
    count++;
  }
  return count;
}

static int parse_multinet(struct ftpparse *f, char *p[], int l[], 
  unsigned int count)
{
/* "CORE.DIR;1          1  8-SEP-1996 16:09 [SYSTEM] (RWE,RWE,RE,RE)" */
/* "[VMSSERV.FILES]ALARM.DIR;1      1/3          5-MAR-1993 18:09:" */
  int mon;
  unsigned long day;
  unsigned long year;
  unsigned long hour;
  unsigned long min;
  unsigned long sec;
  int mtimetype;
  int x;
  char *q;
  int m;
  if (count<4) return 0;

  q=p[2];
  m=l[2];

  x=get_ulong(q,m,&day);
  if (!x || x>2 || day>31) return 0;
  if (q[x] != '-') return 0;
  q+=x+1;
  m-=x+1;
  mon=get_month(q,m);
  if (-1==mon) return 0;
  if (q[3]!='-') return 0;
  q+=4;
  if (m<5) return 0;
  m-=4;
  x=get_ulong(q,m,&year);
  if (!x || q[x]!=' ') return 0;
  if (!fix_year(&year)) return 0;

  x=scan_time(p[3],l[3],&hour,&min,&sec,&mtimetype);
  if (x!=l[3]) return 0;

  f->mtimetype = mtimetype;;
  utcdate2tai (&f->mtime,year,mon,day,hour,min,sec);

  for (x=0;x<l[0];x++)
    if (p[0][x]==';')
      break;
  if (x>4) 
    if (p[0][x-4]=='.'
     && p[0][x-3]=='D'
     && p[0][x-2]=='I'
     && p[0][x-1]=='R') {
      x-=4;
      f->flagtrycwd=1;
    }
  if (!f->flagtrycwd)
    f->flagtryretr=1;

  f->namelen=x;
  f->name=p[0];
  if (f->name[0]=='[') {
    /* [dir]file.maybe */
    unsigned int y;
    for (y=1;y<f->namelen;y++)
      if (f->name[y]==']')
	break;
    if (y!=f->namelen) y++; /* skip ] */
    if (y!=f->namelen) {
      f->name+=y;
      f->namelen-=y;
    }
  }
  return 1;
}
static int 
parse_unix(struct ftpparse *f, char *buf, int len, 
  char *p[], int l[], unsigned int count)
{

  /* the horror ... */

  /* this list has been taken from Daniel Bernsteins ftpparse.c */

  /* UNIX-style listing, without inum and without blocks */
  /* "-rw-r--r--   1 root     other        531 Jan 29 03:26 README" */
  /* "dr-xr-xr-x   2 root     other        512 Apr  8  1994 etc" */
  /* "dr-xr-xr-x   2 root     512 Apr  8  1994 etc" */
  /* "lrwxrwxrwx   1 root     other          7 Jan 25 00:17 bin -> usr/bin" */
  /* Also produced by Microsoft's FTP servers for Windows: */
  /* "----------   1 owner    group         1803128 Jul 10 10:18 ls-lR.Z" */
  /* "d---------   1 owner    group               0 May  9 19:45 Softlib" */
  /* Also WFTPD for MSDOS: */
  /* "-rwxrwxrwx   1 noone    nogroup      322 Aug 19  1996 message.ftp" */
  /* Also NetWare: */
  /* "d [R----F--] supervisor            512       Jan 16 18:53    login" */
  /* "- [R----F--] rhesus             214059       Oct 20 15:27    cx.exe" */
  /* Also NetPresenz for the Mac: */
  /* "-------r--         326  1391972  1392298 Nov 22  1995 MegaPhone.sit" */
  /* "drwxrwxr-x               folder        2 May 10  1996 network" */
  /*restructured: */
  /* -PERM   1    user  group  531      Jan  29      03:26  README           */
  /* dPERM   2    user  group  512      Apr  8       1994   etc              */
  /* dPERM   2    user  512    Apr      8    1994    etc                     */
  /* lPERM   1    user  group  7        Jan  25      00:17  bin -> usr/bin   */
  /* -PERM   1    user  group  1803128  Jul  10      10:18  ls-lR.Z          */
  /* dPERM   1    user  group  0        May  9       19:45  Softlib          */
  /* -PERM   1    user  group  322      Aug  19      1996   message.ftp      */
  /* d [R----F--] user  512    Jan      16   18:53   login                   */
  /* - [R----F--] user  214059 Oct      20   15:27   cx.exe                  */
  /* -PERM  326   NUMB  NUMBER Nov      22   1995    MegaPhone.sit           */
  /* dPERM  folder 2    May    10       1996 network                         */
  /* handled as: */
  /* dPERM  folder      2      May      10   1996    network                 */
  /* 0      1     2     3      4        5    6       7       8 */

  /* note the date system: MON DAY [YEAR|TIME] */


  int mon=-1; /* keep gcc quiet */
  unsigned long day;
  unsigned long year;
  unsigned long hour;
  unsigned long min;
  unsigned long sec;
  uint64 size;
  int flagtrycwd=0;
  int flagtryretr=0;
  unsigned int i;
  int x;
  int mtimetype;
  int may_have_size=0;

  switch(p[0][0]) {
  case 'd': flagtrycwd=1; break;
  case '-': flagtryretr=1; break;
  case 'l': flagtryretr=flagtrycwd=1; break;
  }
  i=3;
  if (l[1]==6 && my_byte_equal(p[1],l[1],"folder"))
    i=2;

  x=get_uint64(p[i],l[i],&size);
  if (x==l[i]) may_have_size=1;
  i++;

  while (i<count) {
    mon=get_month(p[i],l[i]);
    if (-1==mon) {
      /* may be size */
      x=get_uint64(p[i],l[i],&size);
      if (x==l[i]) may_have_size=1;
    }
    i++;
    if (-1!=mon) break;
  }
  if (i==count) return 0;

  x=get_ulong(p[i],l[i],&day);
  if (!x) return 0;
  if (p[i][x]!=' ') return 0;
  if (++i==count) return 0;

  x=get_ulong(p[i],l[i],&year);
  if (!x) return 0;
  if (p[i][x]==':') {
    x=scan_time(p[i],l[i],&hour,&min,&sec,&mtimetype);
    if (x!=l[i]) return 0;
    year=guess_year(mon,day);
  } else {
    mtimetype=FTPPARSE_MTIME_REMOTEDAY;
    hour=min=sec=0;
/* may be this case: */
/* - [-RWCE-F-] mlm                   11820 Feb  3 93 12:00  drivers.doc */
    if (i+2<count) {
      x=scan_time(p[i+1],l[i+1],&hour,&min,&sec,&mtimetype);
      if (x!=l[i+1]) {
	hour=min=sec=0;
	mtimetype=FTPPARSE_MTIME_REMOTEDAY;
      } else
	i++;
    }
    if (!fix_year(&year)) return 0;
  }
  if (++i==count) return 0;
  /* note: dosplit eats spaces - but we need them here. So go back. */
  f->name=p[i];
  f->namelen=buf+len-p[i];
  /* "-rwxrwxrwx   1 noone    nogroup      322 Aug 19  1996 message.ftp" */
  /* "-rwxrwxrwx   1 noone    nogroup      322 Aug 19  1996   spacy" */
  /* but: */
  /* "d [R----F--] supervisor            512       Jan 16 18:53    login" */
  if (p[0][1]!=' ') {
    while (f->name[-2]==' ') {
      f->name--;
      f->namelen++;
    }
  }
  if (may_have_size) {
    f->sizetype=FTPPARSE_SIZE_BINARY;
    f->size=size;
  }
  f->flagtryretr=flagtryretr;
  f->flagtrycwd=flagtrycwd;
  utcdate2tai (&f->mtime,year,mon,day,hour,min,sec);
  f->mtimetype=mtimetype;
  f->format=FTPPARSE_FORMAT_LS; /* for programs dealing with symlinks */

  if ('l'==*buf) {
    unsigned int j;
    for (j=1;j<f->namelen-4;j++) /* 1, -4: no empty names, please */
      if (f->name[j]==' '
       && f->name[j+1]=='-'
       && f->name[j+2]=='>'
       && f->name[j+3]==' ') {
	f->symlink=f->name+j+4;
	f->symlinklen=f->namelen-j-4;
	f->namelen=j;
	break;
      }
  }
  return 1;
}
static int parse_supertcp(struct ftpparse *f, char *p[], int l[], 
  unsigned int count)
{
  unsigned long mon;
  unsigned long day;
  unsigned long year;
  unsigned long hour;
  unsigned long min;
  unsigned long sec;
  int mtimetype;
  uint64 size=0; /* optional, dirs */
  int x;
  int dir=0;

/* CMT             <DIR>           11-21-94        10:17 */
/* DESIGN1.DOC          11264      05-11-95        14:20 */

  if (count<4) return 0;
  x=scan_time(p[3],l[3],&hour,&min,&sec,&mtimetype);
  if (x!=l[3]) return 0;


  x=get_ulong(p[2],l[2],&mon); 
  if (x!=2 || p[2][x]!='-') return 0;
  x++;
  x+=get_ulong(p[2]+x,l[2]-x,&day); 
  if (x!=5 || p[2][x]!='-') return 0;
  x++;
  x+=get_ulong(p[2]+x,l[2]-x,&year); 
  if ((x!=8  && x!=10) || p[2][x]!=' ') return 0;
  if (!fix_year(&year)) return 0;
  if (my_byte_equal(p[1],5,"<DIR>")) 
    dir=1;
  else {
    x=get_uint64(p[1],l[1],&size);
    if (!x || p[1][x]!=' ') return 0;
  }

  f->name=p[0];
  f->namelen=l[0];
  f->size=size;
  if (!dir)
    f->sizetype=FTPPARSE_SIZE_BINARY;
  utcdate2tai (&f->mtime,year,mon,day,hour,min,sec);
  f->mtimetype=mtimetype;
  if (dir) f->flagtrycwd=1;
  else     f->flagtryretr=1;
  return 1;
}

/* another bright re-invention of a broken wheel from the people, who
 * made an art of it.
 */
static int 
parse_os2(struct ftpparse *f, char *p[], int l[], 
  unsigned int count)
{
/*         0           DIR   04-11-95   16:26  ADDRESS
 *       612      A          07-28-95   16:45  air_tra1.bag
 *    310992                 06-28-94   09:56  INSTALL.EXE
 */
  unsigned long mon;
  unsigned long day;
  unsigned long year;
  unsigned long hour;
  unsigned long min;
  unsigned long sec;
  int mtimetype;
  uint64 size;
  int x;
  unsigned int i;
  int dir=0;
  if (count<4) return 0;

  x=get_uint64(p[0],l[0],&size);
  if (!x || p[0][x]!=' ') return 0;
  
  for (i=1; i<count-2; i++) {
    x=get_ulong(p[i],l[i],&mon);
    if (!x) continue;
    if (x!=2 || p[i][x]!='-') return 0;
    mon-=1;
    x++;
    x+=get_ulong(p[i]+x,l[i]-x,&day);
    if (x!=5 || p[i][x]!='-') return 0;
    x++;
    x+=get_ulong(p[i]+x,l[i]-x,&year);
    if (x!=8 || p[i][x]!=' ') return 0;
    if (!fix_year(&year)) return 0;
    break;
  }
  if (i>1)
    if (my_byte_equal(p[i-1],3,"DIR")) 
      dir=1;
  i++;

  if (i==count) return 0;
  x=scan_time(p[i],l[i],&hour,&min,&sec,&mtimetype);
  if (x!=l[i]) return 0;
  i++;
  if (i==count) return 0;

  f->name=p[i];
  f->namelen=l[i];
  if (dir) {
    f->flagtrycwd=1;
  } else {
    f->flagtryretr=1;
    f->sizetype=FTPPARSE_SIZE_BINARY;
    f->size=size;
  }
  utcdate2tai (&f->mtime,year,mon,day,hour,min,sec);
  f->mtimetype=mtimetype;
  return 1;
}

#define SETUP() do {\
  fp->name = 0;                            \
  fp->namelen = 0;                         \
  fp->flagtrycwd = 0;                      \
  fp->flagtryretr = 0;                     \
  fp->sizetype = FTPPARSE_SIZE_UNKNOWN;    \
  fp->size = 0;                            \
  fp->mtimetype = FTPPARSE_MTIME_UNKNOWN;  \
  tai_uint(&fp->mtime,0);                  \
  fp->idtype = FTPPARSE_ID_UNKNOWN;        \
  fp->id = 0;                              \
  fp->idlen = 0;                           \
  fp->format = FTPPARSE_FORMAT_UNKNOWN;    \
  fp->flagbrokenmlsx=0;                    \
  fp->symlink=0;                       \
  fp->symlinklen=0;                       \
} while(0)

int
ftpparse_mlsx (struct ftpparse *fp, char *x, int ll, int is_mlst)
{
  int i;
  uint64 size;
  struct tai mtime;
  int flagtryretr=0;
  int flagtrycwd=0;
  char *id=0;
  int idlen=0;
  int mtimetype=FTPPARSE_MTIME_UNKNOWN;
  int sizetype=FTPPARSE_SIZE_UNKNOWN;
  int flagbrokenmlsx=0;
  SETUP();
  if (is_mlst)
    if (ll>1) {
      ll--;
      x++;
    }
  if (ll<2) /* empty facts, space, one-byte-filename */
    return 0;

  for (i=0; i<ll;i++) {
    int j=0,k=0;
    if (x[i]==' ')
      break; /* end of facts */
    while (i+j<ll && x[i+j]!=';' && x[i+j]!=' ' && x[i+j]!='=')
      j++;
    if (i+j==ll)
      return 0;
    if (x[i+j]==' ')
      return 0;
    if (x[i+j]==';')
      return 0;
    /* x[i+j] is now '=' */
    while (i+j+k<ll && x[i+j+k]!=';' && x[i+j+k]!=' ')
      k++;
    if (i+j+k==ll)
      return 0;
    /* x[i+j+k] is space or semicolon, so use of getlong is safe */
#define ISFACT(name) (j==sizeof(name)-1 && case_startb(x+i,j,name))
    if (ISFACT ("size")) {
      get_uint64 (x + i + j + 1, k - 1,&size);
      sizetype=FTPPARSE_SIZE_BINARY;
    } else if (ISFACT ("modify")) {
      getmod(&mtime,x + i + j + 1, k - 1);
      mtimetype = FTPPARSE_MTIME_LOCAL;
    } else if (ISFACT ("type")) {
      if (k==5 && case_startb (x + i + j + 1, 4, "file"))
	flagtryretr = 1;
      else if (case_startb (x + i + j + 1, 3, "dir")) /* "current" */
	flagtrycwd = 1;
      else if (case_startb (x + i + j + 1, 4, "pdir")) /* "parent" */
	flagtrycwd = 1;
      else if (case_startb (x + i + j + 1, 4, "cdir"))
	flagtrycwd = 1;
      else {
        flagtryretr = 1;
        flagtrycwd = 1;
      }
    } else if (ISFACT ("unique")) {
      id = x + i + j + 1;
      idlen = k - 1;
    }
    i+=j+k;
    if (x[i]==' ') {
      flagbrokenmlsx=1;
      break;
    }
  }
  if (ll==i) return 0;
  i++;
  if (ll==i) return 0;
  fp->name = x + i;
  fp->namelen = ll - i;
  fp->sizetype = sizetype;
  fp->size=size;
  fp->mtimetype = mtimetype;
  fp->mtime=mtime;
  fp->flagtrycwd=flagtrycwd;
  fp->flagtryretr=flagtryretr;
  if (id) {
    fp->idtype = FTPPARSE_ID_FULL;
    fp->id=id;
    fp->idlen=idlen;
  }
  fp->flagbrokenmlsx=flagbrokenmlsx;
  fp->format=FTPPARSE_FORMAT_MLSX;
  return 1;
}

static int 
ftpparse_int(struct ftpparse *fp,char *buf,int len)
{
  unsigned int count;
  char *p[MAXWORDS];
  int l[MAXWORDS] = { 0,0,0,0,0,0,0,0,0,0 };

  SETUP();

  if (len < 2) /* an empty name in EPLF, with no info, could be 2 chars */
    return 0;

  /* cheap cases first */
  switch (*buf) {
  case '+':
    if (parse_eplf(fp,buf,len))
      return 1;
    break;
  case '0': case '1': case '2': case '3': case '4':
  case '5': case '6': case '7': case '8': case '9':
    if (parse_msdos(fp,buf,len)) return 1;
    break;
  }

  count=dosplit(buf, len, p,l);

  switch(*buf) {
  case 'b': case 'c': case 'd': case 'l':
  case 'p': case 's': case '-':
    if (parse_unix(fp,buf,len,p,l,count)) return 1;
    break;
  }

  if (*buf==' ') {
    switch(p[0][0]) {
    case '0': case '1': case '2': case '3': case '4':
    case '5': case '6': case '7': case '8': case '9':
      if (parse_os2(fp,p,l,count)) return 1;
      break;
    }
  }

  if (parse_multinet(fp,p,l,count)) return 1;
  if (parse_supertcp(fp,p,l,count)) return 1;

  return 0;
}
int 
ftpparse(struct ftpparse *fp,char *buf,int len, int eat_leading_spaces)
{
  int x=ftpparse_int(fp,buf,len);
  if (!x) return x;
  if (eat_leading_spaces && fp->format!=FTPPARSE_FORMAT_EPLF
      && fp->format!=FTPPARSE_FORMAT_MLSX) 
    while (fp->namelen > 1 && fp->name[0]==' ') {
      /* leave at least a " " in the name */
      fp->name++;
      fp->namelen--;
    }
  return x;
}
