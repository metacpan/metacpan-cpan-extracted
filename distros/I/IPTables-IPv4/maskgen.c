/* This code generates a comparison bitmask for the ipt_delete_entry() call.
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

#include <stdio.h>

#include "maskgen.h"
#include "loader.h"
#include "module_iface.h"

/* Generate the matchmask for iptc_delete_entry(). */
unsigned char *ipt_gen_delmask(ENTRY *entry) {
	unsigned int size;
	ENTRY_MATCH *match;
	ENTRY_TARGET *target;
	unsigned char *mask, *mptr;
	ModuleDef *module;

	size = entry->next_offset;

	/* Setup the actual mask data field */
	if(!(mask = calloc(1, size)))
		return(NULL);

	/* Mark off the size of a (struct ipt_entry) as data to compare against -
	 * an entry is never going to be smaller than this. */
	memset(mask, 0xFF, sizeof(ENTRY));
	mptr = mask + sizeof(ENTRY);
	
	/* Go through each of the matches, and ask each available match module
	 * how much of its data should be compared. */
	for(match = (void *)entry->elems;
					(void *)match < (void *)entry + entry->target_offset;
					match = (void *)match + match->u.match_size) {
		module = ipt_find_module(match->u.user.name, MODULE_MATCH, NULL);
		size = ALIGN(sizeof(ENTRY_MATCH));
		if(module)
			size += module->size_uspace;
		else if(match->u.match_size >
						ALIGN(sizeof(ENTRY_MATCH)))
			size = match->u.match_size;
		memset(mptr, 0xFF, size);
		
		mptr += match->u.match_size;
	}

	/* Now do the same for the target, if target data exists (it probably
	 * will, but never hurts to be careful). */
	if(entry->target_offset < entry->next_offset) {
		target = (void *)entry + entry->target_offset;
		module = ipt_find_module(target->u.user.name, MODULE_TARGET, NULL);
		size = ALIGN(sizeof(ENTRY_TARGET));
		if(module)
			size += module->size_uspace;
		else if(target->u.target_size >
						ALIGN(sizeof(ENTRY_TARGET)))
			size = target->u.target_size;
		memset(mptr, 0xFF, size);
	}

	return(mask);
}

/* vim: ts=4
 */
