#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define NEED_newRV_noinc
#define NEED_sv_2pvbyte

#include "ppport.h"

#include <string.h>

#include <mba/diff.h>
#include <mba/diff.c>
#include <mba/varray.h>
#include <mba/varray.c>
#include <mba/allocator.h>
#include <mba/allocator.c>
#include <mba/msgno.c>
#include <mba/suba.h>
#include <mba/suba.c>

struct CTX {
    IV dummy;
};

inline
static IV lcs_DESTROY(SV *sv) 
{
        struct CTX *ctx = (struct CTX *)SvIVX(SvRV(sv));
        if (ctx == NULL)
            return 0;

        free(ctx);
        return 1;
}

inline
static SV *lcs_new(char *class)
{
        struct CTX *ctx = malloc(sizeof *ctx);
        struct LK *end;

        return sv_setref_pv(newSV(0),class,ctx);
}

inline
static int 
_cmp_str(const void *object1, const void *object2, void *context)
{
	return strcmp(object1, object2);
}

inline
static const void * 
_av_idx(const void *a, int idx, void *context)
{
    SV *line = *av_fetch((AV *)a, idx, 0);
    STRLEN klen;
    char *key = SvPVbyte(line, klen);

	return key;
}

inline
static int 
_cmp_idx(const void *a, int idx1, const void *b, int idx2, void *context)
{

    SV *s1 = *av_fetch((AV *)a, idx1, 0);
    STRLEN len1;
    char *key1 = SvPVbyte(s1, len1);

    SV *s2 = *av_fetch((AV *)b, idx2, 0);
    STRLEN len2;
    char *key2 = SvPVbyte(s2, len2);
    
    return strcmp(key1, key2);
}


MODULE = LCS::XS  PACKAGE = LCS::XS  PREFIX = lcs_
PROTOTYPES: DISABLED

SV *lcs_new(char *class)

IV lcs_DESTROY(SV *sv)

SV *
lcs_posindex(obj,a)
    SV *obj
    AV *a
                         
    PREINIT: 
      struct CTX *ctx = (struct CTX *)SvIVX(SvRV(obj));
      IV i;                       
      IV l;                                                          
    CODE:
      l = av_len(a);
      
      HV * pos_hash = newHV();

      for (i = 0; i <= l; ++i) {
            SV *line = *av_fetch(a, i, 0);
            STRLEN klen;
            char *key = SvPVbyte(line, klen);
            
            AV * matches;
            SV **lines = hv_fetch(pos_hash, key, klen, 0);
            if (lines != NULL) {
                matches = (AV *)SvRV(*lines);
            }
            else {
                matches = newAV();
                hv_store(pos_hash, key, klen, newRV_noinc((SV *)matches), 0); 
            }  
            av_push(matches, newSViv(i));  
      }

      RETVAL = (SV*)newRV_noinc((SV *)pos_hash);
    OUTPUT:
      RETVAL 

SV *
lcs_posbit(obj,a)
    SV *obj
    AV *a
                         
    PREINIT: 
      struct CTX *ctx = (struct CTX *)SvIVX(SvRV(obj));
      IV i;                       
      IV l;
      IV bits;                                                         
    CODE:
      l = av_len(a);
      
      HV * pos_hash = newHV();

      for (i = 0; i < l; ++i) {
            SV *line = *av_fetch(a, i, 0);
            STRLEN klen;
            char *key = SvPVbyte(line, klen);
            
            AV * matches;
            SV **lines = hv_fetch(pos_hash, key, klen, 0);
            if (lines != NULL) {
                matches = (AV *)SvRV(*lines);
                bits =  SvIVX(*av_fetch(matches, 0, 0));
                bits |= 1 << (i % 64);
                av_store(matches,0,newSViv(bits));                
            }
            else {
                matches = newAV();
                bits = 1 << (i % 64);
                av_store(matches,0,newSViv(bits));
                hv_store(pos_hash, key, klen, newRV_noinc((SV *)matches), 0); 
            }   
      }

      RETVAL = (SV*)newRV_noinc((SV *)pos_hash);
    OUTPUT:
      RETVAL 

void lcs_LCS(obj, s1, s2)
    SV *obj
    AV * s1
    AV * s2

    PREINIT:
        struct CTX *ctx = (struct CTX *)SvIVX(SvRV(obj));

    PPCODE:
        int d, sn, i;
        struct varray *ses = varray_new(sizeof(struct diff_edit), NULL);
  
        IV n;
        IV m;
        n = av_len(s1);
        m = av_len(s2);

        d = diff(s1, 0, n+1, s2, 0, m+1, &_cmp_idx,  NULL, 0, ses, &sn, NULL);

 
  int x,y,j;
  x=y=0;

  XSprePUSH;
  /*AV *av = newAV();*/

  for (i = 0; i < sn; i++) {
  	struct diff_edit *e = varray_get(ses, i);
  
  	switch (e->op) {
  		case DIFF_MATCH:
  		    /*printf("MAT: ");*/
  			/*printf("off %d len %d\n", e->off, e->len);*/
  		    for (j = 0; j < e->len; j++) {
  		      /*printf("x %d y %d\n", x, y);*/
  		      
  		      AV *arr;
              arr = newAV();
              av_push(arr, newSViv(x));
              av_push(arr, newSViv(y));
              /*av_push( av, (SV*)arr );*/
              XPUSHs(sv_2mortal(newRV_noinc((SV *)arr)));
                    
  			  x++;
  			  y++;
  			}
  			break;
  		case DIFF_DELETE:
  			/*printf("DEL: ");*/
  			/*printf("off %d len %d\n", e->off, e->len);*/
  			x += e->len;
  			break;
  		case DIFF_INSERT:
  			/*printf("INS: ");*/
  			/*printf("off %d len %d\n", e->off, e->len);*/
  			y += e->len;
  			break;
  	}
  }

                
                
  varray_del(ses);
  /*return newRV_noinc( (SV*)av );*/



void lcs_LCSs(obj, s1, s2)
    SV *obj
    SV * s1
    SV * s2

    PREINIT:
        struct CTX *ctx = (struct CTX *)SvIVX(SvRV(obj));

    PPCODE:
        int d, sn, i;
        struct varray *ses = varray_new(sizeof(struct diff_edit), NULL);

        STRLEN n;
        STRLEN m;
        char *a = SvPV (s1, n);
        char *b = SvPV (s2, m);
   
        d = diff(a, 0, n, b, 0, m, NULL, NULL, 0, ses, &sn, NULL);

 
  int x,y,j;
  x=y=0;

  XSprePUSH;

  for (i = 0; i < sn; i++) {
  	struct diff_edit *e = varray_get(ses, i);
  
  	switch (e->op) {
  		case DIFF_MATCH:
  		    /*printf("MAT: ");*/
  			/*printf("off %d len %d\n", e->off, e->len);*/
  		    for (j = 0; j < e->len; j++) {
  		      /*printf("x %d y %d\n", x, y);*/
  		      
  		      AV *arr;
              arr = newAV();
              av_push(arr, newSViv(x));
              av_push(arr, newSViv(y));
              XPUSHs(sv_2mortal(newRV_noinc((SV *)arr)));
                    
  			  x++;
  			  y++;
  			}
  			break;
  		case DIFF_DELETE:
  			/*printf("DEL: ");*/
  			/*printf("off %d len %d\n", e->off, e->len);*/
  			x += e->len;
  			break;
  		case DIFF_INSERT:
  			/*printf("INS: ");*/
  			/*printf("off %d len %d\n", e->off, e->len);*/
  			y += e->len;
  			break;
  	}
  }
                           
  varray_del(ses);



void lcs_cLCSs(obj, s1, s2)

    SV *obj
    SV * s1
    SV * s2

    PREINIT:
        struct CTX *ctx = (struct CTX *)SvIVX(SvRV(obj));

    PPCODE:
        int d, sn, i;
        struct varray *ses = varray_new(sizeof(struct diff_edit), NULL);

        STRLEN n;
        STRLEN m;
        char *a = SvPV (s1, n);
        char *b = SvPV (s2, m);
   
        d = diff(a, 0, n, b, 0, m, NULL, NULL, 0, ses, &sn, NULL);

 
  int x,y,j;
  x=y=0;

  XSprePUSH;

  for (i = 0; i < sn; i++) {
  	struct diff_edit *e = varray_get(ses, i);
  
  	switch (e->op) {
  		case DIFF_MATCH:
  		    /*printf("x %d y %d\n", x, y);*/
            if (1) {
  		      AV *arr;
  		      arr = newAV();
              av_push(arr, newSViv(x));
              av_push(arr, newSViv(y));
              av_push(arr, newSViv(e->len));
              XPUSHs(sv_2mortal(newRV_noinc((SV *)arr)));
  			  x += e->len;
  			  y += e->len;
  			}
  			break;
  		case DIFF_DELETE:
  			/*printf("DEL: ");*/
  			/*printf("off %d len %d\n", e->off, e->len);*/
  			x += e->len;
  			break;
  		case DIFF_INSERT:
  			/*printf("INS: ");*/
  			/*printf("off %d len %d\n", e->off, e->len);*/
  			y += e->len;
  			break;
  	}
  }
                           
  varray_del(ses);

