#define BUILD_MATCH
#define MODULE_DATATYPE struct ipt_pkttype_info
#define MODULE_NAME "pkttype"

#define __USE_GNU
#include "../module_iface.h"
#include <string.h>
#include <stdio.h>
#if defined(__GLIBC__) && __GLIBC__ == 2
#include <net/ethernet.h>
#else
#include <linux/if_ether.h>
#endif
#include <linux/if_packet.h>
#include <linux/netfilter_ipv4/ipt_pkttype.h>

static struct TypeList {
	char value;
	char *name;
} pkttype_list[] = {
	{ PACKET_BROADCAST,		"broadcast" },
	{ PACKET_MULTICAST,		"multicast" },
	{ PACKET_HOST,			"host" }
};

static void setup(void *myinfo, unsigned int *nfcache) {
	*nfcache |= NFC_UNKNOWN;
}

static int parse_field(char *field, SV *value, void *myinfo,
		unsigned int *nfcache, struct ipt_entry *entry, int *flags) {
	MODULE_DATATYPE *info = (void *)(*(MODULE_ENTRYTYPE **)myinfo)->data;
	char *typestr, *temp, *base;
	struct TypeList *selector = NULL;
	unsigned int i;
	STRLEN len;

	if(strcmp(field, "pkt-type"))
		return(FALSE);

	*flags = 1;

	if(!SvPOK(value)) {
		SET_ERRSTR("%s: Must have a string arg", field);
		return(FALSE);
	}

	temp = SvPV(value, len);
	base = typestr = malloc(len + 1);
	strncpy(typestr, temp, len);
	typestr[len] = '\0';

	if(*typestr == INVCHAR) {
		info->invert = TRUE;
		typestr++;
	}
		
	for(i = 0; i < (sizeof(pkttype_list) / sizeof(struct TypeList)); i++) {
		if(!strcmp(typestr, pkttype_list[i].name)) {
			selector = &pkttype_list[i];
			break;
		}
	}
	free(base);
		
	if(!selector) {
		SET_ERRSTR("%s: Couldn't parse type name", field);
		return(FALSE);
	}

	info->pkttype = selector->value;

	return(TRUE);
}

static void get_fields(HV *ent_hash, void *myinfo, struct ipt_entry *entry) {
	MODULE_DATATYPE *info = (void *)((MODULE_ENTRYTYPE *)myinfo)->data;
	char *typestr = NULL, *temp;
	unsigned int i;

	for(i = 0; i < (sizeof(pkttype_list) / sizeof(struct TypeList)); i++) {
		if(info->pkttype == pkttype_list[i].value) {
			typestr = strdup(pkttype_list[i].name);
			break;
		}
	}

	if(info->invert) {
		asprintf(&temp, "%c%s", INVCHAR, typestr);
		free(typestr);
		typestr = temp;
	}
	
	hv_store(ent_hash, "pkt-type", 8, newSVpv(typestr, 0), 0);
	free(typestr);
}

int final_check(void *myinfo, int flags) {
	if(!flags) {
		SET_ERRSTR("pkttype match requires 'pkt-type'");
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
