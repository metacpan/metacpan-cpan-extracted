#define INET6
#define BUILD_MATCH
#define MODULE_DATATYPE struct ip6t_icmp
#define MODULE_NAME "icmp6"

#define __USE_GNU
#include "../module_iface.h"
#include <string.h>
#include <stdio.h>
#include <limits.h>
#include <linux/netfilter_ipv6/ip6_tables.h>

typedef struct {
	char *name;
	char *alias;
	u_int8_t type;
	u_int8_t code_min, code_max;
} icmpv6TypeInfo;

icmpv6TypeInfo icmpv6_types[] = {
	{ "destination-unreachable", NULL, 1, 0, 0xFF },
		{ "no-route", NULL, 1, 0, 0 },
		{ "communication-prohibited", NULL, 1, 1, 1 },
		{ "address-unreachable", NULL, 1, 3, 3 },
		{ "port-unreachable", NULL, 1, 4, 4 },
	{ "packet-too-big", NULL, 2, 0, 0xFF },
	{ "time-exceeded", "ttl-exceeded", 3, 0, 0xFF },
		{ "ttl-zero-during-transit", NULL, 3, 0, 0 },
		{ "ttl-zero-during-reassembly", NULL, 3, 1, 1 },
	{ "parameter-problem", NULL, 4, 0, 0xFF },
		{ "bad-header", NULL, 4, 0, 0 },
		{ "unknown-header-type", NULL, 4, 1, 1 },
		{ "unknown-option", NULL, 4, 2, 2 },
	{ "echo-request", "ping", 128, 0, 0xFF },
	{ "echo-reply", "pong", 129, 0, 0xFF },
	{ "router-solicitation", NULL, 133, 0, 0xFF },
	{ "router-advertisement", NULL, 134, 0, 0xFF },
	{ "neighbour-solicitation", "neighbor-solicitation", 135, 0, 0xFF },
	{ "neighbour-advertisement", "neighbor-advertisement", 136, 0, 0xFF },
	{ "redirect", NULL, 137, 0, 0xFF },
};

static void setup(void *myinfo, unsigned int *nfcache) {
	MODULE_DATATYPE *info = (void *)((MODULE_ENTRYTYPE *)myinfo)->data;
	
	info->code[1] = 0xFF;
}

static int parse_field(char *field, SV *value, void *myinfo,
		unsigned int *nfcache, struct ip6t_entry *entry, int *flags) {
	MODULE_DATATYPE *info = (void *)(*(MODULE_ENTRYTYPE **)myinfo)->data;
	char *typename, *slash, *sep, *extent;
	int type, code;
	unsigned int i;
	icmpv6TypeInfo *selector = NULL;

	if(strcmp(field, "icmpv6-type"))
		return(FALSE);
	
	if(SvIOK(value)) {
		type = SvIV(value);
		if(type < 0 || type > UCHAR_MAX) {
			SET_ERRSTR("%s: type value out of range", field);
			return(FALSE);
		}
		info->type = type;
	}
	else if(SvPOK(value)) {
		char *temp, *base;
		STRLEN len;

		temp = SvPV(value, len);
		base = typename = malloc(len + 1);
		strncpy(typename, temp, len);
		typename[len] = '\0';
		
		if(*typename == INVCHAR) {
			info->invflags |= IP6T_ICMP_INV;
			typename++;
		}

		for(i = 0; i < sizeof(icmpv6_types) / sizeof(icmpv6TypeInfo); i++) {
			if(!strncasecmp(icmpv6_types[i].name, typename, strlen(typename))
							|| (icmpv6_types[i].alias &&
									!strncasecmp(icmpv6_types[i].alias,
											typename, strlen(typename)))) {
				if(selector) {
					SET_ERRSTR("%s: Type name '%s' was ambiguous", field,
									typename);
					free(base);
					return(FALSE);
				}
				selector = &icmpv6_types[i];
				info->type = selector->type;
				info->code[0] = selector->code_min;
				info->code[1] = selector->code_max;
			}
		}
		if(selector)
			free(base);
		else {
			if((slash = strchr(typename, '/'))) {
				*(slash++) = '\0';
				if((sep = strchr(slash, '-'))) {
					*(sep++) = '\0';
					code = strtoul(sep, &extent, 10);
					if(extent - sep < strlen(sep)) {
						SET_ERRSTR("%s: couldn't parse field", field);
						free(base);
						return(FALSE);
					}
					if(code < 0 || code > UCHAR_MAX) {
						SET_ERRSTR("%s: code out of range", field);
						free(base);
						return(FALSE);
					}
					info->code[1] = code;
				}
				code = strtoul(slash, &extent, 10);
				if(extent - slash < strlen(slash)) {
					SET_ERRSTR("%s: couldn't parse field", field);
					free(base);
					return(FALSE);
				}
				if(code < 0 || code > UCHAR_MAX) {
					SET_ERRSTR("%s: code out of range", field);
					free(base);
					return(FALSE);
				}
				info->code[0] = code;
				if(!sep)
					info->code[1] = info->code[0];
			}
			type = strtoul(typename, &extent, 10);
			if(extent - typename < strlen(typename)) {
				SET_ERRSTR("%s: couldn't parse field", field);
				free(base);
				return(FALSE);
			}
			free(base);
			if(type < 0 || type > UCHAR_MAX) {
				SET_ERRSTR("%s: type value out of range", field);
				return(FALSE);
			}
			info->type = type;
		}
	}
	else
		return(FALSE);

	*nfcache |= NFC_IP6_SRC_PT;
	if (info->code[0] != 0 || info->code[1] != 0xFF)
		*nfcache |= NFC_IP6_DST_PT;

	return(TRUE);
}

static void get_fields(HV *ent_hash, void *myinfo, struct ip6t_entry *entry) {
	MODULE_DATATYPE *info = (void *)((MODULE_ENTRYTYPE *)myinfo)->data;
	icmpv6TypeInfo *selector = NULL;
	char *typename = NULL, *temp;
	unsigned int i;

	for(i = 0; i < sizeof(icmpv6_types) / sizeof(icmpv6TypeInfo); i++) {
		if(icmpv6_types[i].type == info->type &&
				icmpv6_types[i].code_min == info->code[0] &&
				icmpv6_types[i].code_max == info->code[1]) {
			selector = &icmpv6_types[i];
			typename = strdup(icmpv6_types[i].name);
			break;
		}
	}
	if(!selector) {
		asprintf(&typename, "%u", info->type);
		if(info->code[0] != 0 && info->code[1] != UCHAR_MAX) {
			asprintf(&temp, "%s/%u", typename, info->code[0]);
			free(typename);
			typename = temp;
			if(info->code[0] != info->code[1]) {
				asprintf(&temp, "%s-%u", typename, info->code[1]);
				free(typename);
				typename = temp;
			}
		}
	}
	if(info->invflags & IP6T_ICMP_INV) {
		asprintf(&temp, "%c%s", INVCHAR, typename);
		free(typename);
		typename = temp;
	}
	hv_store(ent_hash, "icmpv6-type", 11, newSVpv(typename, 0), 0);
	free(typename);
	
}

static ModuleDef _module = {
	.type			= MODULE_TYPE,
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
