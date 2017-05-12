#define BUILD_MATCH
#define MODULE_DATATYPE struct ipt_mark_info
#define MODULE_NAME "mark"

#define __USE_GNU
#include "../module_iface.h"
#include <string.h>
#include <stdio.h>
#include <linux/netfilter_ipv4/ipt_mark.h>

static void setup(void *myinfo, unsigned int *nfcache) {
	*nfcache |= NFC_UNKNOWN;
}

static int parse_field(char *field, SV *value, void *myinfo,
		unsigned int *nfcache, struct ipt_entry *entry, int *flags) {
	MODULE_DATATYPE *info = (void *)(*(MODULE_ENTRYTYPE **)myinfo)->data;
	int num;

	if(strcmp(field, "mark"))
		return(FALSE);

	*flags = 1;

	if(SvIOK(value)) {
		info->mark = SvIV(value);
		info->mask = 0xFFFFFFFF;
	}
	else if(SvPOK(value)) {
		char *markstr, *sep, *extent, *temp, *base;
		STRLEN len;

		temp = SvPV(value, len);
		base = markstr = malloc(len + 1);
		strncpy(markstr, temp, len);
		markstr[len] = '\0';

		if(*markstr == INVCHAR) {
			info->invert = TRUE;
			markstr++;
		}
		
		sep = strchr(markstr, '/');
		num = strtoul(markstr, &extent, 0);
		
		if(extent < (sep ? sep : (markstr + strlen(markstr)))) {
			SET_ERRSTR("%s: Unable to parse", field);
			free(base);
			return(FALSE);
		}
		info->mark = num;

		if(sep) {
			sep++;
			num = strtoul(sep, &extent, 0);
			if(extent < (sep + strlen(sep))) {
				SET_ERRSTR("%s: Unable to parse", field);
				free(base);
				return(FALSE);
			}
			info->mask = num;
		}
		else
			info->mask = 0xFFFFFFFF;
		free(base);
	}
	else {
		SET_ERRSTR("%s: Must have a string or integer arg", field);
		return(FALSE);
	}

	return(TRUE);
}

static void get_fields(HV *ent_hash, void *myinfo, struct ipt_entry *entry) {
	MODULE_DATATYPE *info = (void *)((MODULE_ENTRYTYPE *)myinfo)->data;
	char *markstr, *temp;

	asprintf(&markstr, "0x%lx", info->mark);
	if(info->mask != 0xFFFFFFFF) {
		asprintf(&temp, "%s/0x%lx", markstr, info->mask);
		free(markstr);
		markstr = temp;
	}
	
	if(info->invert) {
		asprintf(&temp, "%c%s", INVCHAR, markstr);
		free(markstr);
		markstr = temp;
	}
	
	hv_store(ent_hash, "mark", 4, newSVpv(markstr, 0), 0);
	free(markstr);
}

int final_check(void *myinfo, int flags) {
	if(!flags) {
		SET_ERRSTR("mark match requires mark field");
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
