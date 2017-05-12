#define BUILD_MATCH
#define MODULE_DATATYPE struct ipt_udp
#define MODULE_NAME "udp"

#define __USE_GNU
#include "../module_iface.h"
#include <string.h>
#include <stdlib.h>
#include <netdb.h>
#include <stdio.h>
#include <netinet/in.h>
#include <limits.h>

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

static int parse_field(char *field, SV *value, void *myinfo,
		unsigned int *nfcache, struct ipt_entry *entry, int *flags) {
	MODULE_DATATYPE *info = (void *)(*(MODULE_ENTRYTYPE **)myinfo)->data;
	int inv;

	if(!strcmp(field, "source-port")) {
		if(!parse_ports_sv(value, info->spts, &inv, "udp")) {
			char *temp = strdup(SvPV_nolen(ERROR_SV));
			SET_ERRSTR("%s: %s", field, temp);
			free(temp);
			return(FALSE);
		}

		if(inv)
			info->invflags |= IPT_UDP_INV_SRCPT;

		*nfcache |= NFC_IP_SRC_PT;
		return(TRUE);
	}
	else if(!strcmp(field, "destination-port")) {
		if(!parse_ports_sv(value, info->dpts, &inv, "udp")) {
			char *temp = strdup(SvPV_nolen(ERROR_SV));
			SET_ERRSTR("%s: %s", field, temp);
			free(temp);
			return(FALSE);
		}

		if(inv)
			info->invflags |= IPT_UDP_INV_DSTPT;

		*nfcache |= NFC_IP_DST_PT;
		return(TRUE);
	}
	return(FALSE);
}

static SV *build_sv_from_portrange(u_int16_t *ports, bool inv) {
	char *temp, *temp2;
	struct servent *service;
	SV *sv;
	
	if((service = getservbyport(htons(ports[0]), "udp")))
		temp = strdup(service->s_name);
	else {
		if(ports[0] == ports[1] && !inv)
			return(newSViv(ports[0]));
		asprintf(&temp, "%u", ports[0]);
	}
	if(ports[0] != ports[1]) {
		if((service = getservbyport(htons(ports[1]), "udp")))
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

static void get_fields(HV *ent_hash, void *myinfo, struct ipt_entry *entry) {
	MODULE_DATATYPE *info =
	    (void *)((MODULE_ENTRYTYPE *)myinfo)->data;
	SV *sv;

	if(info->spts[0] != 0 || info->spts[1] != USHRT_MAX) {
		sv = build_sv_from_portrange(info->spts,
				info->invflags & IPT_UDP_INV_SRCPT);
		hv_store(ent_hash, "source-port", 11, sv, 0);
	}
	if(info->dpts[0] != 0 || info->dpts[1] != USHRT_MAX) {
		sv = build_sv_from_portrange(info->dpts,
				info->invflags & IPT_UDP_INV_DSTPT);
		hv_store(ent_hash, "destination-port", 16, sv, 0);
	}
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
