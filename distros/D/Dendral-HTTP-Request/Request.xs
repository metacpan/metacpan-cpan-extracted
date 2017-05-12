/*-
 * Copyright (c) 2005 - 2010 CAS Dev Team
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 4. Neither the name of the CAS Dev. Team nor the names of its contributors
 *    may be used to endorse or promote products derived from this software
 *    without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE REGENTS AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 *
 *      Request.xs
 *
 * $CAS$
 */

#include <string.h>

#include "RequestStruct.h"

/* Brain-damaged Perl 5.8 API stupidity. */
#if ((PERL_API_VERSION == 8) || (PERL_API_VERSION == 6))
    #ifdef newXS
        #undef newXS
        #define newXS(method, func, file) Perl_newXS(aTHX_ (char *)(method), func, (char *)(file))
    #endif
#endif




/* Apache 2.X */
#if (AP_SERVER_MAJORVERSION_NUMBER == 2)

/*
 * Unlink uploaded files
 */
static apr_status_t upload_cleanup(void *ptr)
{
        Request * pRequest = (Request *)ptr;

	const apr_array_header_t  * aFilesTable = apr_table_elts(pRequest -> filelist);
	const int                   iElements   = aFilesTable -> nelts;
	apr_table_entry_t         * aElements   = (apr_table_entry_t *)aFilesTable -> elts;
	int iI = 0;
	for(; iI < iElements; ++iI)
	{
		char * szKey = aElements[iI].key;
		if (szKey != NULL && *szKey != '\0') { unlink(szKey); }
	}

	return APR_SUCCESS;
}


/* Apache 1.3.X */
#else

/*
 * Unlink uploaded files
 */
static int FilesIterator(void        * req,
                         const char  * key,
                         const char  * value)
{
	// Nothing to do?
	if (key == NULL || *key == '\0') { return 1; }

	unlink(key);

return 1;
}

static void upload_cleanup(void *ptr)
{
	Request * pRequest = (Request *)ptr;

	/* Remove uploaded files */
	ap_table_do(FilesIterator, NULL, pRequest -> filelist, NULL);
}


#endif


/*
 * Iterate through headers
 */
static int HeaderIterator(void        * req,
                          const char  * key,
                          const char  * value)
{
	HV * pData = (HV *)req;

	// Nothing to do?
	if (key == NULL || value == NULL || value[0] == '\0') { return 1; }

	StorePair(pData, key, newSVpv(value, 0));

return 1;
}

/*
 * Handle Apache request
 */
static void HandleRequest(Request * pRequest)
{
	int iTMP;
	/* Need for apache cleanup */
	pRequest -> filelist = ap_make_table(pRequest -> request -> pool, DEFAULT_TABLE_NELTS);

	/* Parse Headers */
	ap_table_do(HeaderIterator, pRequest -> headers, pRequest -> request -> headers_in, NULL);

	/* Upload cleanup hook */
	ap_register_cleanup(pRequest -> request -> pool, pRequest, upload_cleanup, ap_null_cleanup);

	/* Parse request cookies */
	ParseCookies(pRequest, (char*) ap_table_get(pRequest -> request -> headers_in, "Cookie"));

	/* Parse request arguments */
	iTMP = ReadRequest(pRequest);
	if (iTMP != OK && pRequest -> die_on_errors == 0)
	{
		croak("ERROR: Can't parse request arguments data");
	}
}

#define Apache request_rec

//**************************** XS *********************************

MODULE = Dendral::HTTP::Request		PACKAGE = Dendral::HTTP::Request

Request *
Request::new(r, ...)
    Apache * r
    PREINIT:
	Request  * pRequest = NULL;
	int        iTMP     = 0;
	int        iI       = 0;
    CODE:
	pRequest = (Request *)ap_palloc(r -> pool, sizeof(Request));
	pRequest -> request = r;

	if (items % 2 != 0)
	{
		croak("ERROR: new Dendral::HTTP::Request() called with odd number of option parameters - should be of the form option => value");
	}
	pRequest -> max_post_size = -1;
	pRequest -> max_files     = -1;
	pRequest -> max_file_size = -1;
	pRequest -> tempfile_dir  = ap_pstrdup(r -> pool, "/tmp/");
	pRequest -> die_on_errors = -1;

	for (iI = 2; iI < items; iI+=2)
	{
		STRLEN       iKeyLen = 0;
		STRLEN       iValLen = 0;
#ifdef SvPV_const
		const char * szKey   = SvPV_const(ST(iI), iKeyLen);
		const char * szValue = SvPV_const(ST(iI + 1), iValLen);
#else
		char * szKey   = SvPV(ST(iI), iKeyLen);
		char * szValue = SvPV(ST(iI + 1), iValLen);
#endif
		if (strncasecmp("POST_MAX", szKey, iKeyLen) == 0 ||
		    strncasecmp("MAX_POST", szKey, iKeyLen) == 0)
		{
			sscanf(szValue, "%d", &iTMP);
			/* POST requests disabled */
			if (iTMP < 0) { iTMP = -1; }

			pRequest -> max_post_size = iTMP;
		}
		else if (strncasecmp("MAX_FILES", szKey, iKeyLen) == 0)
		{
			sscanf(szValue, "%d", &iTMP);
			if (iTMP < 0) { iTMP = -1; }

			pRequest -> max_files = iTMP;
		}
		else if (strncasecmp("MAX_FILE_SIZE", szKey, iKeyLen) == 0)
		{
			sscanf(szValue, "%d", &iTMP);
			if (iTMP < 0) { iTMP = -1; }

			pRequest -> max_file_size = iTMP;
		}
		else if (strncasecmp("TMP_DIR", szKey, iKeyLen) == 0 ||
		         strncasecmp("TEMP_DIR", szKey, iKeyLen) == 0 ||
		         strncasecmp("TEMPFILE_DIR", szKey, iKeyLen) == 0)
		{
			if (iValLen > 0)
			{
				pRequest -> tempfile_dir = ap_pstrndup(r -> pool, szValue, iValLen);
				/* Always with trailing slash */
				if(szValue[iValLen - 1] != '/') { pRequest -> tempfile_dir = ap_pstrcat(r -> pool, pRequest -> tempfile_dir, "/", NULL); }
			}
		}
		else if (strncasecmp("DIE_ON_ERRORS", szKey, iKeyLen) == 0)
		{
			pRequest -> die_on_errors = 0;
		}
		else
		{
			croak("ERROR: Unknown parameter name: `%s`", szKey);
		}
	}

	/* Arguments */
	pRequest -> arguments = newHV();
	/* Cookies */
	pRequest -> cookies   = newHV();
	/* Headers */
	pRequest -> headers   = newHV();
	/* Files */
	pRequest -> files     = newHV();
	/* Raw request data */
	pRequest -> raw_post  = newSVpvn("", 0);

	HandleRequest(pRequest);

	RETVAL = pRequest;
    OUTPUT:
	RETVAL

SV *
params(pRequest)
	Request  * pRequest
    PROTOTYPE: $
    CODE:
	RETVAL = newRV_inc((SV*)(pRequest -> arguments));
    OUTPUT:
	RETVAL

SV *
files(pRequest)
	Request  * pRequest
    PROTOTYPE: $
    CODE:
	RETVAL = newRV_inc((SV*)(pRequest -> files));
    OUTPUT:
	RETVAL

SV *
cookies(pRequest)
	Request  * pRequest
    PROTOTYPE: $
    CODE:
	RETVAL = newRV_inc((SV*)(pRequest -> cookies));
    OUTPUT:
	RETVAL

SV *
headers(pRequest)
	Request  * pRequest
    PROTOTYPE: $
    CODE:
	RETVAL = newRV_inc((SV*)(pRequest -> headers));
    OUTPUT:
	RETVAL

SV *
param(pRequest, sKey = NULL)
	Request  * pRequest
	char     * sKey
    CODE:
	/* Return all data */
	if (sKey == NULL)
	{
		RETVAL = newRV_inc((SV*)(pRequest -> arguments));
	}
	/* Only search key in hash */
	else
	{
		SV ** pTMP = hv_fetch(pRequest -> arguments, sKey, strlen(sKey), 0);
		if (pTMP == NULL) { XSRETURN_UNDEF; }

		if (SvROK(*pTMP) && SvTYPE(SvRV(*pTMP)) == SVt_PVAV)
		{
			AV * pAV = (AV *)SvRV(*pTMP);
			/* wantarray? */
			switch (GIMME_V)
			{
				case G_SCALAR:
					{
						I32 iArraySize = av_len(pAV);
						if (iArraySize == -1) { XSRETURN_UNDEF; }

						pTMP = av_fetch(pAV, 0, 0);
						if (pTMP == NULL) { XSRETURN_UNDEF; }

						RETVAL = SvREFCNT_inc(*pTMP);
					}
					break;
				case G_ARRAY:
					{
						I32 iPos;
						I32 iArraySize = av_len(pAV) + 1;
						if (iArraySize == 0) { XSRETURN_UNDEF; }

						if (iArraySize > 1) { EXTEND(SP, iArraySize - 1); }

						for (iPos = 0; iPos < iArraySize; ++iPos)
						{
							pTMP = av_fetch(pAV, iPos, 0);
							ST(iPos) = SvREFCNT_inc(*pTMP);
						}
						XSRETURN(iArraySize);
					}
					break;
			}
		}
		else
		{
			RETVAL = SvREFCNT_inc(*pTMP);
		}
	}
    OUTPUT:
	RETVAL

SV *
cookie(pRequest, sKey = NULL)
	Request  * pRequest
	char     * sKey
    CODE:
	/* Return all data */
	if (sKey == NULL)
	{
		RETVAL = newRV_inc((SV*)(pRequest -> cookies));
	}
	/* Only search key in hash */
	else
	{
		SV ** pTMP = hv_fetch(pRequest -> cookies, sKey, strlen(sKey), 0);
		if (pTMP == NULL) { XSRETURN_UNDEF; }

		if (SvROK(*pTMP) && SvTYPE(SvRV(*pTMP)) == SVt_PVAV)
		{
			AV * pAV = (AV *)SvRV(*pTMP);
			/* wantarray? */
			switch (GIMME_V)
			{
				case G_SCALAR:
					{
						I32 iArraySize = av_len(pAV);
						if (iArraySize == -1) { XSRETURN_UNDEF; }

						pTMP = av_fetch(pAV, 0, 0);
						if (pTMP == NULL) { XSRETURN_UNDEF; }

						RETVAL = SvREFCNT_inc(*pTMP);
					}
					break;
				case G_ARRAY:
					{
						I32 iPos;
						I32 iArraySize = av_len(pAV) + 1;
						if (iArraySize == 0) { XSRETURN_UNDEF; }

						if (iArraySize > 1) { EXTEND(SP, iArraySize - 1); }

						for (iPos = 0; iPos < iArraySize; ++iPos)
						{
							pTMP = av_fetch(pAV, iPos, 0);
							ST(iPos) = SvREFCNT_inc(*pTMP);
						}
						XSRETURN(iArraySize);
					}
					break;
			}
		}
		else
		{
			RETVAL = SvREFCNT_inc(*pTMP);
		}
	}
    OUTPUT:
	RETVAL

SV *
header(pRequest, sKey = NULL)
	Request  * pRequest
	char     * sKey
    CODE:
	/* Return all data */
	if (sKey == NULL)
	{
		RETVAL = newRV_inc((SV*)(pRequest -> headers));
	}
	/* Only search key in hash */
	else
	{
		SV ** pTMP = hv_fetch(pRequest -> headers, sKey, strlen(sKey), 0);
		if (pTMP == NULL) { XSRETURN_UNDEF; }

		if (SvROK(*pTMP) && SvTYPE(SvRV(*pTMP)) == SVt_PVAV)
		{
			AV * pAV = (AV *)SvRV(*pTMP);
			/* wantarray? */
			switch (GIMME_V)
			{
				case G_SCALAR:
					{
						I32 iArraySize = av_len(pAV);
						if (iArraySize == -1) { XSRETURN_UNDEF; }

						pTMP = av_fetch(pAV, 0, 0);
						if (pTMP == NULL) { XSRETURN_UNDEF; }

						RETVAL = SvREFCNT_inc(*pTMP);
					}
					break;
				case G_ARRAY:
					{
						I32 iPos;
						I32 iArraySize = av_len(pAV) + 1;
						if (iArraySize == 0) { XSRETURN_UNDEF; }

						if (iArraySize > 1) { EXTEND(SP, iArraySize - 1); }

						for (iPos = 0; iPos < iArraySize; ++iPos)
						{
							pTMP = av_fetch(pAV, iPos, 0);
							ST(iPos) = SvREFCNT_inc(*pTMP);
						}
						XSRETURN(iArraySize);
					}
					break;
			}
		}
		else
		{
			RETVAL = SvREFCNT_inc(*pTMP);
		}
	}
    OUTPUT:
	RETVAL

SV *
file(pRequest, sKey = NULL)
	Request  * pRequest
	char     * sKey
    CODE:
	/* Return all data */
	if (sKey == NULL)
	{
		RETVAL = newRV_inc((SV*)(pRequest -> files));
	}
	/* Only search key in hash */
	else
	{
		SV ** pTMP = hv_fetch(pRequest -> files, sKey, strlen(sKey), 0);
		if (pTMP == NULL) { XSRETURN_UNDEF; }

		if (SvROK(*pTMP) && SvTYPE(SvRV(*pTMP)) == SVt_PVAV)
		{
			AV * pAV = (AV *)SvRV(*pTMP);
			/* wantarray? */
			switch (GIMME_V)
			{
				case G_SCALAR:
					{
						I32 iArraySize = av_len(pAV);
						if (iArraySize == -1) { XSRETURN_UNDEF; }

						pTMP = av_fetch(pAV, 0, 0);
						if (pTMP == NULL) { XSRETURN_UNDEF; }

						RETVAL = sv_mortalcopy(*pTMP);
					}
					break;
				case G_ARRAY:
					{
						I32 iPos;
						I32 iArraySize = av_len(pAV) + 1;
						if (iArraySize == 0) { XSRETURN_UNDEF; }

						if (iArraySize > 1) { EXTEND(SP, iArraySize - 1); }

						for (iPos = 0; iPos < iArraySize; ++iPos)
						{
							pTMP = av_fetch(pAV, iPos, 0);
							ST(iPos) = sv_mortalcopy(*pTMP);
						}
						XSRETURN(iArraySize);
					}
					break;
			}
		}
		else
		{
			RETVAL = sv_mortalcopy(*pTMP);
		}
	}
    OUTPUT:
	RETVAL

SV *
raw(pRequest)
	Request  * pRequest
    CODE:
	RETVAL = sv_mortalcopy(pRequest -> raw_post);
    OUTPUT:
	RETVAL

SV *
method(pRequest)
	Request  * pRequest
    CODE:
	if (pRequest -> request -> method == NULL) { XSRETURN_UNDEF; }
	RETVAL = newSVpv(pRequest -> request -> method, 0);
    OUTPUT:
	RETVAL

SV *
host(pRequest)
	Request  * pRequest
    CODE:
	if (pRequest -> request -> hostname == NULL) { XSRETURN_UNDEF; }
	RETVAL = newSVpv(pRequest -> request -> hostname, 0);
    OUTPUT:
	RETVAL

SV *
request_time(pRequest)
	Request  * pRequest
    CODE:
	RETVAL = newSViv(pRequest -> request -> request_time);
    OUTPUT:
	RETVAL

SV *
the_request(pRequest)
	Request  * pRequest
    CODE:
	if (pRequest -> request -> the_request == NULL) { XSRETURN_UNDEF; }
	RETVAL = newSVpv(pRequest -> request -> the_request, 0);
    OUTPUT:
	RETVAL

SV *
protocol(pRequest)
	Request  * pRequest
    CODE:
	if (pRequest -> request -> protocol == NULL) { XSRETURN_UNDEF; }
	RETVAL = newSVpv(pRequest -> request -> protocol, 0);
    OUTPUT:
	RETVAL

SV *
unparsed_uri(pRequest)
	Request  * pRequest
    CODE:
	if (pRequest -> request -> unparsed_uri == NULL) { XSRETURN_UNDEF; }
	RETVAL = newSVpv(pRequest -> request -> unparsed_uri, 0);
    OUTPUT:
	RETVAL

SV *
uri(pRequest)
	Request  * pRequest
    CODE:
	if (pRequest -> request -> uri == NULL) { XSRETURN_UNDEF; }
	RETVAL = newSVpv(pRequest -> request -> uri, 0);
    OUTPUT:
	RETVAL

SV *
filename(pRequest)
	Request  * pRequest
    CODE:
	if (pRequest -> request -> filename == NULL) { XSRETURN_UNDEF; }
	RETVAL = newSVpv(pRequest -> request -> filename, 0);
    OUTPUT:
	RETVAL

SV *
path_info(pRequest)
	Request  * pRequest
    CODE:
	if (pRequest -> request -> path_info == NULL) { XSRETURN_UNDEF; }
	RETVAL = newSVpv(pRequest -> request -> path_info, 0);
    OUTPUT:
	RETVAL

SV *
args(pRequest)
	Request  * pRequest
    CODE:
	if (pRequest -> request -> args == NULL) { XSRETURN_UNDEF; }
	RETVAL = newSVpv(pRequest -> request -> args, 0);
    OUTPUT:
	RETVAL

SV *
remote_ip(pRequest)
	Request  * pRequest
    CODE:
	if (pRequest -> request -> connection -> remote_ip == NULL) { XSRETURN_UNDEF; }
	RETVAL = newSVpv(pRequest -> request -> connection -> remote_ip, 0);
    OUTPUT:
	RETVAL

SV *
local_ip(pRequest)
	Request  * pRequest
    CODE:
	if (pRequest -> request -> connection -> local_ip == NULL) { XSRETURN_UNDEF; }
	RETVAL = newSVpv(pRequest -> request -> connection -> local_ip, 0);
    OUTPUT:
	RETVAL

SV *
port(pRequest)
	Request  * pRequest
    CODE:
	RETVAL = newSViv(pRequest -> request -> server -> port);
    OUTPUT:
	RETVAL

void
DESTROY(pRequest)
	Request *  pRequest
    PROTOTYPE: $
    CODE:
	/* warn("Dendral::HTTP::Request::DESTROY(0x%p)", pRequest); */
	hv_undef(pRequest -> arguments);
	SvREFCNT_dec(pRequest -> arguments);
	hv_undef(pRequest -> cookies);
	SvREFCNT_dec(pRequest -> cookies);
	hv_undef(pRequest -> headers);
	SvREFCNT_dec(pRequest -> headers);
	hv_undef(pRequest -> files);
	SvREFCNT_dec(pRequest -> files);
	SvREFCNT_dec(pRequest -> raw_post);

