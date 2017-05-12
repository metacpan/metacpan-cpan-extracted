#define BUILD_MATCH
#define MODULE_DATATYPE struct ipt_length_info
#define MODULE_NAME "length"

#define __USE_GNU
#include "../module_iface.h"
#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include <limits.h>
#include <linux/netfilter_ipv4/ipt_length.h>

static void setup(void *myinfo, unsigned int *nfcache) {
	*nfcache |= NFC_UNKNOWN;
}

static int parse_field(char *field, SV *value, void *myinfo,
		unsigned int *nfcache, struct ipt_entry *entry, int *flags) {
	MODULE_DATATYPE *info = (void *)(*(MODULE_ENTRYTYPE **)myinfo)->data;
	int val;

	if(strcmp(field, "length"))
		return(FALSE);

	*flags = 1;

	if(SvIOK(value)) {
		val = SvIV(value);
		if(val < 0 || val > USHRT_MAX) {
			SET_ERRSTR("%s: Value out of range", field);
			return(FALSE);
		}
		info->min = info->max = val;
	}
	else if(SvPOK(value)) {
		char *str, *temp, *base, *extent, *sep;
		STRLEN len;

		temp = SvPV(value, len);
		base = str = malloc(len + 1);
		strncpy(str, temp, len);
		str[len] = '\0';

		if(*str == INVCHAR) {
			info->invert = TRUE;
			str++;
		}

		sep = strchr(str, ':');
		val = strtoul(str, &extent, 10);
		if(extent < (sep ? sep : str + strlen(str)) || val < 0 ||
						val > USHRT_MAX) {
			SET_ERRSTR("%s: Unable to parse '%s'", field, str);
			free(base);
			return(FALSE);
		}
		info->min = val;

		if(sep) {
			sep++;
			val = strtoul(sep, &extent, 10);
			if(extent < sep + strlen(sep) || val < 0 || val > USHRT_MAX) {
				SET_ERRSTR("%s: Unable to parse '%s'", field, str);
				free(base);
				return(FALSE);
			}
		}
		free(base);
		info->max = val;
	}
	else {
		SET_ERRSTR("%s: Must be passed as integer or string", field);
		return(FALSE);
	}

	return(TRUE);
}

static void get_fields(HV *ent_hash, void *myinfo, struct ipt_entry *entry) {
	MODULE_DATATYPE *info = (void *)((MODULE_ENTRYTYPE *)myinfo)->data;
	char *string, *temp;

	asprintf(&string, "%u", info->min);
	if(info->min != info->max) {
		asprintf(&temp, "%s:%u", string, info->max);
		free(string);
		string = temp;
	}
	if(info->invert) {
		asprintf(&temp, "%c%s", INVCHAR, string);
		free(string);
		string = temp;
	}
	hv_store(ent_hash, "length", 6, newSVpv(string, 0), 0);
	free(string);
}

static int final_check(void *myinfo, int flags) {
	if(!flags) {
		SET_ERRSTR("length match requires 'length'");
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
