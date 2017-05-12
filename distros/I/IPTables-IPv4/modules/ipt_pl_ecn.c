#define BUILD_MATCH
#define MODULE_DATATYPE struct ipt_ecn_info
#define MODULE_NAME "ecn"

#define __USE_GNU
#include "../module_iface.h"
#include <string.h>
#include <stdio.h>
#include <linux/netfilter_ipv4/ip_tables.h>
#include <linux/netfilter_ipv4/ipt_ecn.h>

static void setup(void *myinfo, unsigned int *nfcache) {
	*nfcache |= NFC_IP_TOS;
}

static int parse_field(char *field, SV *value, void *myinfo,
		unsigned int *nfcache, struct ipt_entry *entry, int *flags) {
	MODULE_DATATYPE *info = (void *)(*(MODULE_ENTRYTYPE **)myinfo)->data;

	if(!strcmp(field, "ecn-tcp-cwr")) {
		if(!SvIOK(value)) {
			SET_ERRSTR("%s: Must have integer arg", field);
			return(FALSE);
		}
		if(!SvIV(value))
			info->invert |= IPT_ECN_OP_MATCH_CWR;
		info->operation |= IPT_ECN_OP_MATCH_CWR;
		*flags |= IPT_ECN_OP_MATCH_CWR;
	}
	else if(!strcmp(field, "ecn-tcp-ece")) {
		if(!SvIOK(value)) {
			SET_ERRSTR("%s: Must have integer arg", field);
			return(FALSE);
		}
		if(!SvIV(value))
			info->invert |= IPT_ECN_OP_MATCH_ECE;
		info->operation |= IPT_ECN_OP_MATCH_ECE;
		*flags |= IPT_ECN_OP_MATCH_ECE;
	}
	else if(!strcmp(field, "ecn-ip-ect")) {
		if(SvIOK(value))
			info->ip_ect = SvIV(value);
		else if(SvPOK(value)) {
			char *temp, *base, *str, *extent;
			int val;
			STRLEN len;

			temp = SvPV(value, len);
			base = str = malloc(len + 1);
			strncpy(str, temp, len);
			str[len] = '\0';

			if(*str == INVCHAR) {
				info->invert |= IPT_ECN_OP_MATCH_IP;
				str++;
			}

			val = strtoul(str, &extent, 10);
			if(extent < str + strlen(str)) {
				SET_ERRSTR("%s: Couldn't parse value", field);
				free(base);
				return(FALSE);
			}
			free(base);

			if(val < 0 || val > 3) {
				SET_ERRSTR("%s: Value out of range", field);
				return(FALSE);
			}
			info->ip_ect = val;
		}
		else {
			SET_ERRSTR("%s: Must have integer or string arg", field);
			return(FALSE);
		}
		info->operation |= IPT_ECN_OP_MATCH_IP;
		*flags |= IPT_ECN_OP_MATCH_IP;
	}
	else
		return(FALSE);

	return(TRUE);
}

static void get_fields(HV *ent_hash, void *myinfo, struct ipt_entry *entry) {
	MODULE_DATATYPE *info = (void *)((MODULE_ENTRYTYPE *)myinfo)->data;

	if(info->operation & IPT_ECN_OP_MATCH_CWR)
		hv_store(ent_hash, "ecn-tcp-cwr", 11,
						newSViv(info->invert & IPT_ECN_OP_MATCH_CWR ? 0 : 1),
						0);

	if(info->operation & IPT_ECN_OP_MATCH_ECE)
		hv_store(ent_hash, "ecn-tcp-ece", 11,
						newSViv(info->invert & IPT_ECN_OP_MATCH_ECE ? 0 : 1),
						0);

	if(info->operation & IPT_ECN_OP_MATCH_IP) {
		SV *sv = NULL;

		if(info->invert & IPT_ECN_OP_MATCH_IP)
			sv = newSVpvf("%c%d", INVCHAR, info->ip_ect);
		else
			sv = newSViv(info->ip_ect);
		hv_store(ent_hash, "ecn-ip-ect", 10, sv, 0);
	}
}

int final_check(void *myinfo, int flags) {
	if(!flags) {
		SET_ERRSTR("ecn match requires one or more of 'ecn-tcp-cwr', "
						"'ecn-tcp-ece', 'ecn-ip-ect'");
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
