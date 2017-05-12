#define INET6
#define BUILD_MATCH
#define MODULE_DATATYPE struct ip6t_owner_info
#define MODULE_NAME "owner"

#define __USE_GNU
#include "../module_iface.h"
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <pwd.h>
#include <grp.h>
#include <linux/netfilter_ipv6/ip6t_owner.h>

static void setup(void *myinfo, unsigned int *nfcache) {
	*nfcache |= NFC_UNKNOWN;
}

static int parse_field(char *field, SV *value, void *myinfo,
		unsigned int *nfcache, struct ip6t_entry *entry, int *flags) {
	MODULE_DATATYPE *info = (void *)(*(MODULE_ENTRYTYPE **)myinfo)->data;
	char  *str, *base, *temp, *extent;
	STRLEN len;

	if(!strcmp(field, "uid-owner")) {
		if(SvIOK(value))
			info->uid = SvIV(value);
		else if(SvPOK(value)) {
			struct passwd *pwd;

			temp = SvPV(value, len);
			base = str = malloc(len + 1);
			strncpy(str, temp, len);
			str[len] = '\0';
			if(str[0] == INVCHAR) {
				info->invert |= IP6T_OWNER_UID;
				str++;
			}
			if((pwd = getpwnam(str)))
				info->uid = pwd->pw_uid;
			else {
				info->uid = strtoul(str, &extent, 10);
				if(str + strlen(str) > extent) {
					SET_ERRSTR("%s: Couldn't parse uid '%s'", field, str);
					free(base);
					return(FALSE);
				}
			}
			free(base);
		}
		else {
			SET_ERRSTR("%s: Must have an integer or string value", field);
			return(FALSE);
		}
		info->match |= IP6T_OWNER_UID;
	}
	else if(!strcmp(field, "gid-owner")) {
		if(SvIOK(value))
			info->gid = SvIV(value);
		else if(SvPOK(value)) {
			struct group *grp;

			temp = SvPV(value, len);
			base = str = malloc(len + 1);
			strncpy(str, temp, len);
			str[len] = '\0';
			if(str[0] == INVCHAR) {
				info->invert |= IP6T_OWNER_GID;
				str++;
			}
			if((grp = getgrnam(str)))
				info->gid = grp->gr_gid;
			else {
				info->gid = strtoul(str, &extent, 10);
				if(str + strlen(str) > extent) {
					SET_ERRSTR("%s: Couldn't parse gid '%s'", field, str);
					free(base);
					return(FALSE);
				}
			}
			free(base);
		}
		else {
			SET_ERRSTR("%s: Must have an integer or string value", field);
			return(FALSE);
		}
		info->match |= IP6T_OWNER_GID;
	}
	else if(!strcmp(field, "pid-owner")) {
		if(SvIOK(value))
			info->pid = SvIV(value);
		else if(SvPOK(value)) {
			temp = SvPV(value, len);
			base = str = malloc(len + 1);
			strncpy(str, temp, len);
			str[len] = '\0';
			if(str[0] == INVCHAR) {
				info->invert |= IP6T_OWNER_PID;
				str++;
			}
			info->pid = strtoul(str, &extent, 10);
			if(str + strlen(str) > extent) {
				SET_ERRSTR("%s: Couldn't parse pid '%s'", field, str);
				free(base);
				return(FALSE);
			}
			free(base);
		}
		else {
			SET_ERRSTR("%s: Must have an integer or string value", field);
			return(FALSE);
		}
		info->match |= IP6T_OWNER_PID;
	}
	else if(!strcmp(field, "sid-owner")) {
		if(SvIOK(value))
			info->sid = SvIV(value);
		else if(SvPOK(value)) {
			temp = SvPV(value, len);
			base = str = malloc(len + 1);
			strncpy(str, temp, len);
			str[len] = '\0';
			if(str[0] == INVCHAR) {
				info->invert |= IP6T_OWNER_SID;
				str++;
			}
			info->sid = strtoul(str, &extent, 10);
			if(str + strlen(str) > extent) {
				SET_ERRSTR("%s: Couldn't parse sid '%s'", field, str);
				free(base);
				return(FALSE);
			}
			free(base);
		}
		else {
			SET_ERRSTR("%s: Must have an integer or string value", field);
			return(FALSE);
		}
		info->match |= IP6T_OWNER_SID;
	}
#ifdef IP6T_OWNER_COMM
	else if(!strcmp(field, "cmd-owner")) {
		if(!SvPOK(value)) {
			SET_ERRSTR("%s: Must have a string value", field);
			return(FALSE);
		}
		temp = SvPV(value, len);
		base = str = malloc(len + 1);
		strncpy(str, temp, len);
		str[len] = '\0';
		if (str[0] == INVCHAR) {
			info->invert |= IP6T_OWNER_COMM;
			str++;
		}
		if (strlen(str) > sizeof(info->comm)) {
			SET_ERRSTR("%s: Command name is too long", field);
			return(FALSE);
		}
		strncpy(info->comm, str, sizeof(info->comm));
		free(base);
		info->match |= IP6T_OWNER_COMM;
	}
#endif /* IP6T_OWNER_COMM */
	else
		return(FALSE);

	if(*flags) {
#ifdef IP6T_OWNER_COMM
		SET_ERRSTR("%s: Only one of 'uid-owner', 'gid-owner', 'pid-owner', "
						"'sid-owner', 'cmd-owner' allowed with owner match",
						field);
#else /* !IP6T_OWNER_COMM */
		SET_ERRSTR("%s: Only one of 'uid-owner', 'gid-owner', 'pid-owner', "
						"'sid-owner' allowed with owner match", field);
#endif /* IP6T_OWNER_COMM */
		return(FALSE);
	}
	*flags = 1;
	
	return(TRUE);
}

static void get_fields(HV *ent_hash, void *myinfo, struct ip6t_entry *entry) {
	MODULE_DATATYPE *info = (void *)((MODULE_ENTRYTYPE *)myinfo)->data;
	char *name, *temp;
	SV *sv;
	
	if(info->match & IP6T_OWNER_UID) {
		struct passwd *pwd;
		pwd = getpwuid(info->uid);
		if(pwd) {
			name = strdup(pwd->pw_name);
			if(info->invert & IP6T_OWNER_UID) {
				asprintf(&temp, "%c%s", INVCHAR, name);
				free(name);
				name = temp;
			}
			sv = newSVpv(name, 0);
			free(name);
		}
		else if(info->invert & IP6T_OWNER_UID) {
			asprintf(&name, "%c%u", INVCHAR, info->uid);
			sv = newSVpv(name, 0);
			free(name);
		}
		else
			sv = newSViv(info->uid);
		hv_store(ent_hash, "uid-owner", 9, sv, 0);
	}
	else if(info->match & IP6T_OWNER_GID) {
		struct group *grp;
		grp = getgrgid(info->gid);
		if(grp) {
			name = strdup(grp->gr_name);
			if(info->invert & IP6T_OWNER_GID) {
				asprintf(&temp, "%c%s", INVCHAR, name);
				free(name);
				name = temp;
			}
			sv = newSVpv(name, 0);
			free(name);
		}
		else if(info->invert & IP6T_OWNER_GID) {
			asprintf(&name, "%c%u", INVCHAR, info->gid);
			sv = newSVpv(name, 0);
			free(name);
		}
		else 
			sv = newSViv(info->gid);
		hv_store(ent_hash, "gid-owner", 9, sv, 0);
	}
	else if(info->match & IP6T_OWNER_PID) {
		if(info->invert & IP6T_OWNER_PID) {
			asprintf(&name, "%c%u", INVCHAR, info->pid);
			sv = newSVpv(name, 0);
			free(name);
		}
		else 
			sv = newSViv(info->pid);
		hv_store(ent_hash, "pid-owner", 9, sv, 0);
	}
	else if(info->match & IP6T_OWNER_SID) {
		if(info->invert & IP6T_OWNER_SID) {
			asprintf(&name, "%c%u", INVCHAR, info->sid);
			sv = newSVpv(name, 0);
			free(name);
		}
		else 
			sv = newSViv(info->sid);
		hv_store(ent_hash, "sid-owner", 9, sv, 0);
	}
#ifdef IP6T_OWNER_COMM
	else if (info->match & IP6T_OWNER_COMM) {
		name = strdup(info->comm);
		if (info->invert & IP6T_OWNER_COMM) {
			asprintf(&temp, "%c%s", INVCHAR, name);
			free(name);
			name = temp;
		}
		hv_store(ent_hash, "cmd-owner", 9, newSVpv(name, 0), 0);
		free(name);
	}
#endif /* IP6T_OWNER_COMM */
}

int final_check(void *myinfo, int flags) {
	if(!flags) {
#ifdef IP6T_OWNER_COMM
		SET_ERRSTR("owner must have one of 'uid-owner', 'gid-owner', "
						"'pid-owner', 'sid-owner', 'cmd-owner'");
#else /* !IP6T_OWNER_COMM */
		SET_ERRSTR("owner must have one of 'uid-owner', 'gid-owner', "
						"'pid-owner', 'sid-owner'");
#endif /* IP6T_OWNER_COMM */
		return(FALSE);
	}

	return(TRUE);
}

static ModuleDef _module = {
	.type			= MODULE_TYPE,
	.name			= MODULE_NAME,
	.size			= IP6T_ALIGN(sizeof(MODULE_DATATYPE)),
	.size_uspace	= IP6T_ALIGN(sizeof(MODULE_DATATYPE)),
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
