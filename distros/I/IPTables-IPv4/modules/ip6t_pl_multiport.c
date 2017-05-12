#define INET6
#define BUILD_MATCH
#define MODULE_DATATYPE struct ip6t_multiport
#define MODULE_NAME "multiport"

#define __USE_GNU
#include "../module_iface.h"
#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include <netdb.h>
#include <netinet/in.h>
#include <linux/netfilter_ipv6/ip6t_multiport.h>

static int parse_field(char *field, SV *value, void *myinfo,
		unsigned int *nfcache, struct ip6t_entry *entry, int *flags) {
	MODULE_DATATYPE *info = (void *)(*(MODULE_ENTRYTYPE **)myinfo)->data;
	SV **port;
	AV *portlist;
	struct servent *service;
	struct protoent *proto;
	int i, val;
	char *portstr, *extent;
	
	if(!strcmp(field, "source-ports")) {
		info->flags = IP6T_MULTIPORT_SOURCE;
		*nfcache |= NFC_IP6_SRC_PT;
	}
	else if(!strcmp(field, "destination-ports")) {
		info->flags = IP6T_MULTIPORT_DESTINATION;
		*nfcache |= NFC_IP6_DST_PT;
	}
	else if(!strcmp(field, "ports")) {
		info->flags = IP6T_MULTIPORT_EITHER;
		*nfcache |= NFC_IP6_SRC_PT | NFC_IP6_DST_PT;
	}
	else
		return(FALSE);

	if(*flags) {
		SET_ERRSTR("%s: Only one of 'ports', 'source-ports', "
						"'destination-ports' may be used with multiport",
						field);
		return(FALSE);
	}

	*flags = 1;
	if(entry->ipv6.proto != IPPROTO_TCP && entry->ipv6.proto != IPPROTO_UDP) {
		SET_ERRSTR("%s: Protocol must be TCP or UDP", field);
		return(FALSE);
	}
	
	if(!SvROK(value) || !(portlist = (AV *)SvRV(value)) ||
			SvTYPE((SV *)portlist) != SVt_PVAV) {
		SET_ERRSTR("%s: Must have an array reference arg", field);
		return(FALSE);
	}

	if(av_len(portlist) >= IP6T_MULTI_PORTS) {
		SET_ERRSTR("%s: List of ports is too long", field);
		return(FALSE);
	}

	info->count = 0;
	proto = getprotobynumber(entry->ipv6.proto);
	for(i = 0; i <= av_len(portlist); i++) {
		port = av_fetch(portlist, i, 0);
		if(SvIOK(*port)) {
			if (SvIV(*port) < 0 || SvIV(*port) > USHRT_MAX) {
				SET_ERRSTR("%s: Value out of range", field);
				return(FALSE);
			}
			info->ports[i] = SvIV(*port);
		}
		else if(SvPOK(*port)) {
			char *temp;
			STRLEN len;

			temp = SvPV(*port, len);
			portstr = malloc(len + 1);
			strncpy(portstr, temp, len);
			portstr[len] = '\0';
			service = getservbyname(portstr, proto->p_name);
			if(service)
				info->ports[i] = htons(service->s_port);
			else {
				val= strtoul(portstr, &extent, 10);
				if(portstr + strlen(portstr) > extent) {
					SET_ERRSTR("%s: Couldn't parse port '%s'", field, portstr);
					info->count = 0;
					free(portstr);
					return(FALSE);
				}
				if (val < 0 || val > USHRT_MAX) {
					SET_ERRSTR("%s: Value out of range", field);
					free(portstr);
					return(FALSE);
				}
				info->ports[i] = val;
			}
			free(portstr);
		}
		else {
			SET_ERRSTR("%s: Array elements must be integer or string", field);
			info->count = 0;
			return(FALSE);
		}
		info->count++;
	}

	return(TRUE);
}

static void get_fields(HV *ent_hash, void *myinfo, struct ip6t_entry *entry) {
	MODULE_DATATYPE *info = (void *)((MODULE_ENTRYTYPE *)myinfo)->data;
	int i;
	AV *av;
	char *keyname = NULL;
	struct servent *service;
	struct protoent *proto;

	av = newAV();
	if(!(proto = getprotobynumber(entry->ipv6.proto)))
		return;
	
	for(i = 0; i < info->count; i++) {
		service = getservbyport(htons(info->ports[i]),
		    proto->p_name); // LEAK
		if(service)
			av_push(av, newSVpv(service->s_name, 0));
		else
			av_push(av, newSViv(info->ports[i]));
	}		
	
	if(info->flags == IP6T_MULTIPORT_SOURCE)
		keyname = "source-ports";
	else if(info->flags == IP6T_MULTIPORT_DESTINATION)
		keyname = "destination-ports";
	else if(info->flags == IP6T_MULTIPORT_EITHER)
		keyname = "ports";
	
	hv_store(ent_hash, keyname, strlen(keyname), newRV_noinc((SV *)av), 0);
}

int final_check(void *myinfo, int flags) {
	if(!flags) {
		SET_ERRSTR("multiport must have a parameter");
		return(FALSE);
	}

	return(TRUE);
}

static ModuleDef _module = {
	.type			= MODULE_TYPE,
	.name			= MODULE_NAME,
	.size			= IP6T_ALIGN(sizeof(MODULE_DATATYPE)),
	.size_uspace	= IP6T_ALIGN(sizeof(MODULE_DATATYPE)),
	.parse_field	= parse_field,
	.get_fields		= get_fields,
	.final_check	= final_check,
};

ModuleDef *init(void) {
	return(&_module);
}
/* vim: ts=4
 */
