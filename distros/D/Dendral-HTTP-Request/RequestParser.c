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
 *      RequestParser.c
 *
 * $CAS$
 */

#define DEFAULT_ENCTYPE    "application/x-www-form-urlencoded"
#define MULTIPART_ENCTYPE  "multipart/form-data"
#define TEXT_XML_ENCTYPE   "text/xml"

#include "RequestStruct.h"

/*
 * Store Par
 */
void StorePair(HV * pData, const char * sKey, SV * pVal)
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

static void unescape_space(char* szString)
{
	register int x;
	for(x=0;szString[x];x++) 
	{
		if(szString[x] == '+') szString[x] = ' ';
	}
}

void ParseArguments(Request * pRequest, const char* szString)
{
	char *szKey;
	char *szVal;

	while(*szString && (szVal = ap_getword(pRequest -> request -> pool, (const char**) &szString, '&'))) 
	{
		szKey = ap_getword(pRequest -> request -> pool, (const char**) &szVal, '=');

		ap_unescape_url(szKey);
		unescape_space(szVal);
		ap_unescape_url(szVal);

		StorePair(pRequest -> arguments, szKey, newSVpv(szVal, 0));
	}
}


/*
 * Parse cookies foo=bar; baz=bar+baz/boo
 */
void ParseCookies(Request * pRequest, char * szString)
{
	const char *pair;

	if(!szString) return;
	

	
	while(*szString && (pair = ap_getword(pRequest -> request -> pool, (const char**) &szString, ';'))) 
	{
		const char *szKey, *szVal;
		if(*szString == ' ') ++szString;
		szKey = ap_getword(pRequest -> request -> pool, (const char**) &pair, '=');
		
		while(*pair && (szVal = ap_getword(pRequest -> request -> pool,(const char**) &pair, '&'))) 
		{
			ap_unescape_url((char*) szVal);

			StorePair(pRequest -> cookies, szKey, newSVpv(szVal, 0));


		}
	}
}

/*
 * Find first occurense in string
 */
static const char * StrCaseStr(const char * sX, const char * sY)
{
	while (tolower(*sX) == tolower(*sY))
	{
		++sY; ++sX;
		if (*sY == '\0') { return sX; }
	}
	
	return NULL;
}


/* Apache 2.X */
#if (AP_SERVER_MAJORVERSION_NUMBER == 2)

/*
 * Parse POST request
 */
static int ParsePOST(Request       * pRequest,
                     RequestParser * pRequestParser)
{
	apr_bucket_brigade  * pBucketBrigade = apr_brigade_create(pRequest -> request -> pool, pRequest -> request -> connection -> bucket_alloc);
	int                   iEOSFound   = 0;
	apr_status_t          iReadStatus = 0;

	int iReadBytes = 0;
	int iCanRead = 0;
	do
	{
		apr_bucket * oBucket;

		iReadStatus = ap_get_brigade(pRequest -> request -> input_filters, pBucketBrigade, AP_MODE_READBYTES, APR_BLOCK_READ, HUGE_STRING_LEN);
		if (iReadStatus != APR_SUCCESS)
		{
			warn("Dendral::HTTP::Request: Error reading request entity data");
			return HTTP_INTERNAL_SERVER_ERROR;
		}

		oBucket = APR_BRIGADE_FIRST(pBucketBrigade);
		while (oBucket != APR_BRIGADE_SENTINEL(pBucketBrigade))
		{
			const char * pData;
			apr_size_t iDataSize;

			if (APR_BUCKET_IS_EOS(oBucket))
			{
				iEOSFound = 1;
				break;
			}

			if (APR_BUCKET_IS_FLUSH(oBucket)) { continue; }

			// Read data
			apr_bucket_read(oBucket, &pData, &iDataSize, APR_BLOCK_READ);

			// Check max. post size
			if (pRequest -> max_post_size != -1 && iReadBytes >= pRequest -> max_post_size) { iCanRead = -1; }

			// Process data
			if (iCanRead == 0) { pRequestParser -> ParseChunk(pRequest, pData, pData + iDataSize); }

			// Read bytes
			iReadBytes += iDataSize;

			oBucket = APR_BUCKET_NEXT(oBucket);
		}
		apr_brigade_destroy(pBucketBrigade);
	}
	while (iEOSFound == 0);
	apr_brigade_destroy(pBucketBrigade);

	if (iCanRead == -1)
	{
		warn("Dendral::HTTP::Request: POST Content-Length of %d bytes exceeds the limit of %d bytes", (int)iReadBytes, (int)pRequest -> max_post_size);
		return HTTP_REQUEST_ENTITY_TOO_LARGE;
	}

	return OK;
}



/* Apache 1.3.X */
#else
/*
 * Parse POST request
 */
static int ParsePOST(Request       * pRequest,
                     RequestParser * pRequestParser)
{
	int   iDataSize  = 0;
	int   iReadBytes = 0;
	int   iCanRead   = 0;
	int   iRC        = OK;

	/* Set timeout for request */
	ap_hard_timeout((char *)"ParsePOST", pRequest -> request);

	/* Read data */
	while ((iDataSize = ap_get_client_block(pRequest -> request, pRequest -> escape_buffer, C_ESCAPE_BUFFER_LEN)) > 0)
	{
		/* Read bytes */
		iReadBytes += iDataSize;

		/* Check max. post size */
		if (pRequest -> max_post_size != -1 && iReadBytes >= pRequest -> max_post_size) { iCanRead = -1; }

		/* Process data */
		if (iCanRead == 0)
		{
			iRC = pRequestParser -> ParseChunk(pRequest, pRequest -> escape_buffer, pRequest -> escape_buffer + iDataSize);
		}

		/* Reset timeout */
		ap_reset_timeout(pRequest -> request);
	}
	/* Remove timeout */
	ap_kill_timeout(pRequest -> request);

	/* All done */
	if (iCanRead == -1)
	{
		warn("Dendral::HTTP::Request: POST Content-Length of %d bytes exceeds the limit of %d bytes", (int)iReadBytes, (int)pRequest -> max_post_size);
		return HTTP_REQUEST_ENTITY_TOO_LARGE;
	}

	return iRC;
}


#endif




//
// Read request
//
int ReadRequest(Request * pRequest)
{
	int iRC = OK;

	static const char * szBoundaryPrefix = "\r\n--";

	// GET
	if (pRequest -> request -> method_number == M_GET && pRequest -> request -> args)
	{
		ParseArguments(pRequest, pRequest -> request -> args);
	}

	// POST
	if (pRequest -> request -> method_number == M_POST)
	{

#if (AP_SERVER_MAJORVERSION_NUMBER != 2)
		/* Got Error? */
		if (ap_setup_client_block(pRequest -> request, REQUEST_CHUNKED_ERROR) != OK) { return -1; }
#endif

		// Get content type
		const char * szContentType = ap_table_get(pRequest -> request -> headers_in, "Content-Type");

		// foo=bar&baz=boo
		const char * szFoundContentType = NULL;
		char       *  szBoundary         = NULL;

		// URL-encoded data
		if ((szFoundContentType = StrCaseStr(szContentType, DEFAULT_ENCTYPE)) != NULL)
		{
			UrlencodedParser.ParseInit(pRequest);
			iRC = ParsePOST(pRequest, &UrlencodedParser);
			UrlencodedParser.ParseDone(pRequest);
		}
		// Multipart message
		else if ((szFoundContentType = StrCaseStr(szContentType, MULTIPART_ENCTYPE)) != NULL)
		{
			// Get boundary
			const char * szTMPBoundary = StrCaseStr(szFoundContentType, "; boundary=");
			if (szTMPBoundary == NULL)
			{
				warn("Dendral::HTTP::Request: Read POST(" MULTIPART_ENCTYPE "), invalid boundary");
				return HTTP_INTERNAL_SERVER_ERROR;
			}
			// New boundary
			szBoundary = (char *)ap_pcalloc(pRequest -> request -> pool, strlen(szTMPBoundary) + 5);
			strcpy(szBoundary, szBoundaryPrefix);
			stpcpy(szBoundary + 4, szTMPBoundary);

			pRequest -> boundary = szBoundary;
		
			MultipartParser.ParseInit(pRequest);
			iRC = ParsePOST(pRequest, &MultipartParser);
			MultipartParser.ParseDone(pRequest);
		}
/*
		/ * XML POST data, TBD * /
		else if ((szFoundContentType = StrCaseStr(szContentType, TEXT_XML_ENCTYPE)) != NULL)
		{
			XMLParser.ParseInit(pRequest);
			iRC = ParsePOST(pRequest, &XMLParser);
			XMLParser.ParseDone(pRequest);
		}
*/
		/* Default parser */
		else
		{
			DefaultParser.ParseInit(pRequest);
			iRC = ParsePOST(pRequest, &DefaultParser);
			DefaultParser.ParseDone(pRequest);
		}
	}

	return iRC;
}

/* End. */

