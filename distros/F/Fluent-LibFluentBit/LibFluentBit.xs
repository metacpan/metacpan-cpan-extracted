#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "PerlFluentBit.h"

#ifndef newSVivpv
static SV *PerlFluentBit_newSVivpv(pTHX_ IV ival, const char *pval) {
   SV *s= newSVpv(pval, 0);
   SvUPGRADE(s, SVt_PVIV);
   SvIV_set(s, ival);
   SvIOK_on(s);
   return s;
}
#  ifdef USE_ITHREADS
#  define newSVivpv(a,b) PerlFluentBit_newSVivpv(aTHX,a,b)
#  else
#  define newSVivpv PerlFluentBit_newSVivpv
#  endif
#endif

//#define TRACE warn
#define TRACE(x...) do { } while (0)

MODULE = Fluent::LibFluentBit              PACKAGE = Fluent::LibFluentBit

flb_ctx_t*
flb_create()

int
flb_service_set(ctx, ...)
   flb_ctx_t *ctx
   INIT:
      int i= 1;
      const char *k_str, *v_str;
	CODE:
      // final argmuent either must not exist or be undef
      if (items < i+2 || (((items-i) & 1) && SvOK(ST(items-i))))
         croak("Arguments must be even-length (key,value) list optionally followed by undef");
		while (i+1 < items) {
         k_str= SvPV_nolen(ST(i));
         v_str= SvPV_nolen(ST(i+1));
         TRACE("flb_service_set(%p, %s, %s, NULL)", ctx, k_str, v_str);
         if ((RETVAL= flb_service_set(ctx, k_str, v_str, NULL)) < 0)
            break;
         i+= 2;
      }
	OUTPUT:
		RETVAL

int
flb_input(ctx, name, data_sv=NULL)
   flb_ctx_t *ctx
   const char *name
   SV *data_sv
   INIT:
      void *data= data_sv && SvOK(data_sv)? (void*)SvIV(data_sv) : NULL;
   CODE:
      RETVAL= flb_input(ctx, name, data);
      TRACE("flb_input(%p, %s, %p) = %d", ctx, name, data, RETVAL);
   OUTPUT:
      RETVAL

int
flb_input_set(ctx, in_ffd, ...)
   flb_ctx_t *ctx
   int in_ffd
   INIT:
      int i= 2;
      const char *k_str, *v_str;
   CODE:
      // final argmuent either must not exist or be undef
      if (items < i+2 || (((items-i) & 1) && SvOK(ST(items-i))))
         croak("Arguments must be even-length (key,value) list optionally followed by undef");
		while (i+1 < items) {
         k_str= SvPV_nolen(ST(i));
         v_str= SvPV_nolen(ST(i+1));
         TRACE("flb_input_set(%p, %d, %s, %s, NULL)", ctx, in_ffd, k_str, v_str);
         if ((RETVAL= flb_input_set(ctx, in_ffd, k_str, v_str, NULL)) < 0)
            break;
         i+= 2;
      }
	OUTPUT:
		RETVAL

int
flb_filter(ctx, name, data_sv=NULL)
   flb_ctx_t *ctx
   const char *name
   SV *data_sv
   INIT:
      void *data= data_sv && SvOK(data_sv)? (void*)SvIV(data_sv) : NULL;
   CODE:
      RETVAL= flb_filter(ctx, name, data);
   OUTPUT:
      RETVAL

int
flb_filter_set(ctx, flt_ffd, ...)
   flb_ctx_t *ctx
   int flt_ffd
   INIT:
      int i= 2;
      const char *k_str, *v_str;
   CODE:
      // final argmuent either must not exist or be undef
      if (items < i+2 || (((items-i) & 1) && SvOK(ST(items-i))))
         croak("Arguments must be even-length (key,value) list optionally followed by undef");
		while (i+1 < items) {
         k_str= SvPV_nolen(ST(i));
         v_str= SvPV_nolen(ST(i+1));
         TRACE("flb_filter_set(%p, %d, %s, %s, NULL)", ctx, flt_ffd, k_str, v_str);
         if ((RETVAL= flb_filter_set(ctx, flt_ffd, k_str, v_str, NULL)) < 0)
            break;
         i+= 2;
      }
	OUTPUT:
		RETVAL

int
flb_output(ctx, name, data_sv=NULL)
   flb_ctx_t *ctx
   const char *name
   SV *data_sv
   INIT:
      void *data= data_sv && SvOK(data_sv)? (void*)SvIV(data_sv) : NULL;
   CODE:
      RETVAL= flb_output(ctx, name, data);
      TRACE("flb_output(%p, %s, %p)= %d", ctx, name, data, RETVAL);
   OUTPUT:
      RETVAL

int
flb_output_set(ctx, out_ffd, ...)
   flb_ctx_t *ctx
   int out_ffd
   INIT:
      int i= 2;
      const char *k_str, *v_str;
   CODE:
      // final argmuent either must not exist or be undef
      if (items < i+2 || (((items-i) & 1) && SvOK(ST(items-i))))
         croak("Arguments must be even-length (key,value) list optionally followed by undef");
		while (i+1 < items) {
         k_str= SvPV_nolen(ST(i));
         v_str= SvPV_nolen(ST(i+1));
         TRACE("flb_output_set(%p, %d, %s, %s, NULL)", ctx, out_ffd, k_str, v_str);
         if ((RETVAL= flb_output_set(ctx, out_ffd, k_str, v_str, NULL)) < 0)
            break;
         i+= 2;
      }
	OUTPUT:
		RETVAL

int
flb_start(ctx)
   flb_ctx_t *ctx

int
flb_stop(ctx)
   flb_ctx_t *ctx

void
flb_destroy(obj)
   SV *obj
   INIT:
      flb_ctx_t *ctx= PerlFluentBit_get_ctx_mg(obj);
   CODE:
      if (ctx) {
         flb_destroy(ctx);
         PerlFluentBit_set_ctx_mg(obj, NULL);
      }

int
flb_lib_push(ctx, in_ffd, data_sv, len_sv=NULL)
   flb_ctx_t *ctx
   int in_ffd
   SV *data_sv
   SV *len_sv
   INIT:
      size_t len;
      const char *data= SvPV(data_sv, len);
   CODE:
      TRACE("flb_lib_push %p %d %p %d data_sv=%p", ctx, in_ffd, data, len, data_sv);
      // Use the shorter of the user-supplied length or the actual string length
      if (len_sv && SvIV(len_sv) < len)
         len= SvIV(len_sv);
      RETVAL= flb_lib_push(ctx, in_ffd, data, len);
   OUTPUT:
      RETVAL

int
flb_lib_config_file(ctx, path)
   flb_ctx_t *ctx
   const char *path

BOOT:
  HV* stash= gv_stashpv("Fluent::LibFluentBit", GV_ADD);
  newCONSTSUB(stash, "FLB_LIB_ERROR", newSVivpv(FLB_LIB_ERROR, "FLB_LIB_ERROR"));
  newCONSTSUB(stash, "FLB_LIB_NONE", newSVivpv(FLB_LIB_NONE, "FLB_LIB_NONE"));
  newCONSTSUB(stash, "FLB_LIB_OK", newSVivpv(FLB_LIB_OK, "FLB_LIB_OK"));
  newCONSTSUB(stash, "FLB_LIB_NO_CONFIG_MAP", newSVivpv(FLB_LIB_NO_CONFIG_MAP, "FLB_LIB_NO_CONFIG_MAP"));
