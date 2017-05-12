#define INET6
#define BUILD_TARGET
#define MODULE_DATATYPE struct ip6t_reject_info
#define MODULE_NAME "REJECT"

#define __USE_GNU
#include "../module_iface.h"
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <syslog.h>
#include <netinet/in.h>
#include <linux/netfilter_ipv6/ip6_tables.h>
#include <linux/netfilter_ipv6/ip6t_REJECT.h>

typedef struct {
	char *name, *alias;
	enum ip6t_reject_with with;
} rejectList;

rejectList reject_types[] = {
	{ "icmp6-no-route"			"no-route",		IP6T_ICMP6_NO_ROUTE },
	{ "icmp6-admin-prohibited",	"adm-prohibited", IP6T_ICMP6_ADM_PROHIBITED },
	{ "icmp6-addr-unreachable",	"addr-unreach",	IP6T_ICMP6_ADDR_UNREACH },
	{ "icmp6-port-unreachable",	"port-unreach",	IP6T_ICMP6_PORT_UNREACH },
	{ "tcp-reset",				NULL,			IP6T_TCP_RESET },
};

static void setup(void *myinfo, unsigned int *nfcache) {
	MODULE_DATATYPE *info = (void *)((MODULE_ENTRYTYPE *)myinfo)->data;

	info->with = IP6T_ICMP6_PORT_UNREACH;
	*nfcache |= NFC_UNKNOWN;
}

static int parse_field(char *field, SV *value, void *myinfo,
		unsigned int *nfcache, struct ip6t_entry *entry, int *flags) {
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
	
	if(selector->with == IP6T_TCP_RESET && (entry->ipv6.proto != IPPROTO_TCP ||
							(entry->ipv6.invflags & IP6T_INV_PROTO))) {
		SET_ERRSTR("%s: TCP RST can only be used with TCP protocol", field);
		return(FALSE);
	}
	
	info->with = selector->with;

	return(TRUE);
}

static void get_fields(HV *ent_hash, void *myinfo, struct ip6t_entry *entry) {
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
	.type 			= MODULE_TYPE,
	.name			= MODULE_NAME,
	.size			= IP6T_ALIGN(sizeof(MODULE_DATATYPE)),
	.size_uspace	= IP6T_ALIGN(sizeof(MODULE_DATATYPE)),
	.setup			= setup,
	.parse_field	= parse_field,
	.get_fields		= get_fields,
};

ModuleDef *init(void) {
	return(&_module);
}
/* vim: ts=4
 */
