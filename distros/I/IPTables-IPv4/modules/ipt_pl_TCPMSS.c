#define BUILD_TARGET
#define MODULE_DATATYPE struct ipt_tcpmss_info
#define MODULE_NAME "TCPMSS"

#define __USE_GNU
#include "../module_iface.h"
#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include <limits.h>
#include <netinet/in.h>
#include <linux/netfilter_ipv4/ipt_TCPMSS.h>

static int parse_field(char *field, SV *value, void *myinfo,
		unsigned int *nfcache, struct ipt_entry *entry, int *flags) {
	MODULE_DATATYPE *info = (void *)(*(MODULE_ENTRYTYPE **)myinfo)->data;
	int val;

	if(!strcmp(field, "set-mss")) {
		if(SvIOK(value))
			val = SvIV(value);
		else if(SvPOK(value)) {
			char *extent, *temp, *str;
			STRLEN len;

			temp = SvPV(value, len);
			str = malloc(len + 1);
			strncpy(str, temp, len);
			str[len] = '\0';
			val = strtoul(str, &extent, 10);
			
			if(extent < str + strlen(str)) {
				SET_ERRSTR("%s: Unable to parse", field);
				free(str);
				return(FALSE);
			}
			free(str);
		}
		else {
			SET_ERRSTR("%s: Must be passed as integer or string", field);
			return(FALSE);
		}

		if(val < 0 || val > USHRT_MAX - 40) {
			SET_ERRSTR("%s: Value out of range", field);
			return(FALSE);
		}

		info->mss = val;


	}
	else if(!strcmp(field, "clamp-mss-to-pmtu")) {
		info->mss = IPT_TCPMSS_CLAMP_PMTU;
	}
	else
		return(FALSE);

	if(*flags) {
		SET_ERRSTR("%s: Only one of 'set-mss', 'clamp-mss-to-pmtu' allowed "
						"for TCPMSS target", field);
		return(FALSE);
	}

	if(entry->ip.proto != IPPROTO_TCP || entry->ip.invflags & IPT_INV_PROTO) {
		SET_ERRSTR("%s: Protocol must be TCP", field);
		return(FALSE);
	}

	*flags = 1;

	return(TRUE);
}

static void get_fields(HV *ent_hash, void *myinfo, struct ipt_entry *entry) {
	MODULE_DATATYPE *info = (void *)((MODULE_ENTRYTYPE *)myinfo)->data;

	if(info->mss == IPT_TCPMSS_CLAMP_PMTU)
		hv_store(ent_hash, "clamp-mss-to-pmtu", 17, newSViv(0), 0);
	else
		hv_store(ent_hash, "set-mss", 3, newSViv(info->mss), 0);
}

static int final_check(void *myinfo, int flags) {
	if(!flags) {
		SET_ERRSTR("TCPMSS target requires one of 'set-mss', "
						"'clamp-mss-to-pmtu'");
		return(FALSE);
	}
	return(TRUE);
}

static ModuleDef _module = {
	.type			= MODULE_TYPE,
	.name			= MODULE_NAME,
	.size			= IPT_ALIGN(sizeof(MODULE_DATATYPE)),
	.size_uspace	= IPT_ALIGN(sizeof(MODULE_DATATYPE)),
	.parse_field	= parse_field,
	.get_fields		= get_fields,
	.final_check	= final_check,
};

ModuleDef *init(void) {
	return(&_module);
}
/* vim: ts=4
 */
