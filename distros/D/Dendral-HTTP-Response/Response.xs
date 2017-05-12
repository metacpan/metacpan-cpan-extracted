#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <httpd.h>

#if (AP_SERVER_MAJORVERSION_NUMBER == 2)
	#include "ap_compat.h"
	#include "apr_strings.h"
	#include "apr_uri.h"
	#include "apr_tables.h"
	#include "apr_time.h"
	#include "apr_file_io.h"
	#include "util_filter.h"

	#define ap_palloc    apr_palloc
	#define ap_pstrdup   apr_pstrdup
	#define ap_pstrndup  apr_pstrndup
	#define ap_psprintf  apr_psprintf
	#define ap_pstrcat   apr_pstrcat
	#define ap_table_add apr_table_add
	#define ap_table_set apr_table_set
	#define ap_table_get apr_table_get
	#define ap_table_merge apr_table_merge
	#define ap_table_clear apr_table_clear
	#define ap_table_unset apr_table_unset
	#define ap_table_do apr_table_do
	#define apr_make_array apr_array_make
	#define ap_push_array apr_array_push
	#define ap_array_pstrcat apr_array_pstrcat
	#define array_header apr_array_header_t
	#define ap_make_array apr_array_make
	

#endif

#if (AP_SERVER_MAJORVERSION_NUMBER == 2)
#define RCLASS "Apache2::RequestRec"
#else
#define RCLASS "Apache"
#endif

#define escape(pool,str) ap_os_escape_path(pool,str,1)

static char *r_keys[] = { "_r", "r", NULL };

static request_rec *r_magic_get(SV *sv)
{
	MAGIC *mg  = mg_find(sv, '~');
	return mg ? (request_rec *)mg->mg_ptr : NULL;
}

// HV -> request_rec
request_rec *sv2request_rec(SV *in, char *pclass)
{
	request_rec *r = NULL;
	SV *sv = Nullsv;

	if(SvROK(in) && (SvTYPE(SvRV(in)) == SVt_PVHV)) 
	{
		int i;
		for (i=0; r_keys[i]; i++) 
		{
			int klen = strlen(r_keys[i]);
			if(hv_exists((HV*)SvRV(in), r_keys[i], klen) &&
				(sv = *hv_fetch((HV*)SvRV(in), 
				r_keys[i], klen, FALSE))) 
			{
				if (SvROK(sv) && (SvTYPE(SvRV(sv)) == SVt_PVHV)) 
				{
					/* dig deeper */
					return sv2request_rec(sv, pclass);
				}
				break;
			}
		}
		if(!sv) croak(" `%s' object with no `r' key!",   HvNAME(SvSTASH(SvRV(in))));
	}

	if(!sv) sv = in;
	if(SvROK(sv) && (SvTYPE(SvRV(sv)) == SVt_PVMG)) 
	{
		if(sv_derived_from(sv, pclass)) 
		{
			if((r = r_magic_get(SvRV(sv)))) 
			{
				/* ~ magic */
			}
			else 
			{
				r = (request_rec *) SvIV((SV*)SvRV(sv));
			}
		}
		else 
		{
			return NULL;
		}
	}
	else 
	{
		croak("called without setting Apache->request!");
	}
    return r;
}

char* avcookie2char(request_rec *r, AV *avarr)
{
	int i;
	I32 array_size = av_len(avarr) + 1;	

	array_header *arr = ap_make_array(r -> pool, array_size, sizeof(char*));

	for (i = 0; i < array_size; ++i)
	{
		SV **svcell = av_fetch(avarr, i, 0);
		char *cell = SvPV_nolen(*svcell);
		*(char **)ap_push_array(arr) = cell;
	}
	return ap_array_pstrcat(r -> pool, arr, '&');
}

char* hvcookie2char(request_rec *r, HV *hvhash)
{
	HE *he;
	STRLEN keylen;

	array_header *arr = ap_make_array(r -> pool, 0, sizeof(char*));

	if (!hv_iterinit(hvhash)) {return "";}
	
	while (he = hv_iternext(hvhash))
	{

		char *key = HePV(he,keylen);
		char *value = SvPV_nolen(HeVAL(he));

		*(char **)ap_push_array(arr) = key;

		char *cell = escape(r -> pool, value);
		*(char **)ap_push_array(arr) = cell;
	}
	return ap_array_pstrcat(r -> pool, arr, '&');
}

char* rfc822_date(request_rec *r, int stime)
{
#if (AP_SERVER_MAJORVERSION_NUMBER == 2)
	char *date822 = NULL;
	date822 = ap_palloc(r -> pool, APR_RFC822_DATE_LEN); 
	apr_rfc822_date(date822, (apr_time_t) stime * 1000000);
	return date822;
#else
	return ap_gm_timestr_822(r -> pool, stime);
#endif
}

char* parse_expires(request_rec *r, char *str)
{
	int tt,count;
	int now = time(NULL);


	if (strcasecmp(str, "now") == 0) return rfc822_date(r, now);

	int strl = strlen(str);

	if (strl < 3) return str;
	if (str[0] != '+' && str[0] != '-') return str; 

	if (str[strl - 1] == 's') count = 1;
	else if (str[strl - 1] == 'm') count = 60;
	else if (str[strl - 1] == 'h') count = 60*60;
	else if (str[strl - 1] == 'd') count = 60*60*24;
	else if (str[strl - 1] == 'M') count = 60*60*24*30;
	else if (str[strl - 1] == 'y') count = 60*60*24*365;
	else return str; 

	count *= atoi(str);

	return rfc822_date(r, now + count);

}

int _send_file(request_rec *r, char *filename)
{
#if (AP_SERVER_MAJORVERSION_NUMBER == 2)
	apr_file_t *f;
	apr_finfo_t sb;
	apr_size_t len;
	
	apr_stat(&sb, filename, APR_FINFO_MIN, r -> pool);
	if (apr_file_open(&f, filename, APR_READ, APR_OS_DEFAULT, r -> pool) != APR_SUCCESS) return 0;                                     
	ap_send_fd(f, r, 0, sb.size, &len);
    apr_file_close(f);                               
#else
	FILE *f = ap_pfopen(r->pool, filename, "r");
	if (f == NULL) return 0;
	ap_send_fd(f, r);
	ap_pfclose(r->pool, f);
#endif
	
                                   
}

void store_pair(HV * pData, const char * sKey, SV * pVal)
{
	SV         ** pTMP    = NULL;
	long          eType   = 0;

	if (SvTYPE(pData) != SVt_PVHV)
	{
		croak("StorePair: Impossible happened: SvTYPE(pData) != SVt_PVHV");
		return;
	}


	/* Always create key => value pair */
	pTMP = hv_fetch(pData, sKey, strlen(sKey), 1);
	if (pTMP == NULL)
	{
		croak("StorePair: Impossible happened: root value is not an HASH");
		return;
	}

	eType = SvTYPE(*pTMP);
	if (eType == SVt_RV)
	{
		if (!SvROK(*pTMP) || !SvRV(*pTMP) || SvTYPE(SvRV(*pTMP)) != SVt_PVAV)
		{
			croak("StorePair: Impossible happened: value is not an ARRAY ref");
			return;
		}

		av_push((AV*)SvRV(*pTMP), pVal);
	}
	else if (eType == SVt_PV)
	{
		AV * pAV = newAV();
		av_push(pAV, *pTMP);
		av_push(pAV, pVal);
		*pTMP = newRV_noinc((SV*)pAV);
	}
	else
	{
		SvREFCNT_dec(*pTMP);
		*pTMP = pVal;
	}

	
	
}

int iterator(void        * req,
             const char  * key,
             const char  * value)
{
	HV * pData = (HV *)req;

	// Nothing to do?
	if (key == NULL || value == NULL || value[0] == '\0') { return 1; }


	store_pair(pData, key, newSVpv(value, 0));

	return 1;

}

//**************************** XS *********************************

MODULE = Dendral::HTTP::Response		PACKAGE = Dendral::HTTP::Response		

IV add_cookie(self, ...)
	SV *self;
	PREINIT:
		request_rec *r;
		int i = 0;
		char *name = NULL;
		char *value = NULL;
		char *expires = NULL;
		char *domain = NULL;
		char *path = NULL;
		char *max_age = NULL;
		int secure = 0;
		int httponly = 0;
	CODE:
		if (!SvROK(self)) {XSRETURN_UNDEF;}
		if (items % 2 == 0)
		{
			croak("ERROR: Dendral::HTTP::Response add_cookie - called with odd number of option parameters - should be of the form option => value");
		}

		r = sv2request_rec(self,RCLASS);

		for (i = 1; i < items; i+=2)
		{

			char * szKey = SvPV_nolen(ST(i));
			SV *szValue = ST(i + 1);
			if (strcasecmp("NAME", szKey) == 0)
			{
				name = escape(r -> pool, SvPV_nolen(szValue));
			}
			else if (strcasecmp("VALUE", szKey) == 0)
			{

				if (SvROK(szValue) && SvTYPE(SvRV(szValue)) == SVt_PVAV)
				{
					AV * szValueAV = (AV*) SvRV(szValue);
					value = avcookie2char(r, szValueAV);
				}
				else if (SvROK(szValue) && SvTYPE(SvRV(szValue)) == SVt_PVHV)
				{
					HV * szValueHV = (HV*) SvRV(szValue);
					value = hvcookie2char(r, szValueHV);
				}
				else value = SvPV_nolen(szValue);

			}
			else if (strcasecmp("DOMAIN", szKey) == 0)
			{
				domain = ap_pstrdup(r->pool, SvPV_nolen(szValue));
				ap_str_tolower(domain);
			}
			else if (strcasecmp("PATH", szKey) == 0)
			{
				path = SvPV_nolen(szValue);
			}
			else if (strcasecmp("EXPIRES", szKey) == 0)
			{
				expires = parse_expires(r, SvPV_nolen(szValue));
			}
			else if (strcasecmp("MAX_AGE", szKey) == 0)
			{
				max_age = SvPV_nolen(szValue);
			}
			else if (strcasecmp("SECURE", szKey) == 0)
			{
				secure = SvIV(szValue);
			}
			else if (strcasecmp("HTTPONLY", szKey) == 0)
			{
				httponly = SvIV(szValue);
			}
		}
		
		if (!name) {XSRETURN_UNDEF;}
		
		char * cookie = ap_pstrcat(r -> pool, name, "=", value ? value : "", "; ", 
		                           domain ? ap_psprintf(r -> pool, "domain=%s; ",domain) : "",
		                           path ? ap_psprintf(r -> pool, "path=%s; ",path) : "",
		                           expires ? ap_psprintf(r -> pool, "expires=%s; ",expires) : "", 
		                           max_age ? ap_psprintf(r -> pool, "max-age=%s; ",max_age) : "", 
		                           secure > 0 ? "secure; " : "",
		                           httponly > 0 ? "httponly; " : "",
		                           NULL);
		
		ap_table_add(r -> err_headers_out, "Set-cookie", cookie);

		RETVAL = 1;
	OUTPUT:
		RETVAL

IV set_http_code(self, code)
	SV *self;
	SV *code;
	PREINIT:
		request_rec *r;
	CODE:
		if (!SvROK(self)) {XSRETURN_UNDEF;}
		r = sv2request_rec(self,RCLASS);
		
		r -> status = SvIV(code);
		
		RETVAL = 1;
	OUTPUT:
		RETVAL

IV get_http_code(self)
	SV *self;
	PREINIT:
		request_rec *r;
	CODE:
		if (!SvROK(self)) {XSRETURN_UNDEF;}
		r = sv2request_rec(self, RCLASS);

		RETVAL = r -> status;
	OUTPUT:
		RETVAL

IV send_http_header(self)
	SV *self;
	PREINIT:
		request_rec *r;
	CODE:
		if (!SvROK(self)) {XSRETURN_UNDEF;}
		r = sv2request_rec(self, RCLASS);
		
		ap_send_http_header(r);
		
		RETVAL = 1;
	OUTPUT:
		RETVAL

IV redirect(self, uri)
	SV *self;
	SV *uri;
	PREINIT:
		request_rec *r;
	CODE:
		if (!SvROK(self)) {XSRETURN_UNDEF;}
		r = sv2request_rec(self, RCLASS);
		
		ap_table_set(r -> headers_out, "Location", SvPV_nolen(uri));
		r -> status = HTTP_MOVED_TEMPORARILY;
		
		RETVAL = 1;
	OUTPUT:
		RETVAL

IV redirect_permanent(self, uri)
	SV *self;
	SV *uri;
	PREINIT:
		request_rec *r;
	CODE:
		if (!SvROK(self)) {XSRETURN_UNDEF;}
		r = sv2request_rec(self, RCLASS);
		
		ap_table_set(r -> headers_out, "Location", SvPV_nolen(uri));
		r -> status = HTTP_MOVED_PERMANENTLY;
		
		RETVAL = 1;
	OUTPUT:
		RETVAL

IV set_header(self, name, value)
	SV *self;
	SV *name;
	SV *value;
	PREINIT:
		request_rec *r;
	CODE:
		if (!SvROK(self)) {XSRETURN_UNDEF;}
		if (!SvOK(name) || !SvTRUE(name)) {XSRETURN_UNDEF;}

		r = sv2request_rec(self, RCLASS);

		ap_table_set(r -> headers_out, SvPV_nolen(name), SvPV_nolen(value));
		
		RETVAL = 1;
	OUTPUT:
		RETVAL

SV* get_header(self, name = NULL)
	SV *self;
	SV *name;
	PREINIT:
		request_rec *r;
	CODE:
		if (!SvROK(self)) {XSRETURN_UNDEF;}
		
		r = sv2request_rec(self, RCLASS);

		if (!name || !SvOK(name) || !SvTRUE(name))
		{
			HV *hash = newHV();
			
			ap_table_do(iterator, hash, r -> headers_out, NULL);
			RETVAL = newRV_noinc((SV*) hash);
		}
		else
		{
			const char *header = ap_table_get(r -> headers_out, SvPV_nolen(name));
			RETVAL = newSVpv(header, 0);
		}
	OUTPUT:
		RETVAL

IV set_content_type(self, value)
	SV *self;
	SV *value;
	PREINIT:
		request_rec *r;
	CODE:
		if (!SvROK(self)) {XSRETURN_UNDEF;}

		r = sv2request_rec(self, RCLASS);

		char *tmp = ap_pstrdup(r -> pool, SvPV_nolen(value));
		ap_content_type_tolower(tmp);
		r -> content_type = tmp;
		ap_table_set(r -> headers_out, "Content-Type", tmp);
		
		RETVAL = 1;
	OUTPUT:
		RETVAL
		
SV* get_content_type(self)
	SV *self;
	PREINIT:
		request_rec *r;
	CODE:
		if (!SvROK(self)) {XSRETURN_UNDEF;}
		
		r = sv2request_rec(self, RCLASS);

		const char *content_type = ap_table_get(r -> headers_out, "Content-Type");
		
		RETVAL = newSVpv(content_type, 0);
	OUTPUT:
		RETVAL

IV delete_header(self, name)
	SV *self;
	SV *name;
	PREINIT:
		request_rec *r;
	CODE:
		if (!SvROK(self)) {XSRETURN_UNDEF;}
		if (!SvOK(name) || !SvTRUE(name)) {XSRETURN_UNDEF;}

		r = sv2request_rec(self, RCLASS);

		ap_table_unset(r -> headers_out, SvPV_nolen(name));

		RETVAL = 1;
	OUTPUT:
		RETVAL

IV merge_header(self, name, value)
	SV *self;
	SV *name;
	SV *value;
	PREINIT:
		request_rec *r;
	CODE:
		if (!SvROK(self)) {XSRETURN_UNDEF;}
		if (!SvOK(name) || !SvTRUE(name)) {XSRETURN_UNDEF;}

		r = sv2request_rec(self, RCLASS);

		ap_table_merge(r -> headers_out, SvPV_nolen(name), SvPV_nolen(value));

		RETVAL = 1;
	OUTPUT:
		RETVAL

IV clear_headers(self)
	SV *self;
	PREINIT:
		request_rec *r;
	CODE:
		if (!SvROK(self)) {XSRETURN_UNDEF;}
		r = sv2request_rec(self, RCLASS);

		ap_table_clear(r -> headers_out);

		RETVAL = 1;
	OUTPUT:
		RETVAL

IV send_file(self, filename)
	SV *self;
	SV *filename;
	PREINIT:
		request_rec *r;
	CODE:
		if (!SvROK(self)) {XSRETURN_UNDEF;}
		if (!SvOK(filename) || !SvTRUE(filename)) {XSRETURN_UNDEF;}

		r = sv2request_rec(self, RCLASS);

		if (!_send_file(r, SvPV_nolen(filename))) {XSRETURN_UNDEF;}

		RETVAL = 1;
	OUTPUT:
		RETVAL
