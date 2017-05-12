/* host_info.c
 *
 */
 
#include <stdio.h>
#include <unistd.h>
#include <netinet/in.h>
#include <arpa/nameser.h>
#include <resolv.h>
#include <netdb.h>
#include <string.h>
#include <sys/socket.h>
#include <arpa/inet.h>
#include <db.h>				/* sucks in u_int32_t defs for dumb os's	*/

/* 	from netdb.h
      struct hostent {
	      char    *h_name;		official name of host
	      char    **h_aliases;	alias list
	      int     h_addrtype;	host address type
	      int     h_length;		length of address
	      char    **h_addr_list;	list of addresses
      }
      #define h_addr  h_addr_list[0]	for backward compatibility
*/

#define MAXeth		10		/* allow room for 10 ip addresses	*/
#define MAXipsize	INADDRSZ	/* packed network address		*/
#define MAXipbuf	MAXeth

#define MAXns		15		/* maximum number of name servers	*/
#define MAXnsbuf	MAXns * MAXname

char hostbuf[MAXns * MAXDNAME];		/* buffer space for real names	*/
int mxmark[MAXns];			/* MX marker	*/
u_int32_t A_records[MAXns * MAXipbuf];	/* A records	*/
char local_name_buf[MAXDNAME];		/* local host name for SOA	*/
char * local_name = local_name_buf;
int local_name_len;			/* length of local_name		*/
u_int32_t localip[MAXeth];		/* local IP addresses		*/
const int visibleMAXeth = MAXeth;	/* pass to other modules without .h file	*/
int gh_error;				/* get hostent error		*/

int h_name_ctr = 0;			/* name record count		*/

/*	Storage is organized so that the local host name is always the
	first entry in the 'hostbuf' as well as the A_records.
	Subsequent entries are for NameServers. Hostbuf is incremented
	in by MAXDNAME, and 'A_records incremented on the low level by
	one, and for each new name by MAXipbuf.
 */

/*	Set hostbuf to ZERO, 
	Set A_records to ZERO, 
	return a pointer to beginning of buffer
 */

void
init_names()
{
  extern char hostbuf[];
  extern u_int32_t A_records[];
  extern int h_name_ctr;
  memset(A_records,0,MAXns * MAXipbuf * INADDRSZ);
  memset(hostbuf,0,MAXns * MAXDNAME);
  memset(mxmark,0,MAXns * INT16SZ);	/* interger array	*/
  h_name_ctr = 0;			/* init buffer pointer	*/
}
  
/*	get a pointer to the current name
	based on the input name number
	Returns NULL if attempt to overrun buffer
 */

char *
current_name(int n)
{
  if (n >= MAXns)
  	return(NULL);
  return(hostbuf +(MAXDNAME * n));
}

/*	Insert a name into hostbuf
	same as above (insert_A_record)
	Return NULL on buffer full
 */
 
char *
insert_name(char * Hptr, char * src)
{
  extern int h_name_ctr;
  if(Hptr == NULL)
  	return(NULL);
  if (h_name_ctr < MAXns) {
    strncpy(Hptr,src,MAXDNAME);
    h_name_ctr++;
  }
  return(current_name(h_name_ctr));
}

/* 	Insert an A record, IP address
	into the an A_records array.
	Enter with current A_record pointer,
	return next A_record pointer or
	NULL if the buffer is full.

	Astart points to the beginning
	of the local buffer for this name
 */
 
u_int32_t *
insert_A_record(u_int32_t * Astart, u_int32_t * Aptr, u_int32_t ipaddr)
{
  if (Aptr == NULL)
  	return(NULL);
  if (Aptr < Astart + MAXipbuf)
	*Aptr++ = ipaddr;
  if (Aptr < Astart + MAXipbuf)
	return(Aptr);
  return(NULL);
}

/*	get the next IP address pointer
	from A_record. Return NULL if
	there is no next record.

	Astart points to the beginning
	of the local buffer for this name
 */

u_int32_t *
next_A_record(u_int32_t * Astart, u_int32_t * Aptr)
{
  if (Aptr == NULL)
  	return(NULL);
  if (Aptr < Astart + MAXipbuf)
	Aptr++;
  if (Aptr < Astart + MAXipbuf) {
     if (*Aptr != 0)
  	return(Aptr);
  }
  return(NULL);
}

/*	get pointer to beginning of 
	A_records for current hostname
 */
 
u_int32_t *
current_Astart(int n)
{
  extern u_int32_t A_records[];
  return(A_records + (MAXipbuf * n));
}

/*	get hostent record

	if hostname is NULL, then
	lookup the local host and
	extern local_name will be 
	used as scratch space.

	if Aptr is 0, lookup
	the IP addresses for 'hostname'

	official hostname ends up in
	'hostbuf' and the IP addrs
	end up in 'A_records'
	
	Astart points to the beginning of
	the local IP buffer for this name

	return pointer to hostent on success
    else
    	the error is stored in
    	extern int gh_error
    	-3	memory full
	-1	gethostname failed
	1	HOST_NOT_FOUND
	2	TRY_AGAIN
	3	NO_RECOVERY
	4	NO_ADDRESS or NO_DATA

 */
 
struct hostent *
get_hostent(char * hostname)
{
  extern char * local_name;
  extern int gh_error;
  struct hostent * hep;

  if (hostname == NULL) {
    if ((gh_error = gethostname(local_name,MAXDNAME)) != 0)	/* get short? hostname	*/
	return(NULL);
    hostname = local_name;
  }
  if ((hep = gethostbyname(hostname)) == NULL) {	/* get host info	*/
	gh_error = h_errno;
	return(NULL);
  }
  return(hep);
}

/*	get the host name + domain for this host	*/

int
set_local_name()
{
  struct hostent * hep;
  extern char * local_name;
  extern int h_name_ctr, gh_error;
  extern u_int32_t localip[];
  int i, j;
  char * Hptr;
  u_int32_t ** hip, * Aptr, * Astart;

  memset(localip,0,MAXeth * INADDRSZ);

  if (local_name != local_name_buf) {	/* hostname set with -H flag		*/
    i = 0;
    for(j=0; j < h_name_ctr; j++) {	/* find the local ip address(es)	*/
      Hptr = current_name(j);
      if ((strcasecmp(Hptr,local_name)) == 0) {
        Aptr = Astart = current_Astart(j);
        do {
          localip[i] = *Aptr;
          i++;
       } while ((Aptr = next_A_record(Astart,Aptr)) != NULL && i < visibleMAXeth);
        break;
      }
    }
    if (j >= h_name_ctr)
      return(99);			/* Cannot assign requested address	*/
  }
  else if ((hep = get_hostent(NULL)) != NULL) {
    strncpy(local_name,hep->h_name,MAXDNAME);
    hip = (u_int32_t **)(hep->h_addr_list);
    for(i=0; i < MAXeth; i++) {
      if(*hip == NULL)
	break;
      localip[i] = **hip;
      hip++;
    }
  } else
    return(gh_error);

  local_name_len = strlen(local_name);
  return(0);
}
  
/*	Insert a NS name and A records

	if hostname is NULL, then
	lookup the local host and
	extern local_name will be 
	used as scratch space.
    BUT.... this should never happen
    
	if haveArecs is true, A records
	will not be added via DNS info,
	you have to do it manually

	returns 0 on success
    else
	-3	storage full
	-1	gethostname failed
	1	HOST_NOT_FOUND
	2	TRY_AGAIN
	3	NO_RECOVERY
	4	NO_ADDRESS or NO_DATA

 */
 
int
add_ns_info(char * hostname,int haveArecs)
{
  extern int h_name_ctr;
  u_int32_t ** hip, * Astart, * Aptr;
  struct hostent * hep;
  int i;
  char * Hptr;
  
  if (h_name_ctr == 0)
	init_names();
  
  if ((Hptr = current_name(h_name_ctr)) == NULL)
  	return(-3);
  
  Aptr = Astart = current_Astart(h_name_ctr);
    
  if(haveArecs) {
    insert_name(Hptr,hostname);
    return(0);
  }
  if ((hep = get_hostent(hostname)) == NULL)
    	return(gh_error);

  if( hep->h_length != 4)
	return(-2);

  insert_name(Hptr,hep->h_name);
  
  hip = (u_int32_t **)(hep->h_addr_list);
  
  for(i=0; i < MAXeth; i++) {
    if(*hip == NULL)
	break;
    Aptr = insert_A_record(Astart, Aptr,(u_int32_t)(**hip));
    hip++;
  }
  return(0);
}

/*	print ns info to stdout	*/

void
report_ns()
{
  extern int h_name_ctr, mxmark[];
  struct in_addr in;
  int n;
  char * Hptr;
  u_int32_t * Astart, * Aptr;
  for(n=0;n<h_name_ctr;n++) {
    Hptr = current_name(n);
    if (mxmark[n]) {
      printf("MX =>\t%d  %s\n",mxmark[n],Hptr);
    } else {
      printf("NS =>\t%s\n",Hptr);
    }
    Aptr = Astart = current_Astart(n);
    do {
      in.s_addr = *Aptr;
      printf("\t%s\n",inet_ntoa(in));
    }  while((Aptr = next_A_record(Astart,Aptr)) != NULL);
  }
}

/*
int
main()
{
  struct in_addr in;
  char *hs[16] = { 
	"mx1.hotmail.com",
	"ns2.bizsystems.net",
	"gins1.grtimp.com",
	"earthlink.net",
	"gins2.grtimp.com",
	"ns3.bizsystems.net",
	"yahoo.com",
	"facebook.com",
	"myspace.com",
	"paypal.com",
	"att.com",
	"youtube.com",
	"monster.com",
	"time.com",
	"nytimes.com",
	"washingtonpost.com"
  };
  
  int status, n;

  for(n=0;n<16;n++) {
    if (n == -1) {
      status = add_ns_info(NULL,0);
    }
    else {
      status = add_ns_info(hs[n],0);
    }
    if(status != 0) {
  	printf("ERROR: %d\n",status);
	break;
    }
  }

  mxmark[2] = 55;
  report_ns();
  set_local_name();
  printf("this host => %s\n",local_name);
  for(n=0;n<MAXeth;n++) {
    if ((in.s_addr = localip[n]) == 0)
    	break;
    printf("\t%s\n",inet_ntoa(in));
  }
}
 */
