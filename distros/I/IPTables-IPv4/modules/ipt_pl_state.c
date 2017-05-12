#define BUILD_MATCH
#define MODULE_DATATYPE struct ipt_state_info
#define MODULE_NAME "state"

#define __USE_GNU
#include "../module_iface.h"
#include <string.h>
#include <stdio.h>
#include <linux/netfilter_ipv4/ipt_state.h>
#include <linux/netfilter_ipv4/ip_conntrack.h>

static void setup(void *myinfo, unsigned int *nfcache) {
	*nfcache |= NFC_UNKNOWN;
}

static int parse_field(char *field, SV *value, void *myinfo,
		unsigned int *nfcache, struct ipt_entry *entry, int *flags) {
	MODULE_DATATYPE *info = (void *)(*(MODULE_ENTRYTYPE **)myinfo)->data;
	AV *av;
	SV **svp;
	int i;
	char *flagname, *temp;
	STRLEN len;

	if(strcmp(field, "state"))
		return(FALSE);

	*flags = 1;

	if(!SvROK(value) || !(av = (AV *)SvRV(value)) ||
			SvTYPE((SV *)av) != SVt_PVAV) {
		SET_ERRSTR("%s: Must have an array reference arg", field);
		return(FALSE);
	}
	
	for(i = 0; i <= av_len(av); i++) {
		svp = av_fetch(av, i, 0);
		if(!svp || !SvPOK(*svp)) {
			SET_ERRSTR("%s: Array element %i was not a string scalar", field,
							i);
			return(FALSE);
		}
		temp = SvPV(*svp, len);
		flagname = malloc(len + 1);
		strncpy(flagname, temp, len);
		flagname[len] = '\0';
		if(!strcmp(flagname, "INVALID"))
			info->statemask |= IPT_STATE_INVALID;
		else if(!strcmp(flagname, "NEW"))
			info->statemask |= IPT_STATE_BIT(IP_CT_NEW);
		else if(!strcmp(flagname, "ESTABLISHED"))
			info->statemask |= IPT_STATE_BIT(IP_CT_ESTABLISHED);
		else if(!strcmp(flagname, "RELATED"))
			info->statemask |= IPT_STATE_BIT(IP_CT_RELATED);
		else {
			SET_ERRSTR("%s: Unknown connection state '%s'", field, flagname);
			free(flagname);
			return(FALSE);
		}
		free(flagname);
	}
	
	return(TRUE);
}

static void get_fields(HV *ent_hash, void *myinfo, struct ipt_entry *entry) {
	MODULE_DATATYPE *info = (void *)((MODULE_ENTRYTYPE *)myinfo)->data;
	AV *av;

	av = newAV();
	
	if(info->statemask & IPT_STATE_INVALID)
		av_push(av, newSVpv("INVALID", 0));
	if(info->statemask & IPT_STATE_BIT(IP_CT_NEW))
		av_push(av, newSVpv("NEW", 0));
	if(info->statemask & IPT_STATE_BIT(IP_CT_ESTABLISHED))
		av_push(av, newSVpv("ESTABLISHED", 0));
	if(info->statemask & IPT_STATE_BIT(IP_CT_RELATED))
		av_push(av, newSVpv("RELATED", 0));
	
	hv_store(ent_hash, "state", 5, newRV_noinc((SV *)av), 0);
}

int final_check(void *myinfo, int flags) {
	if(!flags) {
		SET_ERRSTR("state must have a parameter");
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
