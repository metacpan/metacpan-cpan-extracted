/* libipq_wrapper.c
 *
 * Copyright 2004, Michael Robinton <michael@bizsystems.com>
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

 * This small module is a workaround for the problem that is created when using
 * libnet and libipq together. It seems that there are two versions of "if.h", 
 * one in net/if.h and another in linux/if.h. libipq includes one of them and
 * libnet includes the other. sigh.... 
 * This conflict appears only in certain Linux distributions, not in all. This 
 * module seperates libipq and libnet from does not happen

 */

#include "libipq.h"

/* return struct iphdr * iph	*/
void *
lipqw_payload(void * m)
{
  return (void *)((ipq_packet_msg_t *)m)->payload;
}

/* return char indev_name[]	*/
char *
lipqw_indevname(void * m)
{
  return ((ipq_packet_msg_t *)m)->indev_name;
}

/* return unsigned char hw_addr[]	*/
char *
lipqw_hw_addr(void * m)
{
  return (char *)((ipq_packet_msg_t *)m)->hw_addr;
}

/* return long timestamp_sec	*/
long
lipqw_timestamp_sec(void * m)
{
  return ((ipq_packet_msg_t *)m)->timestamp_sec;
}
