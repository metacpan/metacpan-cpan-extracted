#define BUILD_MATCH
#define MODULE_DATATYPE struct ipt_icmp
#define MODULE_NAME "icmp"

#define __USE_GNU
#include "../module_iface.h"
#include <string.h>
#include <stdio.h>
#include <limits.h>

typedef struct {
	char *name;
	char *alias;
	u_int8_t type;
	u_int8_t code_min, code_max;
} icmpTypeInfo;

icmpTypeInfo icmp_types[] = {
	{ "echo-reply", "pong", 0, 0, 0xFF },
	{ "destination-unreachable", NULL, 3, 0, 0xFF },
		{ "network-unreachable", NULL, 3, 0, 0 },
		{ "host-unreachable", NULL, 3, 1, 1 },
		{ "protocol-unreachable", NULL, 3, 2, 2 },
		{ "port-unreachable", NULL, 3, 3, 3 },
		{ "fragmentation-needed", NULL, 3, 4, 4 },
		{ "source-route-failed", NULL, 3, 5, 5 },
		{ "network-unknown", NULL, 3, 6, 6 },
		{ "host-unknown", NULL, 3, 7, 7 },
		{ "network-prohibited", NULL, 3, 9, 9 },
		{ "host-prohibited", NULL, 3, 10, 10 },
		{ "TOS-network-unreachable", NULL, 3, 11, 11 },
		{ "TOS-host-unreachable", NULL, 3, 12, 12 },
		{ "communication-prohibited", NULL, 3, 13, 13 },
		{ "host-precedence-violation", NULL, 3, 14, 14 },
		{ "precedence-cutoff", NULL, 3, 15, 15 },
	{ "source-quench", NULL, 4, 0, 0xFF },
	{ "redirect", NULL, 5, 0, 0xFF },
		{ "network-redirect", NULL, 5, 0, 0 },
		{ "host-redirect", NULL, 5, 1, 1 },
		{ "TOS-network-redirect", NULL, 5, 2, 2 },
		{ "TOS-host-redirect", NULL, 5, 3, 3 },
	{ "echo-request", "ping", 8, 0, 0xFF },
	{ "router-advertisement", NULL, 9, 0, 0xFF },
	{ "router-solicitation", NULL, 10, 0, 0xFF },
	{ "time-exceeded", "ttl-exceeded", 11, 0, 0xFF },
		{ "ttl-zero-during-transit", NULL, 11, 0, 0 },
		{ "ttl-zero-during-reassembly", NULL, 11, 1, 1 },
	{ "parameter-problem", NULL, 12, 0, 0xFF },
		{ "ip-header-bad", NULL, 12, 0, 0 },
		{ "required-option-missing", NULL, 12, 1, 1 },
	{ "timestamp-request", NULL, 13, 0, 0xFF },
	{ "timestamp-reply", NULL, 14, 0, 0xFF },
	{ "address-mask-request", NULL, 17, 0, 0xFF },
	{ "address-mask-reply", NULL, 18, 0, 0xFF }
};

static void setup(void *myinfo, unsigned int *nfcache) {
	MODULE_DATATYPE *info = (void *)((MODULE_ENTRYTYPE *)myinfo)->data;
	
	info->code[1] = 0xFF;
}

static int parse_field(char *field, SV *value, void *myinfo,
		unsigned int *nfcache, struct ipt_entry *entry, int *flags) {
	MODULE_DATATYPE *info = (void *)(*(MODULE_ENTRYTYPE **)myinfo)->data;
	char *typename, *slash, *sep, *extent;
	int type, code;
	unsigned int i;
	icmpTypeInfo *selector = NULL;

	if(!strcmp(field, "icmp-type")) {
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
				info->invflags |= IPT_ICMP_INV;
				typename++;
			}

			for(i = 0; i < sizeof(icmp_types) / sizeof(icmpTypeInfo); i++) {
				if(!strncasecmp(icmp_types[i].name, typename, strlen(typename))
								|| (icmp_types[i].alias &&
										!strncasecmp(icmp_types[i].alias,
												typename, strlen(typename)))) {
					if(selector) {
						SET_ERRSTR("%s: Type name '%s' was ambiguous", field,
										typename);
						free(base);
						return(FALSE);
					}
					selector = &icmp_types[i];
					info->type = icmp_types[i].type;
					info->code[0] = icmp_types[i].code_min;
					info->code[1] = icmp_types[i].code_max;
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

		*nfcache |= NFC_IP_SRC_PT;
		if (info->code[0] != 0 || info->code[1] != 0xFF)
			*nfcache |= NFC_IP_DST_PT;

		return(TRUE);
	}

	return(FALSE);
}

static void get_fields(HV *ent_hash, void *myinfo, struct ipt_entry *entry) {
	MODULE_DATATYPE *info = (void *)((MODULE_ENTRYTYPE *)myinfo)->data;
	icmpTypeInfo *selector = NULL;
	char *typename = NULL, *temp;
	unsigned int i;

	for(i = 0; i < sizeof(icmp_types) / sizeof(icmpTypeInfo); i++) {
		if(icmp_types[i].type == info->type &&
				icmp_types[i].code_min == info->code[0] &&
				icmp_types[i].code_max == info->code[1]) {
			selector = &icmp_types[i];
			typename = strdup(icmp_types[i].name);
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
	if(info->invflags & IPT_ICMP_INV) {
		asprintf(&temp, "%c%s", INVCHAR, typename);
		free(typename);
		typename = temp;
	}
	hv_store(ent_hash, "icmp-type", 9, newSVpv(typename, 0), 0);
	free(typename);
	
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
