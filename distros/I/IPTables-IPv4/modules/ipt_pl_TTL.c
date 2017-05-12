#define BUILD_TARGET
#define MODULE_DATATYPE struct ipt_TTL_info
#define MODULE_NAME "TTL"

#define __USE_GNU
#include "../module_iface.h"
#include <string.h>
#include <stdio.h>
#include <linux/if_ether.h>
#include <linux/netfilter_ipv4/ip_tables.h>
#include <linux/netfilter_ipv4/ipt_TTL.h>

static int parse_field(char *field, SV *value, void *myinfo,
		unsigned int *nfcache, struct ipt_entry *entry, int *flags) {
	MODULE_DATATYPE *info = (void *)(*(MODULE_ENTRYTYPE **)myinfo)->data;

	if(!strcmp(field, "ttl-set"))
		info->mode = IPT_TTL_SET;
	else if(!strcmp(field, "ttl-inc"))
		info->mode = IPT_TTL_INC;
	else if(!strcmp(field, "ttl-dec"))
		info->mode = IPT_TTL_DEC;
	else
		return(FALSE);

	if(*flags) {
		SET_ERRSTR("%s: Only one of 'ttl-set', 'ttl-inc', or 'ttl-dec' "
						"allowed for TTL target", field);
		return(FALSE);
	}

	*flags = 1;

	if(SvIOK(value))
		info->ttl = SvIV(value);
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
		info->ttl = val;
	}
	else {
		SET_ERRSTR("%s: Must have a string or integer arg", field);
		return(FALSE);
	}

	if(info->mode != IPT_TTL_SET && info->ttl == 0) {
		SET_ERRSTR("%s: %screase TTL by zero? Makes no sense", field,
						(info->mode == IPT_TTL_DEC ? "De" : "In"));
		return(FALSE);
	}
	
	return(TRUE);
}

static void get_fields(HV *ent_hash, void *myinfo, struct ipt_entry *entry) {
	MODULE_DATATYPE *info = (void *)((MODULE_ENTRYTYPE *)myinfo)->data;
	SV *sv;

	sv = newSViv(info->ttl);

	if(info->mode == IPT_TTL_SET)
		hv_store(ent_hash, "ttl-set", 7, sv, 0);
	else if(info->mode == IPT_TTL_INC)
		hv_store(ent_hash, "ttl-inc", 7, sv, 0);
	else if(info->mode == IPT_TTL_DEC)
		hv_store(ent_hash, "ttl-dec", 7, sv, 0);
}

int final_check(void *myinfo, int flags) {
	if(!flags) {
		SET_ERRSTR("TTL target requires one of 'ttl-set', 'ttl-inc', or "
						"'ttl-dec'");
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
