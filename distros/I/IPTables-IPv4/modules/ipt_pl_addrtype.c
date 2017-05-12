#define BUILD_MATCH
#define MODULE_DATATYPE struct ipt_addrtype_info
#define MODULE_NAME "addrtype"

#define __USE_GNU
#include "../module_iface.h"
#include <string.h>
#include <stdio.h>
#include <linux/netfilter_ipv4/ip_tables.h>
#include <linux/netfilter_ipv4/ipt_addrtype.h>

static char *rtn_names[] = {
	"UNSPEC",
	"UNICAST",
	"LOCAL",
	"BROADCAST",
	"ANYCAST",
	"MULTICAST",
	"BLACKHOLE",
	"UNREACHABLE",
	"PROHIBIT",
	"THROW",
	"NAT",
	"XRESOLVE",
	NULL
};

static void setup(void *myinfo, unsigned int *nfcache) {
	*nfcache |= NFC_UNKNOWN;
}

static int parse_value(SV *value, u_int16_t *mask, int *invert) {
	SV *sv = NULL;
	AV *av = NULL;
	SV **svp;
	int index = 0, i, len;
	char *str;

	if (SvROK(value) && (av = (AV *)SvRV(value)) &&
					(SvTYPE((SV *)av) == SVt_PVAV)) {
		if (index <= av_len(av)) {
			svp = av_fetch(av, index, 0);
			sv = *svp;
		}
	}
	else if (SvPOK(value))
		sv = value;
	else {
		SET_ERRSTR("Argument must be string or array");
		return(FALSE);
	}

	while (sv) {
		if (!SvPOK(sv)) {
			SET_ERRSTR("Array element must be string");
			return(FALSE);
		}

		str = SvPV(sv, len);
		if (av && !strncasecmp(str, "INVERT", len))
			*invert = 1;
		else {
			for (i = 0; i < sizeof(rtn_names) / sizeof(char *); i++) {
				printf("str is \"%s\", rtn_names[%d] is \"%s\"\n", str, i, rtn_names[i]);
				if (!strncasecmp(str, rtn_names[i], len)) {
					*mask |= (1 << i);
					break;
				}
			}
			if (i >= sizeof(rtn_names) / sizeof(char *)) {
				SET_ERRSTR("Couldn't parse type name");
				return(FALSE);
			}
		}

		if (av && index <= av_len(av)) {
			svp = av_fetch(av, index, 0);
			sv = *svp;
			index++;
		}
		else
			sv = NULL;
	}
	return(TRUE);
}

#define IPT_ADDRTYPE_OPT_SRCTYPE	0x1
#define IPT_ADDRTYPE_OPT_DSTTYPE	0x2

static int parse_field(char *field, SV *value, void *myinfo,
		unsigned int *nfcache, struct ipt_entry *entry, int *flags) {
	MODULE_DATATYPE *info = (void *)(*(MODULE_ENTRYTYPE **)myinfo)->data;
	char *temp;

	if (!strcmp(field, "src-type")) {
		if (!parse_value(value, &info->source, &info->invert_source)) {
			temp = strdup(SvPV_nolen(ERROR_SV));
			SET_ERRSTR("%s: %s", field, temp);
			free(temp);
			return(FALSE);
		}

		*flags |= IPT_ADDRTYPE_OPT_SRCTYPE;
		return(TRUE);
	} else if (!strcmp(field, "dst-type")) {
		if (!parse_value(value, &info->dest, &info->invert_dest)) {
			temp = strdup(SvPV_nolen(ERROR_SV));
			SET_ERRSTR("%s: %s", field, temp);
			free(temp);
			return(FALSE);
		}

		*flags |= IPT_ADDRTYPE_OPT_DSTTYPE;
		return(TRUE);
	}
	return(FALSE);
}

static SV *flag_list(u_int16_t mask, int invert) {
	AV *flags = newAV();
	int i;

	for (i = 0; i < sizeof(rtn_names) / sizeof(char *); i++) {
		if (mask & (1 << i))
			av_push((AV *)flags, newSVpv(rtn_names[i], strlen(rtn_names[i])));
	}

	if (invert)
		av_push((AV *)flags, newSVpv("INVERT", 6));

	return(newRV((SV *)flags));
}

static void get_fields(HV *ent_hash, void *myinfo, struct ipt_entry *entry) {
	MODULE_DATATYPE *info = (void *)((MODULE_ENTRYTYPE *)myinfo)->data;

	if (info->source)
		hv_store(ent_hash, "src-type", 8, flag_list(info->source,
								info->invert_source), 0);
	if (info->dest)
		hv_store(ent_hash, "dst-type", 8, flag_list(info->dest,
								info->invert_dest), 0);
}

int final_check(void *myinfo, int flags) {
	if(!flags) {
		SET_ERRSTR("addrtype requires at least one of 'src-type', 'dst-type'");
		return(FALSE);
	}
	
	return(TRUE);
}

static ModuleDef _module = {
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
