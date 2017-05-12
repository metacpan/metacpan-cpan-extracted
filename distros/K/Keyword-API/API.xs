#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define PL_bufptr (PL_parser->bufptr)
#define PL_bufend (PL_parser->bufend)

static SV *hintkey_keyword_sv;
static SV *keyword_name_sv;
static SV *keyword_parser_sv;
static int (*next_keyword_plugin)(pTHX_ char *, STRLEN, OP **);

/* plugin glue */
static int THX_keyword_active(pTHX_ SV *hintkey_sv)
{
	HE *he;
	if(!GvHV(PL_hintgv)) return 0;
	he = hv_fetch_ent(GvHV(PL_hintgv), hintkey_sv, 0,
				SvSHARED_HASH(hintkey_sv));
	return he && SvTRUE(HeVAL(he));
}
#define keyword_active(hintkey_sv) THX_keyword_active(aTHX_ hintkey_sv)


static void THX_keyword_enable(pTHX_ SV *classname, SV* keyword)
{
    hintkey_keyword_sv = newSVsv(classname);
    keyword_parser_sv = newSVsv(classname);
    keyword_name_sv = newSVsv(keyword);

    sv_catpv(hintkey_keyword_sv, "/");
    sv_catpv(keyword_parser_sv, "::parser");
    sv_catsv(hintkey_keyword_sv, keyword);

	SV *val_sv = newSViv(1);
	HE *he;
	PL_hints |= HINT_LOCALIZE_HH;
	gv_HVadd(PL_hintgv);
	he = hv_store_ent(GvHV(PL_hintgv),
		hintkey_keyword_sv, val_sv, SvSHARED_HASH(hintkey_keyword_sv));
	if(he) {
		SV *val = HeVAL(he);
		SvSETMAGIC(val);
	} else {
		SvREFCNT_dec(val_sv);
	}    
}
#define keyword_enable(class_sv, keyword_sv) THX_keyword_enable(aTHX_ class_sv, keyword_sv)


static void THX_keyword_disable(pTHX)
{
	if(GvHV(PL_hintgv)) {
		PL_hints |= HINT_LOCALIZE_HH;
		hv_delete_ent(GvHV(PL_hintgv),
			hintkey_keyword_sv, G_DISCARD, SvSHARED_HASH(hintkey_keyword_sv));
	}
}
#define keyword_disable() THX_keyword_disable(aTHX)


static int my_keyword_plugin(pTHX_
	char *keyword_ptr, STRLEN keyword_len, OP **op_ptr)
{
    if (keyword_name_sv == NULL) {
	    return next_keyword_plugin(aTHX_ keyword_ptr, keyword_len, op_ptr);
    }

    STRLEN len;
    char * kw_str = SvPV(keyword_name_sv, len);
    int kw_len = strlen(kw_str);    

	if(keyword_len == kw_len && strnEQ(keyword_ptr, kw_str, kw_len) &&
			keyword_active(hintkey_keyword_sv)) {
        call_sv(keyword_parser_sv, G_DISCARD|G_NOARGS);
		*op_ptr = newOP(OP_NULL,0);
		return KEYWORD_PLUGIN_STMT;
	} else {
		return next_keyword_plugin(aTHX_
				keyword_ptr, keyword_len, op_ptr);
	}
}


MODULE = Keyword::API		PACKAGE = Keyword::API		

BOOT:
    next_keyword_plugin = PL_keyword_plugin;
	PL_keyword_plugin = my_keyword_plugin;

void
install_keyword(SV *classname, SV *keyword)
PPCODE:
    keyword_enable(classname,keyword);

void
uninstall_keyword();
PPCODE:
    keyword_disable();

void
lex_read_space(int flag);

SV* 
lex_read(int chars)
CODE:
    char *start = PL_bufptr;
    char *end = start + chars;
    lex_read_to(end);
    RETVAL = newSVpvn(start, end-start);
OUTPUT:
    RETVAL

SV *lex_read_to_ws()
CODE:
    char *start = PL_bufptr;
    char *p = start;

    while(1) {
        char x = *++p;
        if (isSPACE(x)) {
            break;
        }
    } 

    RETVAL = newSVpvn(start, p-start);
OUTPUT:
    RETVAL


SV *lex_unstuff_to_ws()
CODE:
    char *start = PL_bufptr;
    char *p = start;

    while(1) {
        char x = *++p;
        if (isSPACE(x)) {
            break;
        }
    } 

    RETVAL = newSVpvn(start, p-start);
    lex_unstuff(p);
OUTPUT:
    RETVAL

SV* lex_unstuff_to(char s)
CODE:
    char *start = PL_bufptr;
    char *p = start;

    while(1) {
        char x = *++p;
        if (x == s) {
            break;
        }
    } 

    p++;

    RETVAL = newSVpvn(start, p-start);
    lex_unstuff(p);
OUTPUT:
    RETVAL

SV*
lex_unstuff(int chars)
CODE:
    char *start = PL_bufptr;
    char *end = start + chars;
    RETVAL = newSVpvn(start, end-start);
    lex_unstuff(end);
OUTPUT:
    RETVAL

void
lex_stuff(SV *str)
CODE:
    lex_stuff_sv(str, 0);
