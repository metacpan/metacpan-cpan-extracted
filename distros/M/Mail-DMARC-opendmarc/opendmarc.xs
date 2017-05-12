#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

/** TODO: replace for distro **/
#include "opendmarc.h"

#include "const-c.inc"

MODULE = Mail::DMARC::opendmarc		PACKAGE = Mail::DMARC::opendmarc

INCLUDE: const-xs.inc

PROTOTYPES: ENABLE

## Program Startup/Shutdown
OPENDMARC_STATUS_T  
opendmarc_policy_library_init(lib_init)
	OPENDMARC_LIB_T *lib_init
	

#typedef struct {
#	int			tld_type;
#	u_char 			tld_source_file[MAXPATHLEN];
#	int    			nscount;
#	struct sockaddr_in 	nsaddr_list[MAXNS];
#} OPENDMARC_LIB_T;

OPENDMARC_STATUS_T
opendmarc_policy_library_init_tld(tld_file)
	const char *tld_file
	INIT:
		OPENDMARC_LIB_T lib_t;
	CODE:
		(void) memset(&lib_t, '\0', sizeof(OPENDMARC_LIB_T));
		lib_t.tld_type = OPENDMARC_TLD_TYPE_MOZILLA;
		strcpy(lib_t.tld_source_file, tld_file);
		printf("libt.tld_type is %d, lib_t.tld_source_file is '%s'\n", lib_t.tld_type, lib_t.tld_source_file);
		RETVAL = opendmarc_policy_library_init(&lib_t);
	OUTPUT:
		RETVAL
		

OPENDMARC_STATUS_T  
opendmarc_policy_library_shutdown(lib_init)
	OPENDMARC_LIB_T *lib_init
	

# Notice: opendmarc 1.0.0 does nothing with the lib_t param.
# We only set it up to avoid future breakage
OPENDMARC_STATUS_T
opendmarc_policy_library_shutdown_tld(tld_file)
	const char *tld_file
	INIT:
		OPENDMARC_LIB_T lib_t;
	CODE:
		(void) memset(&lib_t, '\0', sizeof(OPENDMARC_LIB_T));
		lib_t.tld_type = OPENDMARC_TLD_TYPE_MOZILLA;
		strcpy(lib_t.tld_source_file, tld_file);
		/* printf("libt.tld_type is %d, lib_t.tld_source_file is '%s'\n", lib_t.tld_type, lib_t.tld_source_file); */
		RETVAL = opendmarc_policy_library_shutdown(&lib_t);
	OUTPUT:
		RETVAL

## Per-Envelope Context Functions
DMARC_POLICY_T *
opendmarc_policy_connect_init(ip_addr, ip_type)
	u_char *ip_addr
	int ip_type
	CODE:
		RETVAL = opendmarc_policy_connect_init(ip_addr, ip_type);
		// printf ("policy initialized\n");
	OUTPUT:
		RETVAL

DMARC_POLICY_T * 
opendmarc_policy_connect_clear(pctx)
	DMARC_POLICY_T *pctx

DMARC_POLICY_T * 
opendmarc_policy_connect_rset(pctx)
	DMARC_POLICY_T *pctx

DMARC_POLICY_T * 
opendmarc_policy_connect_shutdown(pctx)
	DMARC_POLICY_T *pctx

## Information Storage Functions

OPENDMARC_STATUS_T 
opendmarc_policy_store_from_domain(pctx, domain)
	DMARC_POLICY_T *pctx
	u_char *domain

OPENDMARC_STATUS_T 
opendmarc_policy_store_dkim(pctx, domain, result, human_result)
	DMARC_POLICY_T *pctx
	u_char *domain
	int result
	u_char *human_result

OPENDMARC_STATUS_T 
opendmarc_policy_store_spf(pctx, domain, result, origin, human_result)
	DMARC_POLICY_T *pctx
	u_char *domain
	int result
	int origin
	u_char *human_result

## DMARC Record Functions

OPENDMARC_STATUS_T 
opendmarc_policy_query_dmarc(pctx, domain)
	DMARC_POLICY_T *pctx
	u_char *domain
#	CODE:
#		RETVAL = opendmarc_policy_query_dmarc(pctx, domain);
#		printf("domain from arg:\'%s\'\tdomain from pctx:\'%s\'\n",
#				domain,
#				pctx->from_domain);
#	OUTPUT:
#		RETVAL


OPENDMARC_STATUS_T 
opendmarc_policy_parse_dmarc(pctx, domain, record)
	DMARC_POLICY_T *pctx 
	u_char *domain
	u_char *record

OPENDMARC_STATUS_T 
opendmarc_policy_store_dmarc(pctx, dmarc_record, domain, organizationaldomain)
	DMARC_POLICY_T *pctx 
	u_char *dmarc_record
	u_char *domain
	u_char *organizationaldomain

## DMARC Result Functions

OPENDMARC_STATUS_T 
opendmarc_get_policy_to_enforce(pctx)
	DMARC_POLICY_T *pctx

OPENDMARC_STATUS_T 
opendmarc_policy_fetch_alignment(pctx, dkim_alignment, spf_alignment)
	DMARC_POLICY_T *pctx
	int &dkim_alignment
	int &spf_alignment
	OUTPUT:
		dkim_alignment
		spf_alignment

OPENDMARC_STATUS_T 
opendmarc_policy_fetch_pct(pctx, pctp)
	DMARC_POLICY_T *pctx
	int &pctp
	OUTPUT:
		pctp

OPENDMARC_STATUS_T 
opendmarc_policy_fetch_adkim(pctx, adkim)
	DMARC_POLICY_T *pctx
	int &adkim
	OUTPUT:
		adkim

OPENDMARC_STATUS_T 
opendmarc_policy_fetch_aspf(pctx, aspf)
	DMARC_POLICY_T *pctx
	int &aspf
	OUTPUT:
		aspf

OPENDMARC_STATUS_T 
opendmarc_policy_fetch_p(pctx, pp)
	DMARC_POLICY_T *pctx
	int &pp
	OUTPUT:
		pp

OPENDMARC_STATUS_T 
opendmarc_policy_fetch_sp(pctx, psp)
	DMARC_POLICY_T *pctx
	int &psp
	OUTPUT:
		psp

u_char **	   
opendmarc_policy_fetch_rua(pctx, list_buf, size_of_buf, constant)
	DMARC_POLICY_T *pctx
	u_char *list_buf
	size_t size_of_buf
	int constant

u_char **	   
opendmarc_policy_fetch_ruf(pctx, list_buf, size_of_buf, constant)
	DMARC_POLICY_T *pctx
	u_char *list_buf
	size_t size_of_buf
	int constant
	
OPENDMARC_STATUS_T 
opendmarc_policy_fetch_fo(pctx, pfo)
	DMARC_POLICY_T *pctx
	int &pfo
	OUTPUT:
		pfo

OPENDMARC_STATUS_T 
opendmarc_policy_fetch_rf(pctx, prf)
	DMARC_POLICY_T *pctx
	int &prf
	OUTPUT:
		prf


OPENDMARC_STATUS_T 
opendmarc_policy_fetch_utilized_domain(pctx, buf, buflen)
	DMARC_POLICY_T *pctx
	u_char *buf
	size_t buflen
	OUTPUT:
		buf
		
SV *
opendmarc_policy_fetch_utilized_domain_string(pctx)
	DMARC_POLICY_T *pctx
	INIT:
		STRLEN len = 1024;
		char *buf;
	CODE:
		buf = safemalloc(len);
		if (buf == NULL)
				XSRETURN_UNDEF;
		int ret = opendmarc_policy_fetch_utilized_domain (pctx, buf, len);
		if (ret == E2BIG) {
			safefree(buf);
			/* Try again with 2048 */
			len = 2048;
			buf = safemalloc(len);
			if (buf == NULL)
				XSRETURN_UNDEF;
			ret = opendmarc_policy_fetch_utilized_domain (pctx, buf, len);
		}
		RETVAL = newSVpvn(buf, strlen(buf));
		safefree(buf);
		if (ret != 0)
				XSRETURN_UNDEF;
	OUTPUT:
		RETVAL
		

## TLD Functions
int  		   
opendmarc_tld_read_file(path_fname, commentstring, drop, except)
	char *path_fname
	char *commentstring
	char *drop
	char *except

void
opendmarc_tld_shutdown()

## XML File Functions
u_char **          
opendmarc_xml(b, blen, e, elen)
	char *b
	size_t blen
	char *e
	size_t elen

u_char **          
opendmarc_xml_parse(fname, err_buf, err_len)
	char *fname
	char *err_buf
	size_t err_len


## Handy Utility Functions

u_char ** 	   
opendmarc_util_clearargv(ary)
	u_char ** ary

const char *	   
opendmarc_policy_status_to_str(status)
	OPENDMARC_STATUS_T status

int
opendmarc_get_tld(domain, tld, tld_len)
		u_char *domain
		u_char *tld
		size_t tld_len


SV *
opendmarc_get_tld_string(domain)
		const char *domain
	INIT:
		STRLEN len = 1024;
		char *buf;
	CODE:
		buf = safemalloc(len);
		if (buf == NULL)
				XSRETURN_UNDEF;
		int ret = opendmarc_get_tld (domain, buf, len);
		if (ret == E2BIG) {
			safefree(buf);
			/* Try again with 2048 */
			len = 2048;
			buf = safemalloc(len);
			if (buf == NULL)
				XSRETURN_UNDEF;
			ret = opendmarc_get_tld (domain, buf, len);
		}
		RETVAL = newSVpvn(buf, strlen(buf));
		safefree(buf);
		if (ret != 0)
				XSRETURN_UNDEF;
	OUTPUT:
		RETVAL



int                
opendmarc_policy_check_alignment(subdomain, tld, mode)
	u_char * subdomain
	u_char * tld
	int mode
	
#typedef struct dmarc_policy_t {
#	/*
#	 * Supplied information
#	 */
#	u_char *	ip_addr;		/* Input: connected IPV4 or IPV6 address */
#	int 		ip_type;		/* Input: IPv4 or IPv6 */
#	u_char * 	spf_domain;		/* Input: Domain used to verify SPF */
#	int 	 	spf_origin;		/* Input: was domain MAIL From: or HELO for SPF check */
#	int		spf_outcome;		/* Input: What was the outcome of the SPF check */
#	u_char *	spf_human_outcome;	/* Input: What was the outcome of the SPF check in human readable form */
#	int		dkim_final;		/* This is the best record found */
#	u_char * 	dkim_domain;		/* Input: The d= domain */
#	int		dkim_outcome;		/* Input: What was the outcome of the DKIM check */
#	u_char *	dkim_human_outcome;	/* Input: What was the outcome of the DKIM check in human readable form */
#
#	/*
#	 * Computed outcomes
#	 */
#	int		dkim_alignment;
#	int		spf_alignment;
#
#	/*
#	 * Computed Organizational domain, if subdomain lacked a record.
#	 */
#	u_char *	from_domain;		/* Input: From: header domain */
#	u_char *	organizational_domain;
#
#	/*
#	 * Found in the _dmarc record or supplied to us.
#	 */
#	int		h_error;	/* Zero if found, else DNS error */
#	int		adkim;
#	int		aspf;
#	int		p;
#	int		sp;
#	int		pct;
#	int		rf;
#	uint32_t	ri;
#	int		rua_cnt;
#	u_char **	rua_list;
#	int		ruf_cnt;
#	u_char **	ruf_list;
#} DMARC_POLICY_T;

SV *
opendmarc_policy_to_buf(pctx)
	DMARC_POLICY_T *pctx
	INIT:
		STRLEN len = 1024;
		char *buf;
	CODE:
		buf = safemalloc(len);
		if (buf == NULL)
				XSRETURN_UNDEF;
		int ret = opendmarc_policy_to_buf (pctx, buf, len);
		if (ret == E2BIG) {
			safefree(buf);
			/* Try again with 2048 */
			len = 2048;
			buf = safemalloc(len);
			if (buf == NULL)
				XSRETURN_UNDEF;
			ret = opendmarc_policy_to_buf (pctx, buf, len);
		}
		RETVAL = newSVpvn(buf, strlen(buf));
		safefree(buf);
		if (ret != 0)
				XSRETURN_UNDEF;
	OUTPUT:
		RETVAL

