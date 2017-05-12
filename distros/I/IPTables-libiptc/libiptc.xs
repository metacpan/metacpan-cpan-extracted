#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <libiptc/libiptc.h>
#include <xtables.h>
#include <iptables.h>
#include <string.h>
#include <stdio.h>
#include <errno.h>

#include "const-c.inc"

#define ERROR_SV perl_get_sv("!", 0)
#define SET_ERRSTR(format...) sv_setpvf(ERROR_SV, ##format)
#define SET_ERRNUM(value) sv_setiv(ERROR_SV, (IV)value)

#define ERRSTR_NULL_HANDLE "ERROR: IPTables handle==NULL, forgot to call init?"

// OLD system
//extern const char *program_name, *program_version;
//extern char *lib_dir;

// Old typedef method:
//typedef struct iptc_handle* iptc_handle_t;
//typedef iptc_handle_t*      IPTables__libiptc;
// Old stype equals:
//typedef struct iptc_handle** IPTables__libiptc;

// New >= 1.4.4 method
typedef struct iptc_handle* IPTables__libiptc;


MODULE = IPTables::libiptc		PACKAGE = IPTables::libiptc

INCLUDE: const-xs.inc


IPTables::libiptc
init(tablename)
    char * tablename
  PREINIT:
    struct iptc_handle* handle;
    //OLD: iptc_handle_t handle;
  INIT:
    int ret;
  CODE:
    iptables_globals.program_name = "perl-to-libiptc";
    //iptables_globals.program_version = XTABLES_VERSION; //??

    // TODO: reassing function pointer exit_err() to avoid that perl
    //       dies on iptables do_command errors.
    //
    //  void (*exit_err)(enum xtables_exittype status, const char *msg, ...) __attribute__((noreturn, format(printf,2,3)));
    //
    // See function examples in:
    //  iptables.c: func iptables_exit_error()
    //  xtables.c : func basic_exit_err()

    ret = xtables_init_all(&iptables_globals, NFPROTO_IPV4);
    if (ret < 0) {
        fprintf(stderr, "%s/%s Failed to initialize xtables\n",
		iptables_globals.program_name,
		iptables_globals.program_version);
		exit(1);
    }

    // related to: ifdef NO_SHARED_LIBS
    // init_extensions();

    handle  = iptc_init(tablename);
    if (handle == NULL) {
	RETVAL  = NULL;
	SET_ERRNUM(errno);
	SET_ERRSTR("%s", iptc_strerror(errno));
	SvIOK_on(ERROR_SV);
    } else {
	RETVAL = handle;
	# TODO: Lock /var/lock/iptables_tablename
    }
  OUTPUT:
    RETVAL


int
commit(self)
    IPTables::libiptc self
  CODE:
    if (self == NULL) croak(ERRSTR_NULL_HANDLE);
    else {
	RETVAL = iptc_commit(self);
	if(!RETVAL) {
	    SET_ERRNUM(errno);
	    SET_ERRSTR("%s", iptc_strerror(errno));
	    SvIOK_on(ERROR_SV);
	}
        /* Newer versions of iptables does not call iptc_free(), after
           iptc_commit().  This is done to support several commits,
           but we choose not to support this feature.  Thus, we need
           to free memory here (used by the iptables ruleset, actually
           the cached libiptc blob version).
        */
	iptc_free(self);
	# TODO: UnLock /var/lock/iptables_tablename
    }
  OUTPUT:
    RETVAL


void
DESTROY(self)
    IPTables::libiptc self
  CODE:
    if(self) {
	//This breaks: if(&self) iptc_free(self);
    }
    # TODO: UnLock /var/lock/iptables_tablename


##########################################
#  Chain operations
##########################################

int
is_chain(self, chain)
    IPTables::libiptc self
    ipt_chainlabel    chain
  CODE:
    if   (self == NULL) croak(ERRSTR_NULL_HANDLE);
    else RETVAL = iptc_is_chain(chain, self);
  OUTPUT:
    RETVAL


int
create_chain(self, chain)
    IPTables::libiptc self
    ipt_chainlabel    chain
  CODE:
    if (self == NULL) croak(ERRSTR_NULL_HANDLE);
    else {
	RETVAL = iptc_create_chain(chain, self);
	if (!RETVAL) {
	    SET_ERRNUM(errno);
	    SET_ERRSTR("%s", iptc_strerror(errno));
	    SvIOK_on(ERROR_SV);
	}
    }
  OUTPUT:
    RETVAL


int
delete_chain(self, chain)
    IPTables::libiptc self
    ipt_chainlabel    chain
  CODE:
    if (self == NULL) croak(ERRSTR_NULL_HANDLE);
    else {
	RETVAL = iptc_delete_chain(chain, self);
	if (!RETVAL) {
	    SET_ERRNUM(errno);
	    SET_ERRSTR("%s", iptc_strerror(errno));
	    SvIOK_on(ERROR_SV);
	}
    }
  OUTPUT:
    RETVAL


int
rename_chain(self, old_name, new_name)
    IPTables::libiptc self
    ipt_chainlabel    old_name
    ipt_chainlabel    new_name
  CODE:
    if (self == NULL) croak(ERRSTR_NULL_HANDLE);
    else {
	RETVAL = iptc_rename_chain(old_name, new_name, self);
	if (!RETVAL) {
	    SET_ERRNUM(errno);
	    SET_ERRSTR("%s", iptc_strerror(errno));
	    SvIOK_on(ERROR_SV);
	}
    }
  OUTPUT:
    RETVAL


int
builtin(self, chain)
    IPTables::libiptc self
    ipt_chainlabel    chain
  CODE:
    if (self == NULL) croak(ERRSTR_NULL_HANDLE);
    else {
	RETVAL = iptc_builtin(chain, self);
	if (!RETVAL) {
	    SET_ERRNUM(errno);
	    SET_ERRSTR("%s", iptc_strerror(errno));
	    SvIOK_on(ERROR_SV);
	}
    }
  OUTPUT:
    RETVAL


int
get_references(self, chain)
    IPTables::libiptc self
    ipt_chainlabel    chain
  CODE:
    if (self == NULL) croak(ERRSTR_NULL_HANDLE);
    else {
	if (!iptc_get_references(&RETVAL, chain, self)) {
	    RETVAL  = -1;
	    SET_ERRNUM(errno);
	    SET_ERRSTR("%s", iptc_strerror(errno));
	    SvIOK_on(ERROR_SV);
	}
    }
  OUTPUT:
    RETVAL


##########################################
# Rules/Entries affecting a full chain
##########################################

int
flush_entries(self, chain)
    IPTables::libiptc self
    ipt_chainlabel    chain
  CODE:
    if (self == NULL) croak(ERRSTR_NULL_HANDLE);
    else {
	RETVAL = iptc_flush_entries(chain, self);
	if (!RETVAL) {
	    SET_ERRNUM(errno);
	    SET_ERRSTR("%s", iptc_strerror(errno));
	    SvIOK_on(ERROR_SV);
	}
    }
  OUTPUT:
    RETVAL


int
zero_entries(self, chain)
    IPTables::libiptc self
    ipt_chainlabel    chain
  CODE:
    if (self == NULL) croak(ERRSTR_NULL_HANDLE);
    else {
	RETVAL = iptc_zero_entries(chain, self);
	if (!RETVAL) {
	    SET_ERRNUM(errno);
	    SET_ERRSTR("%s", iptc_strerror(errno));
	    SvIOK_on(ERROR_SV);
	}
    }
  OUTPUT:
    RETVAL

##########################################
# Listing related
##########################################

void
list_chains(self)
    IPTables::libiptc self
  PREINIT:
    char * chain;
    SV *   sv;
    int    count = 0;
  PPCODE:
    sv = ST(0);
    if (self == NULL) croak(ERRSTR_NULL_HANDLE);
    else {
	chain = (char *)iptc_first_chain(self);
	while(chain) {
	    count++;
	    if (GIMME_V == G_ARRAY)
		XPUSHs(sv_2mortal(newSVpv(chain, 0)));
	    chain = (char *)iptc_next_chain(self);
	}
	if (GIMME_V == G_SCALAR)
	    XPUSHs(sv_2mortal(newSViv(count)));
    }


void
list_rules_IPs(self, type, chain)
    IPTables::libiptc self
    ipt_chainlabel    chain
    char *            type
  PREINIT:
    SV *   sv;
    int    count = 0;
    struct ipt_entry *entry;
    int    the_type;
    char   buf[100]; /* I should be enough with only 32 chars */
    static char * errmsg = "Wrong listing type requested.";
  PPCODE:
    sv = ST(0);
    if (self == NULL) croak(ERRSTR_NULL_HANDLE);
    else {
	if(iptc_is_chain(chain, self)) {
	    entry = (struct ipt_entry *)iptc_first_rule(chain, self);

	    /* Parse what type was requested */
	    if      (strcasecmp(type, "dst") == 0) the_type = 'd';
	    else if (strcasecmp(type, "src") == 0) the_type = 's';
	    else croak(errmsg);

	    while(entry) {
		count++;
 		if (GIMME_V == G_ARRAY) {

		    switch (the_type) {
		    case 'd':
			sprintf(buf,"%s",xtables_ipaddr_to_numeric(&(entry->ip.dst)));
			strcat(buf, xtables_ipmask_to_numeric(&(entry->ip.dmsk)));
			sv = newSVpv(buf, 0);
		        break;
		    case 's':
			sprintf(buf,"%s",xtables_ipaddr_to_numeric(&(entry->ip.src)));
			strcat(buf, xtables_ipmask_to_numeric(&(entry->ip.smsk)));
			sv = newSVpv(buf, 0);
		        break;
		    default:
		        croak(errmsg);
		    }
		    XPUSHs(sv_2mortal(sv));
		}
		entry = (struct ipt_entry *)iptc_next_rule(entry, self);
	    }
	    if (GIMME_V == G_SCALAR)
		XPUSHs(sv_2mortal(newSViv(count)));
	} else {
	    XSRETURN_UNDEF;
	}
    }


##########################################
# Policy related
##########################################

void
get_policy(self, chain)
    IPTables::libiptc self
    ipt_chainlabel    chain
  PREINIT:
    struct ipt_counters  counters;
    SV *                 sv;
    char *               policy;
    char *               temp;
  PPCODE:
    sv = ST(0);
    if (self == NULL) croak(ERRSTR_NULL_HANDLE);
    else {
	if((policy = (char *)iptc_get_policy(chain, &counters, self))) {
	    XPUSHs(sv_2mortal(newSVpv(policy, 0)));
	    asprintf(&temp, "%llu", counters.pcnt);
	    XPUSHs(sv_2mortal(newSVpv(temp, 0)));
	    free(temp);
	    asprintf(&temp, "%llu", counters.bcnt);
	    XPUSHs(sv_2mortal(newSVpv(temp, 0)));
	    free(temp);
	} else {
	    SET_ERRNUM(errno);
	    SET_ERRSTR("%s", iptc_strerror(errno));
	    SvIOK_on(ERROR_SV);
	}
    }


void
set_policy(self, chain, policy, pkt_cnt=0, byte_cnt=0)
    IPTables::libiptc self
    ipt_chainlabel    chain
    ipt_chainlabel    policy
    unsigned int      pkt_cnt
    unsigned int      byte_cnt
  PREINIT:
    struct ipt_counters *  counters = NULL;
    struct ipt_counters    old_counters;
    char *                 old_policy;
    char *                 temp;
    int retval;
  PPCODE:
    if (self == NULL) croak(ERRSTR_NULL_HANDLE);
    else {
	if(pkt_cnt && byte_cnt) {
	    counters = malloc(sizeof(struct ipt_counters));
	    counters->pcnt = pkt_cnt;
	    counters->bcnt = byte_cnt;
	}
	/* Read the old policy and counters */
	old_policy = (char *)iptc_get_policy(chain, &old_counters, self);

	retval = iptc_set_policy(chain, policy, counters, self);
	/* Return retval to perl */
	XPUSHs(sv_2mortal(newSViv(retval)));
	if (!retval) {
	    SET_ERRNUM(errno);
	    SET_ERRSTR("%s", iptc_strerror(errno));
	    SvIOK_on(ERROR_SV);
	} else {
	    /* return old policy and counters to perl */
      	    if (old_policy) {
		XPUSHs(sv_2mortal(newSVpv(old_policy, 0)));
		asprintf(&temp, "%llu", old_counters.pcnt);
		XPUSHs(sv_2mortal(newSVpv(temp, 0)));
		free(temp);
		asprintf(&temp, "%llu", old_counters.bcnt);
		XPUSHs(sv_2mortal(newSVpv(temp, 0)));
		free(temp);
	    }
	}
    }
    if(counters) free(counters);


##########################################
# iptables.{h,c,o} related
##########################################

# !!!FUNCTION NOT TESTED!!!
int
iptables_delete_chain(self, chain)
    IPTables::libiptc self
    ipt_chainlabel    chain
  CODE:
    if (self == NULL) croak(ERRSTR_NULL_HANDLE);
    else {
	RETVAL = delete_chain(chain, 0, self);
	if (!RETVAL) {
	    SET_ERRNUM(errno);
	    SET_ERRSTR("%s", iptc_strerror(errno));
	    SvIOK_on(ERROR_SV);
	}
    }
  OUTPUT:
    RETVAL


# int do_command(int argc, char *argv[], char **table,
#                iptc_handle_t *handle);
#
int
iptables_do_command(self, array_ref)
    IPTables::libiptc self
    SV  * array_ref;
  INIT:
    static char * argv[255];
    // FIXME: Should use IPT_TABLE_MAXNAMELEN here
    static char *fake_table = "fakename"; // TODO: Use real tablename instead
    int argc;      /* number of args */
    int array_len; /* number of array elements */
    int n;

    # Perl type checking
    if ((!SvROK(array_ref))
	|| (SvTYPE(SvRV(array_ref)) != SVt_PVAV)
	|| ((array_len = av_len((AV *)SvRV(array_ref))) < 0))
    {
	XSRETURN_UNDEF;
    }
    # FIXME: Why was the line below uncommentend before?
    array_len = av_len((AV *)SvRV(array_ref));

  CODE:
    // OLD method, see init func for new method
    //program_name = "perl-to-libiptc";
    ////program_version = IPTABLES_VERSION;
    //program_version = XTABLES_VERSION;

 // OLD method
 //    lib_dir = getenv("XTABLES_LIBDIR");
 //    if (lib_dir == NULL) {
 //	lib_dir = getenv("IPTABLES_LIB_DIR");
 //	if (lib_dir != NULL)
 //	    fprintf(stderr, "IPTABLES_LIB_DIR is deprecated\n");
 //    }
 //    if (lib_dir == NULL)
 //        lib_dir = XTABLES_LIBDIR;

    /* Due to getopt parsing in iptables.c
     * argv needs to contain the program name as the first arg */
    argv[0] = iptables_globals.program_name;
    argc=1;

    for (n = 0; n <= array_len; n++, argc++) {
	STRLEN l;
	char* str = SvPV(*av_fetch((AV *)SvRV(array_ref), n, 0), l);
	argv[argc] = str;
	# printf("loop:%d str:%s   \targv[%d]=%s\n", n, str, argc, argv[argc]);
    }
    # printf("value of n:%d array_len:%d argc:%d\n", n, array_len, argc);

    if (self == NULL) croak(ERRSTR_NULL_HANDLE);
    else {
	/* The pointer variable fake_table is needed, because iptables.c
	 * will update it if the "-t" argument is specified.  BUT in old versions
	 * its not used if the handle was defined (which is checked above).
	 *
	 * A problem was introduced with the NAT check for no DROP
	 * targets, in iptables.c do_command(), as it tries to access
	 * the fake_table, even if the handle is defined (which
	 * actually is a bug), thus we need to assign something valid
	 * to fake_table, to avoid a segfault.
	 */
	RETVAL = do_command(argc, argv, &fake_table, &self);
	if (!RETVAL) {
	    SET_ERRNUM(errno);
	    SET_ERRSTR("%s", iptc_strerror(errno));
	    SvIOK_on(ERROR_SV);
	}
	/* Check if do_command() have modified fake_table */
	if ((strcmp(fake_table, "fakename")) != 0) {
	    warn("do_command: Specifying table (%s) has no effect as handle is defined.", fake_table);
	    SET_ERRNUM(ENOTSUP);
	    SET_ERRSTR("Specifying table has no effect (%s).", iptc_strerror(errno));
	    SvIOK_on(ERROR_SV);
	}
    }
  OUTPUT:
    RETVAL


##########################################
# Stuff...
##########################################

