#define INET6
#define BUILD_MATCH
#define MODULE_DATATYPE struct ip6t_hl_info
#define MODULE_NAME "hl"

#define __USE_GNU
#include "../module_iface.h"
#include <string.h>
#include <stdio.h>
#include <linux/if_ether.h>
#include <linux/netfilter_ipv6/ip6_tables.h>
#include <linux/netfilter_ipv6/ip6t_hl.h>

static void setup(void *myinfo, unsigned int *nfcache) {
	*nfcache |= NFC_UNKNOWN;
}

static int parse_field(char *field, SV *value, void *myinfo,
		unsigned int *nfcache, struct ip6t_entry *entry, int *flags) {
	MODULE_DATATYPE *info = (void *)(*(MODULE_ENTRYTYPE **)myinfo)->data;

	if(!strcmp(field, "hl-eq"))
		info->mode = IP6T_HL_EQ;
	else if(!strcmp(field, "hl-lt"))
		info->mode = IP6T_HL_LT;
	else if(!strcmp(field, "hl-gt"))
		info->mode = IP6T_HL_GT;
	else
		return(FALSE);

	if(*flags) {
		SET_ERRSTR("%s: Only one of 'hl-eq', 'hl-lt', or 'hl-gt' allowed "
						"for hl match", field);
		return(FALSE);
	}

	*flags = 1;

	if(SvIOK(value))
		info->hop_limit = SvIV(value);
	else if(SvPOK(value)) {
		char *text, *extent, *base, *temp;
		int val;
		STRLEN len;

		temp = SvPV(value, len);
		base = text = malloc(len + 1);
		strncpy(text, temp, len);
		text[len] = '\0';
		if(info->mode == IP6T_HL_EQ && *text == INVCHAR) {
			info->mode = IP6T_HL_NE;
			text++;
		}

		val = strtoul(text, &extent, 10);
		if(extent != text + strlen(text)) {
			SET_ERRSTR("%s: Couldn't parse field", field);
			free(base);
			return(FALSE);
		}
		free(base);
		info->hop_limit = val;
	}
	else {
		SET_ERRSTR("%s: Must have a string or integer arg", field);
		return(FALSE);
	}
	
	return(TRUE);
}

static void get_fields(HV *ent_hash, void *myinfo, struct ip6t_entry *entry) {
	MODULE_DATATYPE *info = (void *)((MODULE_ENTRYTYPE *)myinfo)->data;
	SV *sv;

	if(info->mode == IP6T_HL_NE)
		sv = newSVpvf("%c%u", INVCHAR, info->hop_limit);
	else
		sv = newSViv(info->hop_limit);

	if(info->mode == IP6T_HL_EQ || info->mode == IP6T_HL_NE)
		hv_store(ent_hash, "hl-eq", 5, sv, 0);
	else if(info->mode == IP6T_HL_LT)
		hv_store(ent_hash, "hl-lt", 5, sv, 0);
	else if(info->mode == IP6T_HL_GT)
		hv_store(ent_hash, "hl-gt", 5, sv, 0);
}

int final_check(void *myinfo, int flags) {
	if(!flags) {
		SET_ERRSTR("hl match requires one of 'hl-eq', 'hl-lt', 'hl-gt'");
		return(FALSE);
	}
	
	return(TRUE);
}

static ModuleDef _module = {
	.type			= MODULE_TYPE,
	.name			= MODULE_NAME,
	.size			= IP6T_ALIGN(sizeof(MODULE_DATATYPE)),
	.size_uspace	= IP6T_ALIGN(sizeof(MODULE_DATATYPE)),
	.setup			= setup,
	.parse_field	= parse_field,
	.get_fields		= get_fields,
	.final_check	= final_check
};

ModuleDef *init(void) {
	return(&_module);
}

/* vim: ts=4
 */
