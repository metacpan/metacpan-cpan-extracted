/* This code unpacks a rule into a Perl hash, for passing to
 * a script for output and manipulation purposes.
 */

/*
 * Author: Derrik Pates <dpates@dsdk12.net>
 *
 *      This program is free software; you can redistribute it and/or modify
 *      it under the terms of the GNU General Public License as published by
 *      the Free Software Foundation; either version 2 of the License, or
 *      (at your option) any later version.
 *
 *      This program is distributed in the hope that it will be useful,
 *      but WITHOUT ANY WARRANTY; without even the implied warranty of
 *      MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *      GNU General Public License for more details.
 *
 *      You should have received a copy of the GNU General Public License
 *      along with this program; if not, write to the Free Software
 *      Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 */


#define __USE_GNU
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

/* for iptables/ip6tables internals */
#include "local_types.h"

/* for getprotobynumber() */
#include <netdb.h>
/* for inet_ntop() */
#include <sys/types.h>
#include <sys/socket.h>
#include <arpa/inet.h>
/* for strtoul() */
#include <stdlib.h>
#include <netinet/in.h>

#include "unpacker.h"
#include "loader.h"
#include "module_iface.h"

/* Translate an address/netmask pair into a string */
static SV *addr_and_mask_to_sv(ADDR_TYPE addr, ADDR_TYPE mask,
		bool inv) {
	char *temp, *temp2, addrstr[ADDR_STRLEN + 1];
	unsigned char *mask_access;
	int i, j, maskwidth = 0, at_zeros = FALSE, contiguous = TRUE;
	SV *sv;

	/* We always translate the address into a string */
	inet_ntop(ADDR_FAMILY, (void *)&addr, addrstr, ADDR_STRLEN);
	temp = strdup(addrstr);
	mask_access = (void *)&mask;
	/* Do the magic work of converting the netmask to a width value, or a
	 * plain netmask, if it can't be stored as a width value */
	for (i = 0; i < sizeof(ADDR_TYPE) && mask_access[i] != 0; i++) {
		switch (mask_access[i]) {
		  case 0:
			at_zeros = TRUE;
			break;
		  case 0xFF:
			/* Optimize out whole bytes with all bits set */
			maskwidth += 8;
			if (at_zeros)
				contiguous = FALSE;
			break;
		  default:
			for (j = 7; j >= 0; j--) {
				if ((mask_access[i] >> j) & 1) {
					maskwidth++;
					if (at_zeros) {
						contiguous = FALSE;
						break;
					}
				}
				else
					at_zeros = TRUE;
			}
			break;
		}
		if (!contiguous)
			break;
	}
	if(maskwidth < sizeof(ADDR_TYPE) * 8) {
		/* Ok, this is not a host entry */
		if(contiguous) /* If it was contiguous, it can be expressed
			        * as a single mask value */
			asprintf(&temp2, "%s/%u", temp, maskwidth);
		else { /* Otherwise, express it as a full netmask value */
			inet_ntop(ADDR_FAMILY, &mask, addrstr, ADDR_STRLEN);
			asprintf(&temp2, "%s/%s", temp, addrstr);
		}
		free(temp);
		temp = temp2;
	}
	if(inv) {
		asprintf(&temp2, "%c%s", INVCHAR, temp);
		free(temp);
		temp = temp2;
	}
	sv = newSVpv(temp, 0);
	free(temp);
	return(sv);
}

/* We have a job, kids - to turn a (ENTRY *) into a hash... */
HV *ipt_do_unpack(ENTRY *entry, HANDLE *table) {
	SV *sv;
	HV *hash;
	AV *match_list = NULL;
	char *temp, *rawkey, *targetname = NULL, *protoname = NULL;
	struct protoent *protoinfo;
	ModuleDef *module = NULL;
	ENTRY_MATCH *match = NULL;
	ENTRY_TARGET *target = NULL;

	/* If the pointer is NULL, then we've got a slight problem. */
	if(!entry)
		return(NULL);
	
	hash = newHV();
	
	/* Ok, let's break this down point by point. First off, the source
	 * address... */
	if(entry->nfcache & NFC_IPx_SRC) {
		sv = addr_and_mask_to_sv(ENTRY_ADDR(entry).src, ENTRY_ADDR(entry).smsk,
				ENTRY_ADDR(entry).invflags & INV_SRCIP);
		hv_store(hash, "source", 6, sv, 0);
	}
	
	/* Now, the destination address */
	if(entry->nfcache & NFC_IPx_DST) {
		sv = addr_and_mask_to_sv(ENTRY_ADDR(entry).dst, ENTRY_ADDR(entry).dmsk,
				ENTRY_ADDR(entry).invflags & INV_DSTIP);
		hv_store(hash, "destination", 11, sv, 0);
	}
	
	/* Now, the packet incoming interface */
	if(entry->nfcache & NFC_IPx_IF_IN) {
		char *ifname = strdup(ENTRY_ADDR(entry).iniface);
		if(ENTRY_ADDR(entry).invflags & INV_VIA_IN) {
			asprintf(&temp, "%c%s", INVCHAR, ifname);
			free(ifname);
			ifname = temp;
		}
		hv_store(hash, "in-interface", 12, newSVpv(ifname, 0), 0);
		free(ifname);
	}
	
	/* Packet outgoing interface */
	if(entry->nfcache & NFC_IPx_IF_OUT) {
		char *ifname = strdup(ENTRY_ADDR(entry).outiface);
		if(ENTRY_ADDR(entry).invflags & INV_VIA_OUT) {
			asprintf(&temp, "%c%s", INVCHAR, ifname);
			free(ifname);
			ifname = temp;
		}
		hv_store(hash, "out-interface", 13, newSVpv(ifname, 0), 0);
		free(ifname);
	}
	
	/* Protocol */
	if(entry->nfcache & NFC_IPx_PROTO) {
		char *protostr;
		if((protoinfo = getprotobynumber(ENTRY_ADDR(entry).proto))) {
			protostr = strdup(protoinfo->p_name);
			protoname = protostr;
			if(ENTRY_ADDR(entry).invflags & INV_PROTO) {
				asprintf(&temp, "%c%s", INVCHAR, protostr);
				free(protostr);
				protostr = temp;
				protoname = protostr + 1;
			}
			protoname = strdup(protoname);
			sv = newSVpv(protostr, 0);
			free(protostr);
		}
		else if(ENTRY_ADDR(entry).invflags & INV_PROTO) {
			asprintf(&protostr, "%c%u", INVCHAR, ENTRY_ADDR(entry).proto);
			sv = newSVpv(protostr, 0);
			free(protostr);
		}
		else
			sv = newSViv(ENTRY_ADDR(entry).proto);
		hv_store(hash, "protocol", 8, sv, 0);
	}

#ifndef INET6
	/* Fragment flag */
	if(ENTRY_ADDR(entry).flags & IPT_F_FRAG) {
		hv_store(hash, "fragment", 8, newSViv(!(ENTRY_ADDR(entry).invflags &
										IPT_INV_FRAG)), 0);
	}
#endif /* !INET6 */

	/* Jump target */
	if((targetname = (char *)GET_TARGET(entry, table))) {
		target = (void *)entry + entry->target_offset;
		if(strcmp("", targetname))
			hv_store(hash, "jump", 4, newSVpv(targetname, 0), 0);

		module = ipt_find_module(targetname, MODULE_TARGET, table);
		/* If we didn't find a module for the target, stuff the raw target
		 * data into the hash with an appropriately-named key. */
		if(!module) {
			char *data;
			int data_size = target->u.target_size -
				ALIGN(sizeof(ENTRY_TARGET));
			if(data_size > 0) {
				asprintf(&rawkey, "%s" TARGET_RAW_POSTFIX, targetname);
				data = malloc(data_size);
				memcpy(data, target->data, data_size);
				hv_store(hash, rawkey, strlen(rawkey), newSVpv(data, data_size),
								0);
				free(rawkey);
				free(data);
			}
		}
		else if(module->get_fields)
			module->get_fields(hash, ((void *)entry + entry->target_offset),
							entry);
	}
	
	/* And now, iterate through the match modules */
	for(match = (void *)entry->elems;
			(void *)match < ((void *)entry + entry->target_offset);
			match = (void *)match + match->u.match_size) {
		/* If it's a protocol match, make sure it doesn't end up on the
		 * match list. */
		if(protoname ? strcmp(protoname, match->u.user.name) : TRUE) {
			/* If we haven't setup the match list already, create the array
			 * now. */
			if(!match_list)
				match_list = newAV();
			av_push(match_list, newSVpv(match->u.user.name, 0));
		}
		
		module = ipt_find_module(match->u.user.name, MODULE_MATCH, table);
		/* If we didn't find a module for the current match, stuff the raw
		 * match data into the hash with an appropriately-named key. */
		if(!module) {
			char *data;
			int data_size = match->u.match_size -
					ALIGN(sizeof(ENTRY_MATCH));
			asprintf(&rawkey, "%s" MATCH_RAW_POSTFIX, match->u.user.name);
			data = malloc(data_size);
			memcpy(data, match->data, data_size);
			hv_store(hash, rawkey, strlen(rawkey), newSVpv(data, data_size), 0);
			free(rawkey);
			free(data);
		}
		else if(module->get_fields)
			module->get_fields(hash, match, entry);
	}

	if(match_list)
		hv_store(hash, "matches", 7, newRV_noinc((SV *)match_list), 0);
	
	/* And the byte and packet counters */
	asprintf(&temp, "%llu", entry->counters.bcnt);
	hv_store(hash, "bcnt", 4, newSVpv(temp, 0), 0);
	free(temp);
	asprintf(&temp, "%llu", entry->counters.pcnt);
	hv_store(hash, "pcnt", 4, newSVpv(temp, 0), 0);
	free(temp);

	if(protoname)
		free(protoname);
	return hash;
}

/* vim: ts=4
 */
