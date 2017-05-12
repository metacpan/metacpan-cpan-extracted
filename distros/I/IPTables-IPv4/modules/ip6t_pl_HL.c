#define INET6
#define BUILD_TARGET
#define MODULE_DATATYPE struct ip6t_HL_info
#define MODULE_NAME "HL"

#define __USE_GNU
#include "../module_iface.h"
#include <string.h>
#include <stdio.h>
#include <linux/if_ether.h>
#include <linux/netfilter_ipv6/ip6_tables.h>
#include <linux/netfilter_ipv6/ip6t_HL.h>

static int parse_field(char *field, SV *value, void *myinfo,
		unsigned int *nfcache, struct ip6t_entry *entry, int *flags) {
	MODULE_DATATYPE *info = (void *)(*(MODULE_ENTRYTYPE **)myinfo)->data;

	if(!strcmp(field, "hl-set"))
		info->mode = IP6T_HL_SET;
	else if(!strcmp(field, "hl-inc"))
		info->mode = IP6T_HL_INC;
	else if(!strcmp(field, "hl-dec"))
		info->mode = IP6T_HL_DEC;
	else
		return(FALSE);

	if(*flags) {
		SET_ERRSTR("%s: Only one of 'hl-set', 'hl-inc', or 'hl-dec' "
						"allowed for HL target", field);
		return(FALSE);
	}

	*flags = 1;

	if(SvIOK(value))
		info->hop_limit = SvIV(value);
	else if(SvPOK(value)) {
		char *text, *temp, *extent;
		int val;
		STRLEN len;

		temp = SvPV(value, len);
		text = malloc(len + 1);
		strncpy(text, temp, len);
		text[len] = '\0';

		val = strtoul(text, &extent, 10);
		if(extent != text + strlen(text)) {
			SET_ERRSTR("%s: Couldn't parse field", field);
			free(text);
			return(FALSE);
		}
		free(text);
		info->hop_limit = val;
	}
	else {
		SET_ERRSTR("%s: Must have a string or integer arg", field);
		return(FALSE);
	}

	if(info->mode != IP6T_HL_SET && info->hop_limit == 0) {
		SET_ERRSTR("%s: %screase HL by zero? Makes no sense", field,
						(info->mode == IP6T_HL_DEC ? "De" : "In"));
		return(FALSE);
	}
	
	return(TRUE);
}

static void get_fields(HV *ent_hash, void *myinfo, struct ip6t_entry *entry) {
	MODULE_DATATYPE *info = (void *)((MODULE_ENTRYTYPE *)myinfo)->data;
	SV *sv;

	sv = newSViv(info->hop_limit);

	if(info->mode == IP6T_HL_SET)
		hv_store(ent_hash, "hl-set", 6, sv, 0);
	else if(info->mode == IP6T_HL_INC)
		hv_store(ent_hash, "hl-inc", 6, sv, 0);
	else if(info->mode == IP6T_HL_DEC)
		hv_store(ent_hash, "hl-dec", 6, sv, 0);
}

int final_check(void *myinfo, int flags) {
	if(!flags) {
		SET_ERRSTR("HL target requires one of 'hl-set', 'hl-inc', or "
						"'hl-dec'");
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
