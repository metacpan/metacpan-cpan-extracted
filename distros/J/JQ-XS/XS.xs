#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <jq.h>
#include <jv.h>

/* Error callback context to capture compilation errors */
typedef struct {
  SV *buffer;
} ErrorContext;

/* The C struct wrapped as the JQ::XS object via T_PTROBJ */
typedef struct {
  jq_state *state;
  SV       *program;
} jq_xs_t;
typedef jq_xs_t *JQ__XS;   /* XS type "JQ::XS" -> C type "JQ__XS", blessed class "JQ::XS" */

/* Forward declaration of conversion functions - need pTHX for Perl context */
static SV *jv_to_sv(pTHX_ jv);
static jv sv_to_jv(pTHX_ SV *);

/* Error callback for jq_set_error_cb */
static void error_callback(void *user_data, jv msg) {
  dTHX;
  ErrorContext *ctx = (ErrorContext *)user_data;
  if (ctx && ctx->buffer && jv_is_valid(msg)) {
    jv err_text = jq_format_error(msg);
    if (jv_is_valid(err_text)) {
      const char *text = jv_string_value(err_text);
      if (text) {
        sv_catpv(ctx->buffer, text);
        sv_catpv(ctx->buffer, "\n");
      }
      jv_free(err_text);
    }
  } else {
    jv_free(msg);
  }
}

/* Convert jv to SV - handles all jv types */
static SV *jv_to_sv(pTHX_ jv v) {
  jv_kind kind = jv_get_kind(v);
  SV *result = NULL;

  switch (kind) {
    case JV_KIND_NULL:
      result = newSV(0);
      break;

    case JV_KIND_FALSE:
      result = newSV(0);
      sv_setref_iv(result, "JSON::PP::Boolean", 0);
      break;

    case JV_KIND_TRUE:
      result = newSV(0);
      sv_setref_iv(result, "JSON::PP::Boolean", 1);
      break;

    case JV_KIND_NUMBER:
      if (jv_is_integer(v)) {
        double d = jv_number_value(v);
        if (d >= IV_MIN && d <= IV_MAX) {
          result = newSViv((IV)d);
        } else {
          result = newSVnv(d);
        }
      } else {
        result = newSVnv(jv_number_value(v));
      }
      break;

    case JV_KIND_STRING: {
      jv copy = jv_copy(v);
      int len = jv_string_length_bytes(copy);
      const char *str = jv_string_value(v);
      result = newSVpvn(str, len);
      SvUTF8_on(result);
      break;
    }

    case JV_KIND_ARRAY: {
      AV *av = newAV();
      jv_array_foreach(v, i, item) {
        SV *item_sv = jv_to_sv(aTHX_ item);
        av_push(av, item_sv);
      }
      result = newRV_noinc((SV *)av);
      break;
    }

    case JV_KIND_OBJECT: {
      HV *hv = newHV();
      jv_object_foreach(v, key, val) {
        SV *key_sv = jv_to_sv(aTHX_ key);
        SV *val_sv = jv_to_sv(aTHX_ val);
        hv_store_ent(hv, key_sv, val_sv, 0);
        SvREFCNT_dec(key_sv);
      }
      result = newRV_noinc((SV *)hv);
      break;
    }

    case JV_KIND_INVALID:
    default:
      result = newSV(0);
      break;
  }

  jv_free(v);
  return result;
}

/* Convert SV to jv - handles all Perl types */
static jv sv_to_jv(pTHX_ SV *sv) {
  /* Perl's native boolean SVs: the immortals returned by comparison and
   * logical operators. On perl < 5.36 a copy of one is indistinguishable
   * from an ordinary dualvar, so only identity can be checked. */
  if (sv == &PL_sv_yes) return jv_true();
  if (sv == &PL_sv_no)  return jv_false();
#ifdef SvIsBOOL
  /* perl >= 5.36: copies keep their boolean flag (builtin::true/false) */
  if (SvIsBOOL(sv)) return SvTRUE(sv) ? jv_true() : jv_false();
#endif

  if (!SvOK(sv)) {
    return jv_null();
  }

  if (SvROK(sv)) {
    SV *ref = SvRV(sv);

    /* Blessed booleans: JSON::PP::Boolean and friends */
    if (SvOBJECT(ref)) {
      if (sv_derived_from(sv, "JSON::PP::Boolean")
          || sv_derived_from(sv, "Types::Serialiser::Boolean")
          || sv_derived_from(sv, "boolean")) {
        return SvTRUE(ref) ? jv_true() : jv_false();
      }
    }

    /* Array reference */
    if (SvTYPE(ref) == SVt_PVAV) {
      AV *av = (AV *)ref;
      jv arr = jv_array();
      I32 len = av_len(av) + 1;
      for (I32 i = 0; i < len; i++) {
        SV **item = av_fetch(av, i, 0);
        if (item) {
          arr = jv_array_append(arr, sv_to_jv(aTHX_ *item));
        } else {
          arr = jv_array_append(arr, jv_null());
        }
      }
      return arr;
    }

    /* Hash reference */
    if (SvTYPE(ref) == SVt_PVHV) {
      HV *hv = (HV *)ref;
      jv obj = jv_object();
      HE *he;
      hv_iterinit(hv);
      while ((he = hv_iternext(hv)) != NULL) {
        SV *key_sv = HeSVKEY(he);
        if (!key_sv) {
          key_sv = hv_iterkeysv(he);
        }
        SV *val_sv = HeVAL(he);
        char *key_str = SvPVutf8_nolen(key_sv);
        jv key = jv_string(key_str);
        jv val = sv_to_jv(aTHX_ val_sv);
        obj = jv_object_set(obj, key, val);
      }
      return obj;
    }

    /* Unblessed reference to a plain scalar: \1 is true, \0 is false */
    if (SvTYPE(ref) < SVt_PVAV) {
      return SvTRUE(ref) ? jv_true() : jv_false();
    }
  }

  /* Check numeric type first */
  if (SvIOK(sv) && !SvPOK(sv)) {
    return jv_number((double)SvIV(sv));
  }
  if (SvNOK(sv) && !SvPOK(sv)) {
    return jv_number(SvNV(sv));
  }

  /* Everything else is a string */
  STRLEN len;
  char *str = SvPVutf8(sv, len);
  return jv_string_sized(str, len);
}

MODULE = JQ::XS		PACKAGE = JQ::XS

JQ::XS
new(SV *klass, SV *program_sv = &PL_sv_undef)
  PREINIT:
    jq_xs_t *self;
    ErrorContext ctx;
    const char *prog;
  CODE:
    PERL_UNUSED_VAR(klass);
    if (!SvOK(program_sv)) {
      croak("program argument required");
    }
    prog = SvPV_nolen(program_sv);

    Newxz(self, 1, jq_xs_t);
    self->state = jq_init();
    if (!self->state) {
      Safefree(self);
      croak("jq_init failed");
    }
    self->program = newSVsv(program_sv);

    ctx.buffer = sv_2mortal(newSVpv("", 0));
    jq_set_error_cb(self->state, error_callback, &ctx);

    jq_compile(self->state, prog);

    jq_set_error_cb(self->state, NULL, NULL);

    if (SvCUR(ctx.buffer) > 0) {
      jq_teardown(&self->state);
      SvREFCNT_dec(self->program);
      Safefree(self);
      croak("jq compile error: %s", SvPV_nolen(ctx.buffer));
    }
    RETVAL = self;
  OUTPUT:
    RETVAL

SV *
program(JQ::XS self)
  CODE:
    RETVAL = newSVsv(self->program);
  OUTPUT:
    RETVAL

AV *
_xs_process(JQ::XS self, SV *input_sv, int as_json)
  PREINIT:
    jv input;
    jv res;
    AV *results;
    SV *output_sv;
  CODE:
    /* Parse/convert input */
    if (as_json) {
      STRLEN len;
      const char *json_str = SvPVutf8(input_sv, len);
      input = jv_parse_sized(json_str, len);
      if (!jv_is_valid(input)) {
        jv err_msg = jv_invalid_get_msg(input);
        SV *errsv;
        if (jv_get_kind(err_msg) == JV_KIND_STRING) {
          errsv = sv_2mortal(newSVpv(jv_string_value(err_msg), 0));
        } else {
          errsv = sv_2mortal(newSVpv("unknown parse error", 0));
        }
        jv_free(err_msg);
        croak("Invalid JSON: %s", SvPV_nolen(errsv));
      }
    } else {
      input = sv_to_jv(aTHX_ input_sv);
    }

    /* Run jq filter */
    jq_start(self->state, input, 0);

    /* Collect results */
    results = newAV();
    sv_2mortal((SV *)results);
    while (jv_is_valid(res = jq_next(self->state))) {
      if (as_json) {
        jv json_str_jv = jv_dump_string(res, 0);
        const char *json_str = jv_string_value(json_str_jv);
        output_sv = newSVpv(json_str, 0);
        SvUTF8_on(output_sv);
        av_push(results, output_sv);
        jv_free(json_str_jv);
      } else {
        output_sv = jv_to_sv(aTHX_ res);
        av_push(results, output_sv);
      }
    }

    /* Check for errors in the result stream */
    if (!jv_is_valid(res)) {
      if (jv_invalid_has_msg(jv_copy(res))) {
        jv err_msg = jv_invalid_get_msg(res);
        jv err_text_jv = jq_format_error(err_msg);
        SV *errsv;
        if (jv_get_kind(err_text_jv) == JV_KIND_STRING) {
          errsv = sv_2mortal(newSVpv(jv_string_value(err_text_jv), 0));
        } else {
          errsv = sv_2mortal(newSVpv("unknown runtime error", 0));
        }
        jv_free(err_text_jv);
        croak("jq runtime error: %s", SvPV_nolen(errsv));
      }
      jv_free(res);
    }

    RETVAL = results;
  OUTPUT:
    RETVAL

void
DESTROY(JQ::XS self)
  CODE:
    if (self) {
      if (self->state) {
        jq_teardown(&self->state);
      }
      SvREFCNT_dec(self->program);
      Safefree(self);
    }
