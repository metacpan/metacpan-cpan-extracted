#define INET6
#define BUILD_MATCH
#define MODULE_DATATYPE struct ip6t_mac_info
#define MODULE_NAME "mac"

#define __USE_GNU
#include "../module_iface.h"
#include <string.h>
#include <stdio.h>
#if defined(__GLIBC__) && __GLIBC__ == 2
#include <net/ethernet.h>
#else
#include <linux/if_ether.h>
#endif
#include <linux/netfilter_ipv6/ip6t_mac.h>

static void setup(void *myinfo, unsigned int *nfcache) {
	*nfcache |= NFC_UNKNOWN;
}

static int parse_field(char *field, SV *value, void *myinfo,
		unsigned int *nfcache, struct ip6t_entry *entry, int *flags) {
	MODULE_DATATYPE *info = (void *)(*(MODULE_ENTRYTYPE **)myinfo)->data;
	char *macstr, *sep, *extent, *temp, *base;
	int i = 0, num;
	STRLEN len;

	if(strcmp(field, "mac-source"))
		return(FALSE);

	*flags = 1;

	if(!SvPOK(value)) {
		SET_ERRSTR("%s: Must have a string arg", field);
		return(FALSE);
	}
	
	temp = SvPV(value, len);
	base = macstr = malloc(len + 1);
	strncpy(macstr, temp, len);
	macstr[len] = '\0';

	if(*macstr == INVCHAR) {
		info->invert = 1;
		macstr++;
	}

	for(i = 0; i < ETH_ALEN; i++) {
		sep = strchr(macstr, ':');
		num = strtoul(macstr, &extent, 16);
		if(extent < (sep ? sep : (macstr + strlen(macstr)))) {
			SET_ERRSTR("%s: Unable to parse argument", field);
			free(base);
			return(FALSE);
		}
		if(num < 0 || num > 255) {
			SET_ERRSTR("%s: MAC byte %d out of range", field, i + 1);
			free(base);
			return(FALSE);
		}
		info->srcaddr[i] = num;
		if (!sep && i < ETH_ALEN - 1) {
			SET_ERRSTR("%s: Unable to parse argument", field);
			free(base);
			return(FALSE);
		}
		macstr = sep + 1;
	}
	
	free(base);
	return(TRUE);
}

static void get_fields(HV *ent_hash, void *myinfo, struct ip6t_entry *entry) {
	MODULE_DATATYPE *info = (void *)((MODULE_ENTRYTYPE *)myinfo)->data;
	char *macstr, *temp;
	int i;

	asprintf(&macstr, "%.2x", info->srcaddr[0]);
	for(i = 1; i < ETH_ALEN; i++) {
		asprintf(&temp, "%s:%.2x", macstr, info->srcaddr[i]);
		free(macstr);
		macstr = temp;
	}
	
	if(info->invert) {
		asprintf(&temp, "%c%s", INVCHAR, macstr);
		free(macstr);
		macstr = temp;
	}
	
	hv_store(ent_hash, "mac-source", 10, newSVpv(macstr, 0), 0);
	free(macstr);
}

int final_check(void *myinfo, int flags) {
	if(!flags) {
		SET_ERRSTR("mac match requires 'mac-source'");
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
