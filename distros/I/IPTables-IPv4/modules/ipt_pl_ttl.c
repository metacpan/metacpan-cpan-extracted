#define BUILD_MATCH
#define MODULE_DATATYPE struct ipt_ttl_info
#define MODULE_NAME "ttl"

#define __USE_GNU
#include "../module_iface.h"
#include <string.h>
#include <stdio.h>
#include <linux/if_ether.h>
#include <linux/netfilter_ipv4/ip_tables.h>
#include <linux/netfilter_ipv4/ipt_ttl.h>

static void setup(void *myinfo, unsigned int *nfcache) {
	*nfcache |= NFC_UNKNOWN;
}

static int parse_field(char *field, SV *value, void *myinfo,
		unsigned int *nfcache, struct ipt_entry *entry, int *flags) {
	MODULE_DATATYPE *info = (void *)(*(MODULE_ENTRYTYPE **)myinfo)->data;

	if(!strcmp(field, "ttl-eq"))
		info->mode = IPT_TTL_EQ;
	else if(!strcmp(field, "ttl-lt"))
		info->mode = IPT_TTL_LT;
	else if(!strcmp(field, "ttl-gt"))
		info->mode = IPT_TTL_GT;
	else
		return(FALSE);

	if(*flags) {
		SET_ERRSTR("%s: Only one of 'ttl-eq', 'ttl-lt', or 'ttl-gt' allowed "
						"for ttl match", field);
		return(FALSE);
	}

	*flags = 1;

	if(SvIOK(value))
		info->ttl = SvIV(value);
	else if(SvPOK(value)) {
		char *text, *extent, *base, *temp;
		int val;
		STRLEN len;

		temp = SvPV(value, len);
		base = text = malloc(len + 1);
		strncpy(text, temp, len);
		text[len] = '\0';
		if(info->mode == IPT_TTL_EQ && *text == INVCHAR) {
			info->mode = IPT_TTL_NE;
			text++;
		}

		val = strtoul(text, &extent, 10);
		if(extent != text + strlen(text)) {
			SET_ERRSTR("%s: Couldn't parse field", field);
			free(base);
			return(FALSE);
		}
		free(base);
		info->ttl = val;
	}
	else {
		SET_ERRSTR("%s: Must have a string or integer arg", field);
		return(FALSE);
	}
	
	return(TRUE);
}

static void get_fields(HV *ent_hash, void *myinfo, struct ipt_entry *entry) {
	MODULE_DATATYPE *info = (void *)((MODULE_ENTRYTYPE *)myinfo)->data;
	SV *sv;

	if(info->mode == IPT_TTL_NE)
		sv = newSVpvf("%c%u", INVCHAR, info->ttl);
	else
		sv = newSViv(info->ttl);

	if(info->mode == IPT_TTL_EQ || info->mode == IPT_TTL_NE)
		hv_store(ent_hash, "ttl-eq", 6, sv, 0);
	else if(info->mode == IPT_TTL_LT)
		hv_store(ent_hash, "ttl-lt", 6, sv, 0);
	else if(info->mode == IPT_TTL_GT)
		hv_store(ent_hash, "ttl-gt", 6, sv, 0);
}

int final_check(void *myinfo, int flags) {
	if(!flags) {
		SET_ERRSTR("ttl match requires one of 'ttl-eq', 'ttl-lt', 'ttl-gt'");
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
