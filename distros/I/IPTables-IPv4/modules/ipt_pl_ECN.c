#define BUILD_TARGET
#define MODULE_DATATYPE struct ipt_ECN_info
#define MODULE_NAME "ECN"

#define __USE_GNU
#include "../module_iface.h"
#include <string.h>
#include <stdio.h>
#include <linux/netfilter_ipv4/ip_tables.h>
#include <linux/netfilter_ipv4/ipt_ECN.h>

static int parse_field(char *field, SV *value, void *myinfo,
		unsigned int *nfcache, struct ipt_entry *entry, int *flags) {
	MODULE_DATATYPE *info = (void *)(*(MODULE_ENTRYTYPE **)myinfo)->data;
	int val;

	if(!strcmp(field, "ecn-tcp-remove")) {
		if(*flags) {
			SET_ERRSTR("%s: Can't use 'ecn-tcp-remove' with other options",
							field);
			return(FALSE);
		}
		info->operation = IPT_ECN_OP_SET_ECE | IPT_ECN_OP_SET_CWR;
		info->proto.tcp.ece = 0;
		info->proto.tcp.cwr = 0;
		*flags = 0x80;
	}
	else if(!strcmp(field, "ecn-tcp-cwr")) {
		if(*flags & 0x80) {
			SET_ERRSTR("%s: Can't use 'ecn-tcp-remove' with other options",
							field);
			return(FALSE);
		}
		if(!SvIOK(value)) {
			SET_ERRSTR("%s: Must have integer arg", field);
			return(FALSE);
		}
		val = SvIV(value);
		if(val < 0 || val > 1) {
			SET_ERRSTR("%s: Value out of range", field);
			return(FALSE);
		}
		info->proto.tcp.cwr = val;
		info->operation |= IPT_ECN_OP_SET_CWR;
		*flags |= IPT_ECN_OP_SET_CWR;
	}
	else if(!strcmp(field, "ecn-tcp-ece")) {
		if(*flags & 0x80) {
			SET_ERRSTR("%s: Can't use 'ecn-tcp-remove' with other options",
							field);
			return(FALSE);
		}
		if(!SvIOK(value)) {
			SET_ERRSTR("%s: Must have integer arg", field);
			return(FALSE);
		}
		val = SvIV(value);
		if(val < 0 || val > 1) {
			SET_ERRSTR("%s: Value out of range", field);
			return(FALSE);
		}
		info->proto.tcp.ece = val;
		info->operation |= IPT_ECN_OP_SET_ECE;
		*flags |= IPT_ECN_OP_SET_ECE;
	}
	else if(!strcmp(field, "ecn-ip-ect")) {
		if(*flags & 0x80) {
			SET_ERRSTR("%s: Can't use 'ecn-tcp-remove' with other options",
							field);
			return(FALSE);
		}
		if(!SvIOK(value)) {
			SET_ERRSTR("%s: Must have integer arg", field);
			return(FALSE);
		}
		val = SvIV(value);
		if(val < 0 || val > 3) {
			SET_ERRSTR("%s: Value out of range", field);
			return(FALSE);
		}
		info->ip_ect = val;
		info->operation |= IPT_ECN_OP_SET_IP;
		*flags |= IPT_ECN_OP_SET_IP;
	}
	else
		return(FALSE);

	return(TRUE);
}

static void get_fields(HV *ent_hash, void *myinfo, struct ipt_entry *entry) {
	MODULE_DATATYPE *info = (void *)((MODULE_ENTRYTYPE *)myinfo)->data;

	if(info->operation == (IPT_ECN_OP_SET_ECE|IPT_ECN_OP_SET_CWR) &&
					info->proto.tcp.cwr == 0 && info->proto.tcp.ece == 0)
		hv_store(ent_hash, "ecn-tcp-remove", 14, newSViv(1), 0);
	else {
		if(info->operation & IPT_ECN_OP_SET_CWR)
			hv_store(ent_hash, "ecn-tcp-cwr", 11, newSViv(info->proto.tcp.cwr),
							0);

		if(info->operation & IPT_ECN_OP_SET_ECE)
			hv_store(ent_hash, "ecn-tcp-ece", 11, newSViv(info->proto.tcp.ece),
							0);

		if(info->operation & IPT_ECN_OP_SET_IP)
			hv_store(ent_hash, "ecn-ip-ect", 10, newSViv(info->ip_ect), 0);
	}
}

int final_check(void *myinfo, int flags) {
	if(!flags) {
		SET_ERRSTR("ECN target requires one or more of 'ecn-tcp-cwr', "
						"'ecn-tcp-ece', 'ecn-ip-ect', 'ecn-tcp-remove'");
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
