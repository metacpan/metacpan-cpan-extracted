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
 *      UrlencodedParser.c
 *
 * $CAS$
 */

#include "RequestStruct.h"

#define C_ESCAPE_BUFFER_LEN 8192

/* FSM states */
#define  C_PARSE_KEY      0x00010000
#define  C_PARSE_VALUE    0x00020000

#define  C_PARSE_ESCAPED1 0x00000001
#define  C_PARSE_ESCAPED2 0x00000002

/*
 * Parse context
 */
struct UrlencodedParserContext
{
	/* FSM state                 */
	unsigned int    state;
	/* FSM data                  */
	unsigned int    tmp_symbol;
	/* Key                       */
	SV            * key;
	/* Value                     */
	SV            * val;
};

/*
 * Initialize parser
 */
static int UrlencodedParserInit(Request * pRequest)
{
	struct UrlencodedParserContext  * pContext = (struct UrlencodedParserContext *)ap_palloc(pRequest -> request -> pool, sizeof(struct UrlencodedParserContext));

	pContext -> state      = 0;
	pContext -> tmp_symbol = 0;
	pContext -> key = newSVpvn("", 0);
	pContext -> val = newSVpvn("", 0);

	pRequest -> context = pContext;

return OK;
}

/*
 * Escape value
 */
static const char * UrlencodedParserEscapeValue(Request           * pRequest,
                                                SV                * pData,
                                                unsigned char       chDelimiter,
                                                unsigned char     * sBuffer,
                                                const char        * szString,
                                                const char const  * szStringEnd)
{
	struct UrlencodedParserContext  * pContext = (struct UrlencodedParserContext *)(pRequest -> context);

	long long      iBufferPointer = 0;
	unsigned char  ucSymbol       = 0;
	unsigned char  ucTMP          = 0;
	long long      iLeftBytes     = 0;

	/* First state */
	if ((pContext -> state & C_PARSE_ESCAPED1) != 0)
	{
		/* Reset parser state */
		pContext -> state &= 0xFFFF0000;
		goto PARSE_ESCAPED1;
	}

	/* Second state */
	if ((pContext -> state & C_PARSE_ESCAPED2) != 0)
	{
		/* Reset parser state */
		pContext -> state &= 0xFFFF0000;

		ucSymbol = pContext -> tmp_symbol;

		if      (ucSymbol >= 'A' && ucSymbol <= 'F') { ucTMP = ((ucSymbol - 'A' + 10) << 4); }
		else if (ucSymbol >= 'a' && ucSymbol <= 'f') { ucTMP = ((ucSymbol - 'a' + 10) << 4); }
		else if (ucSymbol >= '0' && ucSymbol <= '9') { ucTMP =  (ucSymbol - '0')      << 4;  }
		else
		{
			sBuffer[iBufferPointer++] = '%';
			goto PARSE_PLAIN;
		}

		goto PARSE_ESCAPED2;
	}

PARSE_PLAIN:
	/* Iterate through buffer */
	while (szString != szStringEnd && *szString != chDelimiter && *szString != '&' && *szString != ';')
	{
		/* Buffer overflow */
		if (iBufferPointer == C_ESCAPE_BUFFER_LEN)
		{
			sv_catpvn(pData, (const char *)sBuffer, iBufferPointer);
			iBufferPointer = 0;
		}

		/* Change '+' to space */
		if      (*szString == '+') { sBuffer[iBufferPointer++] = ' ';       pContext -> state &= 0xFFFF0000; }
		/* Store all unescaped symbols */
		else if (*szString != '%') { sBuffer[iBufferPointer++] = *szString; pContext -> state &= 0xFFFF0000; }
		else
		{
			iLeftBytes = szStringEnd - szString;
			/* Unexpected end of string */
			if (iLeftBytes > 2)
			{
				++szString;
PARSE_ESCAPED1:
				ucSymbol = *szString;

				/* Unescape correct sequence */
				if      (ucSymbol >= 'A' && ucSymbol <= 'F') { ucTMP = ((ucSymbol - 'A' + 10) << 4); }
				else if (ucSymbol >= 'a' && ucSymbol <= 'f') { ucTMP = ((ucSymbol - 'a' + 10) << 4); }
				else if (ucSymbol >= '0' && ucSymbol <= '9') { ucTMP =  (ucSymbol - '0')      << 4;  }
				/* Store '%' symbol to the buffer */
				else
				{
					sBuffer[iBufferPointer++] = '%';
					continue;
				}

				++szString;
PARSE_ESCAPED2:
				/* Unescape correct sequence */
				if      (*szString >= 'A' && *szString <= 'F') { ucTMP += *szString - 'A' + 10; }
				else if (*szString >= 'a' && *szString <= 'f') { ucTMP += *szString - 'a' + 10; }
				else if (*szString >= '0' && *szString <= '9') { ucTMP += *szString - '0';      }
				/* Store '%' and next symbol to the buffer */
				else
				{
					sBuffer[iBufferPointer++] = '%';
					sBuffer[iBufferPointer++] = ucSymbol;
					continue;
				}

				/* Okay, symbol successfully unescaped */
				sBuffer[iBufferPointer++] = ucTMP;
			}
			else
			{
				/* First state */
				if (iLeftBytes == 1)
				{
					pContext -> state |= C_PARSE_ESCAPED1;
					++szString;
				}
				/* Second state */
				else
				{
					pContext -> state |= C_PARSE_ESCAPED2;
					++szString;
					pContext -> tmp_symbol = *szString;
					++szString;
				}
				break;
			}
		}

		++szString;
	}

	/* Append buffer to result */
	sv_catpvn(pData, (const char *)sBuffer, iBufferPointer);

return szString;
}

/*
 * Split string "key1=value1&key2=value2..."
 */
static int UrlencodedParserParseChunk(Request     * pRequest,
                                      const char  * szString,
                                      const char  * szStringEnd)
{
	struct UrlencodedParserContext  * pContext = (struct UrlencodedParserContext *)(pRequest -> context);

	unsigned char sBuffer[C_ESCAPE_BUFFER_LEN + 4];

	/* Jump to value parsing section */
	if ((pContext -> state & C_PARSE_VALUE) != 0) { goto PARSE_VALUE; }

	/* Split string */
	for(;;)
	{
		/* Skip void sequences */
		while (szString != szStringEnd && (*szString == '&' || *szString == ';')) { ++szString; }

		/* Reset state */
		pContext -> state &= 0x0000FFFF;
		pContext -> state |= C_PARSE_KEY;

		/* Escape key */
		szString = UrlencodedParserEscapeValue(pRequest, pContext -> key, '=', sBuffer, szString, szStringEnd);

		/* End of stream, with current state "C_PARSE_KEY" */
		if (szString == szStringEnd) { return OK; }

		/* No value given, store empty key */
		if (*szString == '&' || *szString == ';')
		{
			StorePair(pRequest -> arguments, SvPV_nolen(pContext -> key), pContext -> val);
			pContext -> key = newSVpvn("", 0);
			pContext -> val = newSVpvn("", 0);
			continue;
		}
		++szString;

PARSE_VALUE:
		/* New state is "C_PARSE_VALUE" */
		pContext -> state &= 0x0000FFFF;
		pContext -> state |= C_PARSE_VALUE;

		/* Escape value */
		szString = UrlencodedParserEscapeValue(pRequest, pContext -> val, '&', sBuffer, szString, szStringEnd);

		/* End of stream, with current state "C_PARSE_VALUE" */
		if (szString == szStringEnd) { return OK; }

		/* Store pair if '&' symbol found */
		if (*szString == '&' || *szString == ';')
		{
			StorePair(pRequest -> arguments, SvPV_nolen(pContext -> key), pContext -> val);
			pContext -> key = newSVpvn("", 0);
			pContext -> val = newSVpvn("", 0);
		}
		++szString;
	}

return OK;
}

/*
 * End of parsing process
 */
static int UrlencodedParserDone(Request  * pRequest)
{
	struct UrlencodedParserContext  * pContext = (struct UrlencodedParserContext *)(pRequest -> context);

	StorePair(pRequest -> arguments, SvPV_nolen(pContext -> key), pContext -> val);


return OK;
}

RequestParser UrlencodedParser =
{
	UrlencodedParserInit,
	UrlencodedParserParseChunk,
	UrlencodedParserDone
};

/* End */

