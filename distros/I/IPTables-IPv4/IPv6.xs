/* This piece of code is a wrapper around libiptc from netfilter/ip6tables
 * for managing rules and chains.
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

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define INET6

#include <libiptc/libip6tc.h>
#include <errno.h>
#include "packer.h"
#include "unpacker.h"
#include "loader.h"
#include "maskgen.h"
#include "module_iface.h"

typedef ip6tc_handle_t* IPTables__IPv6__Table;

MODULE = IPTables::IPv6		PACKAGE = IPTables::IPv6

IPTables::IPv6::Table
init(tablename)
	char *	tablename
	PREINIT:
	ip6tc_handle_t	handle;
	CODE:
		
		handle = ip6tc_init(tablename);
		if(handle == NULL) {
			RETVAL = NULL;
			SET_ERRNUM(errno);
			SET_ERRSTR("%s", ip6tc_strerror(errno));
			SvIOK_on(ERROR_SV);
		}
		else {
			RETVAL = malloc(sizeof(ip6tc_handle_t));
			*RETVAL = handle;
			ipt_loader_setup();
		}
	OUTPUT:
	RETVAL
		
MODULE = IPTables::IPv6		PACKAGE = IPTables::IPv6::Table

int
is_chain(self, chain)
	IPTables::IPv6::Table	self
	ip6t_chainlabel			chain
	CODE:
		RETVAL = ip6tc_is_chain(chain, *self);
	OUTPUT:
	RETVAL

void
list_chains(self)
	IPTables::IPv6::Table	self
	PREINIT:
	char *			chain;
	SV *			sv;
	int				count = 0;
	PPCODE:
		sv = ST(0);
		chain = (char *)ip6tc_first_chain(self);
		while(chain) {
			count++;
			if (GIMME_V == G_ARRAY)
				XPUSHs(sv_2mortal(newSVpv(chain, 0)));
			chain = (char *)ip6tc_next_chain(self);
		}
		if (GIMME_V == G_SCALAR)
			XPUSHs(sv_2mortal(newSViv(count)));

void
list_rules(self, chain)
	IPTables::IPv6::Table	self
	ip6t_chainlabel			chain
	PREINIT:
	SV *					sv;
	int				count = 0;
	PPCODE:
		sv = ST(0);
		if(ip6tc_is_chain(chain, *self)) {
			struct ip6t_entry *entry =
			    (struct ip6t_entry *)ip6tc_first_rule(chain, self);
			while(entry) {
				count++;
				if (GIMME_V == G_ARRAY)
					XPUSHs(sv_2mortal(newRV_noinc((SV*)ipt_do_unpack(entry, self))));
				entry = (struct ip6t_entry *)ip6tc_next_rule(entry, self);
			}
		}
		if (GIMME_V == G_SCALAR)
			XPUSHs(sv_2mortal(newSViv(count)));

int
builtin(self, chain)
	IPTables::IPv6::Table	self
	ip6t_chainlabel			chain
	CODE:
		RETVAL = ip6tc_builtin(chain, *self);
	OUTPUT:
	RETVAL

void
get_policy(self, chain)
	IPTables::IPv6::Table	self
	ip6t_chainlabel			chain
	PREINIT:
	struct ip6t_counters	counter;
	SV *					sv;
	char *					target;
	char *					temp;
	PPCODE:
		sv = ST(0);
		if((target = (char *)ip6tc_get_policy(chain, &counter, self))) {
			XPUSHs(sv_2mortal(newSVpv(target, 0)));
			asprintf(&temp, "%llu", counter.pcnt);
			XPUSHs(sv_2mortal(newSVpv(temp, 0)));
			free(temp);
			asprintf(&temp, "%llu", counter.bcnt);
			XPUSHs(sv_2mortal(newSVpv(temp, 0)));
			free(temp);
		}
		else {
			SET_ERRNUM(errno);
			SET_ERRSTR("%s", ip6tc_strerror(errno));
			SvIOK_on(ERROR_SV);
		}

int
insert_entry(self, chain, entry, rulenum)
	IPTables::IPv6::Table	self
	ip6t_chainlabel			chain
	struct ip6t_entry *		entry
	unsigned int			rulenum
	CODE:
		RETVAL = ip6tc_insert_entry(chain, entry, rulenum, self);
		free(entry);
		if(!RETVAL) {
			SET_ERRNUM(errno);
			SET_ERRSTR("%s", ip6tc_strerror(errno));
			SvIOK_on(ERROR_SV);
		}
	OUTPUT:
	RETVAL

int
replace_entry(self, chain, entry, rulenum)
	IPTables::IPv6::Table	self
	ip6t_chainlabel			chain
	struct ip6t_entry *		entry
	unsigned int			rulenum
	CODE:
		RETVAL = ip6tc_replace_entry(chain, entry, rulenum, self);
		free(entry);
		if(!RETVAL) {
			SET_ERRNUM(errno);
			SET_ERRSTR("%s", ip6tc_strerror(errno));
			SvIOK_on(ERROR_SV);
		}
	OUTPUT:
	RETVAL

int
append_entry(self, chain, entry)
	IPTables::IPv6::Table	self
	ip6t_chainlabel			chain
	struct ip6t_entry *		entry
	CODE:
		RETVAL = ip6tc_append_entry(chain, entry, self);
		free(entry);
		if(!RETVAL) {
			SET_ERRNUM(errno);
			SET_ERRSTR("%s", ip6tc_strerror(errno));
			SvIOK_on(ERROR_SV);
		}
	OUTPUT:
	RETVAL

int
delete_entry(self, chain, origfw)
	IPTables::IPv6::Table	self
	ip6t_chainlabel			chain
	struct ip6t_entry *		origfw
	PREINIT:
	unsigned char *			matchmask = NULL;
	CODE:
		if((matchmask = ipt_gen_delmask(origfw))) {
			RETVAL = ip6tc_delete_entry(chain, origfw, matchmask, self);
			if(!RETVAL) {
				SET_ERRNUM(errno);
				SET_ERRSTR("%s", ip6tc_strerror(errno));
				SvIOK_on(ERROR_SV);
			}
		}
		else {
			SET_ERRSTR("Unable to generate matchmask");
			RETVAL = FALSE;
		}
		free(origfw);
		free(matchmask);
	OUTPUT:
	RETVAL

int
delete_num_entry(self, chain, rulenum)
	IPTables::IPv6::Table	self
	ip6t_chainlabel			chain
	unsigned int			rulenum
	CODE:
		RETVAL = ip6tc_delete_num_entry(chain, rulenum, self);
		if(!RETVAL) {
			SET_ERRNUM(errno);
			SET_ERRSTR("%s", ip6tc_strerror(errno));
			SvIOK_on(ERROR_SV);
		}
	OUTPUT:
	RETVAL

int
flush_entries(self, chain)
	IPTables::IPv6::Table	self
	ip6t_chainlabel			chain
	CODE:
		RETVAL = ip6tc_flush_entries(chain, self);
		if(!RETVAL) {
			SET_ERRNUM(errno);
			SET_ERRSTR("%s", ip6tc_strerror(errno));
			SvIOK_on(ERROR_SV);
		}
	OUTPUT:
	RETVAL

int
zero_entries(self, chain)
	IPTables::IPv6::Table	self
	ip6t_chainlabel			chain
	CODE:
		RETVAL = ip6tc_zero_entries(chain, self);
		if(!RETVAL) {
			SET_ERRNUM(errno);
			SET_ERRSTR("%s", ip6tc_strerror(errno));
			SvIOK_on(ERROR_SV);
		}
	OUTPUT:
	RETVAL

int
create_chain(self, chain)
	IPTables::IPv6::Table	self
	ip6t_chainlabel			chain
	CODE:
		RETVAL = ip6tc_create_chain(chain, self);
		if(!RETVAL) {
			SET_ERRNUM(errno);
			SET_ERRSTR("%s", ip6tc_strerror(errno));
			SvIOK_on(ERROR_SV);
		}
	OUTPUT:
	RETVAL

int
delete_chain(self, chain)
	IPTables::IPv6::Table	self
	ip6t_chainlabel			chain
	CODE:
		RETVAL = ip6tc_delete_chain(chain, self);
		if(!RETVAL) {
			SET_ERRNUM(errno);
			SET_ERRSTR("%s", ip6tc_strerror(errno));
			SvIOK_on(ERROR_SV);
		}
	OUTPUT:
	RETVAL

int
rename_chain(self, oldname, newname)
	IPTables::IPv6::Table	self
	ip6t_chainlabel			oldname
	ip6t_chainlabel			newname
	CODE:
		RETVAL = ip6tc_rename_chain(oldname, newname, self);
		if(!RETVAL) {
			SET_ERRNUM(errno);
			SET_ERRSTR("%s", ip6tc_strerror(errno));
			SvIOK_on(ERROR_SV);
		}
	OUTPUT:
	RETVAL

int
set_policy(self, chain, policy, count = NULL)
	IPTables::IPv6::Table	self
	ip6t_chainlabel			chain
	ip6t_chainlabel			policy
	SV *					count
	PREINIT:
	struct ip6t_counters *	counters = NULL;
	HV *					hash;
	SV *					sv;
	char *					h_key;
	int						h_keylen;
	CODE:
		RETVAL = TRUE;
		if(count) {
			if((SvTYPE(count) == SVt_RV) && (hash = (HV *)SvRV(count)) &&
							(SvTYPE(hash) == SVt_PVHV)) {
				hv_iterinit(hash);
				counters = malloc(sizeof(struct ip6t_counters));
				while((sv = hv_iternextsv(hash, &h_key, (I32 *)&h_keylen))) {
					if(!strcmp(h_key, "pcnt")) {
						if(SvTYPE(sv) == SVt_IV)
							counters->pcnt = SvUV(sv);
						else if(SvPOK(sv))
							sscanf(SvPV_nolen(sv), "%Lu", &counters->pcnt);
						else {
							RETVAL = FALSE;
							SET_ERRSTR("pcnt field must be integer or string");
						}
					}
					else if(!strcmp(h_key, "bcnt")) {
						if(SvTYPE(sv) == SVt_IV)
							counters->bcnt = SvUV(sv);
						else if(SvPOK(sv))
							sscanf(SvPV_nolen(sv), "%Lu", &counters->bcnt);
						else {
							RETVAL = FALSE;
							SET_ERRSTR("bcnt field must be integer or string");
						}
					}
					else {
						RETVAL = FALSE;
						SET_ERRSTR("count hash must contain only bcnt and pcnt keys");
					}
				}
			}
			else {
				RETVAL = FALSE;
				SET_ERRSTR("count must be hash ref");
			}
		}
		if(RETVAL) {
			RETVAL = ip6tc_set_policy(chain, policy, counters, self);
			if(!RETVAL) {
				SET_ERRNUM(errno);
				SET_ERRSTR("%s", ip6tc_strerror(errno));
				SvIOK_on(ERROR_SV);
			}
		}
		if(counters)
			free(counters);
	OUTPUT:
	RETVAL

int
get_references(self, chain)
	IPTables::IPv6::Table	self
	ip6t_chainlabel			chain
	CODE:
		if(!ip6tc_get_references(&RETVAL, chain, self)) {
			RETVAL = -1;
			SET_ERRNUM(errno);
			SET_ERRSTR("%s", ip6tc_strerror(errno));
			SvIOK_on(ERROR_SV);
		}
	OUTPUT:
	RETVAL

int
commit(self)
	IPTables::IPv6::Table	self
	CODE:
		RETVAL = ip6tc_commit(self);
		if(!RETVAL) {
			SET_ERRNUM(errno);
			SET_ERRSTR("%s", ip6tc_strerror(errno));
			SvIOK_on(ERROR_SV);
		}
		*self = NULL;
		
	OUTPUT:
	RETVAL

void
DESTROY(self)
	IPTables::IPv6::Table	&self
	CODE:
		if(self) {
			if(*self)
				ip6tc_free(self);
			free(self);
		}
		ipt_release_modules();
		/* vim: ts=4
		 */
