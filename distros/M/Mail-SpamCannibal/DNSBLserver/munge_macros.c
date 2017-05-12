/* munge_macros.c
 *
 * Copyright 2003 - 2009, Michael Robinton <michael@bizsystems.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 *
 *
 *	Collection of macros to speed operation of RBL name server
 *	these only work in ns.c in the 'munge_msg' subroutine
 */

#include <time.h>
u_int32_t _rr_Addr;

/*
 *
Excerpts from RFC 1035 by P. Mockapetris 
Network Working Group,  November 1987

3.2.1. Format

All RRs have the same top level format shown below:

                                    1  1  1  1  1  1
      0  1  2  3  4  5  6  7  8  9  0  1  2  3  4  5
    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    /                      NAME                     /
    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    |                      TYPE                     |
    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    |                     CLASS                     |
    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    |                      TTL                      |
    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    |                   RDLENGTH                    |
    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--|
    /                     RDATA                     /
    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+

NAME            an owner name, i.e., the name of the node to which this
                resource record pertains.

TYPE            two octets containing one of the RR TYPE codes.

CLASS           two octets containing one of the RR CLASS codes.

TTL             a 32 bit signed integer that specifies the time interval
                that the resource record may be cached before the source
                of the information should again be consulted.  Zero
                values are interpreted to mean that the RR can only be
                used for the transaction in progress, and should not be
                cached.  For example, SOA records are always distributed
                with a zero TTL to prohibit caching.  Zero values can
                also be used for extremely volatile data.

RDLENGTH        an unsigned 16 bit integer that specifies the length in
                octets of the RDATA field.

RDATA           a variable length string of octets that describes the
                resource.  The format of this information varies
                according to the TYPE and CLASS of the resource record.

Because their RDATA format is known, all domain names in the RDATA
section of these RRs may be compressed.

<domain-name> is a domain name represented as a series of labels, and
terminated by a label with zero length.  <character-string> is a single
length octet followed by that number of characters.  <character-string>
is treated as binary information, and can be up to 256 characters in
length (including the length octet).
 *
 *	need: char * rdlptr
 */

#define RR_HEAD(name,type,ttl) \
  if ((n = (dn_comp((name), cp, (IP_MAXPACKET - (cp - ns_msgbuf)), dnptrs, lastdnptr))) < 0) { \
    rcode = SERVFAIL; \
    goto NS_errorExit; \
  } \
  cp += n; \
  PUTSHORT((type),cp); \
  PUTSHORT(C_IN,cp); \
  PUTLONG((ttl),cp); \
  rdlptr = cp; \
  cp += INT16SZ

/*	clear header flags bytes	*/
#define CLEAR_FLAGS() \
  *(u_char *)(ns_msgbuf + INT16SZ) = 0; \
  *(u_char *)(ns_msgbuf + INT16SZ +1) = 0

/*
 *
3.3.9. MX RDATA format

    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    |                  PREFERENCE                   |
    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    /                   EXCHANGE                    /
    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+

PREFERENCE      A 16 bit integer which specifies the preference given to
                this RR among others at the same owner.  Lower values
                are preferred.

EXCHANGE        A <domain-name> which specifies a host willing to act as
                a mail exchange for the owner name.

MX records cause type A additional section processing for the host
specified by EXCHANGE.  The use of MX RRs is explained in detail in
[RFC-974].
 *
 */

#define RR_MX(name,pref,host,counter) \
  RR_HEAD((name),T_MX,minimum); \
  PUTSHORT((pref),cp); \
  if ((n = (dn_comp((host), cp, (IP_MAXPACKET - (cp - ns_msgbuf)), dnptrs, lastdnptr))) < 0) { \
    rcode = SERVFAIL; \
    goto NS_errorExit; \
  } \
  cp += n; \
  PUTSHORT((int)(cp - rdlptr - INT16SZ),rdlptr); \
  (counter) += 1

/*
 *
3.3.11. NS RDATA format

    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    /                   NSDNAME                     /
    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+

NSDNAME         A <domain-name> which specifies a host which should be
                authoritative for the specified class and domain.

NS records cause both the usual additional section processing to locate
a type A record, and, when used in a referral, a special search of the
zone in which they reside for glue information.

The NS RR states that the named host should be expected to have a zone
starting at owner name of the specified class.  Note that the class may
not indicate the protocol family which should be used to communicate
with the host, although it is typically a strong hint.  For example,
hosts which are name servers for either Internet (IN) or Hesiod (HS)
class information are normally queried using IN class protocols.
 *
 */

#define RR_NS(name,host,counter) \
  RR_HEAD((name),T_NS,minimum); \
  if ((n = (dn_comp((host), cp, (IP_MAXPACKET - (cp - ns_msgbuf)), dnptrs, lastdnptr))) < 0) { \
    rcode = SERVFAIL; \
    goto NS_errorExit; \
  } \
  cp += n; \
  PUTSHORT((int)(cp - rdlptr - INT16SZ),rdlptr); \
  (counter) += 1

/*
 *
3.3.13. SOA RDATA format

    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    /                     MNAME                     /
    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    /                     RNAME                     /
    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    |                    SERIAL                     |
    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    |                    REFRESH                    |
    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    |                     RETRY                     |
    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    |                    EXPIRE                     |
    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    |                    MINIMUM                    |
    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+

MNAME           The <domain-name> of the name server that was the
                original or primary source of data for this zone.

RNAME           A <domain-name> which specifies the mailbox of the
                person responsible for this zone.

SERIAL          The unsigned 32 bit version number of the original copy
                of the zone.  Zone transfers preserve this value.  This
                value wraps and should be compared using sequence space
                arithmetic.

REFRESH         A 32 bit time interval before the zone should be
                refreshed.

RETRY           A 32 bit time interval that should elapse before a
                failed refresh should be retried.

EXPIRE          A 32 bit time value that specifies the upper limit on
                the time interval that can elapse before the zone is no
                longer authoritative.

MINIMUM         The unsigned 32 bit minimum TTL field that should be
                exported with any RR from this zone.

SOA records cause no additional section processing.

All times are in units of seconds.

Most of these fields are pertinent only for name server maintenance
operations.  However, MINIMUM is used in all query operations that
retrieve RRs from a zone.  Whenever a RR is sent in a response to a
query, the TTL field is set to the maximum of the TTL field from the RR
and the MINIMUM field in the appropriate SOA.  Thus MINIMUM is a lower
bound on the TTL field for all RRs in a zone.  Note that this use of
MINIMUM should occur when the RRs are copied into the response and not
when the zone is loaded from a master file or via a zone transfer.  The
reason for this provison is to allow future dynamic update facilities to
change the SOA RR with known semantics.

NOTE: SOA records are distributed by this server with TTL's of zero.

	from rfc1035 section 3.2.1 RR definitions - FORMAT - TTL
	
	"SOA records are always distributed
	 with a zero TTL to prohibit caching."
 *
 */

/* NOTE: that serial is fresh when time tick is used, only on the first pass -- for axfr second record */
#define RR_SOA(counter) \
  RR_HEAD(zone_name,T_SOA,soa_ttl); \
  if ((n = (dn_comp(local_name, cp, (IP_MAXPACKET - (cp - ns_msgbuf)), dnptrs, lastdnptr))) < 0) { \
    rcode = SERVFAIL; \
    goto NS_errorExit; \
  } \
  cp += n; \
  if ((n = (dn_comp(contact, cp, (IP_MAXPACKET - (cp - ns_msgbuf)), dnptrs, lastdnptr))) < 0) { \
    rcode = SERVFAIL; \
    goto NS_errorExit; \
  } \
  cp += n; \
  if (dbtp_get(&dbtp,DBtarpit,(void *)&serial_rec.s_addr,sizeof(serial_rec.s_addr))) { \
    if (serial == 0) \
      serial = (u_int32_t)(time(NULL)); \
  } else { \
    serial = *(u_int32_t *)(dbtp.mgdbt.data); \
  } \
  PUTLONG(serial,cp); \
  PUTLONG(refresh,cp); \
  PUTLONG(retry,cp); \
  PUTLONG(expire,cp); \
  PUTLONG(minimum,cp); \
  n = ((int)(cp - rdlptr - INT16SZ)); \
  PUTSHORT(n,rdlptr); \
  (counter) += 1
/*
 *
3.3.14. TXT RDATA format

    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    /                   TXT-DATA                    /
    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+

TXT-DATA        One or more <character-string>s.

TXT RRs are used to hold descriptive text.  The semantics of the text
depends on the domain where it is found.
 *
 */
 
#define RR_TXT(name,txt,counter) \
  RR_HEAD((name),T_TXT,minimum); \
  *cp++ = strlen((txt)); \
  strcpy(cp,(txt)); \
  cp += strlen((txt)); \
  PUTSHORT((int)(cp - rdlptr - INT16SZ),rdlptr); \
  (counter) += 1

/*
 *
3.4. Internet specific RRs

3.4.1. A RDATA format

    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    |                    ADDRESS                    |
    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+

ADDRESS         A 32 bit Internet address.

Hosts that have multiple Internet addresses will have multiple A records.
A records cause no additional section processing.  The RDATA section of
an A line in a master file is an Internet address expressed as four
decimal numbers separated by dots without any imbedded spaces (e.g.,
"10.2.0.52" or "192.0.5.6").

4.1.3. Resource record format

The answer, authority, and additional sections all share the same
format: a variable number of resource records, where the number of
records is specified in the corresponding count field in the header.
Each resource record has the following format:
                                    1  1  1  1  1  1
      0  1  2  3  4  5  6  7  8  9  0  1  2  3  4  5
    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    /                      NAME                     /
    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    |                      TYPE                     |
    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    |                     CLASS                     |
    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    |                      TTL                      |
    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    |                   RDLENGTH                    |
    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--|
    /                     RDATA                     /
    /                                               /
    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+

NAME            a domain name to which this resource record pertains.

TYPE            two octets containing one of the RR type codes.  This
                field specifies the meaning of the data in the RDATA
                field.

CLASS           two octets which specify the class of the data in the
                RDATA field.

TTL             a 32 bit unsigned integer that specifies the time
                interval (in seconds) that the resource record may be
                cached before it should be discarded.  Zero values are
                interpreted to mean that the RR can only be used for the
                transaction in progress, and should not be cached.

RDLENGTH        an unsigned 16 bit integer that specifies the length in
                octets of the RDATA field.

RDATA           a variable length string of octets that describes the
                resource.  The format of this information varies
                according to the TYPE and CLASS of the resource record.
                For example, the if the TYPE is A and the CLASS is IN,
                the RDATA field is a 4 octet ARPA Internet address.
 *
 */

#define RR_A(name,addr,counter) \
  RR_HEAD((name),T_A,minimum); \
  PUTSHORT(INADDRSZ,rdlptr); \
  _rr_Addr = htonl(*(addr)); \
  PUTLONG(_rr_Addr,cp); \
  (counter) += 1

/*
 *	big macros to do multiple RR's
 * 
 *	need:	char * Hptr;
 *		int i;
 *		u_int32_t * Aptr, * Astart;
 */

/*	add all NS names
	always for ZONE name
 */

#define ADD_NS_names(counter) \
  for(i=0;i<h_name_ctr;i++) { \
    if (mxmark[i]) \
	continue; \
    Hptr = current_name(i); \
    RR_NS(zone_name,Hptr,(counter)); \
  }

/*	add all MX names
	always for ZONE name
 */

#define ADD_MX_names(counter) \
  for(i=0;i<h_name_ctr;i++) { \
    if (mxmark[i] == 0) \
	continue; \
    Hptr = current_name(i); \
    RR_MX(zone_name,mxmark[i],Hptr,(counter)); \
  }

/*	add all NS A records
	always for ZONE name
 */

#define ADD_NS_A(counter) \
  for(i=0;i<h_name_ctr;i++) { \
    if (mxmark[i]) \
        continue; \
    Hptr = current_name(i); \
    Aptr = Astart = current_Astart(i); \
    do { \
	RR_A(Hptr,Aptr,(counter)); \
    } while((Aptr = next_A_record(Astart,Aptr)) != NULL); \
  }

/*	add all NS A records except "name"	*/

#define ADD_NS_A_without(name,counter) \
  for(i=0;i<h_name_ctr;i++) { \
    if (mxmark[i]) \
        continue; \
    Hptr = current_name(i); \
    if(strcasecmp(Hptr,(name)) == 0) \
	continue; \
    Aptr = Astart = current_Astart(i); \
    do { \
	RR_A(Hptr,Aptr,(counter)); \
    } while((Aptr = next_A_record(Astart,Aptr)) != NULL); \
  }  

/*	add all A records
	always for ZONE name
 */

#define ADD_ALL_A(counter) \
  for(i=0;i<h_name_ctr;i++) { \
    Hptr = current_name(i); \
    Aptr = Astart = current_Astart(i); \
    do { \
	RR_A(Hptr,Aptr,(counter)); \
    } while((Aptr = next_A_record(Astart,Aptr)) != NULL); \
  }

/*	add all A records except "name"	*/

#define ADD_ALL_A_without(name,counter) \
  for(i=0;i<h_name_ctr;i++) { \
    Hptr = current_name(i); \
    if(strcasecmp(Hptr,(name)) == 0) \
	continue; \
    Aptr = Astart = current_Astart(i); \
    do { \
	RR_A(Hptr,Aptr,(counter)); \
    } while((Aptr = next_A_record(Astart,Aptr)) != NULL); \
  }  

/*	add local A records	*/

#define ADD_local_A(counter) \
  for(i=0;i<visibleMAXeth;i++) { \
    if (localip[i] == 0) \
	break; \
    RR_A(local_name,&(localip[i]),(counter)); \
  }


/*
 *
4.2.2. TCP usage

Messages sent over TCP connections use server port 53 (decimal).  The
message is prefixed with a two byte length field which gives the message
length, excluding the two byte length field.  This length field allows
the low-level processing to assemble a complete message before beginning
to parse it.
 *
 */
