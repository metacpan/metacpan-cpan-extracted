#define BUILD_TARGET
#define MODULE_DATATYPE struct ipt_reject_info
#define MODULE_NAME "REJECT"

#define __USE_GNU
#include "../module_iface.h"
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <syslog.h>
#include <netinet/in.h>
#include <linux/netfilter_ipv4/ipt_REJECT.h>

#ifndef IPT_ICMP_ADMIN_PROHIBITED
#define IPT_ICMP_ADMIN_PROHIBITED	IPT_TCP_RESET + 1
#endif

typedef struct {
	char *name, *alias;
	enum ipt_reject_with with;
} rejectList;

rejectList reject_types[] = {
	{ "icmp-net-unreachable",	"net-unreach",	IPT_ICMP_NET_UNREACHABLE },
	{ "icmp-host-unreachable",	"host-unreach",	IPT_ICMP_HOST_UNREACHABLE },
	{ "icmp-port-unreachable",	"port-unreach",	IPT_ICMP_PORT_UNREACHABLE },
	{ "icmp-proto-unreachable",	"proto-unreach", IPT_ICMP_PROT_UNREACHABLE },
	{ "icmp-net-prohibited",	"net-prohib",	IPT_ICMP_NET_PROHIBITED },
	{ "icmp-host-prohibited",	"host-prohib",	IPT_ICMP_HOST_PROHIBITED },
	{ "tcp-reset",				NULL,			IPT_TCP_RESET },
	{ "icmp-admin-prohibited",	"admin-prohib",	IPT_ICMP_ADMIN_PROHIBITED },
};

static void setup(void *myinfo, unsigned int *nfcache) {
	MODULE_DATATYPE *info = (void *)((MODULE_ENTRYTYPE *)myinfo)->data;

	info->with = IPT_ICMP_PORT_UNREACHABLE;
	*nfcache |= NFC_UNKNOWN;
}

static int parse_field(char *field, SV *value, void *myinfo,
		unsigned int *nfcache, struct ipt_entry *entry, int *flags) {
	MODULE_DATATYPE *info = (void *)(*(MODULE_ENTRYTYPE **)myinfo)->data;
	char *str, *temp;
	unsigned int i;
	rejectList *selector = NULL;
	STRLEN len;

	if(strcmp(field, "reject-with"))
		return(FALSE);
	
	if(!SvPOK(value)) {
		SET_ERRSTR("%s: Requires a string arg", field);
		return(FALSE);
	}

	temp = SvPV(value, len);
	str = malloc(len + 1);
	strncpy(str, temp, len);
	str[len] = '\0';

	for(i = 0; i < sizeof(reject_types) / sizeof(rejectList); i++) {
		if(!strcmp(reject_types[i].name, str) || (reject_types[i].alias &&
								!strcmp(reject_types[i].alias, str))) {
			selector = &reject_types[i];
			break;
		}
	}
	free(str);

	if(!selector) {
		SET_ERRSTR("%s: Unknown reject type", field);
		return(FALSE);
	}
	
	if(selector->with == IPT_TCP_RESET && (entry->ip.proto != IPPROTO_TCP ||
							(entry->ip.invflags & IPT_INV_PROTO))) {
		SET_ERRSTR("%s: TCP RST can only be used with TCP protocol", field);
		return(FALSE);
	}
	
	info->with = selector->with;

	return(TRUE);
}

static void get_fields(HV *ent_hash, void *myinfo, struct ipt_entry *entry) {
	MODULE_DATATYPE *info = (void *)((MODULE_ENTRYTYPE *)myinfo)->data;
	rejectList *selector = NULL;
	unsigned int i;
	
	for(i = 0; i < sizeof(reject_types) / sizeof(rejectList); i++) {
		if(info->with == reject_types[i].with) {
			selector = &reject_types[i];
			break;
		}
	}

	if(!selector) {
		fprintf(stderr, "unknown reject type '%u'\n", info->with);
		return;
	}
	
	hv_store(ent_hash, "reject-with", 11, newSVpv(selector->name, 0), 0);
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
