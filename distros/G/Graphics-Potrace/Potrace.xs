#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include "potracelib.h"

#define ASSERT_SCALAR(sv,message) \
   if (sv == NULL) { \
      warn(message, __LINE__); \
      goto CLEAN_AND_LEAVE; \
   }

SV *_make_point(const potrace_dpoint_t *p) {
   AV *point = newAV();
   av_push(point, newSVnv(p->x));
   av_push(point, newSVnv(p->y));
   return newRV_noinc((SV *)point);
}

SV *_make_pathnode(potrace_path_t *node) {
   HV *retval = newHV();
   AV *curve  = newAV();
   unsigned int i;
   int tag;
   potrace_dpoint_t *c = NULL;
   HV *segment = NULL;
   HV *first_segment = NULL;
   SV *last_endpoint = NULL;
   
   hv_store(retval, "area", 4, newSViv(node->area), FALSE);
   hv_store(retval, "sign", 4, newSVpvn((node->sign == '-' ? "-" : "+"), 1), FALSE);
   hv_store(retval, "curve", 5, newRV_noinc((SV *)curve), FALSE);
   
   for (i = 0; i < (node->curve).n; ++i) {
      tag = (node->curve).tag[i];
      c   = (node->curve).c[i];

      segment = newHV();
      if (first_segment == NULL)
         first_segment = segment;

      if (last_endpoint) {
         hv_store(segment, "begin", 5, last_endpoint, FALSE);
         last_endpoint = NULL;
      }

      hv_store(segment, "end", 3, _make_point(c+2), FALSE);
      last_endpoint = _make_point(c+2); /* "begin" of the next segment */

      if (tag == POTRACE_CORNER) {
         hv_store(segment, "type", 4, newSVpvn("corner", 6), FALSE);
         hv_store(segment, "corner", 6, _make_point(c+1), FALSE);
      }
      else if (tag == POTRACE_CURVETO) {
         hv_store(segment, "type", 4, newSVpvn("bezier", 6), FALSE);
         hv_store(segment, "u", 1, _make_point(c), FALSE);
         hv_store(segment, "w", 1, _make_point(c+1), FALSE);
      }
      else {
         warn("Unknown tag: %d", tag);
         hv_store(segment, "type", 4, newSVpvn("unknown", 7), FALSE);
         hv_store(segment, "tag", 3, newSViv(tag), FALSE);
         hv_store(segment, "p1", 2, _make_point(c), FALSE);
         hv_store(segment, "p2", 2, _make_point(c+1), FALSE);
      }
      av_push(curve, newRV_noinc((SV *)segment));
   }
   if (last_endpoint)
      hv_store(first_segment, "begin", 5, last_endpoint, FALSE);
   
   return newRV_noinc((SV *)retval);
}

SV *_make_listpath(potrace_path_t *plist) {
   AV *retval = newAV();
   SV *node = NULL;
   unsigned int n = 0;

   while (plist != NULL) {
      node = _make_pathnode(plist);
      av_push(retval, node);
      plist = plist->next;
   }

   return newRV_noinc((SV *)retval);
}

SV *_make_treepath(potrace_path_t *plist) {
   AV *retval = newAV();
   SV *node = NULL;
   unsigned int n = 0;

   while (plist != NULL) {
      node = _make_pathnode(plist);
      hv_store((HV*)SvRV(node), "children", 8, _make_treepath(plist->childlist), FALSE);
      av_push(retval, node);
      plist = plist->sibling;
   }

   return newRV_noinc((SV *)retval);
}

void _progress_callback (double progress, void *data) {
   dSP;
   HV *handler = (HV *) SvRV((SV*) data);

   ENTER;
   SAVETMPS;

   PUSHMARK(SP);
   if (hv_exists(handler, "data", 4))
      XPUSHs(*hv_fetch(handler, "data", 4, FALSE));

   PUTBACK;

   call_sv(*hv_fetch(handler, "callback", 8, FALSE), G_DISCARD);

   FREETMPS;
   LEAVE;
}

int _set_progress (potrace_progress_t *target, SV *input) {
   SV *callback = input;
   HV *hash = NULL;
   SV *data = NULL;
   HV *handler = newHV();

   target->callback = _progress_callback;
   target->data = (void *) handler;

   if (SvTYPE(input) == SVt_PVHV) {
      hash = (HV *) SvRV(input);
      if (! hv_exists(hash, "callback", 8)) {
         warn("no callback set!");
         goto CLEAN_AND_LEAVE;
      }

      callback = *hv_fetch(hash, "callback", 8, FALSE);

      if (hv_exists(hash, "data", 4)) {
         data = *hv_fetch(hash, "data", 4, FALSE);
         SvREFCNT_inc(data);
         hv_store(handler, "data", 4, data, FALSE);
      }
   }
   else if (SvTYPE(input) != SVt_PVCV) {
      warn("invalid callback, pass either a sub reference or a hash");
      goto CLEAN_AND_LEAVE;
   }

   SvREFCNT_inc(callback);
   hv_store(handler, "callback", 8, callback, FALSE);

   return 1;

CLEAN_AND_LEAVE:
   if (handler != NULL) SvREFCNT_dec((SV *) handler);
   return 0;
}


int _fill_param(potrace_param_t *_struct_, HV *value_for) {
   int retval = 0;

   #define CHECK_AND_SET_IV(name) \
   if (hv_exists(value_for, #name, 0)) { \
      _struct_->name = SvIV(*hv_fetch(value_for, #name, strlen(#name), 0)); \
   }
#define CHECK_AND_SET_NV(name) \
   if (hv_exists(value_for, #name, 0)) { \
      _struct_->name = SvNV(*hv_fetch(value_for, #name, strlen(#name), 0)); \
   }

   CHECK_AND_SET_IV(turdsize);
   CHECK_AND_SET_IV(turnpolicy);
   CHECK_AND_SET_IV(opticurve);
   CHECK_AND_SET_NV(alphamax);
   CHECK_AND_SET_NV(opttolerance);

#undef CHECK_AND_SET_IV
#undef CHECK_AND_SET_NV

   if (hv_exists(value_for, "progress", 8)) {
      return _set_progress(&(_struct_->progress),
            *hv_fetch(value_for, "progress", 8, FALSE)); 
   }
   return 1;
}

void _fill_bitmap(potrace_bitmap_t *bm, HV *value_for) {
   int mapsize;

   bm->w = SvIV(*hv_fetch(value_for, "width", 5, FALSE));
   bm->h = SvIV(*hv_fetch(value_for, "height", 6, FALSE));
   bm->dy = SvIV(*hv_fetch(value_for, "dy", 2, FALSE));

   mapsize = bm->dy * bm->h;
   if (mapsize < 0) mapsize = -mapsize;
   Newx(bm->map, mapsize, potrace_word);
   Copy(SvPVX(*hv_fetch(value_for, "map", 3, FALSE)), bm->map, mapsize, potrace_word);
}

SV *_trace (HV *parameters, HV *bitmap) {
   potrace_param_t  *param = NULL;
   potrace_bitmap_t bm;
   potrace_state_t  *state = NULL;
   HV *retvalHV = NULL;
   SV *retval = NULL;
   bm.map = NULL;

   ASSERT_SCALAR((param = potrace_param_default()),
      "potrace_param_default() failed at %d");
   if (! _fill_param(param, parameters))
      goto CLEAN_AND_LEAVE;

   _fill_bitmap(&bm, bitmap);

   ASSERT_SCALAR((state = potrace_trace(param, &bm)),
      "potrace_trace() failed at %d");
   if (state->status != POTRACE_STATUS_OK) {
      warn("potrace_trace() call unsuccessful");
      goto CLEAN_AND_LEAVE;
   }

   retvalHV = newHV();
   hv_store(retvalHV, "list", 4, _make_listpath(state->plist), FALSE);
   hv_store(retvalHV, "tree", 4, _make_treepath(state->plist), FALSE);
   hv_store(retvalHV, "width", 5, newSVsv(*hv_fetch(bitmap, "width", 5, FALSE)), FALSE);
   hv_store(retvalHV, "height", 6, newSVsv(*hv_fetch(bitmap, "height", 6, FALSE)), FALSE);
   retval = newRV_noinc((SV *)retvalHV);
   retvalHV = NULL;

CLEAN_AND_LEAVE:
   if (retvalHV) SvREFCNT_dec((SV *)retvalHV);
   if (param) potrace_param_free(param);
   if (bm.map) Safefree(bm.map);

   if (retval == NULL)
      retval = newSV(0);
   return retval;
}



MODULE = Graphics::Potrace::Bitmap	PACKAGE = Graphics::Potrace::Bitmap	PREFIX = gpb_
PROTOTYPES: DISABLE

SV *
gpb__trace (self, param, bitmap)
   SV *self
   SV *param
   SV *bitmap
   CODE:
      RETVAL = _trace((HV *)SvRV(param), (HV *)SvRV(bitmap));
   OUTPUT:
      RETVAL


MODULE = Graphics::Potrace	PACKAGE = Graphics::Potrace	PREFIX = gp_

char *
gp_version()
   CODE:
      RETVAL = potrace_version();
   OUTPUT:
      RETVAL

SV *
gp__trace(param, bitmap)
   SV *param
   SV *bitmap
   CODE:
      RETVAL = _trace((HV *)SvRV(param), (HV *)SvRV(bitmap));
   OUTPUT:
      RETVAL
