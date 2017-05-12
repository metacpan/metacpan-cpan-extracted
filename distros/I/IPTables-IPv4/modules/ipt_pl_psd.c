#define BUILD_MATCH
#define MODULE_DATATYPE struct ipt_psd_info
#define MODULE_NAME "psd"

#define __USE_GNU
#include "../module_iface.h"
#include <string.h>
#include <stdio.h>
#include <linux/netfilter_ipv4/ip_tables.h>
#include <linux/netfilter_ipv4/ipt_psd.h>

static void setup(void *myinfo, unsigned int *nfcache) {
	MODULE_DATATYPE *info =
	    (void *)((struct ipt_entry_match *)myinfo)->data;

	info->weight_threshold = SCAN_WEIGHT_THRESHOLD;
	info->delay_threshold = SCAN_DELAY_THRESHOLD;
	info->lo_ports_weight = PORT_WEIGHT_PRIV;
	info->hi_ports_weight = PORT_WEIGHT_HIGH;
	*nfcache |= NFC_UNKNOWN;
}

#define PSD_WT_THRESH 1
#define PSD_DEL_THRESH 2
#define PSD_LP_WEIGHT 3
#define PSD_HP_WEIGHT 4

static int parse_field(char *field, SV *value, void *myinfo,
		unsigned int *nfcache, struct ipt_entry *entry, int *flags) {
	MODULE_DATATYPE *info =
	    (void *)(*(MODULE_ENTRYTYPE **)myinfo)->data;
	int mode = 0, psdval;

	if(!strcmp(field, "psd-weight-threshold"))
		mode = PSD_WT_THRESH;
	else if(!strcmp(field, "psd-delay-threshold"))
		mode = PSD_DEL_THRESH;
	else if(!strcmp(field, "psd-lo-ports-weight"))
		mode = PSD_LP_WEIGHT;
	else if(!strcmp(field, "psd-hi-ports-weight"))
		mode = PSD_HP_WEIGHT;
	else
		return(FALSE);

	if(!SvIOK(value)) {
		SET_ERRSTR("%s: Must have an integer arg", field);
		return(FALSE);
	}
	
	psdval = SvIV(value);

	if(psdval < 0 || psdval > 10000) {
		SET_ERRSTR("%s: Value out of range", field);
		return(FALSE);
	}

	switch(mode) {
	  case PSD_WT_THRESH:
		info->weight_threshold = psdval;
		break;
	  case PSD_DEL_THRESH:
		info->delay_threshold = psdval;
		break;
	  case PSD_LP_WEIGHT:
		info->lo_ports_weight = psdval;
		break;
	  case PSD_HP_WEIGHT:
		info->hi_ports_weight = psdval;
		break;
	  default:
		SET_ERRSTR("%s: BUG: internal inconsistency", field);
		return(FALSE);
	}

	return(TRUE);
}

static void get_fields(HV *ent_hash, void *myinfo, struct ipt_entry *entry) {
	MODULE_DATATYPE *info = (void *)((MODULE_ENTRYTYPE *)myinfo)->data;

	hv_store(ent_hash, "psd-weight-threshold", 20,
					newSViv(info->weight_threshold), 0);
	hv_store(ent_hash, "psd-delay-threshold", 19,
					newSViv(info->delay_threshold), 0);
	hv_store(ent_hash, "psd-lo-ports-weight", 19,
					newSViv(info->lo_ports_weight), 0);
	hv_store(ent_hash, "psd-hi-ports-weight", 19,
					newSViv(info->hi_ports_weight), 0);
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
