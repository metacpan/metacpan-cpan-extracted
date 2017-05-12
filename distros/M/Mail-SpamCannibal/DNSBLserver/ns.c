/* ns.c
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
*/

#include <string.h>
#include <netinet/in.h>
#include <netinet/in_systm.h>
#include <arpa/nameser.h>
#include <resolv.h>
#include <sys/types.h>
#include "bswap32.h"
#include <sys/socket.h>
#include <arpa/inet.h>
#include "misc_func.h"

/*

    There are more include files specific to the application 
    where the code begins below

 ****************************************************
      The header contains the following fields:

                                           1  1  1  1  1  1
             0  1  2  3  4  5  6  7  8  9  0  1  2  3  4  5
           +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
           |                      ID                       |
           +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
           |QR|   Opcode  |AA|TC|RD|RA|        |   RCODE   |
           +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+  
           |                    QDCOUNT                    |
           +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
           |                    ANCOUNT                    |
           +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
           |                    NSCOUNT                    |
           +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
           |                    ARCOUNT                    |
           +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+

	from arpa/nameser_compat.h (ignoring endianness)

  typedef struct {
        unsigned        id :16;         query identification number 
                      fields in third byte 
        unsigned        qr: 1;          response flag 
        unsigned        opcode: 4;      purpose of message 
        unsigned        aa: 1;          authoritive answer 
        unsigned        tc: 1;          truncated message, forces the use of TCP 
        unsigned        rd: 1;          recursion desired 
                      fields in fourth byte 
        unsigned        ra: 1;          recursion available 
        unsigned        unused :1;      unused bits (MBZ as of 4.9.3a3) 
        unsigned        ad: 1;          authentic data from named 
        unsigned        cd: 1;          checking disabled by resolver 
        unsigned        rcode :4;       response code 
        unsigned        qdcount :16;    number of question entries 
        unsigned        ancount :16;    number of answer entries 
        unsigned        nscount :16;    number of authority entries 
        unsigned        arcount :16;    number of resource entries 
  } HEADER;

  #define NOERROR	0  ns_r_noerror	 No error occurred
  #define FORMERR	1  ns_r_formerr	 Format error
  #define SERVFAIL	2  ns_r_servfail Server failure
  #define NXDOMAIN	3  ns_r_nxdomain Name error
  #define NOTIMP	4  ns_r_notimpl	 Unimplemented
  #define REFUSED	5  ns_r_refused	 Operation refused
  #define YXDOMAIN	6  ns_r_yxdomain Name exists
  #define YXRRSET	7  ns_r_yxrrset	 RRset exists
  #define NXRRSET	8  ns_r_nxrrset	 RRset does not exist
  #define NOTAUTH	9  ns_r_notauth	 Not authoritative for zone
  #define NOTZONE	10 ns_r_notzone	 Zone of record different from zone section

  #define T_A		1   ns_t_a
  #define T_NS		2   ns_t_ns
  #define T_SOA		6   ns_t_soa
  #define T_MX		15  ns_t_mx
  #define T_TXT		16  ns_t_txt
  #define T_AXFR	252 ns_t_axfr
  #define T_ANY		255 ns_t_any

 *
 *
 ***********************************************
 *	Plan
 *
	if (message <= headersize) {
		ignore, do not answer
	}
	if (Query != 0) {
		ignore, do not answer
	}
	if (Opcode != 0 {
		response = NOTIMP
		goto NS_empty
	}
	if (Qcount != 1, NScount > 1 or any of ANcount, ARcount ne 0) {
		response = FORMERR
		goto NS_empty
	}
	if (Class != C_IN) {
		response = REFUSED
		goto NS_empty
	}
	host, domain = parse_addr;
	if (mydomain != domain) {
		response = NXDOMAIN
		goto NS_empty
	}
	AA = 1
	if (host+domain = zone) {
		if (Type == SOA) {
			ANS = SOA
			AUTH = NS
			ADD = NS A records
			goto NS_send
		}
		elsif (Type == A) {
			if (local name == zone name) {
				ANS = A
				AUTH = NS
				ADD = NS A records
					 less any A record above
				goto NS_send
			}
			else {
				goto AUTH SOA
			}
		}
		elsif (Type == NS) {
			ANS = NS
		there is no AUTH
			ADD = NS A records
			goto NS_send
		}
		elsif (Type == MX) {
			ANS = MX
			AUTH = NS
			ADD = MX A records
			      NS A records
			goto NS_send
		}
		elsif (Type == ANY) {
			if (local name == zone name) {
				ANS = A
			}
			ANS = SOA
			ANS = MX
			ANS = NS
		there is no AUTH
			ADD = MX A records
			      NS A records
				 less any A record above
			goto NS_send
		}
		elsif (Type == AXFR) {
			if (blocked) {
				response = REFUSED
				goto empty
			}
			if (UDP) {
				TC = 1
			there is no ANS
				AUTH = NS
				ADD = NS A records
				goto NS_send
			}
			else {
	more......
		}
	}

	if (host NOT numeric) {
		if (Type == A || Type == ANY) {		this is not a zone, no MX, NS, SOA
			if (NS or MX match) {
				ANS = IP - A record
				AUTH = NS
				ADD = NS Arecords
				      less any A record above
				goto NS_send
			}
			else {
				goto AUTH SOA
			}
		}
	}
	elsif (host == isthere) {
		if (Type == ANY) {		this is not a zone, no MX, NS, SOA
			ANS = A
			ANS = TXT	
			AUTH = NS
			ADD = NS A records
			goto NS_send
		}
		elsif (Type == A) {
			ANS = A
			AUTH = NS
			ADD = A records for NS
			goto NS_send
		}
		elsif (Type = TXT) {
			ANS = TXT
			AUTH = NS
			ADD = A records for NS
			goto NS_send
		}
		else {
			AUTH = SOA
			goto NS_send
		}
	}
	else {

		AUTH = SOA
		goto NS_send
	}
	goto NS_send


   ************************************************
	draft-ietf-dnsext-axfr-clarify-05.txt

   3.1. Multiple answers per message

   The zone data in a zone transfer response is a sequence of answer
   RRs.  These RRs are transmitted in the answer section(s) of one or
   more DNS response messages.

   The AXFR protocol definition in RFC1034 does not make a clear
   distinction between response messages and answer RRs.  Historically,
   DNS servers always transmitted a single answer RR per message.  This
   encoding is wasteful due to the overhead of repeatedly sending DNS
   message headers and the loss of domain name compression
   opportunities.  To improve efficiency, some newer servers support a
   mode where multiple RRs are transmitted in a single DNS response
   message.

   A master MAY transmit multiple answer RRs per response message up to
   the largest number that will fit within the 65535 byte limit on TCP
   DNS message size.  In the case of a small zone, this can cause the
   entire transfer to be transmitted in a single response message.

   Slaves MUST accept messages containing any number of answer RRs.  For
   compatibility with old slaves, masters that support sending multiple
   answers per message SHOULD be configurable to revert to the
   historical mode of one answer per message, and the configuration
   SHOULD be settable on a per-slave basis.

3.2. DNS message header contents

   RFC1034 does not specify the contents of the DNS message header of
   the zone transfer response messages.  The header of each message MUST
   be as follows:

       ID      Copy from request
       QR      1
       OPCODE  QUERY
       AA      1, but MAY be 0 when RCODE is not NOERROR
       TC      0
       RD      Copy from request, or 0
       RA      Set according to availability of recursion, or 0
       Z       0
       AD      0
       CD      0
       RCODE   NOERROR on success, error code otherwise

   The slave MUST check the RCODE in each message and abort the transfer
   if it is not NOERROR.  It SHOULD check the ID of the first message
   received and abort the transfer if it does not match the ID of the
   request.  The ID SHOULD be ignored in subsequent messages, and fields
   other than RCODE and ID SHOULD be ignored in all messages, to ensure
   interoperability with certain older implementations which transmit
   incorrect or arbitrary values in these fields.

3.3 see the doc
3.4. The question section

   RFC1034 does not specify whether zone transfer response messages have
   a question section or not.  The initial message of a zone transfer
   response SHOULD have a question section identical to that in the
   request.  Subsequent messages SHOULD NOT have a question section,
   though the final message MAY.  The receiving slave server MUST accept
   any combination of messages with and without a question section.

3.5. The authority section

   The master server MUST transmit messages with an empty authority
   section.  Slaves MUST ignore any authority section contents they may
   receive from masters that do not comply with this requirement.

3.6. The additional section

   The additional section MAY contain additional RRs such as transaction
   signatures.  The slave MUST ignore any unexpected RRs in the
   additional section.  It MUST NOT treat additional section RRs as zone
   data.

4.0 see the doc
5. Transmission order

   RFC1034 states that "The first and last messages must contain the
   data for the top authoritative node of the zone".  This is not
   consistent with existing practice.  All known master implementations
   send, and slave implementations expect to receive, the zone's SOA RR
   as the first and last record of the transfer.

   Therefore, the quoted sentence is hereby superseded by the sentence
   "The first and last RR transmitted must be the SOA record of the
   zone".

   The initial and final SOA record MUST be identical, with the possible
   exception of case and compression.  In particular, they MUST have the
   same serial number.  The slave MUST consider the transfer to be
   complete when, and only when, it has received the message containing
   the second SOA record.

   The transmission order of all other RRs in the zone is undefined.
   Each of them SHOULD be transmitted only once, and slaves MUST ignore
   any duplicate RRs received.

   **************************************************************
	what that means for implementation

	Initial Record
		+-----------------------------------------------+
  Header	| OPCODE=QUERY, RESPONSE, AA			|
		+-----------------------------------------------+
  Question	| same as original				|
		+-----------------------------------------------+
  Answer	| SOA + zero or more records			|
		+-----------------------------------------------+
  Authority	| <empty>					|
		+-----------------------------------------------+
  Additional	| <empty>					|
		+-----------------------------------------------+

	Middle Records
		+-----------------------------------------------+
  Header	| OPCODE=QUERY, RESPONSE, AA			|
		+-----------------------------------------------+
  Question	| <empty>					|
		+-----------------------------------------------+
  Answer	| more records					|
		+-----------------------------------------------+
  Authority	| <empty>					|
		+-----------------------------------------------+
  Additional	| <empty>					|
		+-----------------------------------------------+

	Final Record
		+-----------------------------------------------+
  Header	| OPCODE=QUERY, RESPONSE, AA			|
		+-----------------------------------------------+
  Question	| <empty> (may contain question)		|
		+-----------------------------------------------+
  Answer	| zero or more records + SOA			|
		+-----------------------------------------------+
  Authority	| <empty>					|
		+-----------------------------------------------+
  Additional	| <empty>					|
		+-----------------------------------------------+

 ****************************************************************

  see the stuff in  bind-9.2.1/lib/bind/resolv/res_mkquery.c

 * Inline versions of get/put short/long.  Pointer is advanced
   from	/usr/include/arpa/nameser.h

	NS_GET16(s, cp)
	NS_PUT16(s, cp)

  and from /usr/include/arpa/nameser_compat.h

	#define GETSHORT                NS_GET16
	#define PUTSHORT                NS_PUT16

 */

#include <bdbtarpit.h>
#include "host_info_func.h"
#include "netio_func.h"
#include "ns.h"
#include "misc_func.h"

#include "defines.h"
#include "munge_macros.c"	/* include the macros for "munge_msg"	*/

u_char ns_msgbuf[IP_MAXPACKET];	/* message buffer	*/

/* valid characters for host part of RBL lookup ".0123456789"	*/

u_char validchars[] = {
	'\0','\0','\0','\0','\0','\0','\0','\0','\0','\0','\0','\0','\0','\0','\0','\0',
	'\0','\0','\0','\0','\0','\0','\0','\0','\0','\0','\0','\0','\0','\0','\0','\0',
	'\0','\0','\0','\0','\0','\0','\0','\0','\0','\0','\0','\0','\0','\0', '.','\0',
	 '0', '1', '2', '3', '4', '5', '6', '7', '8', '9','\0','\0','\0','\0','\0','\0',
	'\0','\0','\0','\0','\0','\0','\0','\0','\0','\0','\0','\0','\0','\0','\0','\0',
	'\0','\0','\0','\0','\0','\0','\0','\0','\0','\0','\0','\0','\0','\0','\0','\0',
	'\0','\0','\0','\0','\0','\0','\0','\0','\0','\0','\0','\0','\0','\0','\0','\0',
	'\0','\0','\0','\0','\0','\0','\0','\0','\0','\0','\0','\0','\0','\0','\0','\0',
	'\0','\0','\0','\0','\0','\0','\0','\0','\0','\0','\0','\0','\0','\0','\0','\0',
	'\0','\0','\0','\0','\0','\0','\0','\0','\0','\0','\0','\0','\0','\0','\0','\0',
	'\0','\0','\0','\0','\0','\0','\0','\0','\0','\0','\0','\0','\0','\0','\0','\0',
	'\0','\0','\0','\0','\0','\0','\0','\0','\0','\0','\0','\0','\0','\0','\0','\0',
	'\0','\0','\0','\0','\0','\0','\0','\0','\0','\0','\0','\0','\0','\0','\0','\0',
	'\0','\0','\0','\0','\0','\0','\0','\0','\0','\0','\0','\0','\0','\0','\0','\0',
	'\0','\0','\0','\0','\0','\0','\0','\0','\0','\0','\0','\0','\0','\0','\0','\0',
	'\0','\0','\0','\0','\0','\0','\0','\0','\0','\0','\0','\0','\0','\0','\0','\0',
};

/*	append an IP address to end of text string if qflag is present	*/

struct in_addr in;
char * stdErr_response;
char *
errIP()
{
  extern int qflag;
  extern struct in_addr in;
  extern char mybuffer[], * errormsg;

  if (qflag) {
    sprintf(mybuffer,"%s%s",errormsg,inet_ntoa(in));
    return(mybuffer);
  }
  return(errormsg);
}

/*	verify that the requested IP address
 *	contains only numbers and '.'
 *	returns 1 if not numeric, 0 if numeric
 */

int
not_numericIP(char * ip)
{
  register u_char * vcp = validchars;
  register u_char * cp = (u_char *)ip;
  while(*cp != '\0') {
/* printf("cp=%02X, vcp=%02X\n",*cp,vcp[*cp]); */
	if (! vcp[*cp++])
		return(1);
  }
  return(0);
}

/*	skip over a name in a dns record, cheaper than dn_expand	*/

char *
name_skip(char * cp)
{
  int i;

  for(i=0;i<MAXDNAME;i++) {
    if ( ((u_char)*(cp + i)) == 0 )
      return((char *)(cp +i + 1));
    else if ( ((u_char)*(cp + i)) < 0xC0 )
      continue;
    else 
      return((char *)(cp +i + 2));
  }
/* ERROR, should not reach	*/
  return(NULL);
}

/* serial max	= 4294967295
 * rollover	= (1 + max / 2) = 2147483648
 *
 * returns:
 *	 0	s1 = s2
 *	-1	s1 < s2
 *	 1	s1 > s2
 *	>1	undefined
 */
 
#define RollOver 2147483648

int
cmp_serial(u_int32_t s1, u_int32_t s2)
{
  u_int32_t rollover = 2147483647;

  rollover += 1;	/* silence unsigned integer compiler warning	*/
  if (s1 == s2)
    return(0);
  else if ((s1 < s2 && s2 - s1 < rollover) ||
  	   (s1 > s2 && s1 - s2 > rollover))
    return(-1);
  else if ((s1 < s2 && s2 - s1 > rollover) ||
  	   (s1 > s2 && s1 - s2 < rollover))
    return(1);
  return(2);
}

/* return message reponse A_response if response is needed, else NULL
 * sets stdErr_response
 */

u_int32_t *
ns_response(u_char * keydbt_data)
{
  extern DBTPD dbtp;
  extern struct in_addr stdResp, stdRespBeg, stdRespEnd;
  extern int zflag;
  extern char * stdErr_response, * errormsg;
  
  u_int32_t * A_resp;

  stdErr_response = errormsg;
  
  if (*keydbt_data == 0x7F) {
/*	suppress numeric record for 127.0.0.0, it is used internally
 *	127.0.0.1 should never be reported, it is the localhost
 */
    if ((*(keydbt_data +3) & 0xFE) == 0 &&
	*(keydbt_data +2) == 0 &&
	*(keydbt_data +1) == 0)
	    return(NULL);

    else if ((dbtp_get(&dbtp, DBcontrib, (void *)keydbt_data,sizeof(in.s_addr))) == 0) {
	A_resp = (u_int32_t *)dbtp.mgdbt.data;
	stdErr_response = dbtp.mgdbt.data + INADDRSZ + 1;
    }
    else {
	A_resp = &stdResp.s_addr;
	stdErr_response = errIP();
    }
  }
  else if (dbtp_get(&dbtp,DBevidence,(void *)keydbt_data,sizeof(in.s_addr)) == 0) {
    A_resp = &stdResp.s_addr;
    stdErr_response = errIP();
  }
  else if (zflag == 0)
    return(NULL);			/* do not report promiscious contributions	*/
  else if ((dbtp_get(&dbtp, DBcontrib, (void *)keydbt_data,sizeof(in.s_addr))) == 0) {
    A_resp = (u_int32_t *)dbtp.mgdbt.data;
    if (*A_resp < stdRespBeg.s_addr || *A_resp > stdRespEnd.s_addr) {
	A_resp = &stdRespBeg.s_addr;
	stdErr_response = errIP();
    }
    else {
	stdErr_response = dbtp.mgdbt.data + INADDRSZ + 1;
    }
  }
  else {
/*	should not reach this, but will if used without data in either evidence or contrib	*/
    A_resp = &stdRespBeg.s_addr;
    stdErr_response = errIP();
  }
  return(A_resp);
}
/*	verify the message integrity, 
 *	prep message for sending
 *	return -1 on error
 *
 *	We know where the message buffer
 *	so that is not passed. New
 *	message is written over the old one.
 *
 *	input:	write file descriptor (socked fd),
 *		message length,
 *		mode flag
 *  is_tcp = 0	use UDP
 *  is_tcp = 1	normal, put as much in each message as possible
 *  is_tcp = 2  for AXFR, overhead records in first packet,
 *		as much as possible in subsequent packets
 *  is_tcp >=3  for AXFR, overhead records in first packet,
 *		numeric A+TXT records in individual packets
 *		followed by closing SOA packet
 */

int
munge_msg(int fd, size_t msglen, int is_tcp)
{
  extern u_char ns_msgbuf[];
  extern char * errormsg;
  extern char * local_name;
  extern char * contact;
  extern char * zone_name;
  extern int zone_name_len;
  extern int zoneEQlocal;
  extern DBTPD dbtp;
  extern struct in_addr stdResp, stdRespBeg, stdRespEnd, serial_rec;
  extern u_int32_t refresh, retry, expire, minimum, soa_ttl, localip[];
  extern int h_name_ctr, mxmark[], visibleMAXeth;
  extern int bflag, datalog, zflag;
  extern struct sockaddr_in client;
  extern struct sockaddr * cin_ptr;
  extern char mybuffer[];
  extern char * stdErr_response;
  
  register HEADER * hp = (HEADER *) ns_msgbuf;
  register u_char * cp;
  u_char * dnptrs[20], * rdlptr;		/* for dn_expand-comp	*/
  u_char **lastdnptr, **dpp;
  u_char dnbuf[MAXDNAME];			/* maximum expanded sz	*/
  int rcode;
  u_char * eom;
  int type = 0, class = 0, n, i, qnlen, AA = 0, TC = 0, ci;
  char * notThisA, * Hptr, hostpart[MAXDNAME], * cHptr;
  u_int32_t serial = 0, ixfr_ser, axfrc = 0, * Aptr, * Astart, * A_resp;
  u_short len;
  struct in_addr rev;
  u_int ancount = 0, arcount = 0, nscount = 0, ixfrcnt;
  u_int tmsgcnt = 0, tancnt = 0, tarcnt = 0, tnscnt = 0, tbytcnt = 0;	/* statistics	*/
  size_t origqlen = msglen;
  
  do {	/* check for valid message for this zone	*/
/*	check header	*/
    if (msglen < sizeof(HEADER))	/* short message, ignore	*/
  	return(-1);

    if (hp->qr == 1)			/* response bit should be 0	*/
  	return(-1);			/* ignore			*/

    if (hp->opcode != 0) {		/* opcode should be Query	*/
	rcode = NOTIMP;
	break;
    }
    
/*	should be a single question and nothing more	*/
    if (ntohs(hp->qdcount) != 1 || hp->ancount || (ixfrcnt = ntohs(hp->nscount)) > 1 || hp->arcount) {
	rcode = FORMERR;
	break;
    }
/*	check question
 *
  The question section is used to carry the "question" in most queries,
  i.e., the parameters that define what is being asked.  The section
  contains QDCOUNT (usually 1) entries, each of the following format:

                                    1  1  1  1  1  1
      0  1  2  3  4  5  6  7  8  9  0  1  2  3  4  5
    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    |                                               |
    /                     QNAME                     /
    /                                               /
    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    |                     QTYPE                     |
    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    |                     QCLASS                    |
    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+

    where:

    QNAME	a domain name represented as a sequence of labels, where
		each label consists of a length octet followed by that
		number of octets.  The domain name terminates with the
		zero length octet for the null label of the root.  Note
		that this field may be an odd number of octets; no
		padding is used.

 *
 */
  
    cp	= ns_msgbuf + HFIXEDSZ;
    eom	= ns_msgbuf + msglen;
/*	initialize send buffer	*/
    dpp = dnptrs;
    *dpp++ = ns_msgbuf;
    *dpp++ = ns_msgbuf + HFIXEDSZ;	/* question name	*/
    *dpp++ = NULL;
    lastdnptr = dnptrs + sizeof dnptrs / sizeof dnptrs[0];

/*	get name, stash it in dnbuf	*/
    if ((n = dn_expand(ns_msgbuf, eom, cp, (char *)dnbuf, MAXDNAME)) < 0) {
	rcode = FORMERR;
	break;
    }
    cp += n;
    GETSHORT(type, cp);
    GETSHORT(class, cp);

/* ************************************	*
 *	cp now points to ANSWER sect	*
 * ************************************	*
 */

    if (cp > eom) {
	rcode = FORMERR;
	break;
    }

    origqlen = cp - ns_msgbuf;		/* set error size to just question	*/

    if (class != C_IN) {
	rcode = REFUSED;
	break;
    }
    qnlen = strlen((char *)dnbuf);		/* length of question name	*/
    if (qnlen < zone_name_len) {	/* too short, not this zone	*/
  	rcode = NXDOMAIN;
  	break;
    }
/*	name ends in zone name	*/
    if (strcasecmp((char *)(dnbuf - zone_name_len + qnlen), zone_name)) {
  	rcode = NXDOMAIN;		/* no match, not this zone	*/
	break;
    }
/*	name != zone name and zone name is not preceeded by '.'	*/
    if (qnlen != zone_name_len && *(u_char *)(dnbuf - zone_name_len + qnlen -1) != '.') {
    	rcode = NXDOMAIN;		
	break;
    }
    
    AA = 1;			/* we are authorative for this zone	*/
    rcode = NOERROR;
    break;
  } while(1);

  if (rcode != NOERROR) {
NS_errorExit:
    cp = ns_msgbuf + origqlen;	/* send back original message	*/
    goto NS_send;
  }

  if (datalog > 1 && cin_ptr != NULL) {			/* verbose logging	*/
    sprintf(mybuffer,"query type %d from %s",(u_char)type, inet_ntoa(client.sin_addr));
    LogPrint(mybuffer);
  }
  
  if (qnlen == zone_name_len) {	/* query is for zone name	*/
    switch (type) {
      case T_SOA:
/*    NS_send_SOA:	keep unused label around for now	*/
	RR_SOA(ancount);
/* AUTH	*/
	ADD_NS_names(nscount);
/* ADD	*/	
	ADD_NS_A(arcount);
	goto NS_send;
	break;
	
      case T_A:
      	if (zoneEQlocal) {
	  notThisA = local_name;
      	  ADD_local_A(ancount);
/* AUTH */
	  ADD_NS_names(nscount);
/* ADD  */
	  ADD_NS_A_without(notThisA,arcount);
	  goto NS_send;
	  break;
	} else {
/* AUTHority only	*/
	  goto NS_AuthOnly;
	  break;
	}
	
      case T_NS:
      	ADD_NS_names(ancount);
/* ADD  there is no authority section	*/
      	ADD_NS_A(arcount);
	goto NS_send;
      	break;

      case T_MX:
	ADD_MX_names(ancount);
/* AUTH */
	ADD_NS_names(nscount);
/* ADD  */
	ADD_ALL_A(arcount);
	goto NS_send;
	break;

      case T_ANY:
	notThisA = NULL;		/* flag to mark A record if used	*/
      	if (zoneEQlocal) {
	  notThisA = local_name;
	  ADD_local_A(ancount);
	}
	RR_SOA(ancount);
	ADD_NS_names(ancount);
	ADD_MX_names(ancount);
/* ADD  there is no authority section   */
	if (notThisA != NULL) {
	  ADD_ALL_A_without(notThisA,arcount);
	} else {
	  ADD_ALL_A(arcount);
	}
	goto NS_send;
	break;
	
      case T_IXFR:
	if (bflag)		/* if AXFR is blocked	*/
	  goto NS_AXFR_refuse;
	else if (ixfrcnt != 1) {
	  rcode = FORMERR;
	  goto NS_errorExit;
	}
/* if the serial record is missing, force the transfer	*/
	else if ((n = dbtp_get(&dbtp,DBtarpit,(void *)&serial_rec.s_addr,sizeof(serial_rec.s_addr))) == 0) {
	  serial = *(u_int32_t *)dbtp.mgdbt.data;
	  cp = (u_char *)name_skip((char *)cp)
		 + INT16SZ			/* TYPE			*/
		 + INT16SZ			/* CLASS		*/
		 + INT32SZ			/* TTL			*/
		 + INT16SZ;			/* RDLENGTH		*/
	  cp = (u_char *)name_skip((char *)cp);		/* skip past MNAME	*/
	  cp = (u_char *)name_skip((char *)cp);		/* skip past RNAME	*/
	  ixfr_ser = ntohl(*(u_int32_t *)cp);
	  cp = ns_msgbuf + origqlen;		/* restore pointer to question end		*/	
	  i = cmp_serial(serial,ixfr_ser);
	  if (i < 1) {
	    RR_SOA(ancount);			/* send single SOA if IXFR is not needed	*/
	    goto NS_send;
	  }
	}
/* fall into AXFR	*/

      case T_AXFR:

	if (bflag) {		/* if AXFR is blocked	*/
  NS_AXFR_refuse:
	  rcode = REFUSED;
	  goto NS_errorExit;
	}
	else if (is_tcp == 0) {
	  TC = 1;
/* AUTH  there is no answer section
 *	  ADD_NS_names(nscount);
 *	  ADD_NS_A(arcount);
 *	  goto NS_send;
 * Just send a FORMERR
 */
 	  rcode = FORMERR;
 	  goto NS_errorExit;
	  break;
	}
	else {
/* ************************************************************	*
 *	This section is pretty much independent of the rest
 *	of this routine and requires its own initialization
 *	except for the first pass through the while loop.
 *	Counter 'axfrc' denotes the progress by marking that
 *	the first SOA has been sent and tracking subsequent db 
 *	accesses to retrieve numeric records
 * ************************************************************	*
 */

	  while(1) {
	    ancount = 0;
/* prep header		*/
	    if (axfrc == 0) {		/* first time, initialization completed already, cp correct	*/
	      axfrc = 1;
	/* question remains in header as does qdcount	*/
	      RR_SOA(ancount);		/* first element is SOA	*/
	      notThisA = NULL;		/* flag to mark A record if used	*/
	      if (zoneEQlocal) {
		notThisA = local_name;
	        ADD_local_A(ancount);
	      }
	      ADD_NS_names(ancount);
	      ADD_MX_names(ancount);
	      for(ci=0;ci<h_name_ctr;ci++) {
		cHptr = current_name(ci);
/*	name ends in zone name and is not local name	*/
		if (((len = strlen(cHptr)) >= zone_name_len) &&
		    (strcasecmp((char *)(cHptr - zone_name_len + len), zone_name) == 0) &&
		     strcasecmp((char *)cHptr,local_name)) {
		  Aptr = Astart = current_Astart(ci);
		  do {
		    RR_A(cHptr,Aptr,ancount);
		  } while((Aptr = next_A_record(Astart,Aptr)) != NULL);
		}
	      }
	      if (is_tcp > 1)
	      	goto NS_AXFR_send;
	      else
	      	goto NS_AXFR_more;
	    }
/* **************************************************** *
 *	overhead records complete, add numeric records	*
 * ****************************************************	*
 *	axfrc is > 0
 */
	    hp->qdcount = 0;		/* no question for subsequent packets	*/
	    cp  = ns_msgbuf + HFIXEDSZ;
/*	initialize send buffer	*/
	    dpp = dnptrs;
	    *dpp++ = ns_msgbuf;
	    *dpp++ = NULL;
	    lastdnptr = dnptrs + sizeof dnptrs / sizeof dnptrs[0];

	NS_AXFR_more:

	    do {

	NS_AXFR_next:
		if (dbtp_getrecno(&dbtp,DBtarpit, axfrc++))
			goto NS_AXFR_last_SOA;

/*	suppress numeric record for 127.0.0.0, it is used internally
	127.0.0.1 should never be reported, it is the localhost		*/

		in.s_addr = *(u_int32_t *)dbtp.keydbt.data;	/* propagate address to (in) for errIP() use	*/

		if ((A_resp = ns_response((u_char *)dbtp.keydbt.data)) == NULL)
			goto NS_AXFR_next;		/* do not report promiscious contributions      */

		bswap32((u_char *)&rev.s_addr,(u_char *)dbtp.keydbt.data);
		sprintf((char *)dnbuf,"%s.%s",inet_ntoa(rev),zone_name);
		RR_A(dnbuf,A_resp,ancount);
		RR_TXT(dnbuf,stdErr_response,ancount);
	    } while (is_tcp < 3 && cp - ns_msgbuf < MSGsize);
/* prep header		*/
	NS_AXFR_send:
	    msglen = hp->opcode;	/* temporary storage	*/
	    CLEAR_FLAGS();		/* clear flags	*/
	    hp->qr	= 1;
	    hp->opcode	= msglen;
	    hp->aa	= AA;
	    hp->rcode	= NOERROR;
	    hp->ancount = htons(ancount);
	    hp->nscount	= 0;
	    hp->arcount	= 0;
	    msglen = cp - ns_msgbuf;
	    len = htons((u_short)msglen);
	/* collect statistics	*/
	    tancnt += ancount;
	    tbytcnt += msglen + sizeof(len);
	    tmsgcnt += 1;
	    writen(fd,(u_char *)&len,sizeof(len),is_tcp);
	    writen(fd, ns_msgbuf, msglen,is_tcp);
	  } /* end while 1 */

	NS_AXFR_last_SOA:
	  RR_SOA(ancount);
	  goto NS_send;
	  break;
	}
      default:
	rcode = NOTIMP;
	goto NS_errorExit;
      	break;

    }	/* end switch		*/
  }	/* end if zone request	*/


/*	parse out the host name	and lay
 *	a '\0' on the '.' separating zone name	*/
  memcpy(hostpart,dnbuf,(size_t)(qnlen - zone_name_len));
  *(char *)(hostpart + qnlen - zone_name_len - 1) = '\0';

/* iterator i, pointer Hptr are used in the macros and are replaced here by ci and cHptr	*/
  if (not_numericIP(hostpart)) {		/* if non numeric IP	*/
    if (type == T_A) {				/* only A records are available for our names	*/
      for(ci=0;ci<h_name_ctr;ci++) {
        cHptr = current_name(ci);
        if(strcasecmp(cHptr,(char *)dnbuf))	/* check for name as one of our NS or MX hosts	*/
      		continue;
        Aptr = Astart = current_Astart(ci);
        do {
      	  RR_A(cHptr,Aptr,ancount);
        } while((Aptr = next_A_record(Astart,Aptr)) != NULL);
        ADD_NS_names(nscount);
        ADD_NS_A_without(cHptr,arcount);
        break;
      }
      if (ci < h_name_ctr)
	  goto NS_send;		/* send if A record found	*/
      goto NS_AuthOnly;
    } else {
  NS_AuthOnly:
      rcode = NXDOMAIN;
      RR_SOA(nscount);
      goto NS_send;
    }
  }

  if (inet_aton(hostpart, &rev) == 0)		/* convert to network address	*/
	goto NS_AuthOnly;			/* punt on invalid address	*/
  bswap32((u_char *)&in.s_addr,(u_char *)&rev.s_addr); /* un-reverse IP address	*/
/*  in.s_addr = bswap_32(rev.s_addr);		un-reverse IP address	*/

/* dbtp_get returns 0 on success	*/
  if (dbtp_get(&dbtp, DBtarpit, (void *)(&in.s_addr), sizeof(in.s_addr)))	/* check if in tarpit		*/
  	goto NS_AuthOnly;

  if ((A_resp = ns_response((u_char *)(dbtp.keydbt.data))) == NULL)
  	goto NS_AuthOnly;			/* do not report promiscious contributions      */

  switch(type)
  {
    case T_ANY:
      RR_A(dnbuf,A_resp,ancount);
      RR_TXT(dnbuf,stdErr_response,ancount);
/* AUTH */
  NS_fin:
      ADD_NS_names(nscount);
/* ADD  */
      ADD_NS_A(arcount);
      goto NS_send;
      break;

    case T_A:
      RR_A(dnbuf,A_resp,ancount);
      goto NS_fin;
      break;
      
    case T_TXT:
      RR_TXT(dnbuf,stdErr_response,ancount);
      goto NS_fin;
      break;
      
    default:
	rcode = NOTIMP;
	goto NS_errorExit;
	break;
  }

  NS_send:
    msglen = hp->opcode;	/* temporary storage	*/
    CLEAR_FLAGS();		/* clear flags	*/
    hp->qr	= 1;
    hp->opcode	= msglen;
    hp->aa	= AA;
    hp->tc	= TC;
    hp->rcode	= rcode;
    hp->ancount	= htons(ancount);
    hp->nscount	= htons(nscount);
    hp->arcount	= htons(arcount);

  /* collect statistics	*/
  tancnt += ancount;
  tnscnt += nscount;
  tarcnt += arcount;
  tmsgcnt += 1;
  msglen = cp - ns_msgbuf;
  if (msglen > PACKETSZ && is_tcp == 0) {
    hp->tc = 1;
    msglen = PACKETSZ;
  }
  if (is_tcp) {		/* this is TCP, must prepend message length	*/
    len = htons((u_short)msglen);
    tbytcnt += sizeof(len);
    writen(fd,(u_char *)&len,sizeof(len),is_tcp);
  }
  tbytcnt += msglen;
  if (datalog > 1 && cin_ptr != NULL) {
    if (is_tcp)
      strcpy(mybuffer,"TCP ");
    else
      strcpy(mybuffer,"UDP ");
    sprintf((char *)(mybuffer +4),"type %d, to %s, answer %d, authority %d, additional %d, bytes %d, messages %d",
    	(u_char)type,inet_ntoa(client.sin_addr),tancnt,tnscnt,tarcnt,tbytcnt,tmsgcnt); 
    LogPrint(mybuffer);
  }
  return(writen(fd, ns_msgbuf, msglen, is_tcp));
}
