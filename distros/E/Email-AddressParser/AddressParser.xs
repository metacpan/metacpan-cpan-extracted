#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"
#include <string.h>

#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include <string.h>

#define MM_LOG(a,b) fprintf(stderr, a)

/* UTF8 defs */
#define I2C_MULTI 0x24		/* multi-byte character set */
#define I2C_ESC 0x1b		/* ESCape */
#define I2CS_94x94_JIS_OLD 0x40	/* 4/0 JIS X 0208-1978 */
#define I2CS_94x94_JIS_NEW 0x42	/* 4/2 JIS X 0208-1983 */
#define I2C_G0_94 0x28		/* G0 94-character set */
#define I2CS_94_ASCII 0x42	/* 4/2 ISO 646 USA (ASCII) */
#define I2CS_94_JIS_ROMAN 0x4a	/* 4/a JIS X 0201-1976 left half */
#define I2CS_94_JIS_BUGROM 0x48	/* 4/8 some buggy software does this */

#define ADDRESS struct mail_address
#define NIL 0			/* convenient name */
#define T 1			/* opposite of NIL */
#define LONGT (long) 1		/* long T */
#define VOIDT (void *) ""	/* void T */
#define MAILTMPLEN 1024		/* size of a temporary buffer */
#define PARSE (long) 3		/* mm_log parse error type */

#define MAXGROUPDEPTH 50	/* RFC 822 doesn't allow nesting at all */
#define MAXMIMEDEPTH 50		/* more than any sane MIMEgram */

#define ERRHOST ".SYNTAX-ERROR."
char *errhst = ERRHOST;		/* syntax error host string */

				/* RFC 2822 specials */
const char *specials = " ()<>@,;:\\\"[].\1\2\3\4\5\6\7\10\11\12\13\14\15\16\17\20\21\22\23\24\25\26\27\30\31\32\33\34\35\36\37\177";
				/* RFC 2822 phrase specials (no space) */
const char *rspecials = "()<>@,;:\\\"[].\1\2\3\4\5\6\7\10\11\12\13\14\15\16\17\20\21\22\23\24\25\26\27\30\31\32\33\34\35\36\37\177";
				/* RFC 2822 dot-atom specials (no dot) */
const char *wspecials = " ()<>@,;:\\\"[]\1\2\3\4\5\6\7\10\11\12\13\14\15\16\17\20\21\22\23\24\25\26\27\30\31\32\33\34\35\36\37\177";
				/* RFC 2045 MIME body token specials */
const char *tspecials = " ()<>@,;:\\\"[]/?=\1\2\3\4\5\6\7\10\11\12\13\14\15\16\17\20\21\22\23\24\25\26\27\30\31\32\33\34\35\36\37\177";

static char *rfc822_parse_word (char *s,const char *delimiters);
static ADDRESS *rfc822_parse_routeaddr (char *string,char **ret,char
      *defaulthost); static char *rfc822_parse_domain (char *string,char
         **end);
static ADDRESS *rfc822_parse_addrspec (char *string,char **ret,char
      *defaulthost);
static ADDRESS *rfc822_parse_mailbox (char **string,char *defaulthost);
static void rfc822_skipws (char **s);
static ADDRESS *rfc822_parse_address (ADDRESS **lst,ADDRESS *last,char
      **string, char *defaulthost,unsigned long depth);
static void rfc822_parse_adrlist (ADDRESS **lst,char *string,char *host);
static void *fs_get (size_t size);
static ADDRESS *mail_newaddr (void);
static ADDRESS *rfc822_parse_group (ADDRESS **lst,ADDRESS *last,char **string,
      char *defaulthost,unsigned long depth);
static char *rfc822_parse_phrase (char *s);
static char *rfc822_skip_comment (char **s,long trim);
static char *rfc822_quote (char *src);
static char *rfc822_cpy (char *src);
static char *cpystr (const char *string);

#define MMLOG(a,b) fprintf(stderr, a)

ADDRESS {
  char *personal;		/* personal name phrase */
  char *adl;			/* at-domain-list source route */
  char *mailbox;		/* mailbox name */
  char *host;			/* domain name of mailbox's host */
  char *error;			/* error in address from SMTP module */
  struct {
    char *type;			/* address type (default "rfc822") */
    char *addr;			/* address as xtext */
  } orcpt;
  ADDRESS *next;		/* pointer to next address in list */
};

static void fs_resize (void **block,size_t size)
{
  assert((*block = realloc (*block,size ? size : (size_t) 1)));
}

static void fs_give (void **block)
{
  free (*block);
  *block = NIL;
}

static char *cpystr (const char *string)
{
  return string ? strcpy ((char *) fs_get (1 + strlen (string)),string) : NIL;
}

static char *rfc822_cpy (char *src)
{
				/* copy and unquote */
  return rfc822_quote (cpystr (src));
}

static char *rfc822_quote (char *src)
{
  char *ret = src;
  if (strpbrk (src,"\\\"")) {	/* any quoting in string? */
    char *dst = ret;
    while (*src) {		/* copy string */
      if (*src == '\"') src++;	/* skip double quote entirely */
      else {
	if (*src == '\\') src++;/* skip over single quote, copy next always */
	*dst++ = *src++;	/* copy character */
      }
    }
    *dst = '\0';		/* tie off string */
  }
  return ret;			/* return our string */
}

static char *rfc822_skip_comment (char **s,long trim)
{
  char *ret,tmp[MAILTMPLEN];
  char *s1 = *s;
  char *t = NIL;
				/* skip past whitespace */
  for (ret = ++s1; *ret == ' '; ret++);
  do switch (*s1) {		/* get character of comment */
  case '(':			/* nested comment? */
    if (!rfc822_skip_comment (&s1,(long) NIL)) return NIL;
    t = --s1;			/* last significant char at end of comment */
    break;
  case ')':			/* end of comment? */
    *s = ++s1;			/* skip past end of comment */
    if (trim) {			/* if level 0, must trim */
      if (t) t[1] = '\0';	/* tie off comment string */
      else *ret = '\0';		/* empty comment */
    }
    return ret;
  case '\\':			/* quote next character? */
    if (*++s1) {		/* next character non-null? */
      t = s1;			/* update last significant character pointer */
      break;			/* all OK */
    }
  case '\0':			/* end of string */
    sprintf (tmp,"Unterminated comment: %.80s",*s);
    MM_LOG (tmp,PARSE);
    **s = '\0';			/* nuke duplicate messages in case reparse */
    return NIL;			/* this is wierd if it happens */
  case ' ':			/* whitespace isn't significant */
    break;
  default:			/* random character */
    t = s1;			/* update last significant character pointer */
    break;
  } while (s1++);
  return NIL;			/* impossible, but pacify lint et al */
}

static char *rfc822_parse_word (char *s,const char *delimiters)
{
  char *st,*str;
  if (!s) return NIL;		/* no string */
  rfc822_skipws (&s);		/* flush leading whitespace */
  if (!*s) return NIL;		/* empty string */
  str = s;			/* hunt pointer for strpbrk */
  while (T) {			/* look for delimiter, return if none */
    if (!(st = strpbrk (str,delimiters ? delimiters : wspecials)))
      return str + strlen (str);
				/* ESC in phrase */
    if (!delimiters && (*st == I2C_ESC)) {
      str = ++st;		/* always skip past ESC */
      switch (*st) {		/* special hack for RFC 1468 (ISO-2022-JP) */
      case I2C_MULTI:		/* multi byte sequence */
	switch (*++st) {
	case I2CS_94x94_JIS_OLD:/* old JIS (1978) */
	case I2CS_94x94_JIS_NEW:/* new JIS (1983) */
	  str = ++st;		/* skip past the shift to JIS */
	  while (st = strchr (st,I2C_ESC))
	    if ((*++st == I2C_G0_94) && ((st[1] == I2CS_94_ASCII) ||
					 (st[1] == I2CS_94_JIS_ROMAN) ||
					 (st[1] == I2CS_94_JIS_BUGROM))) {
	      str = st += 2;	/* skip past the shift back to ASCII */
	      break;
	    }
				/* eats entire text if no shift back */
	  if (!st || !*st) return str + strlen (str);
	}
	break;
      case I2C_G0_94:		/* single byte sequence */
	switch (st[1]) {
	case I2CS_94_ASCII:	/* shift to ASCII */
	case I2CS_94_JIS_ROMAN:	/* shift to JIS-Roman */
	case I2CS_94_JIS_BUGROM:/* old buggy definition of JIS-Roman */
	  str = st + 2;		/* skip past the shift */
	  break;
	}
      }
    }

    else switch (*st) {		/* dispatch based on delimiter */
    case '"':			/* quoted string */
				/* look for close quote */
      while (*++st != '"') switch (*st) {
      case '\0':		/* unbalanced quoted string */
	return NIL;		/* sick sick sick */
      case '\\':		/* quoted character */
	if (!*++st) return NIL;	/* skip the next character */
      default:			/* ordinary character */
	break;			/* no special action */
      }
      str = ++st;		/* continue parse */
      break;
    case '\\':			/* quoted character */
      /* This is wrong; a quoted-pair can not be part of a word.  However,
       * domain-literal is parsed as a word and quoted-pairs can be used
       * *there*.  Either way, it's pretty pathological.
       */
      if (st[1]) {		/* not on NUL though... */
	str = st + 2;		/* skip quoted character and go on */
	break;
      }
    default:			/* found a word delimiter */
      return (st == s) ? NIL : st;
    }
  }
}

static ADDRESS *rfc822_parse_routeaddr (char *string,char **ret,char *defaulthost)
{
  char tmp[MAILTMPLEN];
  ADDRESS *adr;
  char *s,*t,*adl;
  size_t adllen,i;
  if (!string) return NIL;
  rfc822_skipws (&string);	/* flush leading whitespace */
				/* must start with open broket */
  if (*string != '<') return NIL;
  t = ++string;			/* see if A-D-L there */
  rfc822_skipws (&t);		/* flush leading whitespace */
  for (adl = NIL,adllen = 0;	/* parse possible A-D-L */
       (*t == '@') && (s = rfc822_parse_domain (t+1,&t));) {
    i = strlen (s) + 2;		/* @ plus domain plus delimiter or NUL */
    if (adl) {			/* have existing A-D-L? */
      fs_resize ((void **) &adl,adllen + i);
      sprintf (adl + adllen - 1,",@%s",s);
    }
				/* write initial A-D-L */
    else sprintf (adl = (char *) fs_get (i),"@%s",s);
    adllen += i;		/* new A-D-L length */
    fs_give ((void **) &s);	/* don't need domain any more */
    rfc822_skipws (&t);		/* skip WS */
    if (*t != ',') break;	/* put if not comma */
    t++;			/* skip the comma */
    rfc822_skipws (&t);		/* skip WS */
  }
  if (adl) {			/* got an A-D-L? */
    if (*t != ':') {		/* make sure syntax good */
      sprintf (tmp,"Unterminated at-domain-list: %.80s%.80s",adl,t);
      MM_LOG (tmp,PARSE);
    }
    else string = ++t;		/* continue parse from this point */
  }

				/* parse address spec */
  if (!(adr = rfc822_parse_addrspec (string,ret,defaulthost))) {
    if (adl) fs_give ((void **) &adl);
    return NIL;
  }
  if (adl) adr->adl = adl;	/* have an A-D-L? */
  if (*ret) if (**ret == '>') {	/* make sure terminated OK */
    ++*ret;			/* skip past the broket */
    rfc822_skipws (ret);	/* flush trailing WS */
    if (!**ret) *ret = NIL;	/* wipe pointer if at end of string */
    return adr;			/* return the address */
  }
  sprintf (tmp,"Unterminated mailbox: %.80s@%.80s",adr->mailbox,
	   *adr->host == '@' ? "<null>" : adr->host);
  MM_LOG (tmp,PARSE);
  adr->next = mail_newaddr ();
  adr->next->mailbox = cpystr ("MISSING_MAILBOX_TERMINATOR");
  adr->next->host = cpystr (errhst);
  return adr;			/* return the address */
}

static char *rfc822_parse_domain (char *string,char **end)
{
  char *ret = NIL;
  char c,*s,*t,*v;
  rfc822_skipws (&string);	/* skip whitespace */
  if (*string == '[') {		/* domain literal? */
    if (!(*end = rfc822_parse_word (string + 1,"]\\")))
      MM_LOG ("Empty domain literal",PARSE);
    else if (**end != ']') MM_LOG ("Unterminated domain literal",PARSE);
    else {
      size_t len = ++*end - string;
      strncpy (ret = (char *) fs_get (len + 1),string,len);
      ret[len] = '\0';		/* tie off literal */
    }
  }
				/* search for end of host */
  else if (t = rfc822_parse_word (string,wspecials)) {
    c = *t;			/* remember delimiter */
    *t = '\0';			/* tie off host */
    ret = rfc822_cpy (string);	/* copy host */
    *t = c;			/* restore delimiter */
    *end = t;			/* remember end of domain */
    rfc822_skipws (&t);		/* skip WS after host */
    while (*t == '.') {		/* some cretin taking RFC 822 too seriously? */
      string = ++t;		/* skip past the dot and any WS */
      rfc822_skipws (&string);
      if (string = rfc822_parse_domain (string,&t)) {
	*end = t;		/* remember new end of domain */
	c = *t;			/* remember delimiter */
	*t = '\0';		/* tie off host */
	s = rfc822_cpy (string);/* copy successor part */
	*t = c;			/* restore delimiter */
				/* build new domain */
	sprintf (v = (char *) fs_get (strlen (ret) + strlen (s) + 2),
		 "%s.%s",ret,s);
	fs_give ((void **) &ret);
	ret = v;		/* new host name */
	rfc822_skipws (&t);	/* skip WS after domain */
      }
      else {			/* barf */
	MM_LOG ("Invalid domain part after .",PARSE);
	break;
      }
    }
  }
  else MM_LOG ("Missing or invalid host name after @",PARSE);
  return ret;
}
static char *rfc822_parse_phrase (char *s)
{
  char *curpos;
  if (!s) return NIL;		/* no-op if no string */
				/* find first word of phrase */
  curpos = rfc822_parse_word (s,NIL);
  if (!curpos) return NIL;	/* no words means no phrase */
  if (!*curpos) return curpos;	/* check if string ends with word */
  s = curpos;			/* sniff past the end of this word and WS */
  rfc822_skipws (&s);		/* skip whitespace */
				/* recurse to see if any more */
  return (s = rfc822_parse_phrase (s)) ? s : curpos;
}

static ADDRESS *rfc822_parse_group (ADDRESS **lst,ADDRESS *last,char **string,
			     char *defaulthost,unsigned long depth)
{
  char tmp[MAILTMPLEN];
  char *p,*s;
  ADDRESS *adr;
  if (depth > MAXGROUPDEPTH) {	/* excessively deep recursion? */
    MM_LOG ("Ignoring excessively deep group recursion",PARSE);
    return NIL;			/* probably abusive */
  }
  if (!*string) return NIL;	/* no string */
  rfc822_skipws (string);	/* skip leading WS */
  if (!**string ||		/* trailing whitespace or not group */
      ((*(p = *string) != ':') && !(p = rfc822_parse_phrase (*string))))
    return NIL;
  s = p;			/* end of candidate phrase */
  rfc822_skipws (&s);		/* find delimiter */
  if (*s != ':') return NIL;	/* not really a group */
  *p = '\0';			/* tie off group name */
  p = ++s;			/* continue after the delimiter */
  rfc822_skipws (&p);		/* skip subsequent whitespace */
				/* write as address */
  (adr = mail_newaddr ())->mailbox = rfc822_cpy (*string);
  if (!*lst) *lst = adr;	/* first time through? */
  else last->next = adr;	/* no, append to the list */
  last = adr;			/* set for subsequent linking */
  *string = p;			/* continue after this point */
  while (*string && **string && (**string != ';')) {
    if (adr = rfc822_parse_address (lst,last,string,defaulthost,depth+1)) {
      last = adr;		/* new tail address */
      if (*string) {		/* anything more? */
	rfc822_skipws (string);	/* skip whitespace */
	switch (**string) {	/* see what follows */
	case ',':		/* another address? */
	  ++*string;		/* yes, skip past the comma */
	case ';':		/* end of group? */
	case '\0':		/* end of string */
	  break;
	default:
	  sprintf (tmp,"Unexpected characters after address in group: %.80s",
		   *string);
	  MM_LOG (tmp,PARSE);
	  *string = NIL;	/* cancel remainder of parse */
	  last = last->next = mail_newaddr ();
	  last->mailbox = cpystr ("UNEXPECTED_DATA_AFTER_ADDRESS_IN_GROUP");
	  last->host = cpystr (errhst);
	}
      }
    }
    else {			/* bogon */
      sprintf (tmp,"Invalid group mailbox list: %.80s",*string);
      MM_LOG (tmp,PARSE);
      *string = NIL;		/* cancel remainder of parse */
      (adr = mail_newaddr ())->mailbox = cpystr ("INVALID_ADDRESS_IN_GROUP");
      adr->host = cpystr (errhst);
      last = last->next = adr;
    }
  }
  if (*string) {		/* skip close delimiter */
    if (**string == ';') ++*string;
    rfc822_skipws (string);
  }
				/* append end of address mark to the list */
  last->next = (adr = mail_newaddr ());
  last = adr;			/* set for subsequent linking */
  return last;			/* return the tail */
}

static void *fs_get (size_t size)
{
  void *block = malloc (size ? size : (size_t) 1);
  assert(block);
  return (block);
}

static void rfc822_skipws (char **s)
{
  while (T) switch (**s) {
  case ' ': case '\t': case '\015': case '\012':
    ++*s;			/* skip all forms of LWSP */
    break;
  case '(':			/* start of comment */
    if (rfc822_skip_comment (s,(long) NIL)) break;
  default:
    return;			/* end of whitespace */
  }
}

static ADDRESS *rfc822_parse_addrspec (char *string,char **ret,char *defaulthost)
{
  ADDRESS *adr;
  char c,*s,*t,*v,*end;
  if (!string) return NIL;	/* no string */
  rfc822_skipws (&string);	/* flush leading whitespace */
  if (!*string) return NIL;	/* empty string */
				/* find end of mailbox */
  if (!(t = rfc822_parse_word (string,wspecials))) return NIL;
  adr = mail_newaddr ();	/* create address block */
  c = *t;			/* remember delimiter */
  *t = '\0';			/* tie off mailbox */
				/* copy mailbox */
  adr->mailbox = rfc822_cpy (string);
  *t = c;			/* restore delimiter */
  end = t;			/* remember end of mailbox */
  rfc822_skipws (&t);		/* skip whitespace */
  while (*t == '.') {		/* some cretin taking RFC 822 too seriously? */
    string = ++t;		/* skip past the dot and any WS */
    rfc822_skipws (&string);
				/* get next word of mailbox */
    if (t = rfc822_parse_word (string,wspecials)) {
      end = t;			/* remember new end of mailbox */
      c = *t;			/* remember delimiter */
      *t = '\0';		/* tie off word */
      s = rfc822_cpy (string);	/* copy successor part */
      *t = c;			/* restore delimiter */
				/* build new mailbox */
      sprintf (v = (char *) fs_get (strlen (adr->mailbox) + strlen (s) + 2),
	       "%s.%s",adr->mailbox,s);
      fs_give ((void **) &adr->mailbox);
      adr->mailbox = v;		/* new host name */
      rfc822_skipws (&t);	/* skip WS after mailbox */
    }
    else {			/* barf */
      MM_LOG ("Invalid mailbox part after .",PARSE);
      break;
    }
  }
  t = end;			/* remember delimiter in case no host */

  rfc822_skipws (&end);		/* sniff ahead at what follows */
#if RFC733			/* RFC 733 used "at" instead of "@" */
  if (((*end == 'a') || (*end == 'A')) &&
      ((end[1] == 't') || (end[1] == 'T')) &&
      ((end[2] == ' ') || (end[2] == '\t') || (end[2] == '\015') ||
       (end[2] == '\012') || (end[2] == '(')))
    *++end = '@';
#endif
  if (*end != '@') end = t;	/* host name missing */
				/* otherwise parse host name */
  else if (!(adr->host = rfc822_parse_domain (++end,&end)))
    adr->host = cpystr (errhst);
				/* default host if missing */
  if (!adr->host) adr->host = cpystr (defaulthost);
				/* try person name in comments if missing */
  if (end && !(adr->personal && *adr->personal)) {
    while (*end == ' ') ++end;	/* see if we can find a person name here */
    if ((*end == '(') && (s = rfc822_skip_comment (&end,LONGT)) && strlen (s))
      adr->personal = rfc822_cpy (s);
    rfc822_skipws (&end);	/* skip any other WS in the normal way */
  }
				/* set return to end pointer */
  *ret = (end && *end) ? end : NIL;
  return adr;			/* return the address we got */
}

static ADDRESS *rfc822_parse_mailbox (char **string,char *defaulthost)
{
  ADDRESS *adr = NIL;
  char *s,*end;
  if (!*string) return NIL;	/* no string */
  rfc822_skipws (string);	/* flush leading whitespace */
  if (!**string) return NIL;	/* empty string */
  if (*(s = *string) == '<') 	/* note start, handle case of phraseless RA */
    adr = rfc822_parse_routeaddr (s,string,defaulthost);
				/* otherwise, expect at least one word */
  else if (end = rfc822_parse_phrase (s)) {
    if ((adr = rfc822_parse_routeaddr (end,string,defaulthost))) {
				/* phrase is a personal name */
      if (adr->personal) fs_give ((void **) &adr->personal);
      *end = '\0';		/* tie off phrase */
      adr->personal = rfc822_cpy (s);
    }
				/* call external phraseparser if phrase only */
    else adr = rfc822_parse_addrspec (s,string,defaulthost);
  }
  return adr;			/* return the address */
}


static ADDRESS *mail_newaddr (void)
{
  return (ADDRESS *) memset (fs_get (sizeof (ADDRESS)),0,sizeof (ADDRESS));
}

static void rfc822_parse_adrlist (ADDRESS **lst,char *string,char *host)
{
  int c;
  char *s,tmp[MAILTMPLEN];
  ADDRESS *last = *lst;
  ADDRESS *adr;
  if (!string) return;		/* no string */
  rfc822_skipws (&string);	/* skip leading WS */
  if (!*string) return;		/* empty string */
				/* run to tail of list */
  if (last) while (last->next) last = last->next;
  while (string) {		/* loop until string exhausted */
    while (*string == ',') {	/* RFC 822 allowed null addresses!! */
      ++string;			/* skip the comma */
      rfc822_skipws (&string);	/* and any leading WS */
    }
    if (!*string) string = NIL;	/* punt if ran out of string */
				/* got an address? */
    else if (adr = rfc822_parse_address (lst,last,&string,host,0)) {
      last = adr;		/* new tail address */
      if (string) {		/* analyze what follows */
	rfc822_skipws (&string);
	switch (c = *(unsigned char *) string) {
	case ',':		/* comma? */
	  ++string;		/* then another address follows */
	  break;
	default:
	  s = isalnum (c) ? "Must use comma to separate addresses: %.80s" :
	    "Unexpected characters at end of address: %.80s";
	  sprintf (tmp,s,string);
	  MM_LOG (tmp,PARSE);
	  last = last->next = mail_newaddr ();
	  last->mailbox = cpystr ("UNEXPECTED_DATA_AFTER_ADDRESS");
	  last->host = cpystr (errhst);
				/* falls through */
	case '\0':		/* null-specified address? */
	  string = NIL;		/* punt remainder of parse */
	  break;
	}
      }
    }
    else if (string) {		/* bad mailbox */
      rfc822_skipws (&string);	/* skip WS */
      if (!*string) strcpy (tmp,"Missing address after comma");
      else sprintf (tmp,"Invalid mailbox list: %.80s",string);
      MM_LOG (tmp,PARSE);
      string = NIL;
      (adr = mail_newaddr ())->mailbox = cpystr ("INVALID_ADDRESS");
      adr->host = cpystr (errhst);
      if (last) last = last->next = adr;
      else *lst = last = adr;
      break;
    }
  }
}

static ADDRESS *rfc822_parse_address (ADDRESS **lst,ADDRESS *last,char **string,
			       char *defaulthost,unsigned long depth)
{
  ADDRESS *adr;
  if (!*string) return NIL;	/* no string */
  rfc822_skipws (string);	/* skip leading WS */
  if (!**string) return NIL;	/* empty string */
  if (adr = rfc822_parse_group (lst,last,string,defaulthost,depth)) last = adr;
				/* got an address? */
  else if (adr = rfc822_parse_mailbox (string,defaulthost)) {
    if (!*lst) *lst = adr;	/* yes, first time through? */
    else last->next = adr;	/* no, append to the list */
				/* set for subsequent linking */
    for (last = adr; last->next; last = last->next);
  }
  else if (*string) return NIL;
  return last;
}

static void mail_free_address (ADDRESS **address)
{   
  if (*address) {    /* only free if exists */
    if ((*address)->personal) fs_give ((void **) &(*address)->personal);
    if ((*address)->adl) fs_give ((void **) &(*address)->adl);
    if ((*address)->mailbox) fs_give ((void **) &(*address)->mailbox);
    if ((*address)->host) fs_give ((void **) &(*address)->host);
    if ((*address)->error) fs_give ((void **) &(*address)->error);
    if ((*address)->orcpt.type) fs_give ((void **) &(*address)->orcpt.type);
    if ((*address)->orcpt.addr) fs_give ((void **) &(*address)->orcpt.addr);
    mail_free_address (&(*address)->next);
    fs_give ((void **) address);/* return address to free storage */
  }
}

MODULE = Email::AddressParser		PACKAGE = Email::AddressParser		

AV *
internal_parse(char *in)
   CODE:
      ADDRESS *list = NULL;
      ADDRESS *p = NULL;
      HV *hv;
      SV *val;

      RETVAL = newAV();
      sv_2mortal((SV*)RETVAL);

      rfc822_parse_adrlist(&list, in, "");

      p = list;
      while(p != NULL) {
         hv = (HV*)newHV();
         if(p->personal)
            hv_store(hv, "personal", 8, newSVpv(p->personal, strlen(p->personal)), 0);
         if(p->mailbox && p->host) {
            if(strcmp(p->mailbox, "INVALID_ADDRESS") == 0) {
               // Got a bad address, skip it
               sv_2mortal((SV*)hv);
               p=p->next;
               continue;
            }
            val = newSVpv(p->mailbox, 0);
            sv_catpv(val, "@");
            sv_catpv(val, p->host);
            hv_store(hv, "email", 5, val, 0);
         }
         av_push(RETVAL, newRV_noinc((SV*)hv));
         p = p->next;
      }

      mail_free_address(&list);
   OUTPUT:
      RETVAL
