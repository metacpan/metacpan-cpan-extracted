/* 
 *
 * The little hampster grew humps, and wrote this....
 *
 * Copyright (c) 2001 Theo Zourzouvillys <theo@crazygreek.co.uk>
 * Includes code from netfilter (netfilter.samba.org)
 *
 * .Copyright (C)  2000-2001 Theo Zourzouvillys
 * .Created:       26/09/2001
 * .Contactid:     <theo@crazygreek.co.uk>
 * .Url:           http://www.crazygreek.co.uk/perl/
 * .Authors:       Theo Zourzouvillys
 * .License:       GPL/Perl Artistic License
 * .ID:            $Id: IPTables.xs,v 1.16 2002/04/05 19:57:40 theo Exp $
 *
 *
 */

#include "EXTERN.h" 
#include "perl.h"
#include "XSUB.h"

#include <getopt.h>
#include <string.h>
#include <netdb.h>
#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <dlfcn.h>
#include <ctype.h>
#include <stdarg.h>
#include <limits.h>
#include <unistd.h>
#include <iptables.h>
#include <fcntl.h>
#include <sys/wait.h>

#ifndef TRUE
#define TRUE 1
#endif
#ifndef FALSE
#define FALSE 0
#endif

#ifndef IPT_LIB_DIR
#define IPT_LIB_DIR "/lib/iptables"
#endif

#ifndef PROC_SYS_MODPROBE
#define PROC_SYS_MODPROBE "/proc/sys/kernel/modprobe"
#endif

#define FMT_NUMERIC			0x0001
#define FMT_NOCOUNTS		0x0002
#define FMT_KILOMEGAGIGA 	0x0004
#define FMT_OPTIONS			0x0008
#define FMT_NOTABLE			0x0010
#define FMT_NOTARGET		0x0020
#define FMT_VIA				0x0040
#define FMT_NONEWLINE		0x0080
#define FMT_LINENUMBERS 	0x0100
#define CMD_NONE			0x0000U
#define CMD_INSERT			0x0001U
#define CMD_DELETE			0x0002U
#define CMD_DELETE_NUM		0x0004U
#define CMD_REPLACE			0x0008U
#define CMD_APPEND			0x0010U
#define CMD_LIST			0x0020U
#define CMD_FLUSH			0x0040U
#define CMD_ZERO			0x0080U
#define CMD_NEW_CHAIN		0x0100U
#define CMD_DELETE_CHAIN	0x0200U
#define CMD_SET_POLICY		0x0400U
#define CMD_CHECK			0x0800U
#define CMD_RENAME_CHAIN	0x1000U
#define NUMBER_OF_CMD		13
#define FMT_PRINT_RULE 		(FMT_NOCOUNTS | FMT_OPTIONS | FMT_VIA | FMT_NUMERIC | FMT_NOTABLE)
#define FMT(tab,notab) 		((format) & FMT_NOTABLE ? (notab) : (tab))

static const char cmdflags[] = { 'I', 'D', 'D', 'R', 'A', 'L', 'F', 'Z', 'N', 'X', 'P', 'C', 'E' };

#define OPTION_OFFSET 256

#define OPT_NONE			0x00000U
#define OPT_NUMERIC			0x00001U
#define OPT_SOURCE			0x00002U
#define OPT_DESTINATION		0x00004U
#define OPT_PROTOCOL		0x00008U
#define OPT_JUMP			0x00010U
#define OPT_VERBOSE			0x00020U
#define OPT_EXPANDED		0x00040U
#define OPT_VIANAMEIN		0x00080U
#define OPT_VIANAMEOUT		0x00100U
#define OPT_FRAGMENT    	0x00200U
#define OPT_LINENUMBERS 	0x00400U
#define OPT_COUNTERS		0x00800U
#define NUMBER_OF_OPT		12

static const char optflags[NUMBER_OF_OPT] = { 'n', 's', 'd', 'p', 'j', 'v', 'x', 'i', 'o', 'f', '3', 'c'};

static struct option original_opts[] = {
	{ "append", 1, 0, 'A' },
	{ "delete", 1, 0,  'D' },
	{ "insert", 1, 0,  'I' },
	{ "replace", 1, 0,  'R' },
	{ "list", 2, 0,  'L' },
	{ "flush", 2, 0,  'F' },
	{ "zero", 2, 0,  'Z' },
	{ "check", 1, 0,  'C' },
	{ "new-chain", 1, 0,  'N' },
	{ "delete-chain", 2, 0,  'X' },
	{ "rename-chain", 2, 0,  'E' },
	{ "policy", 1, 0,  'P' },
	{ "source", 1, 0, 's' },
	{ "destination", 1, 0,  'd' },
	{ "src", 1, 0,  's' }, /* synonym */
	{ "dst", 1, 0,  'd' }, /* synonym */
	{ "protocol", 1, 0,  'p' },
	{ "in-interface", 1, 0, 'i' },
	{ "jump", 1, 0, 'j' },
	{ "table", 1, 0, 't' },
	{ "match", 1, 0, 'm' },
	{ "numeric", 0, 0, 'n' },
	{ "out-interface", 1, 0, 'o' },
	{ "verbose", 0, 0, 'v' },
	{ "exact", 0, 0, 'x' },
	{ "fragments", 0, 0, 'f' },
	{ "version", 0, 0, 'V' },
	{ "help", 2, 0, 'h' },
	{ "line-numbers", 0, 0, '0' },
	{ "modprobe", 1, 0, 'M' },
	{ "set-counters", 1, 0, 'c' },
	{ 0 }
};

#ifndef __OPTIMIZE__
struct ipt_entry_target *
ipt_get_target(struct ipt_entry *e)
{
	return (void *)e + e->target_offset;
}
#endif

static struct option *opts = original_opts;
static unsigned int global_option_offset = 0;

/* Table of legal combinations of commands and options.  If any of the
 * given commands make an option legal, that option is legal (applies to
 * CMD_LIST and CMD_ZERO only).
 * Key:
 *  +  compulsory
 *  x  illegal
 *     optional
 */
static char *newargv[255];  
static int newargc;

static char *newargv[255];
static int newargc;

/* function adding one argument to newargv, updating newargc
 * returns true if argument added, false otherwise */
static int add_argv(char *what) {
    if (what && ((newargc + 1) < sizeof(newargv)/sizeof(char *))) {
        newargv[newargc] = strdup(what);
        newargc++;
        return 1;
    } else
        return 0;
}

static void free_argv(void) {
    int i;

    for (i = 0; i < newargc; i++)   
        free(newargv[i]);
}


char *errstr = NULL;


static char commands_v_options[NUMBER_OF_CMD][NUMBER_OF_OPT] =
/* Well, it's better than "Re: Linux vs FreeBSD" */
{
	/*     -n  -s  -d  -p  -j  -v  -x  -i  -o  -f  --line */
/*INSERT*/    {'x',' ',' ',' ',' ',' ','x',' ',' ',' ','x'},
/*DELETE*/    {'x',' ',' ',' ',' ',' ','x',' ',' ',' ','x'},
/*DELETE_NUM*/{'x','x','x','x','x',' ','x','x','x','x','x'},
/*REPLACE*/   {'x',' ',' ',' ',' ',' ','x',' ',' ',' ','x'},
/*APPEND*/    {'x',' ',' ',' ',' ',' ','x',' ',' ',' ','x'},
/*LIST*/      {' ','x','x','x','x',' ',' ','x','x','x',' '},
/*FLUSH*/     {'x','x','x','x','x',' ','x','x','x','x','x'},
/*ZERO*/      {'x','x','x','x','x',' ','x','x','x','x','x'},
/*NEW_CHAIN*/ {'x','x','x','x','x',' ','x','x','x','x','x'},
/*DEL_CHAIN*/ {'x','x','x','x','x',' ','x','x','x','x','x'},
/*SET_POLICY*/{'x','x','x','x','x',' ','x','x','x','x','x'},
/*CHECK*/     {'x','+','+','+','x',' ','x',' ',' ',' ','x'},
/*RENAME*/    {'x','x','x','x','x',' ','x','x','x','x','x'}
};

static int inverse_for_options[NUMBER_OF_OPT] =
{
/* -n */ 0,
/* -s */ IPT_INV_SRCIP,
/* -d */ IPT_INV_DSTIP,
/* -p */ IPT_INV_PROTO,
/* -j */ 0,
/* -v */ 0,
/* -x */ 0,
/* -i */ IPT_INV_VIA_IN,
/* -o */ IPT_INV_VIA_OUT,
/* -f */ IPT_INV_FRAG,
/*--line*/ 0
};

const char *program_version;
const char *program_name;

/* Keeping track of external matches and targets: linked lists.  */
struct iptables_match *iptables_matches = NULL;
struct iptables_target *iptables_targets = NULL;

/* Extra debugging from libiptc */
extern void dump_entries(const iptc_handle_t handle);

/* A few hardcoded protocols for 'all' and in case the user has no
   /etc/protocols */
struct pprot {
	char *name;
	u_int8_t num;
};

/* Primitive headers... */
/* defined in netinet/in.h */
#if 0
#ifndef IPPROTO_ESP
#define IPPROTO_ESP 50
#endif
#ifndef IPPROTO_AH
#define IPPROTO_AH 51
#endif
#endif

static const struct pprot chain_protos[] = {
	{ "tcp", IPPROTO_TCP },
	{ "udp", IPPROTO_UDP },
	{ "icmp", IPPROTO_ICMP },
	{ "esp", IPPROTO_ESP },
	{ "ah", IPPROTO_AH },
	{ "all", 0 },
};

static char *
proto_to_name(u_int8_t proto, int nolookup)
{
	unsigned int i;

	if (proto && !nolookup) {
		struct protoent *pent = getprotobynumber(proto);
		if (pent)
			return pent->p_name;
	}

	for (i = 0; i < sizeof(chain_protos)/sizeof(struct pprot); i++)
		if (chain_protos[i].num == proto)
			return chain_protos[i].name;

	return NULL;
}

struct in_addr *
dotted_to_addr(const char *dotted)
{
	static struct in_addr addr;
	unsigned char *addrp;
	char *p, *q;
	unsigned int onebyte;
	int i;
	char buf[20];

	/* copy dotted string, because we need to modify it */
	strncpy(buf, dotted, sizeof(buf) - 1);
	addrp = (unsigned char *) &(addr.s_addr);

	p = buf;
	for (i = 0; i < 3; i++) {
		if ((q = strchr(p, '.')) == NULL)
			return (struct in_addr *) NULL;

		*q = '\0';
		if (string_to_number(p, 0, 255, &onebyte) == -1)
			return (struct in_addr *) NULL;

		addrp[i] = (unsigned char) onebyte;
		p = q + 1;
	}

	/* we've checked 3 bytes, now we check the last one */
	if (string_to_number(p, 0, 255, &onebyte) == -1)
		return (struct in_addr *) NULL;

	addrp[3] = (unsigned char) onebyte;

	return &addr;
}

static struct in_addr *
network_to_addr(const char *name)
{
	struct netent *net;
	static struct in_addr addr;

	if ((net = getnetbyname(name)) != NULL) {
		if (net->n_addrtype != AF_INET)
			return (struct in_addr *) NULL;
		addr.s_addr = htonl((unsigned long) net->n_net);
		return &addr;
	}

	return (struct in_addr *) NULL;
}

static void
inaddrcpy(struct in_addr *dst, struct in_addr *src)
{
	/* memcpy(dst, src, sizeof(struct in_addr)); */
	dst->s_addr = src->s_addr;
}


void
exit_error(enum exittype status, char *msg, ...)
{
	char buff[1024]; // Hmmmm......

    va_list args;  
    va_start(args, msg);
    vsprintf(buff, msg, args);
    va_end(args);
	die(buff);
	exit(status);
}


void
exit_tryhelp(int status)
{
	fprintf(stderr, "Try `%s -h' or '%s --help' for more information.\n",
			program_name, program_name );
	exit(status);
}

void
exit_printhelp(void)
{
	struct iptables_match *m = NULL;
	struct iptables_target *t = NULL;

	printf("%s v%s\n\n"
"Usage: %s -[ADC] chain rule-specification [options]\n"
"       %s -[RI] chain rulenum rule-specification [options]\n"
"       %s -D chain rulenum [options]\n"
"       %s -[LFZ] [chain] [options]\n"
"       %s -[NX] chain\n"
"       %s -E old-chain-name new-chain-name\n"
"       %s -P chain target [options]\n"
"       %s -h (print this help information)\n\n",
	       program_name, program_version, program_name, program_name,
	       program_name, program_name, program_name, program_name,
	       program_name, program_name);

	printf(
"Commands:\n"
"Either long or short options are allowed.\n"
"  --append  -A chain		Append to chain\n"
"  --delete  -D chain		Delete matching rule from chain\n"
"  --delete  -D chain rulenum\n"
"				Delete rule rulenum (1 = first) from chain\n"
"  --insert  -I chain [rulenum]\n"
"				Insert in chain as rulenum (default 1=first)\n"
"  --replace -R chain rulenum\n"
"				Replace rule rulenum (1 = first) in chain\n"
"  --list    -L [chain]		List the rules in a chain or all chains\n"
"  --flush   -F [chain]		Delete all rules in  chain or all chains\n"
"  --zero    -Z [chain]		Zero counters in chain or all chains\n"
"  --check   -C chain		Test this packet on chain\n"
"  --new     -N chain		Create a new user-defined chain\n"
"  --delete-chain\n"
"            -X [chain]		Delete a user-defined chain\n"
"  --policy  -P chain target\n"
"				Change policy on chain to target\n"
"  --rename-chain\n"
"            -E old-chain new-chain\n"
"				Change chain name, (moving any references)\n"

"Options:\n"
"  --proto	-p [!] proto	protocol: by number or name, eg. `tcp'\n"
"  --source	-s [!] address[/mask]\n"
"				source specification\n"
"  --destination -d [!] address[/mask]\n"
"				destination specification\n"
"  --in-interface -i [!] input name[+]\n"
"				network interface name ([+] for wildcard)\n"
"  --jump	-j target\n"
"				target for rule (may load target extension)\n"
"  --match	-m match\n"
"				extended match (may load extension)\n"
"  --numeric	-n		numeric output of addresses and ports\n"
"  --out-interface -o [!] output name[+]\n"
"				network interface name ([+] for wildcard)\n"
"  --table	-t table	table to manipulate (default: `filter')\n"
"  --verbose	-v		verbose mode\n"
"  --line-numbers		print line numbers when listing\n"
"  --exact	-x		expand numbers (display exact values)\n"
"[!] --fragment	-f		match second or further fragments only\n"
"  --modprobe=<command>		try to insert modules using this command\n"
"  --set-counters PKTS BYTES	set the counter during insert/append\n"
"[!] --version	-V		print package version.\n");

	/* Print out any special helps. A user might like to be able
	   to add a --help to the commandline, and see expected
	   results. So we call help for all matches & targets */
	for (t=iptables_targets;t;t=t->next) {
		printf("\n");
		t->help();
	}
	for (m=iptables_matches;m;m=m->next) {
		printf("\n");
		m->help();
	}
	exit(0);
}

static void
generic_opt_check(int command, int options)
{
	int i, j, legal = 0;

	/* Check that commands are valid with options.  Complicated by the
	 * fact that if an option is legal with *any* command given, it is
	 * legal overall (ie. -z and -l).
	 */
	for (i = 0; i < NUMBER_OF_OPT; i++) {
		legal = 0; /* -1 => illegal, 1 => legal, 0 => undecided. */

		for (j = 0; j < NUMBER_OF_CMD; j++) {
			if (!(command & (1<<j)))
				continue;

			if (!(options & (1<<i))) {
				if (commands_v_options[j][i] == '+')
					die( "You need to supply the `-%c' "
						   "option for this command\n",
						   optflags[i]);
			} else {
				if (commands_v_options[j][i] != 'x')
					legal = 1;
				else if (legal == 0)
					legal = -1;
			}
		}
		if (legal == -1)
			die("Illegal option `-%c' with this command\n",
				   optflags[i]);
	}
}

static char
opt2char(int option)
{
	const char *ptr;
	for (ptr = optflags; option > 1; option >>= 1, ptr++);

	return *ptr;
}

static char
cmd2char(int option)
{
	const char *ptr;
	for (ptr = cmdflags; option > 1; option >>= 1, ptr++);

	return *ptr;
}

static void
add_command(int *cmd, const int newcmd, const int othercmds, int invert)
{
	if (invert)
		die("unexpected ! flag");
	if (*cmd & (~othercmds))
		die("Can't use -%c with -%c\n",
			   cmd2char(newcmd), cmd2char(*cmd & (~othercmds)));
	*cmd |= newcmd;
}


static void *
fw_calloc(size_t count, size_t size)
{
	void *p;

	if ((p = calloc(count, size)) == NULL) {
		perror("iptables: calloc failed");
		exit(1);
	}
	return p;
}

static void *
fw_malloc(size_t size)
{
	void *p;

	if ((p = malloc(size)) == NULL) {
		perror("iptables: malloc failed");
		exit(1);
	}
	return p;
}

static struct in_addr *
host_to_addr(const char *name, unsigned int *naddr)
{
	struct hostent *host;
	struct in_addr *addr;
	unsigned int i;

	*naddr = 0;
	if ((host = gethostbyname(name)) != NULL) {
		if (host->h_addrtype != AF_INET ||
		    host->h_length != sizeof(struct in_addr))
			return (struct in_addr *) NULL;

		while (host->h_addr_list[*naddr] != (char *) NULL)
			(*naddr)++;
		addr = fw_calloc(*naddr, sizeof(struct in_addr));
		for (i = 0; i < *naddr; i++)
			inaddrcpy(&(addr[i]),
				  (struct in_addr *) host->h_addr_list[i]);
		return addr;
	}

	return (struct in_addr *) NULL;
}

static char *
addr_to_host(const struct in_addr *addr)
{
	struct hostent *host;

	if ((host = gethostbyaddr((char *) addr,
				  sizeof(struct in_addr), AF_INET)) != NULL)
		return (char *) host->h_name;

	return (char *) NULL;
}

/*
 *	All functions starting with "parse" should succeed, otherwise
 *	the program fails.
 *	Most routines return pointers to static data that may change
 *	between calls to the same or other routines with a few exceptions:
 *	"host_to_addr", "parse_hostnetwork", and "parse_hostnetworkmask"
 *	return global static data.
*/

static struct in_addr *
parse_hostnetwork(const char *name, unsigned int *naddrs)
{
	struct in_addr *addrp, *addrptmp;

	if ((addrptmp = dotted_to_addr(name)) != NULL ||
	    (addrptmp = network_to_addr(name)) != NULL) {
		addrp = fw_malloc(sizeof(struct in_addr));
		inaddrcpy(addrp, addrptmp);
		*naddrs = 1;
		return addrp;
	}
	if ((addrp = host_to_addr(name, naddrs)) != NULL)
		return addrp;

	die("host/network `%s' not found", name);
}

static struct in_addr *
parse_mask(char *mask)
{
	static struct in_addr maskaddr;
	struct in_addr *addrp;
	unsigned int bits;

	if (mask == NULL) {
		/* no mask at all defaults to 32 bits */
		maskaddr.s_addr = 0xFFFFFFFF;
		return &maskaddr;
	}
	if ((addrp = dotted_to_addr(mask)) != NULL)
		/* dotted_to_addr already returns a network byte order addr */
		return addrp;
	if (string_to_number(mask, 0, 32, &bits) == -1)
		die("invalid mask `%s' specified", mask);
	if (bits != 0) {
		maskaddr.s_addr = htonl(0xFFFFFFFF << (32 - bits));
		return &maskaddr;
	}

	maskaddr.s_addr = 0L;
	return &maskaddr;
}

static void
parse_hostnetworkmask(const char *name, struct in_addr **addrpp,
		      struct in_addr *maskp, unsigned int *naddrs)
{
	struct in_addr *addrp;
	char buf[256];
	char *p;
	int i, j, k, n;

	strncpy(buf, name, sizeof(buf) - 1);
	if ((p = strrchr(buf, '/')) != NULL) {
		*p = '\0';
		addrp = parse_mask(p + 1);
	} else
		addrp = parse_mask(NULL);
	inaddrcpy(maskp, addrp);

	/* if a null mask is given, the name is ignored, like in "any/0" */
	if (maskp->s_addr == 0L)
		strcpy(buf, "0.0.0.0");

	addrp = *addrpp = parse_hostnetwork(buf, naddrs);
	n = *naddrs;
	for (i = 0, j = 0; i < n; i++) {
		addrp[j++].s_addr &= maskp->s_addr;
		for (k = 0; k < j - 1; k++) {
			if (addrp[k].s_addr == addrp[j - 1].s_addr) {
				(*naddrs)--;
				j--;
				break;
			}
		}
	}
}

struct iptables_match *
find_match(const char *name, enum ipt_tryload tryload)
{
	struct iptables_match *ptr;

	for (ptr = iptables_matches; ptr; ptr = ptr->next) {
		if (strcmp(name, ptr->name) == 0)
			break;
	}

#ifndef NO_SHARED_LIBS
	if (!ptr && tryload != DONT_LOAD) 
	{
		char path[sizeof(IPT_LIB_DIR) + sizeof("/libipt_.so") + strlen(name)];
		sprintf(path, IPT_LIB_DIR "/libipt_%s.so", name);

		if (dlopen(path, RTLD_NOW)) 
		{
			/* Found library.  If it didn't register itself,  maybe they specified target as match. */
			ptr = find_match(name, DONT_LOAD);

			if (!ptr)
				warn("Couldn't load match `%s'\n", name);

		} else if (tryload == LOAD_MUST_SUCCEED)
			die("Couldn't load match `%s':%s\n",  name, dlerror());
	}
#else
	if (ptr && !ptr->loaded) {
		if (tryload != DONT_LOAD)
			ptr->loaded = 1;
		else
			ptr = NULL;
	}
#endif

	if (ptr)
		ptr->used = 1;

	return ptr;
}

/* Christophe Burki wants `-p 6' to imply `-m tcp'.  */
static struct iptables_match *
find_proto(const char *pname, enum ipt_tryload tryload, int nolookup)
{
	unsigned int proto;

	if (string_to_number(pname, 0, 255, &proto) != -1)
		return find_match(proto_to_name(proto, nolookup), tryload);

	return find_match(pname, tryload);
}

static u_int16_t
parse_protocol(const char *s)
{
	unsigned int proto;

	if (string_to_number(s, 0, 255, &proto) == -1) {
		struct protoent *pent;

		if ((pent = getprotobyname(s)))
			proto = pent->p_proto;
		else {
			unsigned int i;
			for (i = 0;
			     i < sizeof(chain_protos)/sizeof(struct pprot);
			     i++) {
				if (strcmp(s, chain_protos[i].name) == 0) {
					proto = chain_protos[i].num;
					break;
				}
			}
			if (i == sizeof(chain_protos)/sizeof(struct pprot))
				die( "unknown protocol `%s' specified",
					   s);
		}
	}

	return (u_int16_t)proto;
}

static void
parse_interface(const char *arg, char *vianame, unsigned char *mask)
{
	int vialen = strlen(arg);
	unsigned int i;

	memset(mask, 0, IFNAMSIZ);
	memset(vianame, 0, IFNAMSIZ);

	if (vialen + 1 > IFNAMSIZ)
		die("interface name `%s' must be shorter than IFNAMSIZ"
			   " (%i)", arg, IFNAMSIZ-1);

	strcpy(vianame, arg);
	if (vialen == 0)
		memset(mask, 0, IFNAMSIZ);
	else if (vianame[vialen - 1] == '+') {
		memset(mask, 0xFF, vialen - 1);
		memset(mask + vialen - 1, 0, IFNAMSIZ - vialen + 1);
		/* Don't remove `+' here! -HW */
	} else {
		/* Include nul-terminator in match */
		memset(mask, 0xFF, vialen + 1);
		memset(mask + vialen + 1, 0, IFNAMSIZ - vialen - 1);
		for (i = 0; vianame[i]; i++) {
			if (!isalnum(vianame[i]) && vianame[i] != '_') {
				printf("Warning: wierd character in interface"
				       " `%s' (No aliases, :, ! or *).\n",
				       vianame);
				break;
			}
		}
	}
}

/* Can't be zero. */
static int
parse_rulenumber(const char *rule)
{
	unsigned int rulenum;

	if (string_to_number(rule, 1, INT_MAX, &rulenum) == -1)
		die("Invalid rule number `%s'", rule);

	return rulenum;
}

static const char *
parse_target(const char *targetname)
{
	const char *ptr;

	if (strlen(targetname) < 1)
		die("Invalid target name (too short)");

	if (strlen(targetname)+1 > sizeof(ipt_chainlabel))
		die("Invalid target name `%s' (%i chars max)",
			   targetname, sizeof(ipt_chainlabel)-1);

	for (ptr = targetname; *ptr; ptr++)
		if (isspace(*ptr))
			die("Invalid target name `%s'", targetname);
	return targetname;
}

static char *
addr_to_network(const struct in_addr *addr)
{
	struct netent *net;

	if ((net = getnetbyaddr((long) ntohl(addr->s_addr), AF_INET)) != NULL)
		return (char *) net->n_name;

	return (char *) NULL;
}

char *
addr_to_dotted(const struct in_addr *addrp)
{
	static char buf[20];
	const unsigned char *bytep;

	bytep = (const unsigned char *) &(addrp->s_addr);
	sprintf(buf, "%d.%d.%d.%d", bytep[0], bytep[1], bytep[2], bytep[3]);
	return buf;
}

static char *
addr_to_anyname(const struct in_addr *addr)
{
	char *name;

	if ((name = addr_to_host(addr)) != NULL ||
	    (name = addr_to_network(addr)) != NULL)
		return name;

	return addr_to_dotted(addr);
}

static char *
mask_to_dotted(const struct in_addr *mask)
{
	int i;
	static char buf[20];
	u_int32_t maskaddr, bits;

	maskaddr = ntohl(mask->s_addr);

	if (maskaddr == 0xFFFFFFFFL)
		/* we don't want to see "/32" */
		return "";

	i = 32;
	bits = 0xFFFFFFFEL;
	while (--i >= 0 && maskaddr != bits)
		bits <<= 1;
	if (i >= 0)
		sprintf(buf, "/%d", i);
	else
		/* mask was not a decent combination of 1's and 0's */
		sprintf(buf, "/%s", addr_to_dotted(mask));

	return buf;
}

int
string_to_number(const char *s, unsigned int min, unsigned int max,
		 unsigned int *ret)
{
	long number;
	char *end;

	/* Handle hex, octal, etc. */
	errno = 0;
	number = strtol(s, &end, 0);
	if (*end == '\0' && end != s) {
		/* we parsed a number, let's see if we want this */
		if (errno != ERANGE && min <= number && number <= max) {
			*ret = number;
			return 0;
		}
	}
	return -1;
}

static void
set_option(unsigned int *options, unsigned int option, u_int8_t *invflg,
	   int invert)
{
	if (*options & option)
		die("multiple -%c flags not allowed",
			   opt2char(option));
	*options |= option;

	if (invert) {
		unsigned int i;
		for (i = 0; 1 << i != option; i++);

		if (!inverse_for_options[i])
			die("cannot have ! before -%c",
				   opt2char(option));
		*invflg |= inverse_for_options[i];
	}
}

struct iptables_target *
find_target(const char *name, enum ipt_tryload tryload)
{
	struct iptables_target *ptr;

	/* Standard target? */
	if (strcmp(name, "") == 0
	    || strcmp(name, IPTC_LABEL_ACCEPT) == 0
	    || strcmp(name, IPTC_LABEL_DROP) == 0
	    || strcmp(name, IPTC_LABEL_QUEUE) == 0
	    || strcmp(name, IPTC_LABEL_RETURN) == 0)
		name = "standard";

	for (ptr = iptables_targets; ptr; ptr = ptr->next) {
		if (strcmp(name, ptr->name) == 0)
			break;
	}

#ifndef NO_SHARED_LIBS
	if (!ptr && tryload != DONT_LOAD) 
	{
		char path[sizeof(IPT_LIB_DIR) + sizeof("/libipt_.so") + strlen(name)];

		sprintf(path, IPT_LIB_DIR "/libipt_%s.so", name);
		if (dlopen(path, RTLD_NOW)) 
		{
			/* Found library.  If it didn't register itself,  maybe they specified match as a target. */
			ptr = find_target(name, DONT_LOAD);
			if (!ptr)
				warn("Couldn't load target `%s'\n", name);
		} else if (tryload == LOAD_MUST_SUCCEED) {
			die("Couldn't load target `%s':%s\n", name, dlerror());
		}
	}
#else
	if (ptr && !ptr->loaded) {
		if (tryload != DONT_LOAD)
			ptr->loaded = 1;
		else
			ptr = NULL;
	}
#endif

	if (ptr)
		ptr->used = 1;

	return ptr;
}

static struct option *
merge_options(struct option *oldopts, const struct option *newopts,
	      unsigned int *option_offset)
{
	unsigned int num_old, num_new, i;
	struct option *merge;

	for (num_old = 0; oldopts[num_old].name; num_old++);
	for (num_new = 0; newopts[num_new].name; num_new++);

	global_option_offset += OPTION_OFFSET;
	*option_offset = global_option_offset;

	merge = malloc(sizeof(struct option) * (num_new + num_old + 1));
	memcpy(merge, oldopts, num_old * sizeof(struct option));
	for (i = 0; i < num_new; i++) {
		merge[num_old + i] = newopts[i];
		merge[num_old + i].val += *option_offset;
	}
	memset(merge + num_old + num_new, 0, sizeof(struct option));

	return merge;
}

void
register_match(struct iptables_match *me)
{
	struct iptables_match **i;
/*
	if (strcmp(me->version, program_version) != 0) {
		fprintf(stderr, "%s: match `%s' v%s (I'm v%s).\n",
			program_name, me->name, me->version, program_version);
		exit(1);
	}
*/
	if (find_match(me->name, DONT_LOAD)) {
		fprintf(stderr, "%s: match `%s' already registered.\n",
			program_name, me->name);
		exit(1);
	}

	if (me->size != IPT_ALIGN(me->size)) {
		fprintf(stderr, "%s: match `%s' has invalid size %u.\n",
			program_name, me->name, me->size);
		exit(1);
	}

	/* Append to list. */
	for (i = &iptables_matches; *i; i = &(*i)->next);
	me->next = NULL;
	*i = me;

	me->m = NULL;
	me->mflags = 0;
}


extern void
register_target(struct iptables_target *me)
{
/*
	if (strcmp(me->version, program_version) != 0) {
		fprintf(stderr, "%s: target `%s' v%s (I'm v%s).\n",
			program_name, me->name, me->version, program_version);
		exit(1);
	}
*/
	if (find_target(me->name, DONT_LOAD)) {
		fprintf(stderr, "%s: target `%s' already registered.\n",
			program_name, me->name);
		exit(1);
	}

	if (me->size != IPT_ALIGN(me->size)) {
		fprintf(stderr, "%s: target `%s' has invalid size %u.\n",
			program_name, me->name, me->size);
		exit(1);
	}

	/* Prepend to list. */
	me->next = iptables_targets;
	iptables_targets = me;
	me->t = NULL;
	me->tflags = 0;
}

static void
print_num(u_int64_t number, unsigned int format)
{
	if (format & FMT_KILOMEGAGIGA) {
		if (number > 99999) {
			number = (number + 500) / 1000;
			if (number > 9999) {
				number = (number + 500) / 1000;
				if (number > 9999) {
					number = (number + 500) / 1000;
					if (number > 9999) {
						number = (number + 500) / 1000;
						printf(FMT("%4lluT ","%lluT "), number);
					}
					else printf(FMT("%4lluG ","%lluG "), number);
				}
				else printf(FMT("%4lluM ","%lluM "), number);
			} else
				printf(FMT("%4lluK ","%lluK "), number);
		} else
			printf(FMT("%5llu ","%llu "), number);
	} else
		printf(FMT("%8llu ","%llu "), number);
}


static void
print_header(unsigned int format, const char *chain, iptc_handle_t *handle)
{
	struct ipt_counters counters;
	const char *pol = iptc_get_policy(chain, &counters, handle);
	printf("Chain %s", chain);
	if (pol) {
		printf(" (policy %s", pol);
		if (!(format & FMT_NOCOUNTS)) {
			fputc(' ', stdout);
			print_num(counters.pcnt, (format|FMT_NOTABLE));
			fputs("packets, ", stdout);
			print_num(counters.bcnt, (format|FMT_NOTABLE));
			fputs("bytes", stdout);
		}
		printf(")\n");
	} else {
		unsigned int refs;
		if (!iptc_get_references(&refs, chain, handle))
			printf(" (ERROR obtaining refs)\n");
		else
			printf(" (%u references)\n", refs);
	}

	if (format & FMT_LINENUMBERS)
		printf(FMT("%-4s ", "%s "), "num");
	if (!(format & FMT_NOCOUNTS)) {
		if (format & FMT_KILOMEGAGIGA) {
			printf(FMT("%5s ","%s "), "pkts");
			printf(FMT("%5s ","%s "), "bytes");
		} else {
			printf(FMT("%8s ","%s "), "pkts");
			printf(FMT("%10s ","%s "), "bytes");
		}
	}
	if (!(format & FMT_NOTARGET))
		printf(FMT("%-9s ","%s "), "target");
	fputs(" prot ", stdout);
	if (format & FMT_OPTIONS)
		fputs("opt", stdout);
	if (format & FMT_VIA) {
		printf(FMT(" %-6s ","%s "), "in");
		printf(FMT("%-6s ","%s "), "out");
	}
	printf(FMT(" %-19s ","%s "), "source");
	printf(FMT(" %-19s "," %s "), "destination");
	printf("\n");
}


static int
print_match(const struct ipt_entry_match *m,
	    const struct ipt_ip *ip,
	    int numeric)
{
	struct iptables_match *match = find_match(m->u.user.name, TRY_LOAD);

	if (match) {
		if (match->print)
			match->print(ip, m, numeric);
		else
			printf("%s ", match->name);
	} else {
		if (m->u.user.name[0])
			printf("UNKNOWN match `%s' ", m->u.user.name);
	}
	/* Don't stop iterating. */
	return 0;
}


/* e is called `fw' here for hysterical raisins */
static void
print_firewall(const struct ipt_entry *fw,
	       const char *targname,
	       unsigned int num,
	       unsigned int format,
	       const iptc_handle_t handle)
{
	struct iptables_target *target = NULL;
	const struct ipt_entry_target *t;
	u_int8_t flags;
	char buf[BUFSIZ];

	/* User creates a chain called "REJECT": this overrides the
	   `REJECT' target module.  Keep feeding them rope until the
	   revolution... Bwahahahahah */

	if (!iptc_is_chain(targname, handle))
		target = find_target(targname, TRY_LOAD);
	else
		target = find_target(IPT_STANDARD_TARGET, DONT_LOAD);

	t = ipt_get_target((struct ipt_entry *)fw);
	flags = fw->ip.flags;

	if (format & FMT_LINENUMBERS)
		printf(FMT("%-4u ", "%u "), num+1);

	if (!(format & FMT_NOCOUNTS)) {
		print_num(fw->counters.pcnt, format);
		print_num(fw->counters.bcnt, format);
	}

	if (!(format & FMT_NOTARGET))
		printf(FMT("%-9s ", "%s "), targname);

	fputc(fw->ip.invflags & IPT_INV_PROTO ? '!' : ' ', stdout);
	{
		char *pname = proto_to_name(fw->ip.proto, format&FMT_NUMERIC);
		if (pname)
			printf(FMT("%-5s", "%s "), pname);
		else
			printf(FMT("%-5hu", "%hu "), fw->ip.proto);
	}

	if (format & FMT_OPTIONS) {
		if (format & FMT_NOTABLE)
			fputs("opt ", stdout);
		fputc(fw->ip.invflags & IPT_INV_FRAG ? '!' : '-', stdout);
		fputc(flags & IPT_F_FRAG ? 'f' : '-', stdout);
		fputc(' ', stdout);
	}

	if (format & FMT_VIA) {
		char iface[IFNAMSIZ+2];

		if (fw->ip.invflags & IPT_INV_VIA_IN) {
			iface[0] = '!';
			iface[1] = '\0';
		}
		else iface[0] = '\0';

		if (fw->ip.iniface[0] != '\0') {
			strcat(iface, fw->ip.iniface);
		}
		else if (format & FMT_NUMERIC) strcat(iface, "*");
		else strcat(iface, "any");
		printf(FMT(" %-6s ","in %s "), iface);

		if (fw->ip.invflags & IPT_INV_VIA_OUT) {
			iface[0] = '!';
			iface[1] = '\0';
		}
		else iface[0] = '\0';

		if (fw->ip.outiface[0] != '\0') {
			strcat(iface, fw->ip.outiface);
		}
		else if (format & FMT_NUMERIC) strcat(iface, "*");
		else strcat(iface, "any");
		printf(FMT("%-6s ","out %s "), iface);
	}

	fputc(fw->ip.invflags & IPT_INV_SRCIP ? '!' : ' ', stdout);
	if (fw->ip.smsk.s_addr == 0L && !(format & FMT_NUMERIC))
		printf(FMT("%-19s ","%s "), "anywhere");
	else {
		if (format & FMT_NUMERIC)
			sprintf(buf, "%s", addr_to_dotted(&(fw->ip.src)));
		else
			sprintf(buf, "%s", addr_to_anyname(&(fw->ip.src)));
		strcat(buf, mask_to_dotted(&(fw->ip.smsk)));
		printf(FMT("%-19s ","%s "), buf);
	}

	fputc(fw->ip.invflags & IPT_INV_DSTIP ? '!' : ' ', stdout);
	if (fw->ip.dmsk.s_addr == 0L && !(format & FMT_NUMERIC))
		printf(FMT("%-19s","-> %s"), "anywhere");
	else {
		if (format & FMT_NUMERIC)
			sprintf(buf, "%s", addr_to_dotted(&(fw->ip.dst)));
		else
			sprintf(buf, "%s", addr_to_anyname(&(fw->ip.dst)));
		strcat(buf, mask_to_dotted(&(fw->ip.dmsk)));
		printf(FMT("%-19s","-> %s"), buf);
	}

	if (format & FMT_NOTABLE)
		fputs("  ", stdout);

	IPT_MATCH_ITERATE(fw, print_match, &fw->ip, format & FMT_NUMERIC);

	if (target) {
		if (target->print)
			/* Print the target information. */
			target->print(&fw->ip, t, format & FMT_NUMERIC);
	} else if (t->u.target_size != sizeof(*t))
		printf("[%u bytes of unknown target data] ",
		       t->u.target_size - sizeof(*t));

	if (!(format & FMT_NONEWLINE))
		fputc('\n', stdout);
}

static void
print_firewall_line(const struct ipt_entry *fw,
		    const iptc_handle_t h)
{
	struct ipt_entry_target *t;

	t = ipt_get_target((struct ipt_entry *)fw);
	print_firewall(fw, t->u.user.name, 0, FMT_PRINT_RULE, h);
}

static int
append_entry(const ipt_chainlabel chain,
	     struct ipt_entry *fw,
	     unsigned int nsaddrs,
	     const struct in_addr saddrs[],
	     unsigned int ndaddrs,
	     const struct in_addr daddrs[],
	     int verbose,
	     iptc_handle_t *handle)
{
	unsigned int i, j;
	int ret = 1;

	for (i = 0; i < nsaddrs; i++) {
		fw->ip.src.s_addr = saddrs[i].s_addr;
		for (j = 0; j < ndaddrs; j++) {
			fw->ip.dst.s_addr = daddrs[j].s_addr;
			if (verbose)
				print_firewall_line(fw, *handle);

			ret &= iptc_append_entry(chain, fw, handle);
		}
	}

	return ret;
}

static int
replace_entry(const ipt_chainlabel chain,
	      struct ipt_entry *fw,
	      unsigned int rulenum,
	      const struct in_addr *saddr,
	      const struct in_addr *daddr,
	      int verbose,
	      iptc_handle_t *handle)
{
	fw->ip.src.s_addr = saddr->s_addr;
	fw->ip.dst.s_addr = daddr->s_addr;

	if (verbose)
		print_firewall_line(fw, *handle);
	return iptc_replace_entry(chain, fw, rulenum, handle);
}

static int
insert_entry(const ipt_chainlabel chain,
	     struct ipt_entry *fw,
	     unsigned int rulenum,
	     unsigned int nsaddrs,
	     const struct in_addr saddrs[],
	     unsigned int ndaddrs,
	     const struct in_addr daddrs[],
	     int verbose,
	     iptc_handle_t *handle)
{
	unsigned int i, j;
	int ret = 1;

	for (i = 0; i < nsaddrs; i++) {
		fw->ip.src.s_addr = saddrs[i].s_addr;
		for (j = 0; j < ndaddrs; j++) {
			fw->ip.dst.s_addr = daddrs[j].s_addr;
			if (verbose)
				print_firewall_line(fw, *handle);
			ret &= iptc_insert_entry(chain, fw, rulenum, handle);
		}
	}

	return ret;
}

static unsigned char *
make_delete_mask(struct ipt_entry *fw)
{
	/* Establish mask for comparison */
	unsigned int size;
	struct iptables_match *m;
	unsigned char *mask, *mptr;

	size = sizeof(struct ipt_entry);
	for (m = iptables_matches; m; m = m->next) {
		if (!m->used)
			continue;

		size += IPT_ALIGN(sizeof(struct ipt_entry_match)) + m->size;
	}

	mask = fw_calloc(1, size
			 + IPT_ALIGN(sizeof(struct ipt_entry_target))
			 + iptables_targets->size);

	memset(mask, 0xFF, sizeof(struct ipt_entry));
	mptr = mask + sizeof(struct ipt_entry);

	for (m = iptables_matches; m; m = m->next) {
		if (!m->used)
			continue;

		memset(mptr, 0xFF,
		       IPT_ALIGN(sizeof(struct ipt_entry_match))
		       + m->userspacesize);
		mptr += IPT_ALIGN(sizeof(struct ipt_entry_match)) + m->size;
	}

	memset(mptr, 0xFF,
	       IPT_ALIGN(sizeof(struct ipt_entry_target))
	       + iptables_targets->userspacesize);

	return mask;
}

static int
delete_entry(const ipt_chainlabel chain,
	     struct ipt_entry *fw,
	     unsigned int nsaddrs,
	     const struct in_addr saddrs[],
	     unsigned int ndaddrs,
	     const struct in_addr daddrs[],
	     int verbose,
	     iptc_handle_t *handle)
{
	unsigned int i, j;
	int ret = 1;
	unsigned char *mask;

	mask = make_delete_mask(fw);
	for (i = 0; i < nsaddrs; i++) {
		fw->ip.src.s_addr = saddrs[i].s_addr;
		for (j = 0; j < ndaddrs; j++) {
			fw->ip.dst.s_addr = daddrs[j].s_addr;
			if (verbose)
				print_firewall_line(fw, *handle);
			ret &= iptc_delete_entry(chain, fw, mask, handle);
		}
	}
	return ret;
}

static int
check_packet(const ipt_chainlabel chain,
	     struct ipt_entry *fw,
	     unsigned int nsaddrs,
	     const struct in_addr saddrs[],
	     unsigned int ndaddrs,
	     const struct in_addr daddrs[],
	     int verbose,
	     iptc_handle_t *handle)
{
	int ret = 1;
	unsigned int i, j;
	const char *msg;

	for (i = 0; i < nsaddrs; i++) {
		fw->ip.src.s_addr = saddrs[i].s_addr;
		for (j = 0; j < ndaddrs; j++) {
			fw->ip.dst.s_addr = daddrs[j].s_addr;
			if (verbose)
				print_firewall_line(fw, *handle);
			msg = iptc_check_packet(chain, fw, handle);
			if (!msg) ret = 0;
			else printf("%s\n", msg);
		}
	}

	return ret;
}

int
for_each_chain(int (*fn)(const ipt_chainlabel, int, iptc_handle_t *),
	       int verbose, int builtinstoo, iptc_handle_t *handle)
{
        int ret = 1;
	const char *chain;
	char *chains;
	unsigned int i, chaincount = 0;

	chain = iptc_first_chain(handle);
	while (chain) {
		chaincount++;
		chain = iptc_next_chain(handle);
        }

	chains = fw_malloc(sizeof(ipt_chainlabel) * chaincount);
	i = 0;
	chain = iptc_first_chain(handle);
	while (chain) {
		strcpy(chains + i*sizeof(ipt_chainlabel), chain);
		i++;
		chain = iptc_next_chain(handle);
        }

	for (i = 0; i < chaincount; i++) {
		if (!builtinstoo
		    && iptc_builtin(chains + i*sizeof(ipt_chainlabel),
				    *handle))
			continue;
	        ret &= fn(chains + i*sizeof(ipt_chainlabel), verbose, handle);
	}

	free(chains);
        return ret;
}

int
flush_entries(const ipt_chainlabel chain, int verbose,
	      iptc_handle_t *handle)
{
	if (!chain)
		return for_each_chain(flush_entries, verbose, 1, handle);

	if (verbose)
		fprintf(stdout, "Flushing chain `%s'\n", chain);
	return iptc_flush_entries(chain, handle);
}

static int
zero_entries(const ipt_chainlabel chain, int verbose,
	     iptc_handle_t *handle)
{
	if (!chain)
		return for_each_chain(zero_entries, verbose, 1, handle);

	if (verbose)
		fprintf(stdout, "Zeroing chain `%s'\n", chain);
	return iptc_zero_entries(chain, handle);
}

int
delete_chain(const ipt_chainlabel chain, int verbose,
	     iptc_handle_t *handle)
{
	if (!chain)
		return for_each_chain(delete_chain, verbose, 0, handle);

	if (verbose)
	        fprintf(stdout, "Deleting chain `%s'\n", chain);
	return iptc_delete_chain(chain, handle);
}

static int
list_entries(const ipt_chainlabel chain, int verbose, int numeric,
	     int expanded, int linenumbers, iptc_handle_t *handle)
{
	int found = 0;
	unsigned int format;
	const char *this;

	format = FMT_OPTIONS;
	if (!verbose)
		format |= FMT_NOCOUNTS;
	else
		format |= FMT_VIA;

	if (numeric)
		format |= FMT_NUMERIC;

	if (!expanded)
		format |= FMT_KILOMEGAGIGA;

	if (linenumbers)
		format |= FMT_LINENUMBERS;

	for (this = iptc_first_chain(handle);
	     this;
	     this = iptc_next_chain(handle)) {
		const struct ipt_entry *i;
		unsigned int num;

		if (chain && strcmp(chain, this) != 0)
			continue;

		if (found) printf("\n");

		print_header(format, this, handle);
		i = iptc_first_rule(this, handle);

		num = 0;
		while (i) {
			print_firewall(i,
				       iptc_get_target(i, handle),
				       num++,
				       format,
				       *handle);
			i = iptc_next_rule(i, handle);
		}
		found = 1;
	}

	errno = ENOENT;
	return found;
}

static char *get_modprobe(void)
{
	int procfile;
	char *ret;

	procfile = open(PROC_SYS_MODPROBE, O_RDONLY);
	if (procfile < 0)
		return NULL;

	ret = malloc(1024);
	if (ret) {
		switch (read(procfile, ret, 1024)) {
		case -1: goto fail;
		case 1024: goto fail; /* Partial read.  Wierd */
		}
		if (ret[strlen(ret)-1]=='\n') 
			ret[strlen(ret)-1]=0;
		close(procfile);
		return ret;
	}
 fail:
	free(ret);
	close(procfile);
	return NULL;
}

int iptables_insmod(const char *modname, const char *modprobe)
{
	char *buf = NULL;
	char *argv[3];

	/* If they don't explicitly set it, read out of kernel */
	if (!modprobe) {
		buf = get_modprobe();
		if (!buf)
			return -1;
		modprobe = buf;
	}

	printf("Warning: FORKING!\n");

	switch (fork()) 
	{
	case 0:
		argv[0] = (char *)modprobe;
		argv[1] = (char *)modname;
		argv[2] = NULL;
		execv(argv[0], argv);

		/* not usually reached */
		exit(0);
	case -1:
		return -1;

	default: /* parent */
		wait(NULL);
	}

	free(buf);
	return 0;
}

static struct ipt_entry *
generate_entry(const struct ipt_entry *fw,
	       struct iptables_match *matches,
	       struct ipt_entry_target *target)
{
	unsigned int size;
	struct iptables_match *m;
	struct ipt_entry *e;

	size = sizeof(struct ipt_entry);
	for (m = matches; m; m = m->next) {
		if (!m->used)
			continue;

		size += m->m->u.match_size;
	}

	e = fw_malloc(size + target->u.target_size);
	*e = *fw;
	e->target_offset = size;
	e->next_offset = size + target->u.target_size;

	size = 0;
	for (m = matches; m; m = m->next) {
		if (!m->used)
			continue;

		memcpy(e->elems + size, m->m, m->m->u.match_size);
		size += m->m->u.match_size;
	}
	memcpy(e->elems + size, target, target->u.target_size);

	return e;
}

int do_command(int argc, char *argv[], char **table, iptc_handle_t *handle)
{
	struct ipt_entry fw, *e = NULL;
	int invert = 0;
	unsigned int nsaddrs = 0, ndaddrs = 0;
	struct in_addr *saddrs = NULL, *daddrs = NULL;

	int c, verbose = 0;
	const char *chain = NULL;
	const char *shostnetworkmask = NULL, *dhostnetworkmask = NULL;
	const char *policy = NULL, *newname = NULL;
	unsigned int rulenum = 0, options = 0, command = 0;
	const char *pcnt = NULL, *bcnt = NULL;
	int ret = 1;
	struct iptables_match *m;
	struct iptables_target *target = NULL;
	struct iptables_target *t;
	const char *jumpto = "";
	char *protocol = NULL;
	const char *modprobe = NULL;

	memset(&fw, 0, sizeof(fw));

	opts = original_opts;
	global_option_offset = 0;

	/* re-set optind to 0 in case do_command gets called
	 * a second time */
	optind = 0;

	/* clear mflags in case do_command gets called a second time
	 * (we clear the global list of all matches for security)*/
	for (m = iptables_matches; m; m = m->next) {
		m->mflags = 0;
		m->used = 0;
	}

	for (t = iptables_targets; t; t = t->next) {
		t->tflags = 0;
		t->used = 0;
	}

	/* Suppress error messages: we may add new options if we
           demand-load a protocol. */
	opterr = 0;

	while ((c = getopt_long(argc, argv,
	   "-A:C:D:R:I:L::F::Z::N:X::E:P:Vh::o:p:s:d:j:i:fbvnt:m:xc:",
					   opts, NULL)) != -1) {
		switch (c) {
			/*
			 * Command selection
			 */
		case 'A':
			add_command(&command, CMD_APPEND, CMD_NONE,
				    invert);
			chain = optarg;
			break;

		case 'D':
			add_command(&command, CMD_DELETE, CMD_NONE,
				    invert);
			chain = optarg;
			if (optind < argc && argv[optind][0] != '-'
			    && argv[optind][0] != '!') {
				rulenum = parse_rulenumber(argv[optind++]);
				command = CMD_DELETE_NUM;
			}
			break;

		case 'C':
			add_command(&command, CMD_CHECK, CMD_NONE,
				    invert);
			chain = optarg;
			break;

		case 'R':
			add_command(&command, CMD_REPLACE, CMD_NONE,
				    invert);
			chain = optarg;
			if (optind < argc && argv[optind][0] != '-'
			    && argv[optind][0] != '!')
				rulenum = parse_rulenumber(argv[optind++]);
			else
				die("-%c requires a rule number",
					   cmd2char(CMD_REPLACE));
			break;

		case 'I':
			add_command(&command, CMD_INSERT, CMD_NONE,
				    invert);
			chain = optarg;
			if (optind < argc && argv[optind][0] != '-'
			    && argv[optind][0] != '!')
				rulenum = parse_rulenumber(argv[optind++]);
			else rulenum = 1;
			break;

		case 'L':
			add_command(&command, CMD_LIST, CMD_ZERO,
				    invert);
			if (optarg) chain = optarg;
			else if (optind < argc && argv[optind][0] != '-'
				 && argv[optind][0] != '!')
				chain = argv[optind++];
			break;

		case 'F':
			add_command(&command, CMD_FLUSH, CMD_NONE,
				    invert);
			if (optarg) chain = optarg;
			else if (optind < argc && argv[optind][0] != '-'
				 && argv[optind][0] != '!')
				chain = argv[optind++];
			break;

		case 'Z':
			add_command(&command, CMD_ZERO, CMD_LIST,
				    invert);
			if (optarg) chain = optarg;
			else if (optind < argc && argv[optind][0] != '-'
				&& argv[optind][0] != '!')
				chain = argv[optind++];
			break;

		case 'N':
			add_command(&command, CMD_NEW_CHAIN, CMD_NONE,
				    invert);
			chain = optarg;
			break;

		case 'X':
			add_command(&command, CMD_DELETE_CHAIN, CMD_NONE,
				    invert);
			if (optarg) chain = optarg;
			else if (optind < argc && argv[optind][0] != '-'
				 && argv[optind][0] != '!')
				chain = argv[optind++];
			break;

		case 'E':
			add_command(&command, CMD_RENAME_CHAIN, CMD_NONE,
				    invert);
			chain = optarg;
			if (optind < argc && argv[optind][0] != '-'
			    && argv[optind][0] != '!')
				newname = argv[optind++];
			else
				die("-%c requires old-chain-name and "
					   "new-chain-name",
					    cmd2char(CMD_RENAME_CHAIN));
			break;

		case 'P':
			add_command(&command, CMD_SET_POLICY, CMD_NONE,
				    invert);
			chain = optarg;
			if (optind < argc && argv[optind][0] != '-'
			    && argv[optind][0] != '!')
				policy = argv[optind++];
			else
				die("-%c requires a chain and a policy",
					   cmd2char(CMD_SET_POLICY));
			break;

		case 'h':
			if (!optarg)
				optarg = argv[optind];

			/* iptables -p icmp -h */
			if (!iptables_matches && protocol)
				find_match(protocol, TRY_LOAD);

			exit_printhelp();

			/*
			 * Option selection
			 */
		case 'p':
			if (check_inverse(optarg, &invert, &optind, 0))
				optind++;
			set_option(&options, OPT_PROTOCOL, &fw.ip.invflags,
				   invert);

			/* Canonicalize into lower case */
			for (protocol = argv[optind-1]; *protocol; protocol++)
				*protocol = tolower(*protocol);

			protocol = argv[optind-1];
			fw.ip.proto = parse_protocol(protocol);

			if (fw.ip.proto == 0
			    && (fw.ip.invflags & IPT_INV_PROTO))
				die("rule would never match protocol");
			fw.nfcache |= NFC_IP_PROTO;
			break;

		case 's':
			if (check_inverse(optarg, &invert, &optind, 0))
				optind++;
			set_option(&options, OPT_SOURCE, &fw.ip.invflags,
				   invert);
			shostnetworkmask = argv[optind-1];
			fw.nfcache |= NFC_IP_SRC;
			break;

		case 'd':
			if (check_inverse(optarg, &invert, &optind, 0))
				optind++;
			set_option(&options, OPT_DESTINATION, &fw.ip.invflags,
				   invert);
			dhostnetworkmask = argv[optind-1];
			fw.nfcache |= NFC_IP_DST;
			break;

		case 'j':
			set_option(&options, OPT_JUMP, &fw.ip.invflags,
				   invert);
			jumpto = parse_target(optarg);
			/* TRY_LOAD (may be chain name) */
			target = find_target(jumpto, TRY_LOAD);

			if (target) {
				size_t size;

				size = IPT_ALIGN(sizeof(struct ipt_entry_target))
					+ target->size;

				target->t = fw_calloc(1, size);
				target->t->u.target_size = size;
				strcpy(target->t->u.user.name, jumpto);
				target->init(target->t, &fw.nfcache);
				opts = merge_options(opts, target->extra_opts, &target->option_offset);
			}
			break;


		case 'i':
			if (check_inverse(optarg, &invert, &optind, 0))
				optind++;
			set_option(&options, OPT_VIANAMEIN, &fw.ip.invflags,
				   invert);
			parse_interface(argv[optind-1],
					fw.ip.iniface,
					fw.ip.iniface_mask);
			fw.nfcache |= NFC_IP_IF_IN;
			break;

		case 'o':
			if (check_inverse(optarg, &invert, &optind, 0))
				optind++;
			set_option(&options, OPT_VIANAMEOUT, &fw.ip.invflags,
				   invert);
			parse_interface(argv[optind-1],
					fw.ip.outiface,
					fw.ip.outiface_mask);
			fw.nfcache |= NFC_IP_IF_OUT;
			break;

		case 'f':
			set_option(&options, OPT_FRAGMENT, &fw.ip.invflags,
				   invert);
			fw.ip.flags |= IPT_F_FRAG;
			fw.nfcache |= NFC_IP_FRAG;
			break;

		case 'v':
			if (!verbose)
				set_option(&options, OPT_VERBOSE,
					   &fw.ip.invflags, invert);
			verbose++;
			break;

		case 'm': {
			size_t size;

			if (invert)
				die("unexpected ! flag before --match");

			m = find_match(optarg, LOAD_MUST_SUCCEED);
			size = IPT_ALIGN(sizeof(struct ipt_entry_match))
					 + m->size;
			m->m = fw_calloc(1, size);
			m->m->u.match_size = size;
			strcpy(m->m->u.user.name, m->name);
			m->init(m->m, &fw.nfcache);
			opts = merge_options(opts, m->extra_opts, &m->option_offset);
		}
		break;

		case 'n':
			set_option(&options, OPT_NUMERIC, &fw.ip.invflags,
				   invert);
			break;

		case 't':
			if (invert)
				die("unexpected ! flag before --table");
			*table = argv[optind-1];
			break;

		case 'x':
			set_option(&options, OPT_EXPANDED, &fw.ip.invflags,
				   invert);
			break;

		case 'V':
			if (invert)
				printf("Not %s ;-)\n", program_version);
			else
				printf("%s v%s\n",
				       program_name, program_version);
			exit(0);

		case '0':
			set_option(&options, OPT_LINENUMBERS, &fw.ip.invflags,
				   invert);
			break;

		case 'M':
			modprobe = optarg;
			break;

		case 'c':

			set_option(&options, OPT_COUNTERS, &fw.ip.invflags,
				   invert);
			pcnt = optarg;
			if (optind < argc && argv[optind][0] != '-'
			    && argv[optind][0] != '!')
				bcnt = argv[optind++];
			else
				die("-%c requires packet and byte counter",
					opt2char(OPT_COUNTERS));

			if (sscanf(pcnt, "%llu", &fw.counters.pcnt) != 1)
				die("-%c packet counter not numeric",
					opt2char(OPT_COUNTERS));

			if (sscanf(bcnt, "%llu", &fw.counters.bcnt) != 1)
				die("-%c byte counter not numeric",
					opt2char(OPT_COUNTERS));
			
			break;


		case 1: /* non option */
			if (optarg[0] == '!' && optarg[1] == '\0') {
				if (invert)
					die("multiple consecutive ! not"
						   " allowed");
				invert = TRUE;
				optarg[0] = '\0';
				continue;
			}
			printf("Bad argument `%s'\n", optarg);
			exit_tryhelp(2);

		default:
			/* FIXME: This scheme doesn't allow two of the same
			   matches --RR */
			if (!target
			    || !(target->parse(c - target->option_offset,
					       argv, invert,
					       &target->tflags,
					       &fw, &target->t))) {
				for (m = iptables_matches; m; m = m->next) {
					if (!m->used)
						continue;

					if (m->parse(c - m->option_offset,
						     argv, invert,
						     &m->mflags,
						     &fw,
						     &fw.nfcache,
						     &m->m))
						break;
				}

				/* If you listen carefully, you can
				   actually hear this code suck. */
				if (m == NULL
				    && protocol
				    && !find_proto(protocol, DONT_LOAD,
						   options&OPT_NUMERIC)
				    && (m = find_proto(protocol, TRY_LOAD,
						       options&OPT_NUMERIC))) {
					/* Try loading protocol */
					size_t size;

					size = IPT_ALIGN(sizeof(struct ipt_entry_match))
							 + m->size;

					m->m = fw_calloc(1, size);
					m->m->u.match_size = size;
					strcpy(m->m->u.user.name, m->name);
					m->init(m->m, &fw.nfcache);

					opts = merge_options(opts,
					    m->extra_opts, &m->option_offset);

					optind--;
					continue;
				}
				if (!m)
					die( "Unknown arg `%s'",
						   argv[optind-1]);
			}
		}
		invert = FALSE;
	}

	for (m = iptables_matches; m; m = m->next) {
		if (!m->used)
			continue;

		m->final_check(m->mflags);
	}

	if (target)
		target->final_check(target->tflags);

	/* Fix me: must put inverse options checking here --MN */

	if (optind < argc)
		exit_error(PARAMETER_PROBLEM,
			   "unknown arguments found on commandline");
	if (!command)
		exit_error(PARAMETER_PROBLEM, "no command specified");
	if (invert)
		exit_error(PARAMETER_PROBLEM,
			   "nothing appropriate following !");

	if (command & (CMD_REPLACE | CMD_INSERT | CMD_DELETE | CMD_APPEND |
	    CMD_CHECK)) {
		if (!(options & OPT_DESTINATION))
			dhostnetworkmask = "0.0.0.0/0";
		if (!(options & OPT_SOURCE))
			shostnetworkmask = "0.0.0.0/0";
	}

	if (shostnetworkmask)
		parse_hostnetworkmask(shostnetworkmask, &saddrs,
				      &(fw.ip.smsk), &nsaddrs);

	if (dhostnetworkmask)
		parse_hostnetworkmask(dhostnetworkmask, &daddrs,
				      &(fw.ip.dmsk), &ndaddrs);

	if ((nsaddrs > 1 || ndaddrs > 1) &&
	    (fw.ip.invflags & (IPT_INV_SRCIP | IPT_INV_DSTIP)))
		exit_error(PARAMETER_PROBLEM, "! not allowed with multiple"
			   " source or destination IP addresses");

	if (command == CMD_CHECK && fw.ip.invflags != 0)
		exit_error(PARAMETER_PROBLEM, "! not allowed with -%c",
			   cmd2char(CMD_CHECK));

	if (command == CMD_REPLACE && (nsaddrs != 1 || ndaddrs != 1))
		exit_error(PARAMETER_PROBLEM, "Replacement rule does not "
			   "specify a unique address");

	generic_opt_check(command, options);

	if (chain && strlen(chain) > IPT_FUNCTION_MAXNAMELEN)
		exit_error(PARAMETER_PROBLEM,
			   "chain name `%s' too long (must be under %i chars)",
			   chain, IPT_FUNCTION_MAXNAMELEN);

	/* only allocate handle if we weren't called with a handle */
	if (!*handle)
		*handle = iptc_init(*table);

	if (!*handle) {
		/* try to insmod the module if iptc_init failed */
		iptables_insmod("ip_tables", modprobe);
		*handle = iptc_init(*table);
	}

	if (!*handle)
		exit_error(VERSION_PROBLEM,
			   "can't initialize iptables table `%s': %s",
			   *table, iptc_strerror(errno));

	if (command == CMD_CHECK
	    || command == CMD_APPEND
	    || command == CMD_DELETE
	    || command == CMD_INSERT
	    || command == CMD_REPLACE) {
		if (strcmp(chain, "PREROUTING") == 0
		    || strcmp(chain, "INPUT") == 0) {
			/* -o not valid with incoming packets. */
			if (options & OPT_VIANAMEOUT)
				exit_error(PARAMETER_PROBLEM,
					   "Can't use -%c with %s\n",
					   opt2char(OPT_VIANAMEOUT),
					   chain);
			/* -i required with -C */
			if (command == CMD_CHECK && !(options & OPT_VIANAMEIN))
				exit_error(PARAMETER_PROBLEM,
					   "Need -%c with %s\n",
					   opt2char(OPT_VIANAMEIN),
					   chain);
		}

		if (strcmp(chain, "POSTROUTING") == 0
		    || strcmp(chain, "OUTPUT") == 0) {
			/* -i not valid with outgoing packets */
			if (options & OPT_VIANAMEIN)
				exit_error(PARAMETER_PROBLEM,
					   "Can't use -%c with %s\n",
					   opt2char(OPT_VIANAMEIN),
					   chain);
			/* -o required with -C */
			if (command == CMD_CHECK && !(options&OPT_VIANAMEOUT))
				exit_error(PARAMETER_PROBLEM,
					   "Need -%c with %s\n",
					   opt2char(OPT_VIANAMEOUT),
					   chain);
		}

		if (target && iptc_is_chain(jumpto, *handle)) {
			printf("Warning: using chain %s, not extension\n",
			       jumpto);

			target = NULL;
		}

		/* If they didn't specify a target, or it's a chain
		   name, use standard. */
		if (!target
		    && (strlen(jumpto) == 0
			|| iptc_is_chain(jumpto, *handle))) {
			size_t size;

			target = find_target(IPT_STANDARD_TARGET,
					     LOAD_MUST_SUCCEED);

			size = sizeof(struct ipt_entry_target)
				+ target->size;
			target->t = fw_calloc(1, size);
			target->t->u.target_size = size;
			strcpy(target->t->u.user.name, jumpto);
			target->init(target->t, &fw.nfcache);
		}

		if (!target) {
			/* it is no chain, and we can't load a plugin.
			 * We cannot know if the plugin is corrupt, non
			 * existant OR if the user just misspelled a
			 * chain. */
			find_target(jumpto, LOAD_MUST_SUCCEED);
		} else {
			e = generate_entry(&fw, iptables_matches, target->t);
		}
	}

	switch (command) {
	case CMD_APPEND:
		ret = append_entry(chain, e,
				   nsaddrs, saddrs, ndaddrs, daddrs,
				   options&OPT_VERBOSE,
				   handle);
		break;
	case CMD_CHECK:
		ret = check_packet(chain, e,
				   nsaddrs, saddrs, ndaddrs, daddrs,
				   options&OPT_VERBOSE, handle);
		break;
	case CMD_DELETE:
		ret = delete_entry(chain, e,
				   nsaddrs, saddrs, ndaddrs, daddrs,
				   options&OPT_VERBOSE,
				   handle);
		break;
	case CMD_DELETE_NUM:
		ret = iptc_delete_num_entry(chain, rulenum - 1, handle);
		break;
	case CMD_REPLACE:
		ret = replace_entry(chain, e, rulenum - 1,
				    saddrs, daddrs, options&OPT_VERBOSE,
				    handle);
		break;
	case CMD_INSERT:
		ret = insert_entry(chain, e, rulenum - 1,
				   nsaddrs, saddrs, ndaddrs, daddrs,
				   options&OPT_VERBOSE,
				   handle);
		break;
	case CMD_LIST:
		ret = list_entries(chain,
				   options&OPT_VERBOSE,
				   options&OPT_NUMERIC,
				   options&OPT_EXPANDED,
				   options&OPT_LINENUMBERS,
				   handle);
		break;
	case CMD_FLUSH:
		ret = flush_entries(chain, options&OPT_VERBOSE, handle);
		break;
	case CMD_ZERO:
		ret = zero_entries(chain, options&OPT_VERBOSE, handle);
		break;
	case CMD_LIST|CMD_ZERO:
		ret = list_entries(chain,
				   options&OPT_VERBOSE,
				   options&OPT_NUMERIC,
				   options&OPT_EXPANDED,
				   options&OPT_LINENUMBERS,
				   handle);
		if (ret)
			ret = zero_entries(chain,
					   options&OPT_VERBOSE, handle);
		break;
	case CMD_NEW_CHAIN:
		ret = iptc_create_chain(chain, handle);
		break;
	case CMD_DELETE_CHAIN:
		ret = delete_chain(chain, options&OPT_VERBOSE, handle);
		break;
	case CMD_RENAME_CHAIN:
		ret = iptc_rename_chain(chain, newname,	handle);
		break;
	case CMD_SET_POLICY:
		ret = iptc_set_policy(chain, policy, NULL, handle);
		break;
	default:
		/* We should never reach this... */
		exit_tryhelp(2);
	}

	if (verbose > 1)
		dump_entries(*handle);

	return ret;
}



/* And this is the main function... */

/*
int
main(int argc, char *argv[])
{
    int ret;
    char *table = "filter";
    iptc_handle_t handle = NULL;

    program_name = "IPTables";
    program_version = XS_VERSION;

#ifdef NO_SHARED_LIBS
    init_extensions();
#endif

    ret = do_command(argc, argv, &table, &handle);
    if (ret)
        ret = iptc_commit(&handle);

    if (!ret)
        fprintf(stderr, "iptables: %s\n",
            iptc_strerror(errno));

    exit(!ret);
}
*/

/* ------ END SRC ------ */

/* Which ends here.... */

static double
constant(name, arg)
char *name;
int arg;
{
    errno = 0;
	if (strcmp(name, "IFNAMSIZ") == 0)
		return IFNAMSIZ; 
	if (strcmp(name, "IPT_TABLE_MAXNAMELEN") == 0)
		return IPT_TABLE_MAXNAMELEN; 

	if (strcmp(name, "IPT_F_FRAG") == 0)
		return IPT_F_FRAG; 
	if (strcmp(name, "IPT_F_MASK") == 0)
		return IPT_F_MASK; 

	if (strcmp(name, "IPT_INV_VIA_IN") == 0)
		return IPT_INV_VIA_IN; 
	if (strcmp(name, "IPT_INV_VIA_OUT") == 0)
		return IPT_INV_VIA_OUT; 
	if (strcmp(name, "IPT_INV_TOS") == 0)
		return IPT_INV_TOS; 
	if (strcmp(name, "IPT_INV_SRCIP") == 0)
		return IPT_INV_SRCIP; 
	if (strcmp(name, "IPT_INV_DSTIP") == 0)
		return IPT_INV_DSTIP; 
	if (strcmp(name, "IPT_INV_FRAG") == 0)
		return IPT_INV_FRAG; 
	if (strcmp(name, "IPT_INV_PROTO") == 0)
		return IPT_INV_PROTO; 
	if (strcmp(name, "IPT_INV_MASK") == 0)
		return IPT_INV_MASK; 

	errno = EINVAL;
	return 0;

not_there:
    errno = ENOENT;
    return 0;
}

typedef const struct ipt_entry entry;
typedef struct ipt_entry entry_n;
typedef iptc_handle_t handle;
typedef const struct ipt_entry_target target;

typedef const struct iptables_target target_z;

typedef struct iptables_match match;

typedef struct iptxs_entry_t
{
	entry_n			*e;	/* Pointer to the C Entry */
	iptc_handle_t	*h;	/* the Handle */
	char			chain[sizeof(ipt_chainlabel)];
} iptxs_entry;

typedef struct iptxs_target_t
{
	target_z		*t;	/* Pointer to the C Entry */
	iptc_handle_t	*h;	/* the Handle */
	iptxs_entry		*e; /* The current entry... */
} iptxs_target;


static int
save(const struct ipt_entry_match *m,
	    const struct ipt_ip *ip,
	    int numeric)
{
	struct iptables_match *match = find_match(m->u.user.name, TRY_LOAD);

	if (match) {
		if (match->save)
			match->save(ip, m);
		else
			printf("%s", match->name);
	} else {
		if (m->u.user.name[0])
			printf("UNKNOWN match `%s' ", m->u.user.name);
	}
	/* Don't stop iterating. */
	return 0;
}



MODULE = IPTables       PACKAGE = IPTables

double
constant(name,arg)
    char    *name
    int arg

iptc_handle_t *
_init_xs(table)
	char *table;
	PREINIT:
		iptc_handle_t * handle;
		char *modprobe = NULL;
	CODE:
		program_name = "IPTables";
		program_version = XS_VERSION;

		RETVAL = (iptc_handle_t *) safemalloc(sizeof(iptc_handle_t));
		if (RETVAL == NULL)
		{
			warn("Unable to safemalloc() to allocate entry for handle.\n");
			XSRETURN_UNDEF;
		}

		*RETVAL = iptc_init(table);

		if (!*RETVAL) 
		{
			warn("Initial _init failed, trying to insmod\n");
			iptables_insmod("ip_tables", modprobe);
			*RETVAL = iptc_init(table);
		}

		if (!*RETVAL || RETVAL == NULL)
		{
			Safefree(RETVAL);
			warn("Error initialising IPTables table '%s': '%s'\n", table, iptc_strerror(errno));
			XSRETURN_UNDEF;
		}

	OUTPUT:
		RETVAL

int
iptc_builtin(h, chain)
	iptc_handle_t * h;
	const char * chain;
	CODE:
		RETVAL = iptc_builtin(chain, *h);
	OUTPUT:
		RETVAL

const char *
iptc_first_chain(h)
    iptc_handle_t * h;
	CODE:
		if (h == NULL)
			XSRETURN_UNDEF;

		RETVAL = iptc_first_chain(h);
	OUTPUT:
		RETVAL


const char *
iptc_next_chain(h)
    iptc_handle_t * h;
	CODE:
        if (h == NULL)
        {
            warn("handle has gone away\n");
            XSRETURN_UNDEF;
        }

		RETVAL = iptc_next_chain(h);
	OUTPUT:
	RETVAL



void
iptc_get_policy(handle, chain)
        const char * chain;
        iptc_handle_t * handle;
    PREINIT:
        struct ipt_counters count;
        char buf[64];
    PPCODE:
		if (!iptc_builtin(chain, *handle))
			XSRETURN_UNDEF;
        XPUSHs(sv_2mortal(newSVpv(iptc_get_policy(chain, &count, handle), 0)));
        sprintf(buf, "%lu", count.pcnt);
        XPUSHs(sv_2mortal(newSVpv(buf, strlen(buf))));
        sprintf(buf, "%lu", count.bcnt);
        XPUSHs(sv_2mortal(newSVpv(buf, strlen(buf))));


iptxs_entry *
iptc_first_rule(h, chain)
	const char * chain;
	iptc_handle_t * h;	
	PREINIT:
		char *CLASS = "IPTables::Entry";
	CODE:
		RETVAL = (iptxs_entry *) safemalloc(sizeof(iptxs_entry));
		if (RETVAL == NULL)
        {
        	warn("Unable to allocate entry\n");
        	XSRETURN_UNDEF;
        }
		RETVAL->e = (entry_n *) iptc_first_rule(chain, h);
		if (RETVAL->e == NULL)
		{
			Safefree(RETVAL);
			XSRETURN_UNDEF;
		}
		strcpy(RETVAL->chain, chain);
		RETVAL->h = h;
	OUTPUT:
		RETVAL


int
iptc_commit(h, table)
		iptc_handle_t * h;
		char *table;
	CODE:
		RETVAL = iptc_commit(h);

		if (RETVAL == 0)
		{
			warn("Warning: commit failed\n");
			XSRETURN_UNDEF;
		}

		if (h)
			Safefree(h);

	OUTPUT:
		RETVAL


int
_print_num(num)
	int num
	CODE:
		print_num(num, FMT_KILOMEGAGIGA);
		RETVAL = 1;
	OUTPUT:
		RETVAL


int
_set_policy(h, chain, policy)
		iptc_handle_t * h;
		char *chain;
		char *policy;
	CODE:
		RETVAL &= iptc_set_policy(chain, policy, NULL, h);
		RETVAL &= iptc_commit(h);
	OUTPUT:
		RETVAL


int
_reset_counter(h, chain)
        iptc_handle_t * h;
        const char *chain;
	CODE:
		RETVAL &= zero_entries(chain, OPT_VERBOSE, h);
        RETVAL &= iptc_commit(h);

    OUTPUT:
        RETVAL

int
_delete_entry(h, tablename, chain, rulenum)
        iptc_handle_t * h;
        char *tablename;
        const char *chain;
		int rulenum;
	CODE:
		if (rulenum < 1)
			RETVAL = 0;
		else {
			RETVAL &= iptc_delete_num_entry(chain, rulenum - 1, h);
	        RETVAL &= iptc_commit(h);
		}
    OUTPUT:
        RETVAL

int 
_add_entry(h, tablename, chain, src, dst, proto, tojump, ...)
        iptc_handle_t * h;
		char *tablename;
		const char *chain;
        char *src;
		char *dst;
		char *proto;
		char *tojump;
	PREINIT:
		struct ipt_entry fw, *e = NULL;
		int invert = 0;
		unsigned int nsaddrs = 0, ndaddrs = 0;
		struct in_addr *saddrs = NULL, *daddrs = NULL;
		const char *shostnetworkmask = NULL, *dhostnetworkmask = NULL;
		struct iptables_match *m;
		struct iptables_target *target = NULL;
		struct iptables_target *t;
		char *protocol = NULL;
		const char *jumpto;
		STRLEN n_a;
		int i,extra,c = 0;
		char **table;

	CODE:
		memset(&fw, 0, sizeof(fw));

		opts = original_opts;
		optind = 0;
		opterr = 0;

		for (m = iptables_matches; m; m = m->next) 
		{
			m->mflags = 0;
			m->used = 0;
		}

		for (t = iptables_targets; t; t = t->next) 
		{
			t->tflags = 0;
			t->used = 0;
		}

		if (src)
		{
			shostnetworkmask = src;
			fw.nfcache |= NFC_IP_SRC;
		} else {
			shostnetworkmask = "0.0.0.0/0";
		}

		if(dst)
		{
			dhostnetworkmask = dst;
			fw.nfcache |= NFC_IP_DST;
		} else {
			dhostnetworkmask = "0.0.0.0/0";
		}

		parse_hostnetworkmask(shostnetworkmask, &saddrs, &(fw.ip.smsk), &nsaddrs);
		parse_hostnetworkmask(dhostnetworkmask, &daddrs, &(fw.ip.dmsk), &ndaddrs);

		for (protocol = proto; *protocol; protocol++)
			*protocol = tolower(*protocol);

		protocol = proto;
		fw.ip.proto = parse_protocol(protocol);

		if (fw.ip.proto == 0 && (fw.ip.invflags & IPT_INV_PROTO))
			 exit_error(PARAMETER_PROBLEM, "rule would never match protocol");
		fw.nfcache |= NFC_IP_PROTO;

		jumpto = parse_target(tojump);
		target = find_target(jumpto, TRY_LOAD);
		if (target) 
		{
			size_t size;
			size = IPT_ALIGN(sizeof(struct ipt_entry_target)) + target->size;
			target->t = fw_calloc(1, size);
			target->t->u.target_size = size;
			strcpy(target->t->u.user.name, jumpto);
			target->init(target->t, &fw.nfcache);
			opts = merge_options(opts, target->extra_opts, &target->option_offset);
		}


		if ( items > 7 ) 
		{
			size_t size;
			if (invert)
				exit_error(PARAMETER_PROBLEM, "unexpected ! flag before match");

			m = find_match((char *) SvPV(ST(7), n_a), LOAD_MUST_SUCCEED);
			size = IPT_ALIGN(sizeof(struct ipt_entry_match)) + m->size;
			m->m = fw_calloc(1, size);
			m->m->u.match_size = size;
			strcpy(m->m->u.user.name, m->name); 
			m->init(m->m, &fw.nfcache);
			opts = merge_options(opts, m->extra_opts, &m->option_offset);
		}

		newargc = 0;
		add_argv("IPTables");

		if ( items > 8 )
		{
			for(i = 8 ; i < items; i++)
			{
				/* printf("ARG: %s\n", (char *) SvPV(ST(i), n_a)); */
				add_argv((char *) SvPV(ST(i), n_a));
			}
		}

		while ((c = getopt_long(newargc, newargv, "", opts, NULL)) != -1) 
		{
			switch (c) 
			{
				default:
					if (!target || !(target->parse(c - target->option_offset, newargv, invert, &target->tflags, &fw, &target->t))) 
					{
		                for (m = iptables_matches; m; m = m->next) 
						{
		                    if (!m->used)
		                        continue;
		                    if (m->parse(c - m->option_offset, newargv, invert, &m->mflags, &fw, &fw.nfcache, &m->m))
		                        break;
		                }

		            	if (m == NULL && protocol && !find_proto(protocol, DONT_LOAD, OPT_NUMERIC) && 
								(m = find_proto(protocol, TRY_LOAD, OPT_NUMERIC)))
		            	{
		                	/* Try loading protocol */
		                	size_t size;

		                	size = IPT_ALIGN(sizeof(struct ipt_entry_match)) + m->size;
		                	m->m = fw_calloc(1, size);
		                	m->m->u.match_size = size;
		                	strcpy(m->m->u.user.name, m->name);
		                	m->init(m->m, &fw.nfcache);
		                	opts = merge_options(opts, m->extra_opts, &m->option_offset);
	
		                	optind--;
		                	continue;
		            	}

		            	if (!m)
		            	    exit_error(PARAMETER_PROBLEM, "Unknown arg `%s'", newargv[optind-1]);
	           	}
	       	}
		}

        /* If they didn't specify a target, or it's a chain
           name, use standard. */
        if (!target && (strlen(jumpto) == 0 || iptc_is_chain(jumpto, *h))) 
		{
            size_t size;
            target = find_target(IPT_STANDARD_TARGET, LOAD_MUST_SUCCEED);
            size = sizeof(struct ipt_entry_target) + target->size;
            target->t = fw_calloc(1, size);
            target->t->u.target_size = size;
            strcpy(target->t->u.user.name, jumpto);
            target->init(target->t, &fw.nfcache);
        }

        if (!target) {
            /* it is no chain, and we can't load a plugin.
             * We cannot know if the plugin is corrupt, non
             * existant OR if the user just misspelled a
             * chain. */
            find_target(jumpto, LOAD_MUST_SUCCEED);
        } else {
            e = generate_entry(&fw, iptables_matches, target->t);
        }



	    for (m = iptables_matches; m; m = m->next)
		{
	        if (!m->used)
	            continue;
	        m->final_check(m->mflags);
	    }

	    if (target)
	        target->final_check(target->tflags);

		/* printf("done, appending\n"); */
		RETVAL &= append_entry(chain, e, nsaddrs, saddrs, ndaddrs, daddrs, OPT_VERBOSE, h);
		/* printf("commiting rule\n"); */
		RETVAL &= iptc_commit(h);
		/* printf("commited\n"); */
	OUTPUT:
		RETVAL

void
get_match_options(name)
		char * name;

	PREINIT:
		struct iptables_match *m;
		unsigned int moo;
	PPCODE:
		m = find_match(name, TRY_LOAD);

		if (m != NULL)
		{
			for (moo = 0; m->extra_opts[moo].name ; moo++)
			{
		        XPUSHs(sv_2mortal(newSVpv(m->extra_opts[moo].name, strlen(m->extra_opts[moo].name))));
			}
		} else {
			XPUSHs(sv_2mortal(newSVpv("-1-", strlen("-1-"))));
		}

void
get_match_help(name)
		char * name;

	PREINIT:
		struct iptables_match *m;
		unsigned int moo;
	PPCODE:
		m = find_match(name, TRY_LOAD);

		if (m != NULL)
		{
 			m->help();
		} else {
			XPUSHs(sv_2mortal(newSVpv("-1-", strlen("-1-"))));
		}



void
get_target_options(name)
		char * name;

	PREINIT:
		struct iptables_target *m;
		unsigned int moo;
	PPCODE:
		m = find_target(name, TRY_LOAD);

		if (m != NULL)
		{
			for (moo = 0; m->extra_opts[moo].name ; moo++)
			{
		        XPUSHs(sv_2mortal(newSVpv(m->extra_opts[moo].name, strlen(m->extra_opts[moo].name))));
			}
		} else {
			XPUSHs(sv_2mortal(newSVpv("-1-", strlen("-1-"))));
		}

void
get_target_help(name)
		char * name;

	PREINIT:
		struct iptables_target *m;
		unsigned int moo;
	PPCODE:
		m = find_target(name, TRY_LOAD);

		if (m != NULL)
		{
 			m->help();
		} else {
			XPUSHs(sv_2mortal(newSVpv("-1-", strlen("-1-"))));
		}


MODULE = IPTables  PACKAGE = IPTables::Entry


const char *
iniface(self)
	iptxs_entry *self
	PREINIT:
		char buf[64];
    CODE:
		if (self->e->ip.iniface[0] != '\0') 
			strcpy(buf, self->e->ip.iniface);
		else
			strcpy(buf,  "*");
		RETVAL = buf;
    OUTPUT:
        RETVAL


const char *
outiface(self)
	iptxs_entry *self
	PREINIT:
		char buf[64];
    CODE:
		if (self->e->ip.outiface[0] != '\0') 
			strcpy(buf, self->e->ip.outiface);
		else
			strcpy(buf,  "*");
		RETVAL = buf;
    OUTPUT:
        RETVAL

int
bytes(self, ...)
	iptxs_entry *self
	PREINIT:
		char *count;
		STRLEN n_a;
	CODE:
		if (items == 1)
		{
			if (self->e == NULL)
				printf("Erk, e is undef!\n");

			RETVAL = self->e->counters.bcnt;
		} else {
			count = (char *) SvPV(ST(1), n_a);
			// self->e->counters.bcnt = atoll(count); // todo
			RETVAL = 0;
		}
	OUTPUT:
		RETVAL

int
packets(self)
	iptxs_entry *self
	CODE:
		RETVAL = self->e->counters.pcnt;
	OUTPUT:
		RETVAL

int
proto(self)
	iptxs_entry *self
	CODE:
		RETVAL = self->e->ip.proto;
	OUTPUT:
		RETVAL

char *
proto_name(self)
	iptxs_entry *self
	CODE:
		RETVAL = proto_to_name(self->e->ip.proto, 0);
	OUTPUT:
		RETVAL

int
invflags(self)
	iptxs_entry *self
	CODE:
		RETVAL = self->e->ip.invflags;
	OUTPUT:
		RETVAL

int
flags(self)
	iptxs_entry *self
	CODE:
		RETVAL = self->e->ip.flags;
	OUTPUT:
		RETVAL


const char *
get_target(self)
	iptxs_entry * self;
	CODE:
		RETVAL = iptc_get_target(self->e, self->h);
	OUTPUT:
		RETVAL

char *
src(self)
	iptxs_entry * self;
	PREINIT:
		char buf[20];
	CODE:
		RETVAL = addr_to_dotted(&(self->e->ip.src));
	OUTPUT:
		RETVAL

const char *
src_mask(self)
	iptxs_entry *self
    CODE:
		RETVAL = mask_to_dotted(&(self->e->ip.smsk));
    OUTPUT:
        RETVAL

char *
dst(self)
	iptxs_entry * self;
	PREINIT:
		char buf[20];
	CODE:
		sprintf(buf, "%s", addr_to_dotted(&(self->e->ip.dst)));
		RETVAL = buf;
	OUTPUT:
		RETVAL


const char *
dst_mask(self)
	iptxs_entry *self
    CODE:
		RETVAL = mask_to_dotted(&(self->e->ip.dmsk));
    OUTPUT:
        RETVAL

iptxs_entry *
iptc_next_rule(self)
	iptxs_entry * self;
	PREINIT:
		char *CLASS = "IPTables::Entry";
	CODE:

		if (self->h == NULL)
		{
			warn("handle has gone away\n");
			XSRETURN_UNDEF;
		}
		RETVAL = (iptxs_entry *) safemalloc(sizeof(iptxs_entry));
		if (RETVAL == NULL) 
		{
			warn("Unable to allocate entry\n");
			XSRETURN_UNDEF;
		}

		Zero(RETVAL, 1, iptxs_entry);
		RETVAL->e = (entry_n *) iptc_next_rule(self->e, self->h);

		if (RETVAL->e == NULL)
		{
			Safefree(RETVAL);
			XSRETURN_UNDEF;
		}
		strcpy(RETVAL->chain, self->chain);
		RETVAL->h = self->h;
	OUTPUT:
		RETVAL


int
DESTROY(self)
	iptxs_entry * self;
	CODE:
		if (self)
			Safefree(self);
		RETVAL = 1;
	OUTPUT:
		RETVAL


iptxs_target *
find_target(self)
	iptxs_entry * self;
	PREINIT:
		 char *CLASS = "IPTables::Target";
	CODE:
		RETVAL = (iptxs_target *) safemalloc(sizeof(iptxs_target));
		if (RETVAL == NULL)
		{
			warn("Unable to allocate target\n");
			XSRETURN_UNDEF;
		}
		RETVAL->t = find_target(iptc_get_target(self->e, self->h), TRY_LOAD); 
		if (RETVAL->t == NULL)
		{
			Safefree(RETVAL);
			XSRETURN_UNDEF;
		}
		RETVAL->e = self;
    OUTPUT: 
        RETVAL

iptxs_entry *
clone(self)
	    iptxs_entry * self;
    PREINIT:
        size_t size;
        char *CLASS = "IPTables::Entry";
		struct iptables_target *target = NULL;
		const struct ipt_entry *e;
		struct iptables_match * m;
		unsigned int moo;
    CODE:
        RETVAL = (iptxs_entry *) safemalloc(sizeof(iptxs_target));

        if (RETVAL == NULL)
        {
            warn("Unable to allocate target\n");
            XSRETURN_UNDEF;
        }

		for (m = iptables_matches; m; m = m->next) 
		{
			m->mflags = 0;
        	m->used = 0;
    	}

		target = find_target(IPT_STANDARD_TARGET, LOAD_MUST_SUCCEED);
		size = sizeof(struct ipt_entry_target) + target->size;
		target->t = fw_calloc(1, size);
		target->t->u.target_size = size;
		strcpy(target->t->u.user.name, IPT_STANDARD_TARGET);
		target->init(target->t, &(self->e->nfcache));

		RETVAL->e = generate_entry(self->e, iptables_matches, target->t);


        if (RETVAL == NULL)
        {
            warn("Can't replicate entry!\n");
            Safefree(RETVAL);
            XSRETURN_UNDEF;
        }

    OUTPUT:
        RETVAL



MODULE = IPTables  PACKAGE = IPTables::Chain


MODULE = IPTables  PACKAGE = IPTables::Target

int
print_match(target)
	iptxs_target * target
	PREINIT:
		const struct ipt_entry_target *match;
	CODE:

	match = ipt_get_target((struct ipt_entry *)target->e->e);
	IPT_MATCH_ITERATE(target->e->e, print_match, &(target->e->e->ip), 0);
	RETVAL = 1;

	OUTPUT:
		RETVAL

int
print_target(target)
	iptxs_target * target
	PREINIT:
		const struct ipt_entry_target *match;
	CODE:
	match = ipt_get_target((struct ipt_entry *)target->e->e);
    if (target->t) 
	{
        if (target->t->print)
		{
            /* Print the target information. */
            target->t->print(&(target->e->e->ip), match, 0);
			RETVAL = 1;

		}/* else if (match->u.target_size != sizeof(*match)) {
	        printf("[%u bytes of unknown target data] ", match->u.target_size - sizeof(*match));
			RETVAL = 0;
		}*/
	} else
		RETVAL = 0;


	OUTPUT:
		RETVAL

int
save(target)
	iptxs_target * target
	PREINIT:
		const struct ipt_entry_target *match;
	CODE:
	match = ipt_get_target((struct ipt_entry *)target->e->e);

	IPT_MATCH_ITERATE(target->e->e, save, &(target->e->e->ip), 0);

    if (target->t) 
	{
        if (target->t->save)
		{
            /* Print the target information. */
            target->t->save(&(target->e->e->ip), match);
			RETVAL = 1;

		}/* else if (match->u.target_size != sizeof(*match)) {
	        printf("[%u bytes of unknown target data] ", match->u.target_size - sizeof(*match));
			RETVAL = 0;
		}*/
	} else
		RETVAL = 0;


	OUTPUT:
		RETVAL

