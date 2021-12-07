/* -*- c -*- 
 * File: pstring.h
 * Author: Igor Vlasenko <vlasenko@imath.kiev.ua>
 * Created: Fri Jul  1 20:11:51 2005
 *
 * $Id$
 */

#ifdef HAVE_CONFIG_H
#include "config.h"
#endif
#include <stdio.h>
#include <string.h>
#include "pstring.h"
#include "tmpllog.h"
#include "exprval.h"
#include "pmiscdef.h" /*for snprintf */

static
PSTRING 
double_to_pstring (double number, char buffer[], size_t bufsize) {
  size_t len=0;
  size_t tmplen=0;
  PSTRING retval;
  snprintf(buffer,bufsize,"%f",number);
  len=strlen(buffer);
  tmplen=len;
  /* removing trailing 0 as 2.00000... */
  while (buffer[tmplen-1]=='0' && tmplen-->0); 
  if (buffer[tmplen-1]=='.') {
    tmplen--;
    len=tmplen;
  }
  retval.begin=buffer;
  retval.endnext=buffer+len;
  return retval;
}

static
PSTRING 
int_to_pstring (EXPR_int64 number, char buffer[], size_t bufsize) {
  size_t len=0;
  PSTRING retval;
  snprintf(buffer, bufsize,"%" EXPR_PRId64 , number);
  len=strlen(buffer);
  retval.begin=buffer;
  retval.endnext=buffer+len;
  return retval;
}

static
int 
pstring_ge(PSTRING a, PSTRING b) {
  const char* in_a=a.begin;
  const char* in_b=b.begin;
  if (in_b==NULL) return 1;
  if (in_a==NULL) return 0;
  while (in_a<a.endnext && in_b < b.endnext && *in_a++==*in_b++);
  if ((in_a==a.endnext && in_b==b.endnext) || *(--in_a) >= *(--in_b) ) return 1; else return 0;
}

static
int 
pstring_le(PSTRING a, PSTRING b) {
  const char* in_a=a.begin;
  const char* in_b=b.begin;
  if (in_a==NULL) return 1;
  if (in_b==NULL) return 0;
  while (in_a<a.endnext && in_b < b.endnext && *in_a++==*in_b++);
  if ((in_a==a.endnext && in_b==b.endnext) || *(--in_a) <= *(--in_b) ) return 1; else return 0;
}

static
int 
pstring_ne(PSTRING a, PSTRING b) {
  const char* in_a=a.begin;
  const char* in_b=b.begin;
  if (in_a==NULL || in_b==NULL) return in_a != in_b;
  while (in_a<a.endnext && in_b < b.endnext && *in_a++==*in_b++);
  if (in_a==a.endnext && in_b==b.endnext && *(--in_a) == *(--in_b)) return 0; else return 1;
}

static
int 
pstring_eq(PSTRING a, PSTRING b) {
  const char* in_a=a.begin;
  const char* in_b=b.begin;
  if (in_a==NULL || in_b==NULL) return in_a == in_b;
  if (in_a==a.endnext) return in_b==b.endnext;
  while (in_a<a.endnext && in_b < b.endnext && *in_a++==*in_b++);
  if (in_a==a.endnext && in_b==b.endnext && *(--in_a) == *(--in_b)) return 1; else return 0;
}

static
int 
pstring_gt(PSTRING a, PSTRING b) {
  const char* in_a=a.begin;
  const char* in_b=b.begin;
  if (in_a==NULL) return 0;
  if (in_b==NULL) return 1;
  while (in_a<a.endnext && in_b < b.endnext && *in_a++==*in_b++);
  if ((in_b==b.endnext && in_a!=a.endnext)
      || (*(--in_a) > *(--in_b)) ) return 1; else return 0;
}

static
int 
pstring_lt(PSTRING a, PSTRING b) {
  const char* in_a=a.begin;
  const char* in_b=b.begin;
  if (in_b==NULL) return 0;
  if (in_a==NULL) return 1;
  while (in_a<a.endnext && in_b < b.endnext && *in_a++==*in_b++);
  if ((in_b!=b.endnext && in_a==a.endnext)
      ||  *(--in_a) < *(--in_b) ) return 1; else return 0;
}

static
int 
re_notlike(struct expr_parser* exprobj, PSTRING a, PSTRING b) {
  return ! re_like(exprobj, a,b);
}

#ifdef HAVE_PCRE2
/* https://github.com/luvit/pcre2/blob/master/src/pcre2demo.c */
#define PCRE2_CODE_UNIT_WIDTH 8
#include <pcre2.h>
static
int
re_like(struct expr_parser* exprobj, PSTRING a, PSTRING b) {
  pcre2_code* re;
  int rc, errornumber;
  PCRE2_SIZE erroroffset;
  PCRE2_SPTR subject=(PCRE2_SPTR)a.begin;
  size_t subject_length=(a.endnext-a.begin);
  char* pattern;
  pcre2_match_data *match_data;
  if (subject==NULL) {
    log_expr(exprobj,TMPL_LOG_INFO, "regular expression: applied to undefined value.\n");
    return 0;
  }
  if (b.begin==NULL || (b.endnext-b.begin)==0) {
    log_expr(exprobj,TMPL_LOG_INFO, "regular expression: the pattern is empty or undefined.\n");
    return 1;
  }
  pattern=(char*)malloc(b.endnext-b.begin);
  if (pattern==NULL) {
    log_expr(exprobj,TMPL_LOG_ERROR, "regular expression: memory allocation failed.\n");
    return 0;
  }
  strncpy(pattern, b.begin, (b.endnext-b.begin));
  *(pattern+(b.endnext-b.begin))=0;
  re = pcre2_compile((PCRE2_SPTR)pattern,PCRE2_ZERO_TERMINATED,0,&errornumber,&erroroffset,NULL);
  free(pattern);
  if (re==NULL) {
      PCRE2_UCHAR buffer[256];
      pcre2_get_error_message(errornumber, buffer, sizeof(buffer));
      log_expr(exprobj,TMPL_LOG_ERROR, "regular expression: PCRE2 compilation failed at offset %zd: %s\n",
      erroroffset, buffer);
      return 0;
  }
  match_data = pcre2_match_data_create_from_pattern(re, NULL);
  rc = pcre2_match(re,subject,subject_length,0,0,match_data,NULL);
  /* Matching failed: handle error cases */
  if(rc<0 && PCRE2_ERROR_NOMATCH != rc) {
      PCRE2_UCHAR buffer[256];
      pcre2_get_error_message(errornumber, buffer, sizeof(buffer));
      log_expr(exprobj,TMPL_LOG_ERROR, "regular expression: PCRE2 reported run error %d: %s\n",errornumber, buffer);
  }
  pcre2_match_data_free(match_data);   /* Release memory used for the match */
  pcre2_code_free(re);                 /* data and the compiled pattern. */
  return (rc<0)?0:1;
}
#else
#ifdef HAVE_PCRE
#include <pcre.h>
static
int 
re_like(struct expr_parser* exprobj, PSTRING a, PSTRING b) {
  pcre* re;
  int ovector[30];
  int rc, erroffset;
  const char* error;
  const char* subject=a.begin;
  int subject_length=(int)(a.endnext-a.begin);
  char* pattern;
  if (subject==NULL) {
    log_expr(exprobj,TMPL_LOG_INFO, "regular expression: applied to undefined value.\n");
    return 0;
  }
  if (b.begin==NULL || (b.endnext-b.begin)==0) {
    log_expr(exprobj,TMPL_LOG_INFO, "regular expression: the pattern is empty or undefined.\n");
    return 1;
  }
  pattern=(char*)malloc(b.endnext-b.begin);
  if (pattern==NULL) {
    log_expr(exprobj,TMPL_LOG_ERROR, "regular expression: memory allocation failed.\n");
    return 0;
  }
  strncpy(pattern, b.begin, (b.endnext-b.begin));
  *(pattern+(b.endnext-b.begin))=0;
  re = pcre_compile(pattern, 0, &error, &erroffset, NULL); /* default character set */
  free(pattern);
  if (re==NULL) {
      log_expr(exprobj,TMPL_LOG_ERROR, "regular expression: PCRE compilation failed at offset %d: %s\n",
      erroffset, error);
    return 0;
  }
  rc=pcre_exec(re, NULL, subject, subject_length, 0, 0, ovector, 30);
  return (rc<0)?0:1;
}
#else
static
int 
re_like(struct expr_parser* exprobj, PSTRING a, PSTRING b) {
  log_expr(exprobj,TMPL_LOG_ERROR,"can't parse the regular expression (sorry, Stanislav Yadykin regexp extension is disabled at compile time) \n");
  return 0;
}
#endif
#endif
