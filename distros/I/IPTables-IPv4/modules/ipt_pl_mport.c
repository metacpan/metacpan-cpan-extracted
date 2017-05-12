#define BUILD_MATCH
#define MODULE_DATATYPE struct ipt_mport
#define MODULE_NAME "mport"

#define __USE_GNU
#include "../module_iface.h"
#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include <netdb.h>
#include <netinet/in.h>
#include <linux/netfilter_ipv4/ipt_mport.h>
#include <limits.h>

static int parse_field(char *field, SV *value, void *myinfo,
		unsigned int *nfcache, struct ipt_entry *entry, int *flags) {
	MODULE_DATATYPE *info = (void *)(*(MODULE_ENTRYTYPE **)myinfo)->data;
	SV **port;
	AV *portlist;
	struct servent *service;
	struct protoent *proto;
	int i, off, mpflags;
	
	if(!strcmp(field, "source-ports")) {
		mpflags = IPT_MPORT_SOURCE;
		*nfcache |= NFC_IP_SRC_PT;
	}
	else if(!strcmp(field, "destination-ports")) {
		mpflags = IPT_MPORT_DESTINATION;
		*nfcache |= NFC_IP_DST_PT;
	}
	else if(!strcmp(field, "ports")) {
		mpflags = IPT_MPORT_EITHER;
		*nfcache |= NFC_IP_SRC_PT | NFC_IP_DST_PT;
	}
	else
		return(FALSE);

	if(*flags) {
		SET_ERRSTR("%s: Only one of 'ports', 'source-ports', "
						"'destination-ports' may be used with mport", field);
		return(FALSE);
	}

	*flags = 1;
	info->flags = mpflags;

	if(entry->ip.proto != IPPROTO_TCP && entry->ip.proto != IPPROTO_UDP) {
		SET_ERRSTR("%s: Protocol must be TCP or UDP", field);
		return(FALSE);
	}
	
	if(!SvROK(value) || !(portlist = (AV *)SvRV(value)) ||
			SvTYPE((SV *)portlist) != SVt_PVAV) {
		SET_ERRSTR("%s: Must have an array reference arg", field);
		return(FALSE);
	}

	proto = getprotobynumber(entry->ip.proto);
	for(off = 0, i = 0; off <= av_len(portlist); i++, off++) {
		if (i >= IPT_MULTI_PORTS) {
			SET_ERRSTR("%s: List of ports is too long", field);
			return(FALSE);
		}
		port = av_fetch(portlist, off, 0);
		if(SvIOK(*port)) {
			if(SvIV(*port) < 0 || SvIV(*port) > USHRT_MAX) {
				SET_ERRSTR("%s: Port value out of range", field);
				return(FALSE);
			}
			info->ports[i] = SvIV(*port);
		}
		else if(SvPOK(*port)) {
			char *portstr, *temp, *extent, *second;
			STRLEN len;

			temp = SvPV(*port, len);
			portstr = malloc(len + 1);
			strncpy(portstr, temp, len);
			portstr[len] = '\0';

			if((second = strchr(portstr, ':')))
				*(second++) = '\0';
			service = getservbyname(portstr, proto->p_name);

			if(service)
				info->ports[i] = htons(service->s_port);
			else {
				int val = strtoul(portstr, &extent, 10);
				if(val < 0 || val > USHRT_MAX) {
					SET_ERRSTR("%s: Port value out of range", field);
					free(portstr);
					return(FALSE);
				}
				info->ports[i] = val;
				if(portstr + strlen(portstr) > extent) {
					SET_ERRSTR("%s: Couldn't parse port '%s'", field, portstr);
					free(portstr);
					return(FALSE);
				}
			}

			if(second) {
				info->pflags |= 1 << i;
				if(++i >= IPT_MULTI_PORTS) {
					SET_ERRSTR("%s: List of ports is too long", field);
					free(portstr);
					return(FALSE);
				}

				service = getservbyname(second, proto->p_name);

				if(service)
					info->ports[i] = htons(service->s_port);
				else {
					int val = strtoul(second, &extent, 10);
					if(val < 0 || val > USHRT_MAX) {
						SET_ERRSTR("%s: Port value out of range", field,
										second);
						free(portstr);
						return(FALSE);
					}
					info->ports[i] = val;
					if(second + strlen(second) > extent) {
						SET_ERRSTR("%s: Couldn't parse port '%s'", field,
										second);
						free(portstr);
						return(FALSE);
					}
				}
			}
			free(portstr);
		}
		else {
			SET_ERRSTR("%s: Array elements must be integer or string", field);
			return(FALSE);
		}
	}
	
	if(i == IPT_MULTI_PORTS-1)
		info->ports[i] = info->ports[i-1];
	else if(i < IPT_MULTI_PORTS-1) {
		info->ports[i] = USHRT_MAX;
		info->pflags |= 1<<i;
	}

	return(TRUE);
}

static void get_fields(HV *ent_hash, void *myinfo, struct ipt_entry *entry) {
	MODULE_DATATYPE *info = (void *)((MODULE_ENTRYTYPE *)myinfo)->data;
	int i;
	AV *av;
	SV *sv;
	char *keyname = NULL;
	struct servent *service;
	struct protoent *proto;

	av = newAV();
	if(!(proto = getprotobynumber(entry->ip.proto)))
		return;
	
	for(i = 0; i < IPT_MULTI_PORTS; i++) {
		if(info->pflags & (1<<i) && info->ports[i] == USHRT_MAX)
			break;
		
		if(i == IPT_MULTI_PORTS - 1 &&
				info->ports[i] == info->ports[i-1])
			break;
		
		service = getservbyport(htons(info->ports[i]), proto->p_name); // LEAK
		if(service)
			sv = newSVpv(service->s_name, 0);
		else
			sv = newSViv(info->ports[i]);

		if(info->pflags & (1<<i)) {
			i++;
			service = getservbyport(htons(info->ports[i]),
							proto->p_name); // LEAK
			if(SvIOK(sv))
				sv = newSVpvf("%u", SvIV(sv));

			sv_catpv(sv, ":");

			if(service)
				sv_catpv(sv, service->s_name);
			else
				sv_catpvf(sv, "%u", info->ports[i]);
		}
		av_push(av, sv);
	}		
	
	if(info->flags == IPT_MPORT_SOURCE)
		keyname = "source-ports";
	else if(info->flags == IPT_MPORT_DESTINATION)
		keyname = "destination-ports";
	else if(info->flags == IPT_MPORT_EITHER)
		keyname = "ports";
	
	hv_store(ent_hash, keyname, strlen(keyname), newRV_noinc((SV *)av), 0);
}

int final_check(void *myinfo, int flags) {
	if(!flags) {
		SET_ERRSTR("mport must be used with one of 'ports', 'source-ports' or "
						"'destination-ports'");
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
