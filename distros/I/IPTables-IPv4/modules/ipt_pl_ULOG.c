/* most of the code was copied form the ipt_pl_LOG.c code and adapted to be
   used with the ULOG package by Harald Welte (see 
   http://www.gnumonks.org/ftp/pub/netfilter)

   Thomas Geffert <thg@users.sourceforge.net> */

#define BUILD_TARGET
#define MODULE_DATATYPE struct ipt_ulog_info
#define MODULE_NAME "ULOG"

#define __USE_GNU
#include "../module_iface.h"
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <syslog.h>
#include <linux/netfilter_ipv4/ipt_ULOG.h>

static void setup(void *myinfo, unsigned int *nfcache) {
	MODULE_DATATYPE *info = (void *)((MODULE_ENTRYTYPE *)myinfo)->data;

	info->nl_group = 1;
	info->copy_range = 0;
	info->qthreshold = 1;

	*nfcache |= NFC_UNKNOWN;
}

static int get_int_value (SV *value, int *val, char *field, int min, int max) {
	char *temp, *str, *extent;
	STRLEN len;

	if(SvIOK(value)) {
		*val = SvIV(value);
		if(*val < min || *val > max) {
			SET_ERRSTR("%s: Integer value %d out of range %d..%d", field, *val,
							min, max);
			return(FALSE);
		}
		return(TRUE);
	}
	else if(SvPOK(value)) {
		temp = SvPV(value, len);
		str = malloc(len + 1);
		strncpy(str, temp, len);
		str[len] = '\0';

		*val = strtoul(str, &extent, 10);
		if(str + strlen(str) > extent) {
			SET_ERRSTR("%s: Unable to parse", field);
			goto gi_failed;
		}
		if(*val < min || *val > max) {
			SET_ERRSTR("%s: Integer value %d out of range %d..%d", field, *val,
							min, max);
			goto gi_failed;
		}
		return(TRUE);
gi_failed:
		free(str);
		return(FALSE);
	}
	else {
		SET_ERRSTR("%s: Must have an integer arg", field);
		return(FALSE);
	}
}

static int parse_field(char *field, SV *value, void *myinfo,
		       unsigned int *nfcache, struct ipt_entry *entry, int *flags) {
	MODULE_DATATYPE *info = (void *)(*(MODULE_ENTRYTYPE **)myinfo)->data;
	int val;
	
	if(!strcmp(field, "ulog-nlgroup")) {
		if(get_int_value(value, &val, field, 1, 32)) {
			info->nl_group = 1 << (val-1);
			return(TRUE);
		}
	}
	else if(!strcmp(field, "ulog-copy-range")) {
		if(get_int_value(value, &val, field, 0, 1500)) {
			info->copy_range = val;
			return (TRUE);
		} 
	}
	else if(!strcmp(field, "ulog-qthreshold")) {
		if(get_int_value(value, &val, field, 1, ULOG_MAX_QLEN)) {
			info->qthreshold = val;
			return (TRUE);
		} 
	}
	else if(!strcmp(field, "ulog-prefix")) {
		char *str, *temp;
		STRLEN len;

		if(!SvPOK(value)) {
			SET_ERRSTR("%s: Must be a string value", field);
			return(FALSE);
		}
		temp = SvPV(value, len);
		str = malloc(len + 1);
		strncpy(str, temp, len);
		str[len] = '\0';
		strncpy(info->prefix, str, ULOG_PREFIX_LEN);
		free(str);
		return(TRUE);
	}
	
	return(FALSE);
}

static void get_fields(HV *ent_hash, void *myinfo, struct ipt_entry *entry) {
	MODULE_DATATYPE *info = (void *)((MODULE_ENTRYTYPE *)myinfo)->data;
	int i;
	
	if(strcmp(info->prefix, ""))
		hv_store(ent_hash, "ulog-prefix", 11, newSVpv(info->prefix, 0), 0);
	
	hv_store(ent_hash, "ulog-copy-range", 15, newSViv(info->copy_range), 0);
	hv_store(ent_hash, "ulog-qthreshold", 15, newSViv(info->qthreshold), 0);
	
	i=0;
	while (info->nl_group) {
		info->nl_group >>= 1;
		i++;
	}
	if (i==0)
	        fprintf(stderr, "ulog->nlgroup has invalid value 0\n");
	else
	        hv_store(ent_hash, "ulog-nlgroup", 12, newSViv(i), 0);
}

ModuleDef _module = {
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
