#define BUILD_MATCH
#define MODULE_DATATYPE struct ipt_rateinfo
#define MODULE_NAME "limit"

#define __USE_GNU
#include "../module_iface.h"
#include <string.h>
#include <stdio.h>
#include <linux/netfilter_ipv4/ip_tables.h>
#include <linux/netfilter_ipv4/ipt_limit.h>

#define DEFAULT_BURST 5
#define DEFAULT_LIMIT IPT_LIMIT_SCALE * 3600 / 3

static struct RateList
{
	char *name, *alias;
	u_int32_t mult;
} rate_list[] = {
	{ "day",	"day",		IPT_LIMIT_SCALE*24*60*60 },
	{ "hour",	"hr",		IPT_LIMIT_SCALE*60*60 },
	{ "min",	"minute",	IPT_LIMIT_SCALE*60 },
	{ "sec",	"second",	IPT_LIMIT_SCALE }
};

static int parse_rate_sv(SV *sv, struct ipt_rateinfo *rate) {
	char *ratestr, *sep, *extent;
	int factor = 1, value;

	if(SvIOK(sv)) {
		value = IPT_LIMIT_SCALE / SvIV(sv);
	}
	else if(SvPOK(sv)) {
		char *temp;
		STRLEN len;

		temp = SvPV(sv, len);
		ratestr = malloc(len + 1);
		strncpy(ratestr, temp, len);
		ratestr[len] = '\0';

		sep = strchr(ratestr, '/');
		value = strtoul(ratestr, &extent, 10);
		if(extent < (sep ? sep : (ratestr + strlen(ratestr)))) {
			free(ratestr);
			return(FALSE);
		}

		if(sep) {
			sep++;
			if(!strcasecmp(sep, "second") || !strcasecmp(sep, "sec"))
				factor = 1;
			else if(!strcasecmp(sep, "minute") || !strcasecmp(sep, "min"))
				factor = 60;
			else if(!strcasecmp(sep, "hour") || !strcasecmp(sep, "hr"))
				factor = 60 * 60;
			else if(!strcasecmp(sep, "day"))
				factor = 60 * 60 * 24;
			else {
				free(ratestr);
				return(FALSE);
			}
		}
		free(ratestr);
	}
	else
		return(FALSE);

	if((value <= 0) || (value / factor > IPT_LIMIT_SCALE))
		return(FALSE);

	rate->avg = IPT_LIMIT_SCALE * factor / value;

	return(TRUE);
}

static void setup(void *myinfo, unsigned int *nfcache) {
	MODULE_DATATYPE *info = (void *)((MODULE_ENTRYTYPE *)myinfo)->data;

	info->avg = DEFAULT_LIMIT;
	info->burst = DEFAULT_BURST;

	*nfcache |= NFC_UNKNOWN;
}

static int parse_field(char *field, SV *value, void *myinfo,
		unsigned int *nfcache, struct ipt_entry *entry, int *flags) {
	MODULE_DATATYPE *info = (void *)(*(MODULE_ENTRYTYPE **)myinfo)->data;
	
	if(!strcmp(field, "limit")) {
		if(!parse_rate_sv(value, info)) {
			SET_ERRSTR("%s: Unable to parse arg, maybe wrong type?", field);
			return(FALSE);
		}
	}
	else if(!strcmp(field, "limit-burst")) {
		if(!SvIOK(value)) {
			SET_ERRSTR("%s: Arg must be integer", field);
			return(FALSE);
		}
		if (SvIV(value) < 0 || SvIV(value) > 10000) {
			SET_ERRSTR("%s: Value out of range", field);
			return(FALSE);
		}
		info->burst = SvIV(value);
	}
	else
		return(FALSE);
	
	return(TRUE);
}

static void get_fields(HV *ent_hash, void *myinfo, struct ipt_entry *entry) {
	MODULE_DATATYPE *info = (void *)((MODULE_ENTRYTYPE *)myinfo)->data;
	unsigned int i;
	
	for(i = 1; i < (sizeof(rate_list) / sizeof(struct RateList)); i++) {
		if(info->avg > rate_list[i].mult || rate_list[i].mult % info->avg != 0)
			break;
	}
	
	hv_store(ent_hash, "limit", 5,
			newSVpvf("%u/%s", rate_list[i-1].mult / info->avg,
				rate_list[i-1].name), 0);
	hv_store(ent_hash, "limit-burst", 11, newSViv(info->burst), 0);
}

static ModuleDef _module = {
	.type			= MODULE_TYPE,
	.name			= MODULE_NAME,
	.size			= IPT_ALIGN(sizeof(MODULE_DATATYPE)),
	.size_uspace	= IPT_ALIGN(sizeof(MODULE_DATATYPE)),
	.setup			= setup,
	.parse_field	= parse_field,
	.get_fields		= get_fields,
};

ModuleDef *init(void) {
	return(&_module);
}
/* vim: ts=4
 */
