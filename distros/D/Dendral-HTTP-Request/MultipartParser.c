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

#include <errno.h>
#include <stdio.h>
#include <string.h>

#include "RequestStruct.h"


#define C_CONTENT_DISPOSITION           "Content-Disposition"
#define C_CONTENT_TYPE                  "Content-Type"
#define C_CONTENT_TRANSFER_ENCODING     "Content-Transfer-Encoding"

/* FSM states */
#define C_KEY_CONTENT_DISPOSITION       0x00000001
#define C_KEY_CONTENT_TYPE              0x00000002
#define C_KEY_CONTENT_TRANSFER_ENCODING 0x00000003

/* Undefined state of parser */
#define C_UNDEF                0x00000000
/* End of MIME message */
#define C_END_MIME             0x01000000
/* Unrecoverable error */
#define C_ERROR                0x10000000


/* Boundary section */

#define C_BOUNDARY_IN          0x00010001

#define C_BOUNDARY_IN_SUFFIX1  0x00010020
#define C_BOUNDARY_IN_SUFFIX2  0x00010040
#define C_BOUNDARY_IN_SUFFIX3  0x00010080
#define C_BOUNDARY_IN_SUFFIX4  0x00010100

/* Header section */
#define C_HEADER               0x00020000
#define C_HEADER_CR            0x00020001
#define C_HEADER_LF            0x00020002

#define C_HEADER_CR2           0x00020004
#define C_HEADER_LF2           0x00020008

/* Header fields */
#define C_KEY_NAME             0x00020010
#define C_KEY_PRE_VALUE        0x00020020
#define C_KEY_TAB_VALUE        0x00020040
#define C_KEY_VALUE            0x00020100

/* Body section */
#define C_BODY                 0x00040000
#define C_BODY_FILE            0x00000001
#define C_BODY_VALUE           0x00000002

#define C_FIELD_IS_NAME        0x00100000
#define C_FIELD_IS_FILENAME    0x00200000

#define C_TMP_FNAME_SIZE       1024

/*
 * Parse context
 */
struct MultipartParserContext
{
	/* FSM state                 */
	unsigned int    prev_state;
	/* FSM state                 */
	unsigned int    state;
	/* FSM state                 */
	unsigned int    value_state;

	/* Header field              */
	unsigned int    header_key_id;
	/* Part name                 */
	SV             * name;
	/* File to write             */
	FILE           * file;
	/* File size                 */
	long long        file_size;
	/* Content type              */
	SV             * content_type;

	SV             * content_transfer_encoding;
	/* File name                 */
	SV             * file_name;
	/* File name with path       */
	SV             * full_filename;
	/* Value buffer              */
	SV             * buffer;
	/* Temp. file name           */
	SV             * tmp_name;

	/* Part of boundary          */
	const char      * prev_block_boundary;
	/* Boundary position         */
	const char      * boundary_pos;
	/* Boundary                  */
	const char      * boundary;
};




/*
 * Compare strings
 */
static const char * StrNFirstCaseStr(const char * sX, unsigned int iMaxChars, const char * sY)
{
	while (tolower(*sX) == tolower(*sY))
	{
		if (iMaxChars == 0) { return NULL; }
		++sY; ++sX; --iMaxChars;

		if (*sY == '\0') { return sX; }
	}

return NULL;
}

/*
 * Compare strings
 */
static const char * StrFirstCaseStr(const char * sX, const char * sY)
{
	while (tolower(*sX) == tolower(*sY))
	{
		++sY; ++sX;
		if (*sY == '\0') { return sX; }
	}

return NULL;
}

/*
 * Store Par
 */
static void StoreFile(HV * pData, SV * pKey, HV * pVal)
{

	STRLEN        iKeyLen = 0;
	const char  * sKey    = NULL;

	SV         ** pTMP    = NULL;
	long          eType   = 0;

	if (SvTYPE(pData) != SVt_PVHV)
	{
		croak("StoreFile: Impossible happened: SvTYPE(pData) != SVt_PVHV");
		return;
	}

	iKeyLen = 0;
#ifdef SvPV_const
	sKey    = SvPV_const(pKey, iKeyLen);
#else
	sKey    = SvPV(pKey, iKeyLen);
#endif
//	hv_store(pData, sKey, iKeyLen, newRV_noinc((SV *)pVal), 0);

	/* Always create key => value pair */
	pTMP = hv_fetch(pData, sKey, iKeyLen, 1);
	if (pTMP == NULL)
	{
		croak("StoreFile: Impossible happened: root value is not an HASH");
		return;
	}

	eType = SvTYPE(*pTMP);
	if (eType == SVt_RV)
	{
		if (!SvROK(*pTMP) || !SvRV(*pTMP) || SvTYPE(SvRV(*pTMP)) != SVt_PVAV)
		{
			croak("StoreFile: Impossible happened: value is not an ARRAY ref");
			return;
		}

		av_push((AV*)SvRV(*pTMP), newRV_noinc((SV *)pVal));
	}
	else if (eType == SVt_PV)
	{
		AV * pAV = newAV();
		av_push(pAV, *pTMP);
		av_push(pAV, newRV_noinc((SV *)pVal));
		SvREFCNT_dec(*pTMP);
		*pTMP = newRV_noinc((SV*)pAV);
	}
	else
	{
		SvREFCNT_dec(*pTMP);
		*pTMP = newRV_noinc((SV *)pVal);
	}

}

/*
 * Parse HTTP header
 */
static void MultipartParserParseHeader(Request                        * pRequest,
                                       struct MultipartParserContext  * pContext)
{


	STRLEN       iBufLen  = 0;
#ifdef SvPV_const
	const char * szBuffer = SvPV_const(pContext -> buffer, iBufLen);
#else
	char * szBuffer = SvPV(pContext -> buffer, iBufLen);
#endif
	/* form-data; name="submit-name"
	 * form-data; name="files"; filename="c:\text.txt"
	 * form-data
	 * 123456789
	 */
	const char * szData    = StrFirstCaseStr(szBuffer, "form-data");
	const char * szDataEnd = szBuffer + iBufLen;

	/* Check parameter name */
	if (szData != (szBuffer + 9)) { return; }

	/* Check ';' */
	if (szData == szDataEnd || *szData != ';') { return; }
	++szData;

	/* Parse string */
	for (;;)
	{
		int           iKeyName   = C_UNDEF;
		const char  * szKeyStart = NULL;
		/* Skip spaces */
		while (szData != szDataEnd && *szData == ' ') { ++szData; }

		szKeyStart = szData;
		/* Find '=' */
		while (szData != szDataEnd && *szData != '=') { ++szData; }

		/* Name */
		if (StrNFirstCaseStr(szKeyStart, szData - szKeyStart, "name") != NULL)
		{
			iKeyName = C_FIELD_IS_NAME;
			pContext -> value_state = C_BODY_VALUE;
		}
		/* FileName */
		else if (StrNFirstCaseStr(szKeyStart, szData - szKeyStart, "filename") != NULL)
		{
			iKeyName = C_FIELD_IS_FILENAME;
			pContext -> value_state = C_BODY_FILE;
		}

		if (szData == szDataEnd || *szData != '=') { break; }
		++szData;
		if (szData == szDataEnd || *szData != '"') { break; }
		++szData;
		szKeyStart = szData;
		/* Find '"' */
		while (szData != szDataEnd && *szData != '"') { ++szData; }
		if (szData == szDataEnd) { break; }

		/* Store field name */
		if      (iKeyName == C_FIELD_IS_NAME)
		{
			sv_setpvn(pContext -> name, szKeyStart, szData - szKeyStart);
		}
		/* Store & process filename */
		else if (iKeyName == C_FIELD_IS_FILENAME)
		{
			/* Nothing to do */
			if (szData - szKeyStart == 0) { pContext -> file = NULL; }
			/* Write file */
			else
			{
				char          szTMPFileName[C_TMP_FNAME_SIZE];

				int           iTMPFileNameLen = 0;
				const char  * szFileName      = szData;

				/* Store filename with full path */
				sv_setpvn(pContext -> full_filename, szKeyStart, szData - szKeyStart);

				/* Store filename without path */
				for (;;)
				{
					if (szFileName == szKeyStart) { break; }
					if (*szFileName == '/' || *szFileName == '\\') { ++szFileName; break; }
					--szFileName;
				}
				sv_setpvn(pContext -> file_name, szFileName, szData - szFileName);

				/* File size = 0 */
				pContext -> file_size = 0;

				/* Create temp file name */
				iTMPFileNameLen = snprintf(szTMPFileName, C_TMP_FNAME_SIZE, "u%d.p%d.t%d.r%d", (int)getuid(), (int)getpid(), (int)time(NULL), (int)rand());
				if (iTMPFileNameLen == 0) { pContext -> file = NULL; }
				else
				{
					STRLEN        iFullTMPFileNameLen = 0;
					const char  * szFullTMPFileName   = NULL;

					sv_setpvn(pContext -> tmp_name, pRequest -> tempfile_dir, strlen(pRequest -> tempfile_dir));
					sv_catpvn(pContext -> tmp_name, szTMPFileName, iTMPFileNameLen);
#ifdef SvPV_const
					szFullTMPFileName = SvPV_const(pContext -> tmp_name, iFullTMPFileNameLen);
#else
					szFullTMPFileName = SvPV(pContext -> tmp_name, iFullTMPFileNameLen);
#endif
					/* Open file for writing */
					pContext -> file = ap_pfopen(pRequest -> request -> pool, szFullTMPFileName, "wb");

					if (pContext -> file != NULL)
					{
						/* Need Apache delete_tmp_file hook here */
						char * sKey = ap_pstrdup(pRequest -> request -> pool, szFullTMPFileName);
						ap_table_add(pRequest -> filelist, sKey, "dummy");
					}
					else
					{
						warn("Dendral::HTTP::Request: Can't open file \"%s\" for writing: %s", szFullTMPFileName, strerror(errno));
					}
				}
			}

		}
		++szData;
		if (szData == szDataEnd || *szData != ';') { break; }
		++szData;
		if (szData == szDataEnd) { break; }
	}
/*
fprintf(stderr, "NAME          `%s`\n", oFile.name.c_str());
fprintf(stderr, "FULL FILENAME `%s`\n", oFile.full_filename.c_str());
fprintf(stderr, "FILENAME      `%s`\n", oFile.filename.c_str());
fprintf(stderr, "TMP NAME      `%s`\n\n\n", oFile.tmp_name.c_str());
fflush(stderr);
*/
}

/*
 * Handle end of buffer
 * If szStringSave pointer is NOT NULL, and
 * 1. state == C_BODY_FILE, write data to the disc
 * 2. state == C_BODY_VALUE, add data to buffer
*/
static const char * MultipartParserHandleEndOfBuffer(Request                        * pRequest,
                                                     struct MultipartParserContext  * pContext,
                                                     const char                     * szStringSave,
                                                     const char                     * szBoundaryStart,
                                                     const unsigned int               iNewState)
{
	/* Store szBoundary, if need */
	if (szStringSave != NULL)
	{
		/* Write data to file */
		if (pContext -> value_state == C_BODY_FILE)
		{
			/* Avoid stupid warning "warn_unused_result" */
			size_t iHandleBytes = 0;
			unsigned int iBufSize = szBoundaryStart - szStringSave;

			/* Write boundary-like data */
			if (pContext -> prev_block_boundary != NULL)
			{
				const unsigned int iBufSize = pContext -> prev_block_boundary - pContext -> boundary;
				if (pContext -> file != NULL)
				{
					pContext -> file_size += iBufSize;
					/* Don't write data if file size is greater than pRequest -> max_file_size */
					if (!(pRequest -> max_file_size != -1 && pContext -> file_size >= pRequest -> max_file_size))
					{
						iHandleBytes = fwrite(pContext -> boundary, 1, iBufSize, pContext -> file);
					}
				}
				pContext -> prev_block_boundary = NULL;
			}

			/* Write data */
			if (pContext -> file != NULL && iBufSize != 0)
			{
				pContext -> file_size += iBufSize;
				/* Don't write data if file size is greater than pRequest -> max_file_size */
				if (!(pRequest -> max_file_size != -1 && pContext -> file_size >= pRequest -> max_file_size))
				{
					iHandleBytes = fwrite(szStringSave, 1, iBufSize, pContext -> file);
				}
			}
		}
		/* Append buffer */
		else if (pContext -> value_state == C_BODY_VALUE)
		{
			unsigned int iBufSize = szBoundaryStart - szStringSave;

			/* Write boundary-like data */
			if (pContext -> prev_block_boundary != NULL)
			{
				const unsigned int iBufSize = pContext -> prev_block_boundary - pContext -> boundary;
				sv_catpvn(pContext -> buffer, pContext -> boundary, iBufSize);
				pContext -> prev_block_boundary = NULL;
			}
			sv_catpvn(pContext -> buffer, szStringSave, iBufSize);
		}
	}
	/* Set new state */
	pContext -> state = iNewState;
	/* Store buffer position */
	szStringSave = szBoundaryStart;

return szStringSave;
}

/*
 * Commit operation
 */
void MultipartParserCommitSection(Request                        * pRequest,
                                  struct MultipartParserContext  * pContext)
{
	/* Write data to file */
	if (pContext -> value_state == C_BODY_FILE)
	{
		/* Only if file was open */
		if (pContext -> file != NULL)
		{
			HV * pFileHash = newHV();
			ap_pfclose(pRequest -> request -> pool, pContext -> file);
//			pContext -> file = NULL;

			/* Unlink file if file size is greater than pRequest -> max_file_size */
			if (pRequest -> max_file_size != -1 && pContext -> file_size >= pRequest -> max_file_size)
			{
				STRLEN iNameLen = 0;
#ifdef SvPV_const
				const char * sName = SvPV_const(pContext -> name, iNameLen);
#else
				char * sName       = SvPV(pContext -> name, iNameLen);
#endif
				warn("Dendral::HTTP::Request: File \"%s\" not saved: file size %llu is larger than max allowed (%llu) bytes",
				      sName,
				      (unsigned long long)(pContext -> file_size),
				      (unsigned long long)(pRequest -> max_file_size));
#ifdef SvPV_const
				sName = SvPV_const(pContext -> tmp_name, iNameLen);
#else
				sName = SvPV(pContext -> tmp_name, iNameLen);
#endif
				unlink(sName);
			}

			/* Temp file name */
			(void)hv_store(pFileHash, "tmp_name",      sizeof("tmp_name") -1,      newSVsv(pContext -> tmp_name),      0);
			/* File name */
			(void)hv_store(pFileHash, "name",          sizeof("name") -1,          newSVsv(pContext -> name),          0);
			/* Full file name */
			(void)hv_store(pFileHash, "filename",      sizeof("filename") -1,      newSVsv(pContext -> file_name),     0);
			/* Full file name */
			(void)hv_store(pFileHash, "full_filename", sizeof("full_filename") -1, newSVsv(pContext -> full_filename), 0);
			/* File size */
			(void)hv_store(pFileHash, "filesize",      sizeof("filesize") -1,      newSViv(pContext -> file_size),     0);
			/* Content-type field */
			(void)hv_store(pFileHash, "content_type",  sizeof("content_type") -1,  newSVsv(pContext -> content_type),  0);
			/* Content-transfer-encoding field */
			if (SvTRUE(pContext -> content_transfer_encoding))
			{
				(void)hv_store(pFileHash, "content_transfer_encoding",
				                                     sizeof("content_transfer_encoding") -1, newSVsv(pContext -> content_transfer_encoding), 0);
			}

			/* Store file */
			StoreFile(pRequest -> files, pContext -> name, pFileHash);
		}
	}
	/* Append buffer */
	else if (pContext -> value_state == C_BODY_VALUE)
	{
		StorePair(pRequest -> arguments, SvPV_nolen(pContext -> name), newSVsv(pContext -> buffer));
	}
}

/*
 * Parse chunk of data
 */
static int MultipartParserParseChunk(Request     * pRequest,
                                     const char  * szString,
                                     const char  * szStringEnd)
{
	struct MultipartParserContext  * pContext = (struct MultipartParserContext *)(pRequest -> context);

	const char * szBoundaryStart = szString;
	const char * szStringSave    = szString;

	if (pContext -> boundary_pos != pContext -> boundary) { pContext -> prev_block_boundary = pContext -> boundary_pos; }
	else                                                  { pContext -> prev_block_boundary = NULL;                     }

	/*
	 * \r - \n - dash - dash - BOUNADRY [dash - dash] - \r - \n
	 * +------------------------------+  |      |       |    |
	 * |                                 |      |       |    |
	 * |                                 |      |       |    BOUNDARY_IN_SUFFIX4
	 * |                                 |      |       |
	 * |                                 |      |       BOUNDARY_IN_SUFFIX3
	 * |                                 |      |
	 * |                                 |      BOUNDARY_IN_SUFFIX2
	 * |                                 |
	 * |                                 BOUNDARY_IN_SUFFIX1
	 * |
	 * C_BOUNDARY_IN
	 */


	if (pContext -> state == C_BOUNDARY_IN)         { goto BOUNDARY_IN;         }

	if (pContext -> state == C_BOUNDARY_IN_SUFFIX1) { goto BOUNDARY_IN_SUFFIX1; }
	if (pContext -> state == C_BOUNDARY_IN_SUFFIX2) { goto BOUNDARY_IN_SUFFIX2; }
	/* Never happenes, but let it still here */
	if (pContext -> state == C_BOUNDARY_IN_SUFFIX3) { goto BOUNDARY_IN_SUFFIX3; }
	if (pContext -> state == C_BOUNDARY_IN_SUFFIX4) { goto BOUNDARY_IN_SUFFIX4; }

	/* Header: [space] HeaderValue; optional="field" \r - \n [ \r - \n ]
	 * |        |      |                              |    |    |    |
	 * |        |      |                              |    |    |    C_HEADER_LF2
	 * |        |      |                              |    |    |
	 * |        |      |                              |    |    HEADER_CR2
	 * |        |      |                              |    |
	 * |        |      |                              |    HEADER_LF
	 * |        |      |                              |
	 * |        |      |                              HEADER_CR
	 * |        |      |
	 * |        |      C_KEY_VALUE
	 * |        |
	 * |        C_KEY_PRE_VALUE
	 * |
	 * C_KEY_NAME
	 */

	if (pContext -> state == C_HEADER)     { goto HEADER;     }
	if (pContext -> state == C_HEADER_CR)  { goto HEADER_CR;  }
	if (pContext -> state == C_HEADER_LF)  { goto HEADER_LF;  }
	if (pContext -> state == C_HEADER_CR2) { goto HEADER_CR2; }
	if (pContext -> state == C_HEADER_LF2) { goto HEADER_LF2; }

	if (pContext -> state == C_KEY_NAME)      { goto KEY_NAME;      }
	if (pContext -> state == C_KEY_PRE_VALUE) { goto KEY_PRE_VALUE; }
	if (pContext -> state == C_KEY_VALUE)     { goto KEY_VALUE;     }

	for(;;)
	{
		/* Check szBoundary */
		pContext -> boundary_pos = pContext -> boundary;
		/* Store state */
		pContext -> prev_state   = pContext -> state;

		/* Start of szBoundary */
		pContext -> state = C_BOUNDARY_IN;
BOUNDARY_IN:
		/* Start of szBoundary */
		szBoundaryStart = szString;

		/* Boundary body */
		for(;;)
		{
			/* End of szBoundary found */
			if (*pContext -> boundary_pos == '\0')
			{
				pContext -> prev_block_boundary = NULL;

				/* End of buffer */
				if (szString == szStringEnd)
				{
					szStringSave = MultipartParserHandleEndOfBuffer(pRequest, pContext, szStringSave, szBoundaryStart, C_BOUNDARY_IN);
					return OK;
				}

				/* Boundary suffix */
				if(*szString == '-')
				{
					/* End of buffer? */
					++szString;
BOUNDARY_IN_SUFFIX1:
					if (szString == szStringEnd)
					{
						szStringSave = MultipartParserHandleEndOfBuffer(pRequest, pContext, szStringSave, szBoundaryStart, C_BOUNDARY_IN_SUFFIX1);
						return OK;
					}

					/* Fatal error: double dashes not found after szBoundary */
					if(*szString != '-')
					{
						pContext -> state = C_ERROR;
						warn("Dendral::HTTP::Request: Fatal error: double dashes not found after boundary");
						return HTTP_INTERNAL_SERVER_ERROR;
					}

					/* End of buffer? */
					++szString;
BOUNDARY_IN_SUFFIX2:

					if (szString == szStringEnd)
					{
						szStringSave = MultipartParserHandleEndOfBuffer(pRequest, pContext, szStringSave, szBoundaryStart, C_BOUNDARY_IN_SUFFIX2);
						return OK;
					}

					/* End of MIME reached, no errors */
					pContext -> state = C_END_MIME;
				}
BOUNDARY_IN_SUFFIX3:

				/* CRLF after szBoundary, REQUIRED in all cases! */
				if(*szString != '\r')
				{
					pContext -> state = C_ERROR;
					warn("Dendral::HTTP::Request: LF after CR REQUIRED in all cases");
					return HTTP_INTERNAL_SERVER_ERROR;
				}

				++szString;
				/* End of buffer */
				if (szString == szStringEnd)
				{
					szStringSave = MultipartParserHandleEndOfBuffer(pRequest, pContext, szStringSave, szBoundaryStart, pContext -> state | C_BOUNDARY_IN_SUFFIX4);
					return OK;
				}
BOUNDARY_IN_SUFFIX4:

				/* CRLF after szBoundary, REQUIRED in all cases! */
				if(*szString != '\n')
				{
					pContext -> state = C_ERROR;
					warn("Dendral::HTTP::Request: LF after CR REQUIRED in all cases");
					return HTTP_INTERNAL_SERVER_ERROR;
				}

				++szString;
				/* End of buffer */
				if (szString == szStringEnd)
				{
					szStringSave = MultipartParserHandleEndOfBuffer(pRequest, pContext, szStringSave, szBoundaryStart, pContext -> state | C_HEADER);
					MultipartParserCommitSection(pRequest, pContext);

					/* End of MIME */
					if ((pContext -> state & C_END_MIME) == C_END_MIME)
					{
						/* End of MIME, end of processing */
						pContext -> state = C_END_MIME;
					}
					else
					{
						/* New state if HEADER */
						pContext -> state = C_HEADER;
					}
					return OK;
				}

				szStringSave = MultipartParserHandleEndOfBuffer(pRequest, pContext, szStringSave, szBoundaryStart, C_HEADER);
				/* Commit operation */
				MultipartParserCommitSection(pRequest, pContext);

				pContext -> state = C_HEADER;
				break;
			}

			/* Boundary not found */
			if (*pContext -> boundary_pos != *szString)
			{
				pContext -> state        = pContext -> prev_state;
				pContext -> boundary_pos = pContext -> boundary;
				break;
			}

			/* Next position */
			++szString;
			++pContext -> boundary_pos;

			/* End of buffer, write data */
			if (szString == szStringEnd)
			{
				/* Store pre-boundary data */
				szStringSave = MultipartParserHandleEndOfBuffer(pRequest, pContext, szStringSave, szBoundaryStart, C_BOUNDARY_IN);
				return OK;
			}
		}

		/* Boundary end, start handling of headers section */
		if ((pContext -> state & C_HEADER) == C_HEADER)
		{
			/* Handle headers section */
			for(;;)
			{
HEADER:

				/* Clear temp. buffer */
				sv_setpvn(pContext -> buffer, "", 0);

				pContext -> state = C_KEY_NAME;
				szStringSave = szString;

HEADER_CR:
KEY_NAME:
KEY_PRE_VALUE:
KEY_VALUE:
				/* Handle header line */
				for (;;)
				{
					/* Header value */
					if (*szString == ':' && ((pContext -> state & C_KEY_NAME) == C_KEY_NAME))
					{
						STRLEN         iHeaderLen  = 0;
						const char  * szHeaderName = NULL;

						sv_catpvn(pContext -> buffer, szStringSave, szString - szStringSave);

						/* Process key name */
#ifdef SvPV_const
						szHeaderName = SvPV_const(pContext -> buffer, iHeaderLen);
#else
						szHeaderName = SvPV(pContext -> buffer, iHeaderLen);
#endif

						/* Check "Content-Disposition" header */
						if (StrFirstCaseStr(szHeaderName, C_CONTENT_DISPOSITION) != NULL)
						{
							pContext -> header_key_id = C_KEY_CONTENT_DISPOSITION;
						}
						/* Check "Content-Type" header */
						else if (StrFirstCaseStr(szHeaderName, C_CONTENT_TYPE) != NULL)
						{
							pContext -> header_key_id = C_KEY_CONTENT_TYPE;
						}
						/* Check "Content-Transfer-Encoding" */
						else if (StrFirstCaseStr(szHeaderName, C_CONTENT_TRANSFER_ENCODING) != NULL)
						{
							pContext -> header_key_id = C_KEY_CONTENT_TRANSFER_ENCODING;
						}
						else
						{
							pContext -> header_key_id = 0;
						}

						/* Free buffer */
						sv_setpvn(pContext -> buffer, "", 0);

						/* Store start point of string */
						szStringSave      = szString;
						pContext -> state = C_KEY_PRE_VALUE;
					}
					/* Header key => value delimiter */
					else if (*szString != ' ' && ((pContext -> state & C_KEY_PRE_VALUE) == C_KEY_PRE_VALUE))
					{
						/* Store start point of string */
						szStringSave      = szString;
						pContext -> state = C_KEY_VALUE;
					}
					/* Handle CRLF after header */
					else if(*szString == '\r')
					{
						/* Store buffer */
						sv_catpvn(pContext -> buffer, szStringSave, szString - szStringSave);

						/* Parse header */
						if (pContext -> header_key_id == C_KEY_CONTENT_DISPOSITION)
						{
							MultipartParserParseHeader(pRequest, pContext);
						}
						/* Store content type */
						else if (pContext -> header_key_id == C_KEY_CONTENT_TYPE)
						{
							sv_setsv(pContext -> content_type, pContext -> buffer);
						}
						else if (pContext -> header_key_id == C_KEY_CONTENT_TRANSFER_ENCODING)
						{
							sv_setsv(pContext -> content_transfer_encoding, pContext -> buffer);
						}
						/* Clear buffer */
						sv_setpvn(pContext -> buffer, "", 0);

						/* End of buffer? */
						++szString;
HEADER_LF:
						if (szString == szStringEnd) { pContext -> state = C_HEADER_LF; return OK; }

						/* LF after CR, REQUIRED in all cases! */
						if(*szString != '\n')
						{
							pContext -> state = C_ERROR;
							warn("Dendral::HTTP::Request: LF after CR REQUIRED in all cases");
							return HTTP_INTERNAL_SERVER_ERROR;
						}

						/* End of buffer? */
						++szString;
						if (szString == szStringEnd) { pContext -> state = C_HEADER_CR2; return OK; }

						/* Store new buffer position */
						szStringSave = szString;
						break;
					}
					/* End of buffer? */
					++szString;
					if (szString == szStringEnd)
					{
						sv_catpvn(pContext -> buffer, szStringSave, szString - szStringSave);
						return OK;
					}
				}
HEADER_CR2:
				/* CRLF/CRLR matches end of section */
				if(*szString == '\r')
				{
					++szString;
					if (szString == szStringEnd)
					{
						pContext -> state = C_HEADER_LF2;
						return OK;
					}
HEADER_LF2:
					/* LF after CR, REQUIRED in all cases! */
					if(*szString != '\n')
					{
						pContext -> state = C_ERROR;
						warn("Dendral::HTTP::Request: LF after CR REQUIRED in all cases");
						return HTTP_INTERNAL_SERVER_ERROR;
					}

					pContext -> state = C_BODY;
					/* End of buffer? */

					/* Store new buffer position of body */
					szStringSave = szString;
					++szStringSave;

					/* Parse value */
					break;
				}
				/* Wait for next key */
				else { pContext -> state = C_KEY_NAME; }
			}
		}

		/* End of string? */
		++szString;
		if (szString == szStringEnd)
		{
			szStringSave = MultipartParserHandleEndOfBuffer(pRequest, pContext, szStringSave, szStringEnd, pContext -> state);
			return OK;
		}
	}
return OK;
}

/*
 * Initialize parser
 */
static int MultipartParserInit(Request * pRequest)
{

	struct MultipartParserContext  * pContext = (struct MultipartParserContext *)ap_palloc(pRequest -> request -> pool, sizeof(struct MultipartParserContext));

	pContext -> boundary     = pRequest -> boundary;
	pContext -> boundary_pos = pRequest -> boundary + 2;
	pContext -> state        = C_BOUNDARY_IN;
	pContext -> value_state  = C_UNDEF;

	pContext -> tmp_name                  = newSVpvn("", 0);
	pContext -> name                      = newSVpvn("", 0);
	pContext -> file_name                 = newSVpvn("", 0);
	pContext -> full_filename             = newSVpvn("", 0);
	pContext -> content_type              = newSVpvn("", 0);
	pContext -> content_transfer_encoding = newSVpvn("", 0);

	pContext -> buffer                    = newSVpvn("", 0);

	pRequest -> context = pContext;

return OK;
}

/*
 * End of parsing process
 */
static int MultipartParserDone(Request  * pRequest)
{
	struct MultipartParserContext  * pContext = (struct MultipartParserContext *)(pRequest -> context);

	/* Clear garbage */
	SvREFCNT_dec(pContext -> tmp_name);
	SvREFCNT_dec(pContext -> name);
	SvREFCNT_dec(pContext -> file_name);
	SvREFCNT_dec(pContext -> full_filename);
	SvREFCNT_dec(pContext -> content_type);
	SvREFCNT_dec(pContext -> content_transfer_encoding);

	SvREFCNT_dec(pContext -> buffer);

return OK;
}

RequestParser MultipartParser =
{
	MultipartParserInit,
	MultipartParserParseChunk,
	MultipartParserDone
};

/* End */

