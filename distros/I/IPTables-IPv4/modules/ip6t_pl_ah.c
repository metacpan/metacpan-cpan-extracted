#define INET6
#define BUILD_MATCH
#define MODULE_DATATYPE struct ip6t_ah
#define MODULE_NAME "ah"

#define __USE_GNU
#include "../module_iface.h"
#include <string.h>
#include <stdlib.h>
#include <netdb.h>
#include <stdio.h>
#include <netinet/in.h>
#include <limits.h>
#include <linux/netfilter_ipv6/ip6t_ah.h>
#include <errno.h>

static void setup(void *myinfo, unsigned int *nfcache) {
	MODULE_DATATYPE *info = (void *)((MODULE_ENTRYTYPE *)myinfo)->data;

	info->spis[1] = 0xFFFFFFFF;
}

static int parse_field(char *field, SV *value, void *myinfo,
		unsigned int *nfcache, struct ip6t_entry *entry, int *flags) {
	MODULE_DATATYPE *info = (void *)(*(MODULE_ENTRYTYPE **)myinfo)->data;
	unsigned int val;

	if (strcmp(field, "ahspi")) {
		if (SvIOK(value)) {
			val = SvIV(value);
			if (val > 0xFFFFFFFF) {
				SET_ERRSTR("%s: Value out of range", field);
				return(FALSE);
			}
			info->spis[0] = info->spis[1] = val;
		}
		else if (SvPOK(value)) {
			STRLEN len;
			char *temp = SvPV(value, len);
			char *text = NULL, *sep = NULL, *base = NULL;
	
			base = text = malloc(len + 1);
			strncpy(text, temp, len);
			text[len] = '\0';
	
			if(*text == INVCHAR) {
				info->invflags |= IP6T_AH_INV_SPI;
				text++;
			}
			sep = strchr(text, ':');
			if(sep == text)
				info->spis[0] = 0;
			else {
				val = strtoul(text, &temp, 10);
				if(sep > temp || (val == 0xFFFFFFFF && errno == ERANGE)) {
					SET_ERRSTR("%s: Unable to parse '%s'", field, text);
					free(base);
					return(FALSE);
				}
				info->spis[0] = val;
			}
	
			if(sep) {
				text = ++sep;
				if(*text == '\0')
					info->spis[1] = 0xFFFFFFFF;
				else {
					val = strtoul(text, &temp, 10);
					if((text + strlen(text)) > temp || (val == 0xFFFFFFFF &&
											errno == ERANGE)) {
						SET_ERRSTR("%s: Unable to parse '%s'", field, text);
						free(base);
						return(FALSE);
					}
					info->spis[1] = val;
				}
			}
			else
				info->spis[1] = info->spis[0];
	
			free(base);
		
		}
		else {
			SET_ERRSTR("%s: Must have integer or string arg", field);
			return(FALSE);
		}

		return(TRUE);
	}
	else if (!strcmp(field, "ahlen")) {
		if (SvIOK(value)) {

		}
		else if (SvPOK(value)) {
			STRLEN len;
			char *temp = SvPV(value, len);
			char *text = NULL, *base = NULL;
	
			base = text = malloc(len + 1);
			strncpy(text, temp, len);
			text[len] = '\0';
	
			if(*text == INVCHAR) {
				info->invflags |= IP6T_AH_INV_LEN;
				text++;
			}
			val = strtoul(text, &temp, 10);
			if((text + strlen(text)) > temp || (val == 0xFFFFFFFF &&
									errno == ERANGE)) {
				SET_ERRSTR("%s: Unable to parse '%s'", field, text);
				free(base);
				return(FALSE);
			}
			info->hdrlen = val;
			free(base);
		}
		else {
			SET_ERRSTR("%s: Must have integer or string arg", field);
			return(FALSE);
		}
		
		return(TRUE);
	}
	else if (!strcmp(field, "ahres")) {
		info->hdrres = 1;
		return(TRUE);
	}

	return(FALSE);
}

static void get_fields(HV *ent_hash, void *myinfo, struct ip6t_entry *entry) {
	MODULE_DATATYPE *info = (void *)((MODULE_ENTRYTYPE *)myinfo)->data;
	char *str, *temp;
	SV *sv;

	if (info->spis[0] != 0 || info->spis[1] != 0xFFFFFFFF) {
		if (info->spis[0] == info->spis[1] &&
						!(info->invflags & IP6T_AH_INV_SPI)) {
			sv = newSViv(info->spis[0]);
		}
		else {
			asprintf(&str, "%u", info->spis[0]);
			if (info->spis[0] != info->spis[1]) {
				asprintf(&temp, "%s:%u", str, info->spis[1]);
				free(str);
				str = temp;
			}
			if (info->invflags & IP6T_AH_INV_SPI) {
				asprintf(&temp, "%c%s", INVCHAR, str);
				free(str);
				str = temp;
			}
			sv = newSVpv(str, 0);
			free(str);
		}
		hv_store(ent_hash, "ahspi", 5, sv, 0);
	}

	if (info->hdrlen != 0) {
		if (info->invflags & IP6T_AH_INV_LEN) {
			char *str;
			asprintf(&str, "%c%u", INVCHAR, info->hdrlen);
			sv = newSVpv(str, 0);
			free(str);
		}
		else
			sv = newSViv(info->hdrlen);
		hv_store(ent_hash, "ahlen", 5, sv, 0);
	}

	if (info->hdrres != 0)
		hv_store(ent_hash, "ahres", 5, newSViv(1), 0);
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
