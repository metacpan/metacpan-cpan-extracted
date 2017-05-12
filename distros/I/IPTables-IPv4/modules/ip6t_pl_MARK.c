#define INET6
#define BUILD_TARGET
#define MODULE_DATATYPE struct ip6t_mark_target_info
#define MODULE_NAME "MARK"

#define __USE_GNU
#include "../module_iface.h"
#include <string.h>
#include <stdio.h>
#include <linux/netfilter_ipv6/ip6t_MARK.h>

static int parse_field(char *field, SV *value, void *myinfo,
		unsigned int *nfcache, struct ip6t_entry *entry, int *flags) {
	MODULE_DATATYPE *info = (void *)(*(MODULE_ENTRYTYPE **)myinfo)->data;

	if(strcmp(field, "set-mark"))
		return(FALSE);

	*flags = 1;

	if(SvIOK(value))
		info->mark = SvIV(value);
	else if(SvPOK(value)) {
		char *markstr, *extent, *temp;
		int num;
		STRLEN len;

		temp = SvPV(value, len);
		markstr = malloc(len + 1);
		strncpy(markstr, temp, len);
		markstr[len] = '\0';
		
		num = strtoul(markstr, &extent, 0);
		if(extent < markstr + strlen(markstr)) {
			SET_ERRSTR("%s: Unable to parse", field);
			free(markstr);
			return(FALSE);
		}
		free(markstr);
		info->mark = num;
	}
	else {
		SET_ERRSTR("%s: Must have a string or integer arg", field);
		return(FALSE);
	}

	return(TRUE);
}

static void get_fields(HV *ent_hash, void *myinfo, struct ip6t_entry *entry) {
	MODULE_DATATYPE *info = (void *)((MODULE_ENTRYTYPE *)myinfo)->data;

	hv_store(ent_hash, "set-mark", 8, newSViv(info->mark), 0);
}

int final_check(void *myinfo, int flags) {
	if(!flags) {
		SET_ERRSTR("MARK target requires 'set-mark'");
		return(FALSE);
	}
	
	return(TRUE);
}

static ModuleDef _module = {
	.type			= MODULE_TYPE,
	.name			= MODULE_NAME,
	.size			= IP6T_ALIGN(sizeof(MODULE_DATATYPE)),
	.size_uspace	= IP6T_ALIGN(sizeof(MODULE_DATATYPE)),
	.parse_field	= parse_field,
	.get_fields		= get_fields,
	.final_check	= final_check,
};

ModuleDef *init(void) {
	return(&_module);
}
/* vim: ts=4
 */
