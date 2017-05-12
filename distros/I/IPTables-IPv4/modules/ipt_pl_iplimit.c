#define BUILD_MATCH
#define MODULE_DATATYPE struct ipt_iplimit_info
#define MODULE_NAME "iplimit"

#define __USE_GNU
#include "../module_iface.h"
#include <string.h>
#include <stdio.h>
#include <linux/netfilter_ipv4/ip_conntrack.h>
#include <linux/netfilter_ipv4/ipt_iplimit.h>
#include <netinet/in.h>

static void setup(void *myinfo, unsigned int *nfcache) {
	MODULE_DATATYPE *info = (void *)((MODULE_ENTRYTYPE *)myinfo)->data;

	*nfcache |= NFC_UNKNOWN;
	info->mask = htonl(UINT_MAX);
}

static int parse_field(char *field, SV *value, void *myinfo,
		unsigned int *nfcache, struct ipt_entry *entry, int *flags) {
	MODULE_DATATYPE *info = (void *)(*(MODULE_ENTRYTYPE **)myinfo)->data;

	if(!strcmp(field, "iplimit-above")) {
		if(SvIOK(value))
			info->limit = SvIV(value);
		else if(SvPOK(value)) {
			char *base, *str, *temp, *extent;
			int val;
			STRLEN len;

			temp = SvPV(value, len);
			base = str = malloc(len + 1);
			strncpy(str, temp, len);
			str[len] = '\0';

			if(*str == INVCHAR) {
				info->inverse = 1;
				str++;
			}

			val = strtoul(str, &extent, 10);
			if(extent < str + strlen(str)) {
				SET_ERRSTR("%s: Couldn't parse arg", field);
				free(base);
				return(FALSE);
			}

			free(base);
			info->limit = val;
		}
		else {
			SET_ERRSTR("%s: Arg must be integer or string", field);
			return(FALSE);
		}
		*flags |= 1;
	}
	else if(!strcmp(field, "iplimit-mask")) {
		int val;
		if(!SvIOK(value)) {
			SET_ERRSTR("%s: Must have integer arg", field);
			return(FALSE);
		}

		val = SvIV(value);
		if(val < 0 || val >= 32) {
			SET_ERRSTR("%s: Value out of range", field);
			return(FALSE);
		}

		info->mask = htonl(UINT_MAX << (32 - val));
		*flags |= 2;
	}
	else
		return(FALSE);

	return(TRUE);
}

static void get_fields(HV *ent_hash, void *myinfo, struct ipt_entry *entry) {
	MODULE_DATATYPE *info = (void *)((MODULE_ENTRYTYPE *)myinfo)->data;
	SV *sv;

	if(info->inverse)
		sv = newSVpvf("%c%u", INVCHAR, info->limit);
	else
		sv = newSViv(info->limit);

	hv_store(ent_hash, "iplimit-above", 13, sv, 0);
	
	if(ntohl(info->mask) != UINT_MAX) {
		int i;

		/* This should work - a little black magic... */
		for(i = 0; (~ntohl(info->mask)) >> i; i++);
		hv_store(ent_hash, "iplimit-mask", 12, newSViv(i), 0);
	}
}

int final_check(void *myinfo, int flags) {
	if(!(flags & 1)) {
		SET_ERRSTR("iplimit match requires 'iplimit-above'");
		return(FALSE);
	}
	
	return(TRUE);
}

static ModuleDef _module = {
	.type			= MODULE_TYPE,
	.name			= MODULE_NAME,
	.size			= IPT_ALIGN(sizeof(MODULE_DATATYPE)),
	.size_uspace	= IPT_ALIGN(sizeof(MODULE_DATATYPE)),
	.setup			= setup,
	.parse_field	= parse_field,
	.get_fields		= get_fields,
	.final_check	= final_check,
};

ModuleDef *init(void) {
	return(&_module);
}
/* vim: ts=4
 */
