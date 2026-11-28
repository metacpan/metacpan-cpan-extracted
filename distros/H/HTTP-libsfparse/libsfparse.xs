#define PERL_NO_GET_CONTEXT 1

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#define MATH_INT64_NATIVE_IF_AVAILABLE
#include "perl_math_int64.h"
#include "sfparse.h"

/* ------------------------------------------------------------------------
 * Parser state.
 *
 * libsfparse is a pull parser with a state machine of its own: every entry
 * point knows which calls may follow the last one, and calls abort() if it
 * is called somewhere that state machine does not allow.  That is not
 * something a Perl program can catch, so it must not be reachable.
 *
 * It is not: each of the three functions this module exposes drives one
 * parser from start to finish inside a single call, in the order the state
 * machine expects, and nothing is shared between calls.  No sequence of
 * calls from Perl can put a parser somewhere the library does not expect,
 * because Perl never sees a parser at all.
 *
 * Keep that true when editing below.  The library is vendored unmodified, so
 * a mistake here is a core dump rather than an exception.
 *
 * The only state carried here is `failed', which pins the offset of a parse
 * error down while the input copy is still allocated, so that the croak
 * after Safefree() never touches a freed pointer.
 * ------------------------------------------------------------------------ */

/* Which top level entry point to call.  A selector for one call, not
   remembered state: the library's own state machine is what refuses a field
   value read as more than one of the three shapes. */
#define SFP_TOP_DICT 0
#define SFP_TOP_LIST 1
#define SFP_TOP_ITEM 2

typedef struct sfp_wrap {
  sfparse_parser sfp;
  char *data;      /* owned copy of the input, NULL when it is empty */
  U8 failed;       /* a parse error was reported */
  UV err_off;      /* byte offset where that error was reported */
} sfp_wrap;

/* Byte offset the parser has reached, for diagnostics.  sfparse_parser.pos
   is nominally private, but its offset within the struct comes from the
   header we compile against, so reading it is ABI-safe. */
static UV sfp_offset(const sfp_wrap *w) {
  if (w->sfp.pos == NULL || w->data == NULL) {
    return 0;
  }

  return (UV)(w->sfp.pos - (const uint8_t *)w->data);
}

/* Pin down the error offset while the input copy is still allocated, so that
   a croak after Safefree() never touches the freed pointer. */
static void sfp_mark_failed(sfp_wrap *w) {
  if (!w->failed) {
    w->err_off = sfp_offset(w);
    w->failed = 1;
  }
}

static void sfp_croak_parse(pTHX_ const sfp_wrap *w) {
  croak("HTTP::libsfparse: parse error at offset %" UVuf,
        w->failed ? w->err_off : sfp_offset(w));
}

/* ------------------------------------------------------------------------
 * Input handling
 * ------------------------------------------------------------------------ */

/* Structured field values are byte strings.  Accept a byte string, or a
   character string that is losslessly representable as bytes; refuse
   anything else rather than silently parsing utf8 internals. */
static const char *sfp_input(pTHX_ SV *sv, STRLEN *lenp) {
  SvGETMAGIC(sv);

  if (!SvOK(sv)) {
    croak("HTTP::libsfparse: input is undefined");
  }

  if (SvUTF8(sv)) {
    SV *tmp = newSVsv_nomg(sv);

    if (!sv_utf8_downgrade(tmp, TRUE)) {
      croak("HTTP::libsfparse: input must be a byte string, but it contains "
            "characters above U+00FF; encode it first");
    }

    return SvPV_nomg_const(tmp, *lenp);
  }

  return SvPV_nomg_const(sv, *lenp);
}

/* ------------------------------------------------------------------------
 * Value conversion
 * ------------------------------------------------------------------------ */

static SV *sfp_int_sv(pTHX_ int64_t v) {
  return newSVi64(v);
}

static SV *sfp_vec_sv(pTHX_ const sfparse_vec *v) {
  if (v->len == 0) {
    return newSVpvn("", 0);
  }

  return newSVpvn((const char *)v->base, v->len);
}

typedef void (*sfp_decoder)(sfparse_vec *dest, const sfparse_vec *src);

/* sfparse_unescape(), sfparse_base64decode() and sfparse_pctdecode() all
   write at most src->len bytes, so one buffer of that size always fits. */
static SV *sfp_decode_sv(pTHX_ const sfparse_vec *src, sfp_decoder decode) {
  SV *sv;
  sfparse_vec dest;

  if (src->len == 0) {
    return newSVpvn("", 0);
  }

  sv = newSV(0);
  sv_grow(sv, src->len + 1);
  SvPOK_only(sv);

  dest.base = (uint8_t *)SvPVX(sv);
  dest.len = 0;

  decode(&dest, src);

  assert(dest.len <= src->len);

  SvCUR_set(sv, dest.len);
  *SvEND(sv) = '\0';

  SvTAINT(sv);

  return sv;
}

/* Every value is an array of three elements:

     [ SFPARSE_TYPE_*, value, params ]

   so that a caller can index into any of them without first looking at the
   type.  `value' is left unset for an inner list, whose members the builder
   fills in.

   A dictionary member and a parameter are each a [ key, item ] pair.

   These names are the ones exported to Perl, so that a caller can index a
   value by name rather than by number, and both sides of the binding take
   the layout from this one place. */

#define SFP_TYPE        0
#define SFP_VALUE       1
#define SFP_PARAMS      2

#define SFP_KEY  0
#define SFP_ITEM 1

#define SFP_ITEM_WIDTH 3
#define SFP_PAIR_WIDTH 2

static SV *sfp_make_value(pTHX_ const sfparse_value *val) {
  AV *av = newAV();
  SV *ref = newRV_noinc((SV *)av);

  /* Fill to the full width up front: the slots left alone read as undef. */
  av_fill(av, SFP_ITEM_WIDTH - 1);

  switch (val->type) {
  case SFPARSE_TYPE_BOOLEAN:
    (void)av_store(av, SFP_VALUE, newSViv(val->boolean ? 1 : 0));

    break;
  case SFPARSE_TYPE_INTEGER:
  case SFPARSE_TYPE_DATE:
    (void)av_store(av, SFP_VALUE, sfp_int_sv(aTHX_ val->integer));

    break;
  case SFPARSE_TYPE_DECIMAL:
    (void)av_store(av, SFP_VALUE,
                   newSVnv((NV)val->decimal.numer / (NV)val->decimal.denom));

    break;
  case SFPARSE_TYPE_STRING:
    if (val->flags & SFPARSE_VALUE_FLAG_ESCAPED_STRING) {
      (void)av_store(av, SFP_VALUE,
                     sfp_decode_sv(aTHX_ & val->vec, sfparse_unescape));
    } else {
      (void)av_store(av, SFP_VALUE, sfp_vec_sv(aTHX_ & val->vec));
    }

    break;
  case SFPARSE_TYPE_TOKEN:
    (void)av_store(av, SFP_VALUE, sfp_vec_sv(aTHX_ & val->vec));

    break;
  case SFPARSE_TYPE_BYTESEQ:
    (void)av_store(av, SFP_VALUE,
                   sfp_decode_sv(aTHX_ & val->vec, sfparse_base64decode));

    break;
  case SFPARSE_TYPE_DISPSTRING: {
    /* The parser has already validated the utf8, so flag the result as
       characters rather than handing back percent-encoded bytes. */
    SV *sv = sfp_decode_sv(aTHX_ & val->vec, sfparse_pctdecode);

    SvUTF8_on(sv);

    (void)av_store(av, SFP_VALUE, sv);

    break;
  }
  case SFPARSE_TYPE_INNER_LIST:
    /* The members are the caller's to fill in. */

    break;
  default:
    SvREFCNT_dec(ref);
    croak("HTTP::libsfparse: unknown sfparse value type %d", (int)val->type);
  }

  (void)av_store(av, SFP_TYPE, newSViv((IV)val->type));

  return ref;
}

/* ------------------------------------------------------------------------
 * The library's entry points.  These are the whole of the parsing logic:
 * call libsfparse and remember a parse error, so that its offset is still
 * available once the input copy has been freed.  The return code is the
 * library's own: 0, SFPARSE_ERR_EOF or SFPARSE_ERR_PARSE.
 * ------------------------------------------------------------------------ */

static int sfp_param(sfp_wrap *w, sfparse_vec *key, sfparse_value *val) {
  int rv = sfparse_parser_param(&w->sfp, key, val);

  if (rv != 0 && rv != SFPARSE_ERR_EOF) {
    sfp_mark_failed(w);
  }

  return rv;
}

static int sfp_inner_list(sfp_wrap *w, sfparse_value *val) {
  int rv = sfparse_parser_inner_list(&w->sfp, val);

  if (rv != 0 && rv != SFPARSE_ERR_EOF) {
    sfp_mark_failed(w);
  }

  return rv;
}

static int sfp_top(sfp_wrap *w, U8 which, sfparse_vec *key,
                   sfparse_value *val) {
  int rv;

  switch (which) {
  case SFP_TOP_DICT:
    rv = sfparse_parser_dict(&w->sfp, key, val);

    break;
  case SFP_TOP_LIST:
    rv = sfparse_parser_list(&w->sfp, val);

    break;
  default:
    rv = sfparse_parser_item(&w->sfp, val);

    break;
  }

  if (rv != 0 && rv != SFPARSE_ERR_EOF) {
    sfp_mark_failed(w);
  }

  return rv;
}

/* ------------------------------------------------------------------------
 * One shot builders.  On a parse error they free what they have built and
 * return NULL, so that the XSUB can croak without leaking.
 * ------------------------------------------------------------------------ */

static SV *sfp_build_params(pTHX_ sfp_wrap *w);
static SV *sfp_build_item(pTHX_ sfp_wrap *w, const sfparse_value *val);

/* Parameters are an array of [ key, value ] pairs in field order, keeping
   duplicate keys: RFC 9651 says the last of a repeated key wins, but only a
   caller that can see them all can reject a field that repeats one. */
static SV *sfp_build_params(pTHX_ sfp_wrap *w) {
  AV *av = newAV();
  SV *ref = newRV_noinc((SV *)av);

  for (;;) {
    sfparse_vec key;
    sfparse_value val;
    AV *pair;
    int rv = sfp_param(w, &key, &val);

    if (rv == SFPARSE_ERR_EOF) {
      break;
    }

    if (rv != 0) {
      SvREFCNT_dec(ref);

      return NULL;
    }

    /* A parameter value is always a bare item, never an inner list, so it
       needs no recursion into sfp_build_item(). */
    pair = newAV();

    av_fill(pair, SFP_PAIR_WIDTH - 1);
    (void)av_store(pair, SFP_KEY, sfp_vec_sv(aTHX_ & key));
    (void)av_store(pair, SFP_ITEM, sfp_make_value(aTHX_ & val));
    av_push(av, newRV_noinc((SV *)pair));
  }

  return ref;
}

static SV *sfp_build_item(pTHX_ sfp_wrap *w, const sfparse_value *val) {
  SV *ref = sfp_make_value(aTHX_ val);
  AV *av = (AV *)SvRV(ref);
  SV *params;

  if (val->type == SFPARSE_TYPE_INNER_LIST) {
    AV *members = newAV();

    (void)av_store(av, SFP_VALUE, newRV_noinc((SV *)members));

    for (;;) {
      sfparse_value inner;
      SV *item;
      int rv = sfp_inner_list(w, &inner);

      if (rv == SFPARSE_ERR_EOF) {
        break;
      }

      if (rv != 0) {
        SvREFCNT_dec(ref);

        return NULL;
      }

      item = sfp_build_item(aTHX_ w, &inner);

      if (item == NULL) {
        SvREFCNT_dec(ref);

        return NULL;
      }

      av_push(members, item);
    }
  }

  params = sfp_build_params(aTHX_ w);

  if (params == NULL) {
    SvREFCNT_dec(ref);

    return NULL;
  }

  (void)av_store(av, SFP_PARAMS, params);

  return ref;
}

/* ------------------------------------------------------------------------
 * Setting a parser up
 * ------------------------------------------------------------------------ */

/* The library points straight into the bytes it is given and keeps no copy,
   so take one: that way nothing the input SV does later -- being freed,
   reallocated or modified by magic -- can move the ground under the parser
   mid-call. */
static void sfp_init(pTHX_ sfp_wrap *w, SV *input) {
  const char *s;
  STRLEN len;

  s = sfp_input(aTHX_ input, &len);

  /*  The HTTPWG test suite requires large fields, but most modern web servers limit fields to 8KiB */
  if (len > 32767) {
    croak("HTTP::libsfparse: field is too large");
  }

  Zero(w, 1, sfp_wrap);

  if (len > 0) {
    Newx(w->data, len, char);
    Copy(s, w->data, len, char);
  }

  sfparse_parser_init(&w->sfp, (const uint8_t *)w->data, len);
}

MODULE = HTTP::libsfparse   PACKAGE = HTTP::libsfparse   PREFIX = sfp_xs_

PROTOTYPES: DISABLE

# The type constants are the library's own enumerators, taken from the header
# this is compiled against rather than written out here, so that re-vendoring
# a libsfparse whose enum has grown or been reordered cannot leave Perl with
# stale numbers.  The index constants come from the #defines above, which is
# also what the code building the structures uses.

BOOT:
  PERL_MATH_INT64_LOAD_OR_CROAK;
{
  static const struct {
    const char *name;
    int value;
  } constants[] = {
    {"SFPARSE_TYPE_BOOLEAN", SFPARSE_TYPE_BOOLEAN},
    {"SFPARSE_TYPE_INTEGER", SFPARSE_TYPE_INTEGER},
    {"SFPARSE_TYPE_DECIMAL", SFPARSE_TYPE_DECIMAL},
    {"SFPARSE_TYPE_STRING", SFPARSE_TYPE_STRING},
    {"SFPARSE_TYPE_TOKEN", SFPARSE_TYPE_TOKEN},
    {"SFPARSE_TYPE_BYTESEQ", SFPARSE_TYPE_BYTESEQ},
    {"SFPARSE_TYPE_INNER_LIST", SFPARSE_TYPE_INNER_LIST},
    {"SFPARSE_TYPE_DATE", SFPARSE_TYPE_DATE},
    {"SFPARSE_TYPE_DISPSTRING", SFPARSE_TYPE_DISPSTRING},
    {"SFP_TYPE", SFP_TYPE},
    {"SFP_VALUE", SFP_VALUE},
    {"SFP_PARAMS", SFP_PARAMS},
    {"SFP_KEY", SFP_KEY},
    {"SFP_ITEM", SFP_ITEM}
  };
  HV *stash = gv_stashpvs("HTTP::libsfparse", GV_ADD);
  size_t i;
  for (i = 0; i < sizeof(constants) / sizeof(constants[0]); ++i) {
    newCONSTSUB(stash, constants[i].name, newSViv((IV)constants[i].value));
  }
}

SV *
sfp_xs_parse_item(input)
    SV *input
  PREINIT:
    sfp_wrap w;
    sfparse_value val;
    SV *item;
    int rv;
  CODE:
    sfp_init(aTHX_ &w, input);

    rv = sfp_top(&w, SFP_TOP_ITEM, NULL, &val);

    if (rv != 0) {
      sfp_mark_failed(&w);
      Safefree(w.data);
      sfp_croak_parse(aTHX_ &w);
    }

    item = sfp_build_item(aTHX_ &w, &val);

    if (item == NULL) {
      sfp_mark_failed(&w);
      Safefree(w.data);
      sfp_croak_parse(aTHX_ &w);
    }

    /* A second read must report EOF, otherwise there is trailing garbage. */
    rv = sfp_top(&w, SFP_TOP_ITEM, NULL, NULL);

    if (rv != SFPARSE_ERR_EOF) {
      sfp_mark_failed(&w);
    }

    Safefree(w.data);

    if (rv != SFPARSE_ERR_EOF) {
      SvREFCNT_dec(item);
      sfp_croak_parse(aTHX_ &w);
    }

    RETVAL = item;
  OUTPUT:
    RETVAL

SV *
sfp_xs_parse_list(input)
    SV *input
  PREINIT:
    sfp_wrap w;
    AV *av;
    SV *ref;
  CODE:
    sfp_init(aTHX_ &w, input);

    av = newAV();
    ref = newRV_noinc((SV *)av);

    for (;;) {
      sfparse_value val;
      SV *item;
      int rv = sfp_top(&w, SFP_TOP_LIST, NULL, &val);

      if (rv == SFPARSE_ERR_EOF) {
        break;
      }

      if (rv != 0) {
        sfp_mark_failed(&w);
        SvREFCNT_dec(ref);
        Safefree(w.data);
        sfp_croak_parse(aTHX_ &w);
      }

      item = sfp_build_item(aTHX_ &w, &val);

      if (item == NULL) {
        sfp_mark_failed(&w);
        SvREFCNT_dec(ref);
        Safefree(w.data);
        sfp_croak_parse(aTHX_ &w);
      }

      av_push(av, item);
    }

    Safefree(w.data);

    RETVAL = ref;
  OUTPUT:
    RETVAL

SV *
sfp_xs_parse_dictionary(input)
    SV *input
  PREINIT:
    sfp_wrap w;
    AV *av;
    SV *ref;
  CODE:
    sfp_init(aTHX_ &w, input);

    av = newAV();
    ref = newRV_noinc((SV *)av);

    for (;;) {
      sfparse_vec key;
      sfparse_value val;
      SV *item;
      AV *pair;
      int rv = sfp_top(&w, SFP_TOP_DICT, &key, &val);

      if (rv == SFPARSE_ERR_EOF) {
        break;
      }

      if (rv != 0) {
        sfp_mark_failed(&w);
        SvREFCNT_dec(ref);
        Safefree(w.data);
        sfp_croak_parse(aTHX_ &w);
      }

      item = sfp_build_item(aTHX_ &w, &val);

      if (item == NULL) {
        sfp_mark_failed(&w);
        SvREFCNT_dec(ref);
        Safefree(w.data);
        sfp_croak_parse(aTHX_ &w);
      }

      pair = newAV();

      av_fill(pair, SFP_PAIR_WIDTH - 1);
      (void)av_store(pair, SFP_KEY, sfp_vec_sv(aTHX_ & key));
      (void)av_store(pair, SFP_ITEM, item);
      av_push(av, newRV_noinc((SV *)pair));
    }

    Safefree(w.data);

    RETVAL = ref;
  OUTPUT:
    RETVAL
