#define BUILD_MATCH
#define MODULE_DATATYPE struct ipt_dscp_info
#define MODULE_NAME "dscp"

#define __USE_GNU
#include "../module_iface.h"
#include <string.h>
#include <stdio.h>
#include <linux/netfilter_ipv4/ip_tables.h>
#include <linux/netfilter_ipv4/ipt_dscp.h>

static struct dsClass
{
	char *name;
	unsigned int value;
} dscpClasses[] = 
{
	{ "CS0",	0x00 },		{ "CS1",	0x08 },
	{ "CS2",	0x10 },		{ "CS3",	0x18 },
	{ "CS4",	0x20 },		{ "CS5",	0x28 },
	{ "CS6",	0x30 },		{ "CS7",	0x38 },
	{ "BE",		0x00 },		{ "AF11",	0x0a },
	{ "AF12",	0x0c },		{ "AF13",	0x0e },
	{ "AF21",	0x12 },		{ "AF22",	0x14 },
	{ "AF23",	0x16 },		{ "AF31",	0x1a },
	{ "AF32",	0x1c },		{ "AF33",	0x1e },
	{ "AF41",	0x22 },		{ "AF42",	0x24 },
	{ "AF43",	0x26 },		{ "EF",		0x2e }
};

static void setup(void *myinfo, unsigned int *nfcache) {
	*nfcache |= NFC_IP_TOS;
}

static int parse_field(char *field, SV *value, void *myinfo,
		unsigned int *nfcache, struct ipt_entry *entry, int *flags) {
	MODULE_DATATYPE *info = (void *)(*(MODULE_ENTRYTYPE **)myinfo)->data;
	char *dscpstr, *extent;
	int dscpval;
	unsigned int i;
	struct dsClass *selector = NULL;

	if(!strcmp(field, "dscp")) {
		if(SvIOK(value))
			dscpval = SvIV(value);
		else if(SvPOK(value)) {
			char *temp, *base;
			STRLEN len;

			temp = SvPV(value, len);
			base = dscpstr = malloc(len + 1);
			strncpy(dscpstr, temp, len);
			dscpstr[len] = '\0';

			if(*dscpstr == INVCHAR) {
				info->invert = 1;
				dscpstr++;
			}

			dscpval = strtoul(dscpstr, &extent, 0);
			if(extent < dscpstr + strlen(dscpstr)) {
				SET_ERRSTR("%s: Couldn't parse value", field);
				free(base);
				return(FALSE);
			}
			free(base);
		}
		else {
			SET_ERRSTR("%s: Must have a string or integer arg", field);
			return(FALSE);
		}

		if(dscpval < 0 || dscpval > IPT_DSCP_MAX) {
			SET_ERRSTR("%s: Value out of range", field);
			return(FALSE);
		}
	}
	else if(!strcmp(field, "dscp-class")) {
		char *base, *temp;
		STRLEN len;

		if(!SvPOK(value)) {
			SET_ERRSTR("%s: Must have a string arg", field);
			return(FALSE);
		}
		temp = SvPV(value, len);
		base = dscpstr = malloc(len + 1);
		strncpy(dscpstr, temp, len);
		dscpstr[len] = '\0';

		if(*dscpstr == INVCHAR) {
			info->invert = 1;
			dscpstr++;
		}

		for(i = 0; i < (sizeof(dscpClasses) / sizeof(struct dsClass)); i++) {
			if(!strcmp(dscpstr, dscpClasses[i].name)) {
				selector = &dscpClasses[i];
				break;
			}
		}
		free(base);

		if(selector)
			dscpval = selector->value;
		else {
			SET_ERRSTR("%s: Couldn't parse value", field);
			return(FALSE);
		}
	}
	else
		return(FALSE);

	if(*flags) {
		SET_ERRSTR("%s: Only one of 'dscp', 'dscp-class' allowed for dscp "
						"match", field);
		return(FALSE);
	}

	info->dscp = dscpval;
	*flags = 1;

	return(TRUE);
}

static void get_fields(HV *ent_hash, void *myinfo, struct ipt_entry *entry) {
	MODULE_DATATYPE *info = (void *)((MODULE_ENTRYTYPE *)myinfo)->data;
	char *dscpstr = NULL, *keystr;
	unsigned int i;
	SV *sv;

	for(i = 0; i < (sizeof(dscpClasses) / sizeof(struct dsClass)); i++) {
		if(info->dscp == dscpClasses[i].value) {
			dscpstr = strdup(dscpClasses[i].name);
			break;
		}
	}

	if(dscpstr)
		keystr = "dscp-class";
	else
		keystr = "dscp";
	
	if(dscpstr || info->invert) {
		if(!dscpstr)
			asprintf(&dscpstr, "%u", info->dscp);

		if(info->invert) {
			char *temp = dscpstr;
			asprintf(&dscpstr, "%c%s", INVCHAR, temp);
			free(temp);
		}

		sv = newSVpv(dscpstr, 0);
		free(dscpstr);
	}
	else
		sv = newSViv(info->dscp);

	hv_store(ent_hash, keystr, strlen(keystr), sv, 0);
}

int final_check(void *myinfo, int flags) {
	if(!flags) {
		SET_ERRSTR("dscp match requires one of 'dscp', 'dscp-class'");
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
