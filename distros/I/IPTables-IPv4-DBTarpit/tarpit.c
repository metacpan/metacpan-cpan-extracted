/* tarpit.c
 * 
 * Portions copyright 2003, 2009, Michael Robinton <michael@bizsystems.com>
 *
 * Portions adapted from LaBrea - IPHandler.c by Tom Liston <tliston@premmag.com>, Copyright (C) 2001, 2002
 * Portions adapted from ipt_TARPIT.c by Aaron Hopkins <tools@die.net> Copyright (c) 2002
 *
 ** Portions adapted from libnet_link_sockpacket.c and libnet_write.c
 **  Copyright (c) 1998 - 2001 Mike D. Schiffman <mike@infonexus.com>
 **  All rights reserved.
 **
 ** Copyright (c) 1996, 1997
 **      The Regents of the University of California.  All rights reserved.
 **
 ** Redistribution and use in source and binary forms, with or without
 ** modification, are permitted provided that: (1) source code distributions
 ** retain the above copyright notice and this paragraph in its entirety, (2)
 ** distributions including binary code include the above copyright notice and
 ** this paragraph in its entirety in the documentation or other materials
 ** provided with the distribution, and (3) all advertising materials mentioning
 ** features or use of this software display the following acknowledgement:
 ** `This product includes software developed by the University of California,
 ** Lawrence Berkeley Laboratory and its contributors.'' Neither the name of
 ** the University nor the names of its contributors may be used to endorse
 ** or promote products derived from this software without specific prior
 ** written permission.
 ** THIS SOFTWARE IS PROVIDED `AS IS'' AND WITHOUT ANY EXPRESS OR IMPLIED
 ** WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
 ** MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.
 *
 */

#include "supported_os.h"

#ifdef DBTARPIT_SUPPORTED_OS_LINUX

#include "libipq_wrapper.h"
#include "libnet_version.h"
/*	workaround for ENDIAN definition problems in libnet.h	*/
#if DBTARPIT_LNV_HIGH == 1 && DBTARPIT_LNV_MID == 0
# include "endian.h"
#endif

#include <time.h>
#include <libnet.h>
#include <linux/netfilter.h>
#include "defines.h"
#include "misc_func.h"

/*	define common IP header for IPV4	*/
#ifdef LIBNET_IPV4_H
# define LIBNET_IP_H LIBNET_IPV4_H
#endif

/*	from /usr/src/linux/include/net/ip.h
 *	"Fragment Offset" part
 */
#define IP_OFFSET	0x1FFF

/*
	NOTE: all these definitions and related code have
	been moved to libipq_wrapper.c because of a header
	conflict in certain Linux distributions

	ipt message structure
	from libipq.h -> linux/netfilter_ipv4/ip_queue.h

Messages sent from kernel
typedef struct ipq_packet_msg {
        unsigned long packet_id;         ID of queued packet
        unsigned long mark;              Netfilter mark value
        long timestamp_sec;              Packet arrival time (seconds)
        long timestamp_usec;             Packet arrvial time (+useconds)
        unsigned int hook;               Netfilter hook we rode in on
        char indev_name[IFNAMSIZ];       Name of incoming interface
        char outdev_name[IFNAMSIZ];      Name of outgoing interface
        unsigned short hw_protocol;      Hardware protocol (network order)
        unsigned short hw_type;          Hardware type
        unsigned char hw_addrlen;        Hardware address length
        unsigned char hw_addr[8];        Hardware address
        size_t data_len;                 Length of packet data
        unsigned char payload[0];        Optional packet data
} ipq_packet_msg_t;

 * *******						*******
 * *******	iptables QUEUE target stuff		*******
 * *******		man libipq(3)			*******

 *
 *	test if tarpitting is required
 *
 *	input:		message packet pointer from libipq
 *	returns:	return true if IP is in tarpit database
 *			else return false
 */

void *
p_dump(void * p)
{
  printf("%02x%02x ",*(unsigned char *)p, *(unsigned char *)(p +1));
  return((void *)(p + 2));
}

/* DEBUG: print a hex buffer in doubles
 * input:	void * ptr, int count
 * returns:	pointer to end of buffer
 */

void *
pkt_dump(void * p,int i)
{
  if((i > 0) && (i < 55)) {	/* punt if too big or two little	*/
    for(;i > 0;i--) {
      p = p_dump(p_dump(p_dump(p_dump(p_dump(p_dump(p_dump(p_dump(p))))))));
      printf("%s","\n");
    }
    printf("%s","\n");
  }
  return p;
}

int
tarpit(void * m)
{
/* externs */
  extern int trace_tarpit, dummy_tarpit;
  extern void * ipq_h;	/* ipq_handle * h;	*/
  extern u_int32_t randqueue1[], randqueue2[];
  extern int newthisminute, currentbandwidth, currentrand1, currentrand2, datalog;
  extern int oflag, Oflag, kflag, Dflag, pflag, Pflag, star;
  extern short throttlesize;
  extern char mybuffer[], mybuffer2[], strstar[], format1[], format2[], format8[], format9[];
  extern char msg1[], msg2[], msg3[], msg4[], msg4a[], msg5[], strlf[];
  extern char * fifoname;

/* locals */
  u_char bwuse = 0, flags, * pktptr;
  char src_addr[20], dst_addr[20], tnow[60], *msgptr = NULL;
  u_int32_t ip_src, ip_dst, seq, ack, ack_out;
  u_int boolLinuxWinProbe = 0, rv = 0, i;
  short windowsize;
  u_short headersize, sport = 0, dport = 0, ipid, tlength;
  struct iphdr * iph    = (struct iphdr *)lipqw_payload(m);
  struct libnet_tcp_hdr * tcph;
  u_char * mymac, err_buf[100];
/* err_buf will double for the packet buffer	*/
  int c, packet_size;
  u_int8_t *packet = NULL;
  u_int32_t len;
  long tss;

#if DBTARPIT_LNV_HIGH == 1 && DBTARPIT_LNV_MID == 0	/* libnet version 1.0.x		*/
  struct libnet_link_int * network;
#else							/* libnet version 1.1.x and up	*/
  libnet_t *network;
#endif

  packet_size = LIBNET_IP_H + LIBNET_ETH_H + LIBNET_TCP_H;


  if(ipq_h == NULL) {			/* return now if testing	*/
    trace_tarpit = dummy_tarpit;	/* mark transit through this routine    */
    return(trace_tarpit);
  }

  tlength = ntohs(iph->tot_len);
  bwuse = tlength;			/* this much got sucked up on incoming	*/
  
  if(	((i = iph->ihl*4) != LIBNET_IP_H) ||	/* drop non standard packets	*/
	(iph->frag_off & htons(IP_OFFSET)) ||	/* drop fragments		*/
	(tlength < (i + LIBNET_TCP_H))	)	/* drop truncated headers	*/
    goto verdict;

  ip_src	= iph->saddr;
  ip_dst	= iph->daddr;

  tcph	= (struct libnet_tcp_hdr *)((u_int32_t)iph + i);
  headersize	= (iph->ihl * 4) + (tcph->th_off * 4);
  flags		= tcph->th_flags;
  sport		= ntohs(tcph->th_sport);
  dport		= ntohs(tcph->th_dport);
  seq		= ntohl(tcph->th_seq);
  ack		= ntohl(tcph->th_ack);

  if(Dflag) {
    printf("flags= %02x  urg ack : psh  rst  syn  fin\n", flags);
    pkt_dump((void *)iph,3);
  }

  /*************************************************/
  /* Special code to handle funky Linux win probes */
  /*************************************************/
  /* We're going to "encode" the remote sequence   */
  /* number that we should be seeing on the first  */
  /* inbound window probe - we use this encoded    */
  /* value as *our* sequence number... when we get */
  /* an inbound packet that could be a win probe   */
  /* we'll "decode" the ack... if it matches the   */
  /* sequence number, then it's a win probe...     */
  /* This is one of those cool hacks that no one   */
  /* else is ever going to understand. Oh well...  */
  /*************************************************/
  ack_out		= (seq + throttlesize);
  ack_out		^= randqueue2[currentrand2];
  ack_out		^= ((sport << 16) + dport);
  ack_out		^= ip_src;
  ack_out--;
  currentrand2++;
  if(currentrand2 >= RANDSIZE2)
    currentrand2	= 0;
  /* the IPID we'll use in our reply packet   */
  ipid			= (short)randqueue1[currentrand1];
  currentrand1++;
  if(currentrand1 >= RANDSIZE1)
    currentrand1	= 0;
  /* a packet w/SYN only set -- we reply w/a SYN/ACK */
  if((flags & TH_SYN) && ((flags & TH_ACK) == 0)) {
    /* if we're persist only, and we're at our limit */
    if((Pflag) && (newthisminute == 0))
      goto verdict;
    /* this will be our ack # (ack = inbound seq + 1)*/
    seq++;
    /* this will be our seq # (random seq #)         */
    ack			= ack_out;
    /* send a SYN/ACK packet                         */
    flags = TH_SYN | TH_ACK;
    /* throttle down the window to our throttlesize  */
    windowsize		= throttlesize;
    msgptr		= msg1;
    goto sendit;
  } else {
    /* if the inbound packet is a SYN/ACK, reply w/a RST */
    if((flags & TH_SYN) && (flags & TH_ACK)) {
      if(kflag)
        goto verdict;
      /* this will be our ack # (ack = inbound seq + 1)*/
      seq++;
      /* this will be our seq # (random seq #)         */
      ack		= ack_out;
      /* send a RST packet                             */
      flags		= TH_RST;
      /* throttle down the window to our throttlesize  */
      windowsize	= throttlesize;
      msgptr		= msg5;
      goto sendit;
    } else {
      /* an ACK packet */
      if((pflag) && (flags & TH_ACK)) {
        /* the 1st data packet. they're sending a packet   */
        /* that is a header plus our throttle size...      */
        if(tlength == (headersize + throttlesize)) {
          /* if we've already added all of the connections */
          /* that we can during this minute, then ignore   */
          /* this packet. this should allow us to ease up  */
          /* toward maximum bw... even when we're being    */
          /* hammered by inbound connects                  */
          if(newthisminute == 0)
            goto verdict;
          /* this will be our ack # (ack = inbound seq + throttlesize)*/
          seq		+= throttlesize;
          /* note: we'll use ack as our seq... it remains unchanged   */
          /* send an ACK packet                                       */
          flags		= TH_ACK;
          /* lay the trap... throttle down the window to 0 - persist  */
          windowsize	= 0;
          msgptr	= msg3;
          /* lower possible new connects by 1...                      */
          newthisminute--;
          goto sendit;
        } else {
          /* check for oddball Linux winprobe     */
          /* decode the ack and see if it matches */
          /* the inbound sequence number... if it */
          /* does, then it's a win probe          */
          ack_out	= ack;
          ack_out	^= ip_src;
          ack_out	^= ((sport << 16) + dport);
          for(i = 0; i < RANDSIZE2; i++) {
            if((ack_out ^ randqueue2[i]) == seq)
              boolLinuxWinProbe = 1;
          }
          if((tlength == (headersize + 1)) || boolLinuxWinProbe) {
            /* we'll send back syn = inbound ack */
            /* and ack = inbound syn...          */
            /* set the ACK flag...               */
            flags	= TH_ACK;
            /* tell 'em to keep waiting          */
            windowsize	= 0;
            if(boolLinuxWinProbe) {
              msgptr	= msg4a;
            } else {
              msgptr	= msg4;
            }
            goto sendit;
          } else {
            /* we ignore everything else, but (optionally) log the */
            /* fact that we saw activity...                        */
            msgptr	= msg2;
            goto logit;
          }
        }
      }
    }
  }
  goto verdict;

  sendit:
  bwuse += LIBNET_IP_H + LIBNET_TCP_H;	/* bandwidth is incoming packet + outgoing, if any */

#if DBTARPIT_LNV_HIGH == 1 && DBTARPIT_LNV_MID == 0	/* libnet version 1.0.x		*/

  if ((network = libnet_open_link_interface(lipqw_indevname(m), err_buf)) == NULL)
    goto logit;

  mymac = (u_char *)libnet_get_hwaddr(network,lipqw_indevname(m),err_buf);

  pktptr = err_buf;
  memset(pktptr, 0, packet_size);

  libnet_build_ethernet(
	lipqw_hw_addr(m),		/* return MAC address	*/
  	mymac,			/* my outgoing device	*/
	ETHERTYPE_IP,		/* ethernet protocol	*/
	NULL,			/* payload (none)	*/
	0,			/* length		*/
	pktptr);		/* pointer		*/

  libnet_build_ip(
	LIBNET_TCP_H,		/* size of packet less IP header	*/
	0,			/* tos			*/
	ipid,			/* IP ID		*/
	0,			/* fragment stuff	*/
	255,			/* TTL			*/
	IPPROTO_TCP,		/* transport protocol	*/
	ip_dst,			/* source IP, swap'm	*/
	ip_src,			/* destination IP	*/
	NULL,			/* payload (none)	*/
	0,			/* payload length	*/
	pktptr + LIBNET_ETH_H);	/* pointer		*/

  libnet_build_tcp(
	dport,			/* src TCP port, swap'm	*/
	sport,			/* destination TCP port	*/
	ack,			/* sequence #, swap'm	*/
	seq,			/* acknowledgement #	*/
	flags,			/* control flags	*/
	windowsize,		/* window size		*/
	0,			/* urgent pointer	*/
	NULL,			/* payload (none)	*/
	0,			/* payload length	*/
	pktptr + LIBNET_IP_H + LIBNET_ETH_H); /* pointer	*/

  libnet_do_checksum(pktptr + LIBNET_ETH_H, IPPROTO_IP, LIBNET_TCP_H);
  libnet_do_checksum(pktptr + LIBNET_ETH_H, IPPROTO_TCP, LIBNET_TCP_H);

  if(Dflag)
    pkt_dump((void *)pktptr + LIBNET_ETH_H,3);

  if(!(libnet_write_link_layer(network, lipqw_indevname(m), pktptr, packet_size) < packet_size))
    rv = 1;

  libnet_close_link_interface(network);
  free(network);			/* the above close_link does not seem to release memory	*/

#else							/* libnet version 1.1x and up	*/

  if ((network = libnet_init(LIBNET_LINK, lipqw_indevname(m), (char *)err_buf)) == NULL)
    goto logit;

  mymac = (u_char *)libnet_get_hwaddr(network);

  libnet_build_tcp(
	dport,			/* src TCP port, swap'm	*/
	sport,			/* destination TCP port	*/
	ack,			/* sequence #, swap'm	*/
	seq,			/* acknowledgement #	*/
	flags,			/* control flags	*/
	windowsize,		/* window size		*/
	0,			/* checksum		*/
	0,			/* urgent pointer	*/
	LIBNET_TCP_H,		/* length		*/
	NULL,			/* payload (none)	*/
	0,			/* payload length	*/
	network,		/* libnet context	*/
	0);			/* new pblock		*/

  libnet_build_ipv4(
	LIBNET_IPV4_H + LIBNET_TCP_H,	/* size of packet	*/
	0,			/* tos			*/
	ipid,			/* IP ID		*/
	0,			/* fragment stuff	*/
	255,			/* TTL			*/
	IPPROTO_TCP,		/* transport protocol	*/
	0,			/* checksum		*/
	ip_dst,			/* source IP, swap'm	*/
	ip_src,			/* destination IP	*/
	NULL,			/* payload (none)	*/
	0,			/* payload length	*/
	network,		/* libnet context	*/
	0);			/* new pblock		*/

  libnet_build_ethernet(
	(u_char *)lipqw_hw_addr(m),	/* return MAC address	*/
  	mymac,				/* my outgoing device	*/
	ETHERTYPE_IP,			/* ethernet protocol	*/
	NULL,				/* payload (none)	*/
	0,				/* length		*/
	network,			/* libnet context	*/
	0);				/* new pblock		*/

  libnet_pblock_coalesce(network, &packet, &len);

  if(Dflag && packet != NULL)
    pkt_dump((void *)packet + LIBNET_ETH_H,3);

  c = libnet_write_link(network, packet, len);

  if(c == len)
  {
    network->stats.packets_sent++;
    network->stats.bytes_written += c;
    rv = 1;
  }
  else
  {
    network->stats.packet_errors++;
    if (c > 0)
      network->stats.bytes_written += c;
  }
  if(network->aligner > 0)
    packet = packet - network->aligner;

  free(packet);

  libnet_destroy(network);

#endif

  logit:
  if(msgptr == NULL)
    goto verdict;
  currentbandwidth	+= bwuse;
  if(((datalog == 1) && (bwuse)) || !datalog)
    goto verdict;
  sprintf(src_addr, format1, (ip_src & 0xFF),((ip_src & 0xFF00) >> 8),
          ((ip_src & 0xFF0000) >> 16),((ip_src & 0xFF000000) >> 24));
  sprintf(dst_addr, format1, (ip_dst & 0xFF),((ip_dst & 0xFF00) >> 8),
          ((ip_dst & 0xFF0000) >> 16),((ip_dst & 0xFF000000) >> 24));
  sprintf(mybuffer, format2, msgptr, src_addr, sport, dst_addr, dport);
  if(star) {
    strcat(mybuffer, strstar);
    star = 0;
  } else {
    star = 1;
  }

  tss = lipqw_timestamp_sec(m);
  if (fifoname != NULL) {
    sprintf(mybuffer2, format8, tss, mybuffer);
    LogPrint(mybuffer2);
  }
  else if (oflag) {
    if(Oflag)
      sprintf(mybuffer2, format8, tss, mybuffer);
    else {
      strncpy(tnow, (char *)ctime(&tss), 50);
      strtok(tnow, strlf);
      sprintf(mybuffer2, format9, tnow, mybuffer);
    }
    LogPrint(mybuffer2);
  } else
    syslog(LOGTYPE, mybuffer);

  verdict:
  return(rv);
/* not reached, silence compiler warning        */
  pktptr = err_buf;
}

#endif	/* DBTARPIT_SUPPORTED_OS_LINUX	*/
