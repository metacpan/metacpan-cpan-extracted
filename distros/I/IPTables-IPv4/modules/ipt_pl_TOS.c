#define BUILD_TARGET
#define MODULE_DATATYPE struct ipt_tos_target_info
#define MODULE_NAME "TOS"

#define __USE_GNU
#include "../module_iface.h"
#include <string.h>
#include <stdio.h>
#include <linux/netfilter_ipv4/ipt_TOS.h>

static struct TOSList {
	char value;
	char *name;
} tos_list[] = {
	{ IPTOS_LOWDELAY,		"Minimize-Delay" },
	{ IPTOS_THROUGHPUT,		"Maximize-Throughput" },
	{ IPTOS_RELIABILITY,	"Maximize-Reliability" },
	{ IPTOS_MINCOST,		"Minimize-Cost" },
	{ IPTOS_NORMALSVC,		"Normal-Service" }
};

static int parse_field(char *field, SV *value, void *myinfo,
		unsigned int *nfcache, struct ipt_entry *entry, int *flags) {
	MODULE_DATATYPE *info = (void *)(*(MODULE_ENTRYTYPE **)myinfo)->data;
	int tosval;
	unsigned int i;
	struct TOSList *selector = NULL;

	if(strcmp(field, "set-tos"))
		return(FALSE);

	*flags = 1;

	if(SvIOK(value))
		tosval = SvIV(value);
	else if(SvPOK(value)) {
		char *tosstr, *temp, *extent;
		STRLEN len;

		temp = SvPV(value, len);
		tosstr = malloc(len + 1);
		strncpy(tosstr, temp, len);
		tosstr[len] = '\0';

		for(i = 0; i < (sizeof(tos_list) / sizeof(struct TOSList)); i++) {
			if(!strcmp(tosstr, tos_list[i].name)) {
				selector = &tos_list[i];
				break;
			}
		}
		
		if(selector)
			tosval = selector->value;
		else {
			tosval = strtoul(tosstr, &extent, 0);
			if(extent < (tosstr + strlen(tosstr))) {
				SET_ERRSTR("%s: Couldn't parse value", field);
				free(tosstr);
				return(FALSE);
			}
		}
		free(tosstr);
		
	}
	else {
		SET_ERRSTR("%s: Must have a string or integer arg", field);
		return(FALSE);
	}

	for(i = 0; i < (sizeof(tos_list) / sizeof(struct TOSList)); i++) {
		if(tosval == tos_list[i].value) {
			info->tos = tosval;
			return(TRUE);
		}
	}

	SET_ERRSTR("%s: Unknown type-of-service value %d", field, tosval);
	return(FALSE);
}

static void get_fields(HV *ent_hash, void *myinfo, struct ipt_entry *entry) {
	MODULE_DATATYPE *info = (void *)((MODULE_ENTRYTYPE *)myinfo)->data;
	char *tosstr = NULL;
	unsigned int i;

	for(i = 0; i < (sizeof(tos_list) / sizeof(struct TOSList)); i++) {
		if(info->tos == tos_list[i].value) {
			tosstr = strdup(tos_list[i].name);
			break;
		}
	}

	if(!tosstr)
		asprintf(&tosstr, "%u", info->tos);
	
	hv_store(ent_hash, "set-tos", 3, newSVpv(tosstr, 0), 0);
	free(tosstr);
}

int final_check(void *myinfo, int flags) {
	if(!flags) {
		SET_ERRSTR("TOS target requires set-tos field");
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
