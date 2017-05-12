/* This code will pack the contents of a Perl hash into a (ENTRY)
 * for use in rule-adding andd rule-modifying operations.
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

/* for getprotobynumber() and getprotobyname() */
#include <netdb.h>
/* for inet_pton() */
#include <sys/types.h>
#include <sys/socket.h>
#include <arpa/inet.h>
/* for strtoul() */
#include <stdlib.h>
/* for htonl() */
#include <netinet/in.h>
#include <stdio.h>

#include "packer.h"
#include "loader.h"

#define ADDRTEXTWIDTH ADDR_STRLEN * 2 + 1

typedef struct {
	ENTRY_MATCH *match;
	int flags;
} MatchElem;

typedef MatchElem * MatchList;

/* Parse out an IP address/mask pair into (ADDR_TYPE)s */
static int parse_addr(SV *addrsv, ADDR_TYPE *addr, ADDR_TYPE *mask,
				bool *inv) {
	char *sep, *maskstr, *maskend, *addrstr, *base, *temp;
	unsigned int maskwidth;
	unsigned char *mask_access;
	STRLEN len;

	*inv = FALSE;
	/* Make sure the value is of the right type */
	if(!SvPOK(addrsv)) {
		SET_ERRSTR("Must be passed as string");
		return(FALSE);
	}

	temp = SvPV(addrsv, len);
	base = addrstr = malloc(len + 1);
	strncpy(addrstr, temp, len);
	addrstr[len] = '\0';

	/* If the first character is our designated invert
	 * character, set the invert flag */
	if(addrstr[0] == INVCHAR) {
		*inv = TRUE;
		addrstr++;
	}

	/* Is there a slash? If so, we have a netmask or mask width value to
	 * read in */
	if((sep = strchr(addrstr, '/'))) {
		maskstr = sep + 1;
		/* Try to read an int from the mask side */
		maskwidth = strtoul(maskstr, &maskend, 10);
		/* If the integer ends before the mask does, then assume it's
		 * a full netmask */
		if(strlen(maskstr) > maskend - maskstr) {
			if(inet_pton(ADDR_FAMILY, maskstr, mask) < 1) {
				SET_ERRSTR("Couldn't parse mask '%s'", maskstr);
				goto pa_failed;
			}
		}
		/* If not, it's a single-value mask */
		else {
			if (maskwidth > sizeof(ADDR_TYPE) * 8) {
				SET_ERRSTR("Impossible mask width %d", maskwidth);
				goto pa_failed;
			}
			/* Zero the whole mask */
			memset(mask, 0, sizeof(ADDR_TYPE));
			/* Set all whole bytes to 0xFF right away */
			memset(mask, 0xFF, maskwidth / 8);
			mask_access = (void *)mask;
			/* Do shift/invert to get the trailing bits */
			mask_access[maskwidth / 8] = ~(0xFF >> (maskwidth % 8)) & 0xFF;
		}
	}
	/* If not, all mask bits must be set, because it's a host rule */
	else
		memset(mask, 0xFF, sizeof(ADDR_TYPE));
	if(sep)
		*sep = '\0';
	if(inet_pton(ADDR_FAMILY, addrstr, addr) < 1) {
		SET_ERRSTR("Couldn't parse address '%s'", addrstr);
		goto pa_failed;
	}
	if(sep)
		*sep = '/';
	free(base);
	return(TRUE);
pa_failed:
	free(base);
	return(FALSE);
}

/* Parse an interface name */
static int parse_iface(SV *ifacesv, char *ifnam, unsigned char *ifmask,
				bool *inv) {
	char *wc_off, *ifacestr, *base, *temp;
	int maskwidth;
	STRLEN len;

	*inv = FALSE;
	/* Make sure the parameter we got can be coerced into a string. */
	if(!SvPOK(ifacesv)) {
		SET_ERRSTR("Must be passed as string");
		return(FALSE);
	}
	
	temp = SvPV(ifacesv, len);
	base = ifacestr = malloc(len + 1);
	strncpy(ifacestr, temp, len);
	ifacestr[len] = '\0';

	/* If the parameter is prefixed with the invert character, tell the caller
	 * to set the invert flag for the field. */
	if(ifacestr[0] == INVCHAR) {
		*inv = TRUE;
		ifacestr++;
	}
	/* Is there a wildcard character? If so, set the mask width
	 * appropriately and limit the string to just before the wildcard */
	if((wc_off = strchr(ifacestr, '+')))
		maskwidth = wc_off - ifacestr;
	else
		maskwidth = strlen(ifacestr) + 1;
	/* Copy the interface name */
	strncpy(ifnam, ifacestr, IFNAMSIZ - 1);
	/* Fill in the mask */
	memset(ifmask, 0xFF, maskwidth > IFNAMSIZ ? IFNAMSIZ : maskwidth);
	free(base);
	return(TRUE);
}

/* Build a (ENTRY *) from a Perl hash */
int ipt_do_pack(HV *hash, ENTRY **entry, HANDLE *table) {
	SV *sv = NULL, **svp = NULL;
	bool gotproto = FALSE, inv;
	char *h_key, *rawkey, *targetname = strdup(""), *protoname = NULL;
	unsigned int h_keylen, size = 0, psize = 0, datalen = 0;
	int rval, i, n_matches = 0;
	ModuleDef *module = NULL;
	MatchList matches = NULL;
	ENTRY_MATCH *match = NULL;
	int target_flags = 0;
	ENTRY_TARGET *target = NULL;
	void *datazone = NULL;

	/* Give $! an undef value. If it's not still undef by the end of the
	 * call, then a module was called, tried to parse a field, and couldn't. */
	sv_setsv(ERROR_SV, &PL_sv_undef);
	/* Setup the base allocation size, and allocate the necessary zone. */
	*entry = calloc(1, sizeof(ENTRY));

	/* Must handle the protocol first! */
	if((svp = hv_fetch(hash, "protocol", 8, FALSE))) {
		struct protoent *protoinfo;
		/* If the protocol is being passed as an integer val, confirm that
		 * the protocol exists, and store it. */
		if(SvIOK(*svp)) {
			if((protoinfo = getprotobynumber(SvIV(*svp)))) // LEAK
				protoname = protoinfo->p_name;
			ENTRY_ADDR(*entry).proto = SvIV(*svp);
		}
		/* If it's a string, use a different approach to parse the field. */
		else if(SvPOK(*svp)) {
			int protonum;
			char *extent, *protostr, *base, *temp;
			STRLEN len;

			temp = SvPV(*svp, len);
			base = protostr = malloc(len + 1);
			strncpy(protostr, temp, len);
			protostr[len] = '\0';
			
			/* If the first character is the "magic" invert char, set the
			 * protocol invert flag, and advance the pointer by one */
			if(protostr[0] == INVCHAR) {
				ENTRY_ADDR(*entry).invflags |= INV_PROTO;
				protostr++;
			}
			
			/* Does this string contain a protocol name? If so, store that */
			if((protoinfo = getprotobyname(protostr))) { // LEAK
				ENTRY_ADDR(*entry).proto = protoinfo->p_proto;
				protoname = protoinfo->p_name;
			}
			/* Is it a number? Maybe it's a protocol number... */
			else {
				protonum = strtoul(protostr, &extent, 10);
				if(protostr + strlen(protostr) != extent) {
					/* Then again, maybe not. */
					SET_ERRSTR("proto: Unable to parse '%s'", protostr);
					free(base);
					goto pack_fail;
				}
				if((protoinfo = getprotobynumber(protonum)))
					protoname = protoinfo->p_name;
				ENTRY_ADDR(*entry).proto = protonum;
			}
			free(base);
		}
		/* If the data type is wrong, pass back an error and drop out now. */
		else {
			SET_ERRSTR("protocol: Must be passed as integer or string");
			goto pack_fail;
		}
		(*entry)->nfcache |= NFC_IPx_PROTO;

		/* Does the protocol have a name? If so, then we want to see if
		 * it's got raw data to copy. */
		if(protoname) {
			datazone = NULL;
			datalen = 0;
			asprintf(&rawkey, "%s" MATCH_RAW_POSTFIX, protoname);
			/* Check and see if there's any raw data to go with the
			 * match module for the protocol. */
			svp = hv_fetch(hash, rawkey, strlen(rawkey), FALSE);
			free(rawkey);
			if(svp) {
				/* Check and see if the raw data field is, or at least
				 * can be coerced to be, a string. */
				if(!SvPOK(*svp)) {
					SET_ERRSTR("%s: Must be passed as a string", rawkey);
					goto pack_fail;
				}
				datazone = (void *)SvPV(*svp, datalen);
				/* Extend the list of matches by one. */
				matches = realloc(matches, ++n_matches *
				    sizeof(MatchElem));
				/* Establish the match data zone's length. */
				size = ALIGN(sizeof(ENTRY_MATCH) + datalen);
				matches[n_matches - 1].match = match = calloc(1, size);
				match->u.match_size = size;
				strncpy(match->u.user.name, protoname,
								TARGET_NAME_LEN);
				memcpy(match->data, datazone, datalen);
				/* Make sure it's confirmed that we have a match entry
				 * for the selected protocol setup. */
				gotproto = TRUE;
			}
		}
	}

	/* If a list of matches to be used has been provided, load up those
	 * match modules. */
	if((svp = hv_fetch(hash, "matches", 7, FALSE))) {
		AV *av;
		/* Check the parameter's data type before we go further. */
		if(!SvROK(*svp) || (SvTYPE((av = (AV *)SvRV(*svp))) != SVt_PVAV)) {
			SET_ERRSTR("matches: Must be passed as array ref");
			goto pack_fail;
		}
		/* Iterate through the list of match module names. */
		for(i = 0; i <= av_len(av); i++) {
			char *matchname, *temp;
			STRLEN len;
			/* Fetch an item from the list */
			svp = av_fetch(av, i, FALSE);

			/* Do some type checking to make sure we're getting a string */
			if(!svp || !SvPOK(*svp)) {
				SET_ERRSTR("matches: Element %u must be passed as string", i);
				goto pack_fail;
			}

			temp = SvPV(*svp, len);
			matchname = malloc(len + 1);
			strncpy(matchname, temp, len);
			matchname[len] = '\0';
			module = ipt_find_module(matchname, MODULE_MATCH, table);

			/* See if there's raw data for this match module */
			datazone = NULL;
			datalen = 0;
			asprintf(&rawkey, "%s" MATCH_RAW_POSTFIX, matchname);
			svp = hv_fetch(hash, rawkey, strlen(rawkey), FALSE);
			free(rawkey);
			if(svp) {
				if(!SvPOK(*svp)) {
					SET_ERRSTR("%s: Must be passed as string", rawkey);
					free(matchname);
					goto pack_fail;
				}
				datazone = (void *)SvPV(*svp, datalen);
			}
			else if(!module) {
				free(matchname);
				goto pack_fail;
			}

			if(module && module->size < datalen)
				datalen = module->size;

			/* Allocate storage for the match's data, then stick it onto the
			 * array of matches */
			size = ALIGN(sizeof(ENTRY_MATCH)
							+ ((module && module->size > datalen) ?
									module->size : datalen));
			matches = realloc(matches, ++n_matches *
							sizeof(MatchElem));
			matches[n_matches - 1].match = match = calloc(1, size);
			matches[n_matches - 1].flags = 0;
			match->u.match_size = size;
			strncpy(match->u.user.name, matchname, TARGET_NAME_LEN);
			if(module && module->setup)
				module->setup((void *)match, &(*entry)->nfcache);

			/* If there was raw match data, copy it to where it belongs. */
			if(datazone)
				memcpy(match->data, datazone, datalen);
			free(matchname);
		}
	}
	
	/* Setup the target info */
	if((svp = hv_fetch(hash, "jump", 4, FALSE))) {
		char *temp;
		STRLEN len;
		if(!SvPOK(*svp)) {
			SET_ERRSTR("target: Must be passed as string");
			goto pack_fail;
		}

		free(targetname);
		temp = SvPV(*svp, len);
		targetname = malloc(len + 1);
		strncpy(targetname, temp, len);
		targetname[len] = '\0';
	}
	
	module = ipt_find_module(targetname, MODULE_TARGET, table);
	
	/* See if there's a key containing raw data for the target we're
	 * using for this rule */
	datazone = NULL;
	datalen = 0;
	asprintf(&rawkey, "%s" TARGET_RAW_POSTFIX, targetname);
	svp = hv_fetch(hash, rawkey, strlen(rawkey), FALSE);
	free(rawkey);
	if(svp) {
		if(!SvPOK(*svp)) {
			SET_ERRSTR("%s: Must be passed as string", rawkey);
			goto pack_fail;
		}
		datazone = (void *)SvPV(*svp, datalen);
	}
	else if(!module)
		goto pack_fail;

	if(module && module->size < datalen)
		datalen = module->size;
	
	/* Allocate the target info struct */
	size = ALIGN(sizeof(ENTRY_TARGET))
			+ ALIGN(((module && module->size > datalen) ? module->size :
									datalen));
	target = calloc(1, size);
	target->u.target_size = size;
	strncpy(target->u.user.name, targetname, TARGET_NAME_LEN);

	/* Call the target module's setup routine, so it can initialize its
	 * data area correctly (if we loaded the module) */
	if(module && module->setup)
		module->setup((void *)target, &(*entry)->nfcache);

	/* If we got raw data, copy it into its respective place */
	if(datazone)
		memcpy(target->data, datazone, datalen);

	/* Now, we go through all the hash keys */
	hv_iterinit(hash);
	while((sv  = hv_iternextsv(hash, &h_key, (I32 *)&h_keylen))) {
		rval = FALSE;
		/* Ok, give the match modules the first crack at parsing this field. */
		for(i = 0; i < n_matches; i++) {
			match = matches[i].match;
			/* Try to look up the module for the current match. */
			module = ipt_find_module(match->u.user.name,
							MODULE_MATCH, table);
			if(!module || !module->parse_field)
				continue;
			rval = module->parse_field(h_key, sv, &match,
							&(*entry)->nfcache, *entry, &matches[i].flags);
			/* Make sure to copy the pointer back into the array, in
			 * case the match module changed something. If it did, the
			 * struct probably got realloc'd. */
			matches[i].match = match;
			if(rval)
				break;
		}
		/* If rval is TRUE, then one of the match modules successfully
		 * parsed the current field, so go on to the next. */
		if(rval)
			continue;

		/* If the match modules didn't parse the key, try the target module. */
		module = ipt_find_module(targetname, MODULE_TARGET, table);
		if(module && module->parse_field && module->parse_field(h_key, sv,
								&target, &(*entry)->nfcache, *entry,
								&target_flags))
			continue;

		/* Parse the source address */
		if(!strcmp(h_key, "source")) {
			/* Try to parse the address and mask out */
			if(!parse_addr(sv, &ENTRY_ADDR(*entry).src, &ENTRY_ADDR(*entry).smsk, &inv)) {
				char *temp = strdup(SvPV_nolen(ERROR_SV));
				SET_ERRSTR("%s: %s", h_key, temp);
				free(temp);
				goto pack_fail;
			}
			if(inv)
				ENTRY_ADDR(*entry).invflags |= INV_SRCIP;
			(*entry)->nfcache |= NFC_IPx_SRC;
		}

		/* Destination address */
		else if(!strcmp(h_key, "destination")) {
			/* Try to parse the address and mask out */
			if(!parse_addr(sv, &ENTRY_ADDR(*entry).dst, &ENTRY_ADDR(*entry).dmsk, &inv)) {
				char *temp = strdup(SvPV_nolen(ERROR_SV));
				SET_ERRSTR("%s: %s", h_key, temp);
				free(temp);
				goto pack_fail;
			}
			if(inv)
				ENTRY_ADDR(*entry).invflags |= INV_DSTIP;
			(*entry)->nfcache |= NFC_IPx_DST;
		}

		/* Incoming interface */
		else if(!strcmp(h_key, "in-interface")) {
			if(!parse_iface(sv, ENTRY_ADDR(*entry).iniface, ENTRY_ADDR(*entry).iniface_mask,
									&inv)) {
				char *temp = strdup(SvPV_nolen(ERROR_SV));
				SET_ERRSTR("%s: %s", h_key, temp);
				free(temp);
				goto pack_fail;
			}
			if(inv)
				ENTRY_ADDR(*entry).invflags |= INV_VIA_IN;
			(*entry)->nfcache |= NFC_IPx_IF_IN;
		}

		/* Outgoing interface */
		else if(!strcmp(h_key, "out-interface")) {
			if(!parse_iface(sv, ENTRY_ADDR(*entry).outiface,
									ENTRY_ADDR(*entry).outiface_mask, &inv)) {
				char *temp = strdup(SvPV_nolen(ERROR_SV));
				SET_ERRSTR("%s: %s", h_key, temp);
				free(temp);
				goto pack_fail;
			}
			if(inv)
				ENTRY_ADDR(*entry).invflags |= INV_VIA_OUT;
			(*entry)->nfcache |= NFC_IPx_IF_OUT;
		}

#ifndef INET6
		/* Fragment flag */
		else if(!strcmp(h_key, "fragment")) {
			if(!SvIOK(sv)) {
				SET_ERRSTR("%s: Must be passed as integer", h_key);
				goto pack_fail;
			}
			ENTRY_ADDR(*entry).flags |= IPT_F_FRAG;
			if(!SvIV(sv))
				ENTRY_ADDR(*entry).invflags |= IPT_INV_FRAG;
			(*entry)->nfcache |= NFC_IP_FRAG;
		}
#endif /* !INET6 */

		else if(!strcmp(h_key, "bcnt")) {
			if(SvIOK(sv))
				(*entry)->counters.bcnt = SvIV(sv);
			else if(SvPOK(sv))
				sscanf(SvPV_nolen(sv), "%Lu", &(*entry)->counters.bcnt);
			else {
				SET_ERRSTR("%s: Must be passed as integer or string", h_key);
				goto pack_fail;
			}
		}

		else if(!strcmp(h_key, "pcnt")) {
			if(SvIOK(sv))
				(*entry)->counters.pcnt = SvIV(sv);
			else if(SvPOK(sv))
				sscanf(SvPV_nolen(sv), "%Lu", &(*entry)->counters.pcnt);
			else {
				SET_ERRSTR("%s: Must be passed as integer or string", h_key);
				goto pack_fail;
			}
		}

		/* All these are NOPs, because they've already been handled
		 * elsewhere, so we just need to make sure that they don't
		 * reach the fallthrough case in this loop. */
		else if(!strcmp(h_key, "jump") || !strcmp(h_key, "matches") ||
		    !strcmp(h_key, "protocol"))
			/* Yes, that's right. NOTHING. */;
		
		/* Check to guarantee that this raw target data actually goes
		 * with the target this rule is using. The actual process of
		 * putting the raw data where it belongs is rolled in with
		 * the rest of the target init process earlier on. */
		else if(strstr(h_key, TARGET_RAW_POSTFIX)) {
			asprintf(&rawkey, "%s" TARGET_RAW_POSTFIX, targetname);
			rval = strcmp(h_key, rawkey);
			free(rawkey);
			if(rval) {
				SET_ERRSTR("%s: Mismatched raw target data", h_key);
				goto pack_fail;
			}
		}

		/* This will check to make sure that the any raw match data
		 * keys are associated with matches we are using. The actual
		 * process of getting the match data is rolled in with the
		 * rest of the match init process */
		else if(strstr(h_key, MATCH_RAW_POSTFIX)) {
			bool matched = FALSE;
			for(i = 0; i < n_matches; i++) {
				asprintf(&rawkey, "%s" MATCH_RAW_POSTFIX,
								matches[i].match->u.user.name);
				rval = strcmp(h_key, rawkey);
				free(rawkey);
				if(!rval) {
					matched = TRUE;
					break;
				}
			}
			/* If the name on the raw match data field isn't found, then
			 * pass back an error, and fail now */
			if(!matched) {
				SET_ERRSTR("%s: Mismatched raw match data", h_key);
				goto pack_fail;
			}
		}
		else {
			rval = FALSE;
			/* If we get here, and the protocol match module hasn't already
			 * been loaded, then load it and init its match module info space.
			 * This has to be done to make the icmp protocol match module work
			 * right. This is more than a little weird. I originally just did
			 * this at the start, with the rest of the match modules - but if
			 * I do it that way, then you can't just match all ICMP packets.
			 * Rusty, why did you do this?!? */
			if(!gotproto && protoname && (module = ipt_find_module(protoname,
											MODULE_MATCH, table))) {
				int i;
				gotproto = TRUE;
				size = ALIGN(sizeof(ENTRY_MATCH)) + module->size;
				matches = realloc(matches, ++n_matches *
								sizeof(MatchElem));
				i = n_matches - 1;
				match = calloc(1, size);
				matches[i].flags = 0;
				match->u.match_size = size;
				strncpy(match->u.user.name, protoname, TARGET_NAME_LEN);
				if(module->setup)
					module->setup((void *)match, &(*entry)->nfcache);
				if(module->parse_field)
					rval = module->parse_field(h_key, sv, &match,
									&(*entry)->nfcache, *entry,
									&matches[i].flags);
				matches[i].match = match;
			}
			/* Oops. If we get here, there was a key that we're not supposed
			 * to get, so we return a FALSE to denote that we had a problem
			 * interpreting the hash's contents */
			if(!rval) {
				if(!SvOK(ERROR_SV))
					SET_ERRSTR("%s: field unknown", h_key);
				goto pack_fail;
			}
		}
	}

	/* Before we call it good, call the final_check() routine for each
	 * match and target module, so they can make sure everything is
	 * kosher */
	for(i = 0; i < n_matches; i++) {
		match = matches[i].match;
		module = ipt_find_module(match->u.user.name, MODULE_MATCH, table);
		if(module && module->final_check &&
						!module->final_check(match, matches[i].flags))
				goto pack_fail;
	}
	module = ipt_find_module(target->u.user.name, MODULE_TARGET, table);
	if(module && module->final_check &&
					!module->final_check(target, target_flags))
			goto pack_fail;

	/* Generate final data structure to be passed back */
	size = ALIGN(sizeof(ENTRY));
	/* If there are match modules, reallocate the ipt_entry to make room
	 * for them, and copy them into place */
	for(i = 0; i < n_matches; i++) {
		psize = size;
		size += matches[i].match->u.match_size;
		*entry = realloc(*entry, size);
		memcpy((void *)*entry + psize, matches[i].match,
						matches[i].match->u.match_size);
		free(matches[i].match);
	}
	free(matches);
	/* Put the target into place as well (no conditional, there's always
	 * a target of some sort */
	psize = size;
	size += target->u.target_size;
	*entry = realloc(*entry, size);
	memcpy((void *)*entry + psize, target, target->u.target_size);
	free(target);
	(*entry)->target_offset = psize;
	(*entry)->next_offset = size;
	
	/* Ok, we made it to the end, so it must've been a well-formed hash,
	 * and all the data elements must have been parsable, so now we return
	 * TRUE to signify that we are OK */
	free(targetname);
	return(TRUE);
pack_fail:
	if (matches) {
		for(i = 0; i < n_matches; i++) {
			psize = size;
			size += matches[i].match->u.match_size;
			*entry = realloc(*entry, size);
			memcpy((void *)*entry + psize, matches[i].match,
							matches[i].match->u.match_size);
			free(matches[i].match);
		}
		free(matches);
	}
	if (target)
		free(target);
	if (*entry)
		free(*entry);
	if (targetname)
		free(targetname);
	return(FALSE);
}

/* vim: ts=4
 */
