/* check.c
 *
 * Copyright 2003, 2009, Michael Robinton <michael@bizsystems.com>
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

#include "supported_os.h"

#ifdef DBTARPIT_SUPPORTED_OS_LINUX

#include "tarpit.h"
#include <netinet/ip.h>
#include <linux/netfilter.h>
#include "libipq.h"

#define BUFSIZE IP_MAXPACKET + sizeof(ipq_packet_msg_t)

/*
	ipt message structure
	from libipq.h -> linux/netfilter_ipv4/ip_queue.h

    typedef struct ipq_packet_msg {
	unsigned long packet_id;	ID of queued packet
	unsigned long mark;		Netfilter mark value
	long timestamp_sec;		Packet arrival time (seconds)
	long timestamp_usec;		Packet arrvial time (+useconds)
	unsigned int hook;		Netfilter hook we rode in on
	char indev_name[IFNAMSIZ];      Name of incoming interface
	char outdev_name[IFNAMSIZ];	Name of outgoing interface
	unsigned short hw_protocol;	Hardware protocol (network order)
	unsigned short hw_type;		Hardware type
	unsigned char hw_addrlen;	Hardware address length
	unsigned char hw_addr[8];	Hardware address
	size_t data_len;		Length of packet data
	unsigned char payload[0];	Optional packet data
    } ipq_packet_msg_t;

 * *******						*******
 * *******	iptables QUEUE target stuff		*******
 * *******		man libipq(3)			*******
 */

/*	test if tarpitting is required
 *
 *	input:		message packet pointer from libipq
 *	returns:	return true(1) if IP is in tarpit database
 *			else return false(0)
 */

#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>

/* used in main -- ipq buffer	*/
unsigned char buf[BUFSIZE];

long lastsync = 0;	/* last time sync was performed	*/

void
check_no_support()
{}

int
c4_verdict(int verdict, ipq_packet_msg_t * m_pkt)
{
  extern void * ipq_h;
  
  struct ipq_handle * h = ipq_h;

  if(h)
    ipq_set_verdict(h, m_pkt->packet_id, verdict, 0, NULL);
  if(verdict == NF_DROP)
    return(1);
  return(0);
}

int
check_4_tarpit(ipq_packet_msg_t * m_pkt)
{
  extern DBTPD dbtp;
  extern int Xflag, xflag, aflag, Lflag;
  extern long lastsync;
  struct iphdr * iph	= (struct iphdr *)m_pkt->payload;
  int isTCP = 1;

  if (iph->protocol != IPPROTO_TCP) {
    if (!Xflag)
      return(c4_verdict(NF_ACCEPT, m_pkt));
    isTCP = 0;
  }

  if (Lflag == 0 && (*(unsigned char *)&(iph->saddr)) == 127)		/* don't tarpit localnet unless flagged */
    return(c4_verdict(NF_ACCEPT, m_pkt));

  if (dbtp_find_addr(&dbtp,DBtarpit,(void *)&(iph->saddr), m_pkt->timestamp_sec)) {	/* tarpit if found and isTCP	*/
    if (lastsync + 900 < m_pkt->timestamp_sec) {					/* if it has been more than 15 minutes since last sync	*/
      lastsync = m_pkt->timestamp_sec;							/* update the lastsync time	*/
      (void)dbtp_sync(&dbtp,DBtarpit);							/* sync the database		*/
    }
    if (xflag == 0 && isTCP)								/* and not disabled		*/
      (void)tarpit((void *)m_pkt);

    if (aflag == 0)							/* if all connections not allowed	*/
      return(c4_verdict(NF_DROP, m_pkt));				/* drop packet			*/
  }
  if (dbtp.dbaddr[DBarchive] != NULL) {
    (void)dbtp_put(&dbtp,DBarchive,&iph->saddr,sizeof(iph->saddr),&m_pkt->timestamp_sec, sizeof(m_pkt->timestamp_sec));
    (void)dbtp_sync(&dbtp,DBarchive);
  }

  return(c4_verdict(NF_ACCEPT, m_pkt));
}

#else

void
check_no_support()
{
  char sorry_msg[] = "\n"
"  The \"dbtarpit\" daemon portion of this package is not\n"
"  supported on your OS since it does not have IPTABLES.\n"
"\n"
"  If you are interested in porting dbtarpit to your OS,\n"
"  most of the non-portable code is currently contained\n"
"  within 3 modules:\n"
"\n"
"	check.c\n"
"	tarpit.c\n"
"	main.c\n"
"\n"
"  tarpit.c has a single entry point \"tarpit\" used only by\n"
"  check.c. Besides the subroutine that prints this message,\n"
"  check.c (included in main.c) has a single entry point\n"
"  \"check_4_tarpit\". A small amount of code is contained in\n"
"  main.c to initialize Linux iptables and related pointers. You\n"
"  are encouraged to port this daemon to other platforms.\n\n";
  printf("%s",sorry_msg);
  exit(1);
} 

#endif
