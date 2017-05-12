/* -*- c -*- 
 * File: pstring.h
 * Author: Igor Vlasenko <vlasenko@imath.kiev.ua>
 * Created: Fri Jul  1 20:11:51 2005
 *
 * $Id$
 */

#include <stdio.h>
#include <string.h>
#include <ctype.h>
#include "pbuffer.h"
#include "pstring.h"

static
PSTRING
lowercase_pstring (pbuffer* pBuffer ,PSTRING pstring) {
  const size_t size=pstring.endnext-pstring.begin;
  char* buf=pbuffer_resize(pBuffer, size+1);
  char* inbuf=buf;
  const char* i=pstring.begin;
  PSTRING retval;
  while (i<pstring.endnext) {
    *inbuf++=tolower((unsigned char) *i++);
  }
  *inbuf=0;
  retval.begin=buf;
  retval.endnext=buf+size;
  return retval;
}

/*
static
void 
lowercase_pstring_inplace (PSTRING pstring) {
  char* i=pstring.begin;
  while (i<pstring.endnext) {
    *i=tolower(*i);
    i++;
  }
}
*/

static
PSTRING
uppercase_pstring (pbuffer* pBuffer ,PSTRING pstring) {
  const size_t size=pstring.endnext-pstring.begin;
  char* buf=pbuffer_resize(pBuffer, size+1);
  char* inbuf=buf;
  const char* i=pstring.begin;
  PSTRING retval;
  while (i<pstring.endnext) {
    *inbuf++=toupper((unsigned char) *i++);
  }
  *inbuf=0;
  retval.begin=buf;
  retval.endnext=buf+size;
  return retval;
}


static
int
is_pstring_true (PSTRING s) {
  const size_t len = s.endnext-s.begin;
  if (s.begin == NULL || 0==len) return 0;
  if (1==len) {
    if (*(s.begin)=='0') return 0; else return 1;
  } else if (3==len) {
    if ('0'==*(s.begin) && '.'==*(s.begin+1) && '0'==*(s.begin+2)) return 0; else return 1;
  } else return 1;
}

#define MAX_ESCAPE_SEQ sizeof("&quot;")
static 
PSTRING 
htmlencode_pstring (pbuffer* StrBuffer, PSTRING pstring) {
  char* buf=pbuffer_resize(StrBuffer, pstring.endnext-pstring.begin+1+MAX_ESCAPE_SEQ);
  const char* curpos=pstring.begin;
  size_t offset=0;
  size_t buflen=pbuffer_size(StrBuffer);
  PSTRING retval;
  while (curpos<pstring.endnext) {
    unsigned char curchar=*curpos++;
    int bufdelta=1;
    if (offset>=buflen-MAX_ESCAPE_SEQ) {
      buf=pbuffer_resize(StrBuffer, 2*(offset+MAX_ESCAPE_SEQ));
      buflen=pbuffer_size(StrBuffer);
    }
    switch (curchar) {
      /* straight from the CGI.pm bible. (HTML::Template) */
    case '&' : bufdelta=5; strncpy(buf+offset, "&amp;", bufdelta);break;
    case '"' : bufdelta=6; strncpy(buf+offset, "&quot;",bufdelta);break;
    case '>' : bufdelta=4; strncpy(buf+offset, "&gt;",  bufdelta);break;
    case '<' : bufdelta=4; strncpy(buf+offset, "&lt;",  bufdelta);break;
    case '\'': bufdelta=5; strncpy(buf+offset, "&#39;", bufdelta);break;
    default: *(buf+offset)=curchar;
    }
    offset+=bufdelta;
  }
  retval.begin=buf;
  retval.endnext=buf+offset;
  return retval;
}

static 
PSTRING 
jsencode_pstring (pbuffer* StrBuffer, PSTRING pstring) {
  char* buf=pbuffer_resize(StrBuffer, pstring.endnext-pstring.begin+1+MAX_ESCAPE_SEQ);
  const char* curpos=pstring.begin;
  size_t offset=0;
  size_t buflen=pbuffer_size(StrBuffer);
  PSTRING retval;
  while (curpos<pstring.endnext) {
    unsigned char curchar=*curpos++;
    int bufdelta=1;
    if (offset>=buflen-MAX_ESCAPE_SEQ) {
      buf=pbuffer_resize(StrBuffer, 2*(offset+MAX_ESCAPE_SEQ));
      buflen=pbuffer_size(StrBuffer);
    }
    switch (curchar) {
    case '\\' : bufdelta=6; strncpy(buf+offset, "\\u005c", bufdelta);break;
    case '"'  : bufdelta=6; strncpy(buf+offset, "\\u0022",bufdelta);break;
    case '\'' : bufdelta=6; strncpy(buf+offset, "\\u0027",bufdelta);break;
    case '\n' : bufdelta=6; strncpy(buf+offset, "\\u000a",bufdelta);break;
    case '\r' : bufdelta=6; strncpy(buf+offset, "\\u000d",bufdelta);break;
    case '>' : bufdelta=6; strncpy(buf+offset, "\\u003e;",  bufdelta);break;
    case '<' : bufdelta=6; strncpy(buf+offset, "\\u003c;",  bufdelta);break;
    case '&' : bufdelta=6; strncpy(buf+offset, "\\u0026;",  bufdelta);break;
    case '=' : bufdelta=6; strncpy(buf+offset, "\\u003d;",  bufdelta);break;
    case '-' : bufdelta=6; strncpy(buf+offset, "\\u002d;",  bufdelta);break;
    case ';' : bufdelta=6; strncpy(buf+offset, "\\u003b;",  bufdelta);break;
    case '+' : bufdelta=6; strncpy(buf+offset, "\\u002b;",  bufdelta);break;
    default: *(buf+offset)=curchar;
    }
    offset+=bufdelta;
  }
  retval.begin=buf;
  retval.endnext=buf+offset;
  return retval;
}

static 
PSTRING 
urlencode_pstring (pbuffer* StrBuffer, PSTRING pstring) {
  char* buf=pbuffer_resize(StrBuffer, pstring.endnext-pstring.begin+1+MAX_ESCAPE_SEQ);
  const char* curpos=pstring.begin;
  size_t offset=0;
  size_t buflen=pbuffer_size(StrBuffer);
  PSTRING retval;
  while (curpos<pstring.endnext) {
    unsigned char curchar=*curpos++;
    int bufdelta=1;
    if (offset>=buflen-MAX_ESCAPE_SEQ) {
      buf=pbuffer_resize(StrBuffer, 2*(offset+MAX_ESCAPE_SEQ));
      buflen=pbuffer_size(StrBuffer);
    }
    /* 
     * # do the translation (RFC 2396 ^uric)
     * s!([^a-zA-Z0-9_.\-])!sprintf('%%%02X', $_)
     */
    if ((curchar>='a' && curchar<='z') ||
	(curchar>='A' && curchar<='Z') ||
	(curchar>='0' && curchar<='9') ||
	curchar=='_' || curchar=='.' || curchar=='\\' || curchar=='-'
	) 
      *(buf+offset)=curchar;
    else {
      bufdelta=3; sprintf(buf+offset,"%%%.2X",(int) curchar);
    }
    offset+=bufdelta;
  }
  retval.begin=buf;
  retval.endnext=buf+offset;
  return retval;
}

static 
PSTRING 
escape_pstring (pbuffer* strBuffer, PSTRING pstring, const int escapeopt) {
  switch (escapeopt) {
  case HTML_TEMPLATE_OPT_ESCAPE_HTML:
    return htmlencode_pstring(strBuffer, pstring);
  case HTML_TEMPLATE_OPT_ESCAPE_JS:
    return jsencode_pstring(strBuffer, pstring);
  case HTML_TEMPLATE_OPT_ESCAPE_URL: 
    return urlencode_pstring(strBuffer, pstring);
  default : return pstring;
  }
}
