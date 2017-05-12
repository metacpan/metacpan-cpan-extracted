#define BUILD_MATCH
#define MODULE_DATATYPE struct ipt_time_info
#define MODULE_NAME "time"

#define __USE_GNU
#include "../module_iface.h"
#include <string.h>
#include <stdio.h>
#include <linux/netfilter_ipv4/ipt_time.h>
#include <time.h>
#include <limits.h>

#define TIME_TIMESTART	(1 << 0)
#define TIME_TIMESTOP	(1 << 1)
#define TIME_DAYS		(1 << 2)
#define TIME_ALLOPTS	(TIME_TIMESTART | TIME_TIMESTOP | TIME_DAYS)

typedef struct {
	char *name;
	u_int8_t value;
} DayList;

DayList days[] = {
	{ "Sun",	1 << 6 },
	{ "Mon",	1 << 5 },
	{ "Tue",	1 << 4 },
	{ "Wed",	1 << 3 },
	{ "Thu",	1 << 2 },
	{ "Fri",	1 << 1 },
	{ "Sat",	1 << 0 }
};

static void setup(void *myinfo, unsigned int *nfcache) {
	*nfcache |= NFC_UNKNOWN;
}

static u_int16_t string_to_hrmin(char *string) {
	char *extent = NULL, *sep = NULL;
	unsigned int hr, min;

	hr = strtoul(string, &sep, 10);
	if(!sep || *sep != ':' || hr >= 24)
		return(USHRT_MAX);
	sep++;

	min = strtoul(sep, &extent, 10);
	if(!extent || *extent != '\0' || min >= 60)
		return(USHRT_MAX);
	min += hr * 60;
	return min;
}

static int parse_field(char *field, SV *value, void *myinfo,
		unsigned int *nfcache, struct ipt_entry *entry, int *flags) {
	MODULE_DATATYPE *info = (void *)(*(MODULE_ENTRYTYPE **)myinfo)->data;
	char *str = NULL, *temp = NULL;
	STRLEN len;

	if(!strcmp(field, "timestart")) {
		if(!SvPOK(value)) {
			SET_ERRSTR("%s: Must have a string arg", field);
			return(FALSE);
		}
		temp = SvPV(value, len);
		str = malloc(len + 1);
		strncpy(str, temp, len);
		str[len] = '\0';
		info->time_start = string_to_hrmin(str);
		free(str);
		if(info->time_start == USHRT_MAX) { 
			SET_ERRSTR("%s: Couldn't parse arg", field);
			return(FALSE);
		}
		*flags |= TIME_TIMESTART;
	}
	else if(!strcmp(field, "timestop")) {
		if(!SvPOK(value)) {
			SET_ERRSTR("%s: Must have a string arg", field);
			return(FALSE);
		}
		temp = SvPV(value, len);
		str = malloc(len + 1);
		strncpy(str, temp, len);
		str[len] = '\0';
		info->time_stop = string_to_hrmin(str);
		free(str);
		if(info->time_stop == USHRT_MAX) { 
			SET_ERRSTR("%s: Couldn't parse arg", field);
			return(FALSE);
		}
		*flags |= TIME_TIMESTOP;
	}
	else if(!strcmp(field, "days")) {
		SV *av = NULL;
		int i;
		unsigned int j;
		if(!SvROK(value)) {
			SET_ERRSTR("%s: Must have a reference arg", field);
			return(FALSE);
		}
		
		av = SvRV(value);
		if(SvTYPE(av) != SVt_PVAV) {
			SET_ERRSTR("%s: Must be an array ref", field);
			return(FALSE);
		}

		for(i = 0; i <= av_len((AV *)av); i++) {
			SV **svp = av_fetch((AV *)av, i, FALSE);
			DayList *selector = NULL;
			if(!svp || !SvPOK(*svp)) {
				SET_ERRSTR("%s: Array must contain strings", field);
				return(FALSE);
			}
			temp = SvPV(*svp, len);
			str = malloc(len + 1);
			strncpy(str, temp, len);
			str[len] = '\0';
			selector = NULL;
			for(j = 0; j < sizeof(days) / sizeof(DayList) ; j++) {
				if(!strcmp(str, days[j].name)) {
					selector = &days[j];
					break;
				}
			}
			if(selector)
				info->days_match |= selector->value;
			else {
				SET_ERRSTR("%s: Unknown day %s", field, str);
				free(str);
				return(FALSE);
			}
			free(str);
		}
		*flags |= TIME_DAYS;
	}
	else
		return(FALSE);

	return(TRUE);
}

static SV *hrmin_to_sv(u_int16_t mins) {
	char *string = NULL;
	int hrs = mins / 60;
	SV *sv;

	mins %= 60;
	hrs %= 24;
	asprintf(&string, "%d:%.2d", hrs, mins);

	sv = newSVpv(string, 0);
	free(string);

	return sv;
}

static void get_fields(HV *ent_hash, void *myinfo, struct ipt_entry *entry) {
	MODULE_DATATYPE *info = (void *)((MODULE_ENTRYTYPE *)myinfo)->data;
	AV *av = newAV();
	unsigned int i;

	hv_store(ent_hash, "timestart", 9, hrmin_to_sv(info->time_start), 0);
	hv_store(ent_hash, "timestop", 8, hrmin_to_sv(info->time_stop), 0);
	for(i = 0; i < sizeof(days) / sizeof(DayList); i++) {
		if(info->days_match & days[i].value)
			av_push(av, newSVpv(days[i].name, 0));
	}
	hv_store(ent_hash, "days", 4, newRV_noinc((SV *)av), 0);
}

static int final_check(void *myinfo, int flags) {
/*	MODULE_DATATYPE *info =
	    (void *)((struct ipt_entry_match *)myinfo)->data; */

	if(flags != TIME_ALLOPTS) {
		SET_ERRSTR("time match requires timestart, timestop and days fields");
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
