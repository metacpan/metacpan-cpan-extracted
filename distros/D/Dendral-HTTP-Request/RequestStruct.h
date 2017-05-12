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
 *      RequestStruct.h
 *
 * $CAS$
 */

#ifndef _REQUEST_STRUCT_H__
#define _REQUEST_STRUCT_H__ 1

#ifdef __cplusplus
extern "C" {
#endif

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "perliol.h"
#include "ppport.h"

#ifdef __cplusplus
}
#endif

#include <httpd.h>

#if (AP_SERVER_MAJORVERSION_NUMBER == 2)
	#include "apr_strings.h"
	#include "apr_uri.h"
	#include "util_filter.h"

	#define ap_palloc    apr_palloc
	#define ap_pstrdup   apr_pstrdup
	#define ap_pstrndup  apr_pstrndup
	#define ap_pstrcat   apr_pstrcat
	#define ap_table_add apr_table_add
	#define ap_table_get apr_table_get
	#define ap_table_do apr_table_do

	#define ap_make_table apr_table_make

    #define ap_pcalloc apr_pcalloc
	
	/* CleenUp */
	#define ap_register_cleanup apr_pool_cleanup_register
	#define ap_null_cleanup apr_pool_cleanup_null
	
    #define ap_pfopen(pool, file, mode)  fopen((file), (mode))
    #define ap_pfclose(pool, file)       fclose(file)
    
#endif

#define C_ESCAPE_BUFFER_LEN 8192

#define DEFAULT_TABLE_NELTS 10

/*
 * Request data
 */
typedef struct RequestStruct
{
	/* Apache request            */
	request_rec   * request;
	/* Max. POST size            */
	long long       max_post_size;
	/* Max. number of files      */
	long long       max_files;
	/* Max. file size            */
	long long       max_file_size;
	/* Directory for temp. files */
	char          * tempfile_dir;
	/* Data buffer               */
	char            escape_buffer[C_ESCAPE_BUFFER_LEN];
#if (AP_SERVER_MAJORVERSION_NUMBER == 2)
	apr_table_t   * filelist;
#else
	/* Filetable                 */
	table         * filelist;
#endif
	/* Die on errors?            */
	int             die_on_errors;

	/* Multipart boundary        */
	const char    * boundary;

	/* Parser context            */
	void          * context;

	/* Arguments                 */
	HV            * arguments;
	/* Cookies                   */
	HV            * cookies;
	/* Headers                   */
	HV            * headers;
	/* Files                     */
	HV            * files;
	/* Raw request               */
	SV            * raw_post;

} Request;

/*
 * Request parser
 */
typedef struct RequestParserStruct
{
	/* Init parser        */
	int (*ParseInit)  (Request *);
	/* Parse chunk of data */
	int (*ParseChunk) (Request *, const char *, const char *);
	/* Finish              */
	int (*ParseDone)  (Request *);

} RequestParser;

/*
 * Export table
 */
extern RequestParser UrlencodedParser;
extern RequestParser MultipartParser;
extern RequestParser DefaultParser;

/*
 * Read request
 */
int ReadRequest(Request * pRequest);

/*
 * Parse cookies foo=bar; baz=bar+baz/boo
 */
void ParseCookies(Request * pRequest, char  * szString);

/*
 * Store Pair
 */
void StorePair(HV * pData, const char * sKey, SV * pVal);

#endif /* _REQUEST_STRUCT_H__ */
/* End */

