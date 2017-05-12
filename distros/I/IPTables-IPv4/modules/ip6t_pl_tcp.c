#define INET6
#define BUILD_MATCH
#define MODULE_DATATYPE struct ip6t_tcp
#define MODULE_NAME "tcp"

#define __USE_GNU
#include "../module_iface.h"
#include <string.h>
#include <stdlib.h>
#include <netdb.h>
#include <stdio.h>
#include <netinet/in.h>
#include <limits.h>
#include <linux/netfilter_ipv6/ip6_tables.h>

typedef struct {
	char *name;
	unsigned int value;
} FlagList;

FlagList tcp_flags[] = {
	{"FIN", 1 << 0},
	{"SYN", 1 << 1},
	{"RST", 1 << 2},
	{"PSH", 1 << 3},
	{"ACK", 1 << 4},
	{"URG", 1 << 5},
	{"ALL", 0x3f},
	{"NONE", 0},
};

static void setup(void *myinfo, unsigned int *nfcache) {
	MODULE_DATATYPE *info = (void *)((MODULE_ENTRYTYPE *)myinfo)->data;

	info->spts[0] = info->dpts[0] = 0;
	info->spts[1] = info->dpts[1] = USHRT_MAX;
}

static bool parse_ports_sv(SV *portval, u_int16_t *ports, int *inv,
				const char *protocol_name) {
	struct servent *service;
	int val;
	
	*inv = FALSE;
	if(SvIOK(portval)) {
		val = SvIV(portval);
		if(val < 0 || val > USHRT_MAX) {
			SET_ERRSTR("Port number out of range");
			return(FALSE);
		}
		ports[0] = ports[1] = val;
	}
	else if(SvPOK(portval)) {
		STRLEN len;
		char *temp = SvPV(portval, len);
		char *text = NULL, *sep = NULL, *base = NULL;

		base = text = malloc(len + 1);
		strncpy(text, temp, len);
		text[len] = '\0';

		if(*text == INVCHAR) {
			*inv = TRUE;
			text++;
		}
		sep = strchr(text, ':');
		if(sep == text)
			ports[0] = 0;
		else {
			if(sep)
				*sep = '\0';
			if((service = getservbyname(text, protocol_name)))
				ports[0] = ntohs(service->s_port);
			else {
				val = strtoul(text, &temp, 10);
				if((text + strlen(text) > temp) || val < 0 || val > USHRT_MAX) {
					SET_ERRSTR("Unable to parse '%s'", text);
					free(base);
					return(FALSE);
				}
				ports[0] = val;
			}
			if(temp)
				*temp = ':';
		}

		if(sep) {
			text = ++sep;
			if(*text == '\0')
				ports[1] = USHRT_MAX;
			else {
				if((service = getservbyname(text, protocol_name)))
					ports[1] = ntohs(service->s_port);
				else {
					val = strtoul(text, &temp, 10);
					if((text + strlen(text) > temp) || val < 0 ||
							val > USHRT_MAX) {
						SET_ERRSTR("Unable to parse '%s'", text);
						free(base);
						return(FALSE);
					}
					ports[1] = val;
				}
			}
		}
		else
			ports[1] = ports[0];

		free(base);
	}
	else {
		SET_ERRSTR("Must be passed as integer or string");
		return(FALSE);
	}
	return(TRUE);
}

static bool assemble_mask_from_arrayref(SV *arrayref, FlagList *flags,
		int nflags, u_int8_t *mask) {
	SV **svp, *sv;
	char *temp, *str;
	int i, j;
	STRLEN len;
	
	if(!SvROK(arrayref) || !(sv = SvRV(arrayref)) || SvTYPE(sv) != SVt_PVAV)
		return(FALSE);
	for(i = 0; i <= av_len((AV *)sv); i++) {
		svp = av_fetch((AV *)sv, i, FALSE);
		if(!svp || !SvPOK(*svp))
			return(FALSE);
		temp = SvPV(*svp, len);
		str = malloc(len + 1);
		strncpy(str, temp, len);
		str[len] = '\0';
		for(j = 0; j < nflags; j++) {
			if(!strcmp(str, flags[j].name)) {
				*mask |= flags[j].value;
				break;
			}
		}
		free(str);
		if(j == nflags)
			return(FALSE);
	}
	return(TRUE);
}

static int parse_field(char *field, SV *value, void *myinfo,
		unsigned int *nfcache, struct ip6t_entry *entry, int *flags) {
	MODULE_DATATYPE *info = (void *)(*(MODULE_ENTRYTYPE **)myinfo)->data;
	char *temp, *text, *base;
	SV **svp;
	int val, inv;
	STRLEN len;

	if(!strcmp(field, "source-port")) {
		if(!parse_ports_sv(value, info->spts, &inv, "tcp")) {
			char *temp = strdup(SvPV_nolen(ERROR_SV));
			SET_ERRSTR("%s: %s", field, temp);
			free(temp);
			return(FALSE);
		}

		if(inv)
			info->invflags |= IP6T_TCP_INV_SRCPT;

		*nfcache |= NFC_IP6_SRC_PT;
		return(TRUE);
	}
	else if(!strcmp(field, "destination-port")) {
		if(!parse_ports_sv(value, info->dpts, &inv, "tcp")) {
			char *temp = strdup(SvPV_nolen(ERROR_SV));
			SET_ERRSTR("%s: %s", field, temp);
			free(temp);
			return(FALSE);
		}

		if(inv)
			info->invflags |= IP6T_TCP_INV_DSTPT;

		*nfcache |= NFC_IP6_DST_PT;
		return(TRUE);
	}
	else if(!strcmp(field, "tcp-flags")) {
		if(!SvROK(value) || !(value = SvRV(value)) ||
				SvTYPE(value) != SVt_PVHV) {
			SET_ERRSTR("%s: Must be passed as a hash ref", field);
			return(FALSE);
		}
		if(hv_fetch((HV *)value, "inv", 3, FALSE))
			info->invflags |= IP6T_TCP_INV_FLAGS;
		if(!(svp = hv_fetch((HV *)value, "mask", 4, FALSE)) ||
				!assemble_mask_from_arrayref(*svp, tcp_flags,
					sizeof(tcp_flags) / sizeof(FlagList),
					&info->flg_mask)) {
			SET_ERRSTR("%s: Unable to parse mask flags", field);
			return(FALSE);
		}
		if(!(svp = hv_fetch((HV *)value, "comp", 4, FALSE)) ||
				!assemble_mask_from_arrayref(*svp, tcp_flags,
					sizeof(tcp_flags) / sizeof(FlagList),
					&info->flg_cmp)) {
			SET_ERRSTR("%s: Unable to parse compare flags", field);
			return(FALSE);
		}
		*nfcache |= NFC_IP6_TCPFLAGS;
		return(TRUE);
	}
	else if(!strcmp(field, "tcp-option")) {
		if(SvIOK(value))
			val = SvIV(value);
		else if(SvPOK(value)) {
			temp = SvPV(value, len);
			base = text = malloc(len + 1);
			strncpy(text, temp, len);
			text[len] = '\0';
			if(*text == INVCHAR) {
				info->invflags |= IP6T_TCP_INV_OPTION;
				text++;
			}
			temp = NULL;
			val = strtoul(text, &temp, 10);
			if((temp - text) < strlen(text)) {
				SET_ERRSTR("%s: Unable to parse option number", field);
				free(base);
				return(FALSE);
			}
			free(base);
		}
		else {
			SET_ERRSTR("%s: Must be passed as integer or string", field);
			return(FALSE);
		}

		if(val < 0 || val > 0xFF) {
			SET_ERRSTR("%s: Value out of range", field);
			return(FALSE);
		}
		info->option = val;
		*nfcache |= NFC_IP6_PROTO_UNKNOWN;
		return(TRUE);
	}
	return(FALSE);
}

static SV *build_flag_list_from_mask(u_int8_t mask, FlagList *flags,
		int nflags) {
	int i;
	AV *av = newAV();
	
	for(i = 0; i < nflags; i++) {
		if(flags[i].value & mask)
			av_push(av, newSVpv(flags[i].name, 0));
	}
	return((SV *)newRV_noinc((SV *)av));
}

static SV *build_sv_from_portrange(u_int16_t *ports, bool inv) {
	char *temp, *temp2;
	struct servent *service;
	SV *sv;
	
	if((service = getservbyport(htons(ports[0]), "tcp")))
		temp = strdup(service->s_name);
	else {
		if(ports[0] == ports[1] && !inv)
			return(newSViv(ports[0]));	
		asprintf(&temp, "%u", ports[0]);
	}
	if(ports[0] != ports[1]) {
		if((service = getservbyport(htons(ports[1]), "tcp")))
			asprintf(&temp2, "%s:%s", temp, service->s_name);
		else
			asprintf(&temp2, "%s:%u", temp, ports[1]);
		free(temp);
		temp = temp2;
	}
	if(inv) {
		asprintf(&temp2, "%c%s", INVCHAR, temp);
		free(temp);
		temp = temp2;
	}
	sv = newSVpv(temp, 0);
	free(temp);
	return(sv);
}

static void get_fields(HV *ent_hash, void *myinfo, struct ip6t_entry *entry) {
	MODULE_DATATYPE *info = (void *)((MODULE_ENTRYTYPE *)myinfo)->data;
	char *temp;
	SV *sv;

	if(info->spts[0] != 0 || info->spts[1] != USHRT_MAX) {
		sv = build_sv_from_portrange(info->spts,
				info->invflags & IP6T_TCP_INV_SRCPT);
		hv_store(ent_hash, "source-port", 11, sv, 0);
	}

	if(info->dpts[0] != 0 || info->dpts[1] != USHRT_MAX) {
		sv = build_sv_from_portrange(info->dpts,
				info->invflags & IP6T_TCP_INV_DSTPT);
		hv_store(ent_hash, "destination-port", 16, sv, 0);
	}
	if(info->flg_mask || info->flg_cmp) {
		HV *hv = newHV();
		if(info->flg_mask)
			hv_store(hv, "mask", 4, build_flag_list_from_mask(info->flg_mask,
									tcp_flags, (sizeof(tcp_flags) /
											sizeof(FlagList)) - 2), 0);
		if(info->flg_cmp)
			hv_store(hv, "comp", 4, build_flag_list_from_mask(info->flg_cmp,
									tcp_flags, (sizeof(tcp_flags) /
											sizeof(FlagList)) - 2), 0);
		if(info->invflags & IP6T_TCP_INV_FLAGS)
			hv_store(hv, "inv", 3, newSViv(1), 0);
		hv_store(ent_hash, "tcp-flags", 9, newRV_noinc((SV *)hv), 0);
	}
	if(info->option) {
		if(info->invflags & IP6T_TCP_INV_OPTION) {
			asprintf(&temp, "%c%u", INVCHAR, info->option);
			sv = newSVpv(temp, 0);
			free(temp);
		}
		else
			sv = newSViv(info->option);
		hv_store(ent_hash, "tcp-option", 10, sv, 0);
	}
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
