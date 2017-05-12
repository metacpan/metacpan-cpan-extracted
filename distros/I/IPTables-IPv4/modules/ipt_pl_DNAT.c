#define BUILD_TARGET
#define MODULE_DATATYPE struct ip_nat_multi_range
#define MODULE_NAME "DNAT"

#define __USE_GNU
#include "../module_iface.h"
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <linux/netfilter_ipv4/ip_tables.h>
#include <linux/netfilter_ipv4/ip_nat.h>
#include <limits.h>
#include <netinet/in.h>

static void setup(void *myinfo, unsigned int *nfcache) {
	*nfcache |= NFC_UNKNOWN;
}

static int parse_nat_range(char *string, struct ip_nat_range *range,
		struct ipt_entry *entry) {
	char *sep, *asep, *psep, *ptext, *atext, *extent, *temp;
	int port;

	sep = strchr(string, ':');
	if(sep) {
		if(entry->ip.proto != IPPROTO_TCP && entry->ip.proto != IPPROTO_UDP) {
			SET_ERRSTR("to-destination: Protocol must be TCP or UDP to "
							"specify ports");
			return(FALSE);
		}
		
		range->flags |= IP_NAT_RANGE_PROTO_SPECIFIED;

		ptext = sep + 1;
		psep = strchr(ptext, '-');

		port = strtoul(ptext, &extent, 10);
		if(extent < (psep ? psep : (ptext + strlen(ptext))) ||
				port == 0 || port > USHRT_MAX)
			return(FALSE);

		range->min.tcp.port = range->max.tcp.port = htons(port);

		if(psep) {
			ptext = psep + 1;
			port = strtoul(ptext, &extent, 10);

			if(extent < (ptext + strlen(ptext)) ||
					port == 0 || port > 65535 ||
					port < range->min.tcp.port)
				return(FALSE);

			range->max.tcp.port = htons(port);
		}
	}

	if(sep > string || !sep) {
		range->flags |= IP_NAT_RANGE_MAP_IPS;
		temp = atext = strndup(string, sep - string);
		asep = strchr(atext, '-');
		if(asep)
			*asep = '\0';
		if(inet_pton(AF_INET, atext, &range->min_ip) <= 0) {
			free(temp);
			return(FALSE);
		}
		range->max_ip = range->min_ip;

		if(asep) {
			atext = asep + 1;
			if(inet_pton(AF_INET, atext, &range->max_ip) <= 0) {
				free(temp);
				return(FALSE);
			}
		}
		free(temp);
	}

	if(!range->flags)
		return(FALSE);
	
	return(TRUE);
}

static int parse_field(char *field, SV *value, void *myinfo,
		unsigned int *nfcache, struct ipt_entry *entry, int *flags) {
	struct ipt_entry_target **targinfo = myinfo;
	MODULE_DATATYPE *info = (void *)(*(MODULE_ENTRYTYPE **)myinfo)->data;
	int i;
	
	if(strcmp(field, "to-destination"))
		return(FALSE);

	*flags = 1;

	if(SvROK(value) && (SvTYPE(SvRV(value)) == SVt_PVAV)) {
		SV **svp;
		AV *av = (AV *)SvRV(value);
		struct ip_nat_range *range;
		for(i = 0; i <= av_len(av); i++) {
			char *temp, *rangestr;
			STRLEN len;
			svp = av_fetch(av, i, 0);
			if(!svp || !SvPOK(*svp)) {
				SET_ERRSTR("%s: Array element %d must be a string", field, i);
				return(FALSE);
			}

			/* Get a pointer to the range base */
			if(info->rangesize) {
				(*targinfo)->u.target_size +=
					IPT_ALIGN(sizeof(struct ip_nat_range));
				*targinfo = realloc(*targinfo, (*targinfo)->u.target_size);
				info = (struct ip_nat_multi_range *)(*targinfo)->data;
				range = &(info->range[info->rangesize]);
				memset(range, 0, IPT_ALIGN(sizeof(struct ip_nat_range)));
			}
			else
				range = info->range;
			
			temp = SvPV(*svp, len);
			rangestr = malloc(len + 1);
			strncpy(rangestr, temp, len);
			rangestr[len] = '\0';
			if(!parse_nat_range(rangestr, range, entry)) {
				if(!SvOK(ERROR_SV))
					SET_ERRSTR("%s: Unable to parse element %d", field, i);
				free(rangestr);
				return(FALSE);
			}
			free(rangestr);
			info->rangesize++;
		}
		return(TRUE);
	}
	else if(SvPOK(value)) {
		char *temp, *rangestr;
		STRLEN len;

		temp = SvPV(value, len);
		rangestr = malloc(len + 1);
		strncpy(rangestr, temp, len);
		rangestr[len] = '\0';

		if(!parse_nat_range(rangestr, info->range, entry)) {
			SET_ERRSTR("%s: Unable to parse value", field);
			free(rangestr);
			return(FALSE);
		}

		free(rangestr);
		info->rangesize = 1;
		return(TRUE);
	}

	SET_ERRSTR("%s: Arg must be string or array ref", field);
	return(FALSE);
}

static SV *string_from_nat_range(struct ip_nat_range *range) {
	char *string, *temp, *temp2;
	SV *sv;
	
	if(range->flags & IP_NAT_RANGE_MAP_IPS) {
		string = malloc(INET_ADDRSTRLEN + 1);
		inet_ntop(AF_INET, &range->min_ip, string, INET_ADDRSTRLEN);
		if(range->min_ip != range->max_ip) {
			temp = string;
			temp2 = malloc(INET_ADDRSTRLEN + 1);
			inet_ntop(AF_INET, &range->max_ip, temp2, INET_ADDRSTRLEN);
			asprintf(&string, "%s-%s", temp, temp2);
			free(temp);
			free(temp2);
		}
	}
	if(range->flags & IP_NAT_RANGE_PROTO_SPECIFIED) {
		asprintf(&temp, ":%u", ntohs(range->min.tcp.port));
		if(range->min.tcp.port < range->max.tcp.port) {
			asprintf(&temp2, "%s-%u", temp, ntohs(range->max.tcp.port));
			free(temp);
			temp = temp2;
		}

		if(string) {
			asprintf(&temp2, "%s%s", string, temp);
			free(string);
			free(temp);
			string = temp2;
		}
		else
			string = temp;
	}
	
	sv = newSVpv(string, 0);
	free(string);
	return(sv);
}

static void get_fields(HV *ent_hash, void *myinfo, struct ipt_entry *entry) {
	MODULE_DATATYPE *info = (void *)((MODULE_ENTRYTYPE *)myinfo)->data;
	SV *sv = NULL;

	if(info->rangesize > 1) {
		AV *av;
		unsigned int i;

		av = newAV();
		for(i = 0; i < info->rangesize; i++)
			av_store(av, i, string_from_nat_range(&info->range[i]));
		sv = newRV_noinc((SV *)av);
	}
	else if(info->rangesize == 1)
		sv = string_from_nat_range(info->range);

	hv_store(ent_hash, "to-destination", 14, sv, 0);
}

static int final_check(void *myinfo, int flags) {
	if(!flags) {
		SET_ERRSTR("DNAT target requires 'to-destination'");
		return(FALSE);
	}

	return(TRUE);
}

ModuleDef _module = {
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
