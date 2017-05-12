/*
  Inspired by Text::Balanced
  (Which unfortunately doesn't work on large amounts of text, probably
   because perl regex max-out well below 32k.)
*/

#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif

static int isword(char ch)
{
  return (isalnum(ch) || ch == '#' || ch == '_')?1:0;
}

static int myrelen(char *re, int relen)
{
  int len=0;
  int tx;
  for (tx=0; tx < relen; tx++) {
    if (re[tx] == '\\') { tx++; continue; }
    ++len;
  }
  return len;
}

static int myrematch(char *base, char *targ, int targlen)
{
  int tx;
  int bx;
  for (tx=0,bx=0; tx < targlen; tx++) {
    if (targ[tx] == '\\') {
      ++tx;
      if (targ[tx] == 'b') {
/*	fprintf(stderr, "\\b=%c.%c\n", base[bx-1], base[bx]);/**/
	if (!(isword(base[bx-1]) ^ isword(base[bx]))) return 0;
      } else {
	croak("myrematch: unknown metacharacter '%c'", targ[tx]);
      }
    } else {
/*      fprintf(stderr, "%c=%c\n", base[bx], targ[tx]);/**/
      if (base[bx] != targ[tx]) return 0;
      bx++;
    }
  }
  return 1;
}

MODULE = Devel::CCov		PACKAGE = Devel::CCov

PROTOTYPES: ENABLE

void
cc_exprstr(in_str, in_target)
	SV *in_str
	SV *in_target
	PREINIT:
	STRLEN length;
	STRLEN targlen, relen;
	char *base_str;
	char *targ_str;
	int st_start, st_pos;
	int pos = 0;
	int state = 'r';
	int line = 1;
	int plevel = 0;
	PPCODE:
	base_str = SvPV(in_str, length);
	if (length == 0) croak("cc_exprstr: length=0");
	targ_str = SvPV(in_target, targlen);
	relen = myrelen(targ_str, targlen);
	while (pos < length) {
	  char at = base_str[pos];
	  char at2 = pos+1 < length? base_str[pos+1] : ' ';
	  char old_st = state;
	  if (at == '\n') ++line;
	  switch (state) {
	  case 'r':
	    if (at == '/' && at2 == '*') { state = 'c'; break; }
	    if (at == '/' && at2 == '/') { state = 'C'; break; }
	    if (at == '\'') { state = 'q'; break; }
	    if (at == '"') { state = 'Q'; break; }
	    if (at == '(') { ++plevel; break; }
	    if (at == ')') { --plevel; break; }
	    if (pos <= length - relen && plevel==0 &&
	        myrematch(base_str+pos, targ_str, targlen)) {
	      STRLEN tlen;
	      /*warn("len=%d targlen=%d pos=%d", length, targlen, pos);/**/
	      tlen = pos;
	      XPUSHs(sv_2mortal(newSVpv(base_str,tlen>0? tlen:0)));
	      tlen = length-pos;
	      XPUSHs(sv_2mortal(newSVpv(base_str+pos,tlen>0? tlen:0)));
	      PUTBACK;
	      return;
	    }
	    break;
	  case 'c':
	    if (at == '*' && at2 == '/') { ++pos; state = 'r'; }
	    break;
	  case 'C':
	    if (at == '\n') state = 'r';
	    break;
	  case 'q':
	    if (at == '\\' && at2 == '\\') { ++pos; break; }
	    if (at == '\\' && at2 == '\'') { ++pos; break; }
	    if (at == '\'') { state = 'r'; break; }
	    break;
	  case 'Q':
	    if (at == '\\' && at2 == '\\') { ++pos; break; }
	    if (at == '\\' && at2 == '"') { ++pos; break; }
	    if (at == '"') { state = 'r'; break; }
	    break;
	  default: croak("cc_exprstr: unknown state '%c' at line %d", state, line);
	  }
	  if (state != old_st && state != 'r') {
	    st_start = line; st_pos = pos;
	  }
	  ++pos;
	}
	if (state == 'c') croak("cc_exprstr: unclosed comment starting on line %d: %s",st_start,base_str+st_pos);
	if (state == 'q')
	  croak("cc_exprstr: unmatched single quote starting on line %d", st_start);
	if (state == 'Q')
	  croak("cc_exprstr: unmatched double quote starting on line %d", st_start);

void
cc_strstr(in_str, in_target)
	SV *in_str
	SV *in_target
	PREINIT:
	STRLEN length;
	STRLEN targlen, relen;
	char *base_str;
	char *targ_str;
	int st_start, st_pos;
	int pos = 0;
	int state = 'r';
	int line = 1;
	PPCODE:
	base_str = SvPV(in_str, length);
	if (length == 0) croak("cc_strstr: length=0");
	targ_str = SvPV(in_target, targlen);
	relen = myrelen(targ_str, targlen);
	while (pos < length) {
	  char at = base_str[pos];
	  char at2 = pos+1 < length? base_str[pos+1] : ' ';
	  char old_st = state;
	  if (at == '\n') ++line;
	  switch (state) {
	  case 'r':
	    if (at == '/' && at2 == '*') { state = 'c'; break; }
	    if (at == '/' && at2 == '/') { state = 'C'; break; }
	    if (at == '\'') { state = 'q'; break; }
	    if (at == '"') { state = 'Q'; break; }
	    if (pos <= length - relen &&
	        myrematch(base_str+pos, targ_str, targlen)) {
	      STRLEN tlen;
	      /*warn("len=%d targlen=%d pos=%d", length, targlen, pos);/**/
	      tlen = pos;
	      XPUSHs(sv_2mortal(newSVpv(base_str,tlen>0? tlen:0)));
	      tlen = length-pos;
	      XPUSHs(sv_2mortal(newSVpv(base_str+pos,tlen>0? tlen:0)));
	      PUTBACK;
	      return;
	    }
	    break;
	  case 'c':
	    if (at == '*' && at2 == '/') { ++pos; state = 'r'; break; }
	    break;
	  case 'C':
	    if (at == '\n') state = 'r';
	    break;
	  case 'q':
	    if (at == '\\' && at2 == '\\') { ++pos; break; }
	    if (at == '\\' && at2 == '\'') { ++pos; break; }
	    if (at == '\'') { state = 'r'; break; }
	    break;
	  case 'Q':
	    if (at == '\\' && at2 == '\\') { ++pos; break; }
	    if (at == '\\' && at2 == '"') { ++pos; break; }
	    if (at == '"') { state = 'r'; break; }
	    break;
	  default: croak("cc_strstr: unknown state '%c' at line %d", state, line);
	  }
	  if (0 && state != old_st) {
	    warn("LINE %d:%d state %c->%c\n", line, pos, old_st, state);
	  }
	  if (state != old_st && state != 'r') {
	    st_start = line; st_pos = pos;
	  }
	  if (0 && state != old_st && state == 'r') {
	    int px;
	    fprintf(stderr, "LINE %d %c[%d-%d] [", st_start, old_st, st_pos, pos);
	    for (px=st_pos; px <= pos && px < length; px++) {
	      fprintf(stderr, "%c", base_str[px]);
	    }
	    fprintf(stderr, "]\n");
	  }
	  ++pos;
	}
	if (state == 'c') croak("cc_strstr: unclosed comment starting on line %d: %s",st_start,base_str+st_pos);
	if (state == 'q')
	  croak("cc_strstr: unmatched single quote starting on line %d", st_start);
	if (state == 'Q')
	  croak("cc_strstr: unmatched double quote starting on line %d", st_start);

void
extract_balanced(in_str, paren1)
	SV *in_str
	char paren1
	PREINIT:
	STRLEN length;
	char *base_str;
	int line;
	int pos;
	int opens,closes;
	int st_start;
	int st_pos;
	char state;
	char paren2;
	PPCODE:
	/*warn("---BEGIN codeblock\n");/**/
	if (!(paren1 == '(' || paren1 == '{'))
	  croak("extract_balanced: only works on () and {}");
	paren2 = paren1 == '('? ')' : '}';
	base_str = SvPV(in_str, length);
	line = 1;
	pos = 0;
	opens = closes = 0;
	state = 'r';
	if (base_str[0] != paren1)
	  croak("extract_balanced: string doesn't begin with open quote");
	++pos;
	++opens;
	while (opens - closes > 0 && pos < length) {
	  char at = base_str[pos];
	  char at2 = pos+1 < length? base_str[pos+1] : ' ';
	  char old_st = state;
	  if (at == '\n') ++line;
	  switch (state) {
	  case 'r':
	    if (at == paren1) { ++opens; break; }
	    if (at == paren2) { ++closes; break; }
	    if (at == '/' && at2 == '*') { state = 'c'; break; }
	    if (at == '/' && at2 == '/') { state = 'C'; break; }
	    if (at == '\'') { state = 'q'; break; }
	    if (at == '"') { state = 'Q'; break; }
	    break;
	  case 'c':
	    if (at == '*' && at2 == '/') { ++pos; state = 'r'; break; }
	    break;
	  case 'C':
	    if (at == '\n') state = 'r';
	    break;
	  case 'q':
	    if (at == '\\' && at2 == '\\') { ++pos; break; }
	    if (at == '\\' && at2 == '\'') { ++pos; break; }
	    if (at == '\'') { state = 'r'; break; }
	    break;
	  case 'Q':
	    if (at == '\\' && at2 == '\\') { ++pos; break; }
	    if (at == '\\' && at2 == '"') { ++pos; break; }
	    if (at == '"') { state = 'r'; break; }
	    break;
	  default: croak("extract_balanced: unknown state '%c' at line %d", state, line);
	  }
	  if (state != old_st && state != 'r') {
	    st_start = line; st_pos = pos;
	  }
	  if (0 && state != old_st && state == 'r') {
	    int px;
	    fprintf(stderr, "LINE %d %c[%d-%d] [", st_start, old_st, st_pos, pos);
	    for (px=st_pos; px <= pos && px < length; px++) {
	      fprintf(stderr, "%c", base_str[px]);
	    }
	    fprintf(stderr, "]\n");
	  }
	  ++pos;
	}
	if (state == 'c') croak("extract_balanced: unclosed comment starting on line %d: %s",st_start,base_str+st_pos);
	if (state == 'q')
	  croak("extract_balanced: unmatched single quote starting on line %d", st_start);
	if (state == 'Q')
	  croak("extract_balanced: unmatched double quote starting on line %d", st_start);
	if (opens - closes != 0) {
	  XPUSHs(&sv_undef);
	  assert(length >= 0);
	  XPUSHs(sv_2mortal(newSVpv(base_str, length)));
	} else {
	  STRLEN tlen;
	  tlen = pos;
	  XPUSHs(sv_2mortal(newSVpv(base_str, tlen>0? tlen:0)));
	  tlen = length-pos;
	  XPUSHs(sv_2mortal(newSVpv(base_str+pos, tlen>0? tlen:0)));
	}
