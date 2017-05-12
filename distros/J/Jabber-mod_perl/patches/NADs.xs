/*

Jabber::mod_perl

-- mod_perl for jabberd --

Copyright (c) 2002, Piers Harding. All Rights Reserved.
This module is free software. It may be used, redistributed
and/or modified under the same terms as Perl itself.

*/

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

/* do this to make sure that the config.h of j2 is loaded first
   and not perls one */
#include "../config.h"
#include "util/util.h"


SV* my_nad_cache_new( ){

    SV* obj_ref = NULL;
    SV* obj = NULL;

    nad_cache_t nc = nad_cache_new();

    obj_ref = newSViv(0);
    obj = newSVrv(obj_ref, NULL);
    sv_setiv(obj, (IV) nc);
    SvREADONLY_on(obj);
    return obj_ref;

}


void my_nad_cache_free(SV* sv_nc){

    nad_cache_free(((nad_cache_t) SvIV(SvRV(sv_nc))));

}


SV* my_nad_nad_new(SV* sv_nc){

    SV* obj_ref = NULL;
    SV* obj = NULL;

    nad_t n = nad_new(((nad_cache_t) SvIV(SvRV(sv_nc))));

    obj_ref = newSViv(0);
    obj = newSVrv(obj_ref, NULL);
    sv_setiv(obj, (IV) n);
    sv_bless(obj_ref, gv_stashpv("Jabber::NADs", 0));
    SvREADONLY_on(obj);

    return obj_ref;

}


SV* my_nad_copy(SV* sv_n){

    SV* obj_ref = NULL;
    SV* obj = NULL;

    nad_t n = nad_copy(((nad_t) SvIV(SvRV(sv_n))));

    obj_ref = newSViv(0);
    obj = newSVrv(obj_ref, NULL);
    sv_setiv(obj, (IV) n);
    sv_bless(obj_ref, gv_stashpv("Jabber::NADs", 0));
    SvREADONLY_on(obj);

    return obj_ref;

}


void my_nad_wrap_elem(SV* sv_n, SV* sv_startelem, SV* sv_ns, SV* sv_name){

    if (SvIV(sv_startelem) < 0 )
						return;

    nad_wrap_elem(((nad_t) SvIV(SvRV(sv_n))),
                  SvIV(sv_startelem),
                  SvIV(sv_ns),
                  SvPV(sv_name, SvCUR(sv_name)));

}


SV* my_nad_insert_elem(SV* sv_n, SV* sv_startelem, SV* sv_ns, SV* sv_name, SV* sv_cdata){

    if (SvIV(sv_startelem) < 0 )
            return newSVsv(&PL_sv_undef);

    return newSViv( 
         nad_insert_elem( 
             ((nad_t) SvIV(SvRV(sv_n))),
             SvIV(sv_startelem),
             SvIV(sv_ns),
             SvPV(sv_name, SvCUR(sv_name)),
             SvPV(sv_cdata, SvCUR(sv_cdata))
         )
      );

}


SV* my_nad_append_elem(SV* sv_n, SV* sv_ns, SV* sv_name, SV* sv_depth){

    char *str;
    int len;

    return newSViv( nad_append_elem(((nad_t) SvIV(SvRV(sv_n))),
                    SvIV(sv_ns),
                    SvPV(sv_name, SvCUR(sv_name)),
                    SvIV(sv_depth)) );

}


SV* my_nad_print(SV* sv_n, SV* sv_depth){

    char *xml;
    int len;
    nad_print(((nad_t) SvIV(SvRV(sv_n))), SvIV(sv_depth), &xml, &len);
    return newSVpvn(xml,len);

}


void my_nad_write(SV* sv_n, SV* sv_c){

//    my_modperl_write_nad(sv_n, sv_c);
    //my_mod_perl_write_nad(((nad_t) SvIV(SvRV(sv_n))), ((conn_t) SvIV(SvRV(sv_c))));

}


void my_nad_free(SV* sv_n){

    nad_free(((nad_t) SvIV(SvRV(sv_n))));

}


SV* my_nad_find_elem(SV* sv_n, SV* sv_startelem, SV* sv_ns, SV* sv_name, SV* sv_depth){

    char *name = NULL;

    if (SvIV(sv_startelem) < 0 )
            return newSVsv(&PL_sv_undef);

    if (SvTRUE(sv_name))
        name = SvPV(sv_name, SvCUR(sv_name));
    //fprintf(stderr, "NAME: %s \n", name);
    //fprintf(stderr, "found at: %d \n",  nad_find_elem(((nad_t) SvIV(SvRV(sv_n))),
    //                2, 1,  "unsubscribe", 1) );
    return newSViv( nad_find_elem(((nad_t) SvIV(SvRV(sv_n))),
                    SvIV(sv_startelem),SvIV(sv_ns),  name, SvIV(sv_depth)) );

}


void my_nad_append_cdata(SV* sv_n, SV* sv_cdata, SV* sv_len, SV* sv_depth){

    nad_append_cdata(((nad_t) SvIV(SvRV(sv_n))),
                 SvPV(sv_cdata, SvCUR(sv_cdata)),
                 SvIV(sv_len),
                 SvIV(sv_depth));

}

/** this is the safety check used to make sure there's always enough mem */
#define NAD_SAFE(blocks, size, len) if((size) > len) len = _nad_realloc((void**)&(blocks),(size));

void my_nad_append_cdata_head(SV* sv_n, SV* sv_elem, SV* sv_cdata){

    if (SvIV(sv_elem) < 0 )
            return;

    nad_t nad = ((nad_t) SvIV(SvRV(sv_n)));
    int elem = SvIV(sv_elem);
    int len = SvCUR(sv_cdata);

/*        nad, current tot len + strlen to add, current block len */
		NAD_SAFE(nad->cdata, nad->ccur + len, nad->clen);

		// move other data down
		//   tgt, src, len
    int toset = nad->elems[elem].icdata + nad->elems[elem].lcdata + len;
		int soset = nad->elems[elem].icdata + nad->elems[elem].lcdata;
		int copy_len = nad->ccur - (nad->elems[elem].icdata + nad->elems[elem].lcdata);
		SV* sv_temp = newSVpv(nad->cdata+soset, copy_len);
    memcpy(nad->cdata+toset, SvPV(sv_temp, SvCUR(sv_temp)), copy_len);

		// increment overall length
		nad->ccur += len;

		// copy in new data
    memcpy(nad->cdata+(nad->elems[elem].icdata + nad->elems[elem].lcdata), SvPV(sv_cdata, SvCUR(sv_cdata)), len);

		// adjust pointers for all others after this one
		//    attrs, ns, elem

		// attributes
		int iattr, ins, ielem;
	  for(iattr=0;iattr < nad->acur;iattr++)
	  {
						if (nad->attrs[iattr].iname > nad->elems[elem].icdata)
							nad->attrs[iattr].iname += len;
						if (nad->attrs[iattr].ival >  nad->elems[elem].icdata)
						  nad->attrs[iattr].ival += len;
		}
		// namespaces
	  for(ins=0;ins < nad->ncur;ins++)
	  {
						// namespaces
						if (nad->nss[ins].iuri > nad->elems[elem].icdata)
							nad->nss[ins].iuri += len;
						// namespace prefixes
						if (nad->nss[ins].iprefix > nad->elems[elem].icdata)
							nad->nss[ins].iprefix += len;
		}
		// Elements
	  for(ielem=0;ielem < nad->ecur;ielem++)
	  {
						if (nad->elems[ielem].iname > nad->elems[elem].icdata)
							nad->elems[ielem].iname += len;
					  if (nad->elems[ielem].icdata > nad->elems[elem].icdata)
						  nad->elems[ielem].icdata += len;
						if (nad->elems[ielem].itail > nad->elems[elem].icdata)
							nad->elems[ielem].itail += len;
		}
		
		// adjust pointer + len for modified elem offender
    nad->elems[elem].lcdata += len;

		// reprint the nad so that the xml serialisation is inline
    char *xml;
    int xlen;
    nad_print(nad, 0, &xml, &xlen);

}

void my_nad_replace_cdata_head(SV* sv_n, SV* sv_elem, SV* sv_cdata){

    if (SvIV(sv_elem) < 0 )
            return;

    nad_t nad = ((nad_t) SvIV(SvRV(sv_n)));
    int elem = SvIV(sv_elem);
    int len = SvCUR(sv_cdata);

		// if len_diff < 0 then we have to reduce the overall length of cdata
		//    if not - then increase cdata by len_diff
    int len_diff = len  - nad->elems[elem].lcdata;


		if (len_diff > 0) {
/*        nad, current tot len + strlen to add, current block len */
		  NAD_SAFE(nad->cdata, nad->ccur + len_diff, nad->clen);
	  }

		// move other data down
		//   tgt, src, len
    int toset = nad->elems[elem].icdata + nad->elems[elem].lcdata + len_diff;
		int soset = nad->elems[elem].icdata + nad->elems[elem].lcdata;
		int copy_len = nad->ccur - (nad->elems[elem].icdata + nad->elems[elem].lcdata);
		SV* sv_temp = newSVpv(nad->cdata+soset, copy_len);
    memcpy(nad->cdata+toset, SvPV(sv_temp, SvCUR(sv_temp)), copy_len);

		// increment overall length
		nad->ccur += len_diff;

		// copy in new data
    memcpy(nad->cdata+nad->elems[elem].icdata, SvPV(sv_cdata, SvCUR(sv_cdata)), len);

		// adjust pointers for all others after this one
		//    attrs, ns, elem

		// attributes
		int iattr, ins, ielem;
	  for(iattr=0;iattr < nad->acur;iattr++)
	  {
						if (nad->attrs[iattr].iname > nad->elems[elem].icdata)
							nad->attrs[iattr].iname += len_diff;
						if (nad->attrs[iattr].ival >  nad->elems[elem].icdata)
						  nad->attrs[iattr].ival += len_diff;
		}
		// namespaces
	  for(ins=0;ins < nad->ncur;ins++)
	  {
						// namespaces
						if (nad->nss[ins].iuri > nad->elems[elem].icdata)
							nad->nss[ins].iuri += len_diff;
						// namespace prefixes
						if (nad->nss[ins].iprefix > nad->elems[elem].icdata)
							nad->nss[ins].iprefix += len_diff;
		}
		// Elements
	  for(ielem=0;ielem < nad->ecur;ielem++)
	  {
						if (nad->elems[ielem].iname > nad->elems[elem].icdata)
							nad->elems[ielem].iname += len_diff;
					  if (nad->elems[ielem].icdata > nad->elems[elem].icdata)
						  nad->elems[ielem].icdata += len_diff;
						if (nad->elems[ielem].itail > nad->elems[elem].icdata)
							nad->elems[ielem].itail += len_diff;
		}
		
		// adjust pointer + len for modified elem offender
    nad->elems[elem].lcdata += len_diff;

		// reprint the nad so that the xml serialisation is inline
    char *xml;
    int xlen;
    nad_print(nad, 0, &xml, &xlen);

}


void my_nad_append_cdata_tail(SV* sv_n, SV* sv_elem, SV* sv_cdata){

    if (SvIV(sv_elem) < 0 )
            return;

    nad_t nad = ((nad_t) SvIV(SvRV(sv_n)));
    int elem = SvIV(sv_elem);
    int len = SvCUR(sv_cdata);

/*        nad, current tot len + strlen to add, current block len */
		NAD_SAFE(nad->cdata, nad->ccur + len, nad->clen);

		// move other data down
		//   tgt, src, len
    int toset = nad->elems[elem].itail + nad->elems[elem].ltail + len;
		int soset = nad->elems[elem].itail + nad->elems[elem].ltail;
		int copy_len = nad->ccur - (nad->elems[elem].itail + nad->elems[elem].ltail);
		SV* sv_temp = newSVpv(nad->cdata+soset, copy_len);
    memcpy(nad->cdata+toset, SvPV(sv_temp, SvCUR(sv_temp)), copy_len);

		// increment overall length
		nad->ccur += len;

		// copy in new data
    memcpy(nad->cdata+(nad->elems[elem].itail + nad->elems[elem].ltail), SvPV(sv_cdata, SvCUR(sv_cdata)), len);

		// adjust pointers for all others after this one
		//    attrs, ns, elem

		// attributes
		int iattr, ins, ielem;
	  for(iattr=0;iattr < nad->acur;iattr++)
	  {
						if (nad->attrs[iattr].iname > nad->elems[elem].itail)
							nad->attrs[iattr].iname += len;
						if (nad->attrs[iattr].ival > nad->elems[elem].itail)
							nad->attrs[iattr].ival += len;
		}
		// namespaces
	  for(ins=0;ins < nad->ncur;ins++)
	  {
						// namespaces
						if (nad->nss[ins].iuri > nad->elems[elem].itail)
							nad->nss[ins].iuri += len;
						// namespace prefixes
						if (nad->nss[ins].iprefix > nad->elems[elem].itail)
							nad->nss[ins].iprefix += len;
		}
		// Elements
	  for(ielem=0;ielem < nad->ecur;ielem++)
	  {
						if (nad->elems[ielem].iname > nad->elems[elem].itail)
							nad->elems[ielem].iname += len;
						if (nad->elems[ielem].icdata >  nad->elems[elem].itail)
						  nad->elems[ielem].icdata += len;
						if (nad->elems[ielem].itail > nad->elems[elem].itail)
							nad->elems[ielem].itail += len;
		}
		
		// adjust pointer + len for modified elem offender
    nad->elems[elem].ltail += len;

		// reprint the nad so that the xml serialisation is inline
    char *xml;
    int xlen;
    nad_print(nad, 0, &xml, &xlen);

}


void my_nad_replace_cdata_tail(SV* sv_n, SV* sv_elem, SV* sv_cdata){

    if (SvIV(sv_elem) < 0 )
            return;

    nad_t nad = ((nad_t) SvIV(SvRV(sv_n)));
    int elem = SvIV(sv_elem);
    int len = SvCUR(sv_cdata);

		// if len_diff < 0 then we have to reduce the overall length of cdata
		//    if not - then increase cdata by len_diff
    int len_diff = len  - nad->elems[elem].lcdata;


		if (len_diff > 0) {
    /*        nad, current tot len + strlen to add, current block len */
		  NAD_SAFE(nad->cdata, nad->ccur + len_diff, nad->clen);
	  }


		// move other data down
		//   tgt, src, len
    int toset = nad->elems[elem].itail + nad->elems[elem].ltail + len_diff;
		int soset = nad->elems[elem].itail + nad->elems[elem].ltail;
		int copy_len = nad->ccur - (nad->elems[elem].itail + nad->elems[elem].ltail);
		SV* sv_temp = newSVpv(nad->cdata+soset, copy_len);
    memcpy(nad->cdata+toset, SvPV(sv_temp, SvCUR(sv_temp)), copy_len);

		// increment overall length
		nad->ccur += len_diff;

		// copy in new data
    memcpy(nad->cdata+nad->elems[elem].itail, SvPV(sv_cdata, SvCUR(sv_cdata)), len);

		// adjust pointers for all others after this one
		//    attrs, ns, elem

		// attributes
		int iattr, ins, ielem;
	  for(iattr=0;iattr < nad->acur;iattr++)
	  {
						if (nad->attrs[iattr].iname > nad->elems[elem].itail)
							nad->attrs[iattr].iname += len_diff;
						if (nad->attrs[iattr].ival > nad->elems[elem].itail)
							nad->attrs[iattr].ival += len_diff;
		}
		// namespaces
	  for(ins=0;ins < nad->ncur;ins++)
	  {
						// namespaces
						if (nad->nss[ins].iuri > nad->elems[elem].itail)
							nad->nss[ins].iuri += len_diff;
						// namespace prefixes
						if (nad->nss[ins].iprefix > nad->elems[elem].itail)
							nad->nss[ins].iprefix += len_diff;
		}
		// Elements
	  for(ielem=0;ielem < nad->ecur;ielem++)
	  {
						if (nad->elems[ielem].iname > nad->elems[elem].itail)
							nad->elems[ielem].iname += len_diff;
						if (nad->elems[ielem].icdata >  nad->elems[elem].itail)
						  nad->elems[ielem].icdata += len_diff;
						if (nad->elems[ielem].itail > nad->elems[elem].itail)
							nad->elems[ielem].itail += len_diff;
		}
		
		// adjust pointer + len for modified elem offender
    nad->elems[elem].ltail += len_diff;

		// reprint the nad so that the xml serialisation is inline
    char *xml;
    int xlen;
    nad_print(nad, 0, &xml, &xlen);

}


SV* my_nad_find_attr(SV* sv_n, SV* sv_startelem, SV* sv_ns, SV* sv_name, SV* sv_val){

    char *val = NULL;

    if (SvIV(sv_startelem) < 0 )
            return newSVsv(&PL_sv_undef);

    if (SvTRUE(sv_val))
        val = SvPV(sv_val, SvCUR(sv_val));
    return newSViv( nad_find_attr(((nad_t) SvIV(SvRV(sv_n))),
                    SvIV(sv_startelem), SvIV(sv_ns), SvPV(sv_name, SvCUR(sv_name)), val) );

}


SV* my_nad_get_attr(SV* sv_n, SV* sv_attr){

    return newSVpvn(NAD_AVAL(((nad_t) SvIV(SvRV(sv_n))), SvIV(sv_attr)),
                    NAD_AVAL_L(((nad_t) SvIV(SvRV(sv_n))), SvIV(sv_attr)));

}


void my_nad_set_attr(SV* sv_n, SV* sv_startelem, SV* sv_ns, SV* sv_name, SV* sv_val){

    if (SvIV(sv_startelem) < 0 )
            return;

    nad_set_attr(((nad_t) SvIV(SvRV(sv_n))),
                 SvIV(sv_startelem),
                 SvIV(sv_ns),
                 SvPV(sv_name, SvCUR(sv_name)),
                 SvPV(sv_val, SvCUR(sv_val)),
                 SvCUR(sv_val));

}


SV* my_nad_append_attr(SV* sv_n, SV* sv_ns, SV* sv_name, SV* sv_val){

    return newSViv( nad_append_attr(((nad_t) SvIV(SvRV(sv_n))),
                       SvIV(sv_ns),
                       SvPV(sv_name, SvCUR(sv_name)),
                       SvPV(sv_val, SvCUR(sv_val))) );

}


SV* my_nad_add_namespace(SV* sv_n, SV* sv_ns){

    return newSViv( nad_add_namespace(((nad_t) SvIV(SvRV(sv_n))),
                       SvPV(sv_ns, SvCUR(sv_ns)),
                       NULL
                       )
                    );

}


SV* my_nad_find_namespace(SV* sv_n, SV* sv_elem, SV* sv_uri, SV* sv_prefix){

    nad_t nad = ((nad_t) SvIV(SvRV(sv_n)));
    if ((SvIV(sv_elem) < 0) || (SvIV(sv_elem) >= nad->ecur ))
            return newSVsv(&PL_sv_undef);

		if (SvCUR(sv_prefix) == 0){
	    return newSViv( nad_find_namespace(nad,
  	                     SvIV(sv_elem),
    	                   SvPV(sv_uri, SvCUR(sv_uri)),
      	                 NULL )
        	            );
    } else {
	    return newSViv( nad_find_namespace(nad,
  	                     SvIV(sv_elem),
    	                   SvPV(sv_uri, SvCUR(sv_uri)),
      	                 SvPV(sv_prefix, SvCUR(sv_prefix)) )
        	            );
    }

}


SV* my_nad_find_scoped_namespace(SV* sv_n, SV* sv_uri, SV* sv_prefix){

		if (SvCUR(sv_uri) < 1)
      return newSVsv(&PL_sv_undef);

		if (SvCUR(sv_prefix) == 0){
    	return newSViv( nad_find_scoped_namespace(((nad_t) SvIV(SvRV(sv_n))),
      	                 SvPV(sv_uri, SvCUR(sv_uri)),
        	               NULL )
          	          );
    } else {
    	return newSViv( nad_find_scoped_namespace(((nad_t) SvIV(SvRV(sv_n))),
      	                 SvPV(sv_uri, SvCUR(sv_uri)),
        	               SvPV(sv_prefix, SvCUR(sv_prefix)) )
          	          );
		}

}


AV* my_nad_list_namespaces(SV* sv_n){

		// namespaces
		int ins;
    AV* array;
	  AV* nss = newAV();
    nad_t nad = ((nad_t) SvIV(SvRV(sv_n)));

	  for(ins=0;ins < nad->ncur;ins++)
	  {
						// namespaces
						av_push(nss, newRV_noinc( (SV*) ( array = newAV() ) ));
	          av_push(array, newSVpv(NAD_NURI(nad, ins), NAD_NURI_L(nad, ins)));
						if (nad->nss[ins].iprefix >= 0){
	            av_push(array, newSVpv(NAD_NPREFIX(nad, ins), NAD_NPREFIX_L(nad, ins)));
					  } else {
	            av_push(array, newSVsv(&PL_sv_undef));
						}
		}
    return nss;

}


SV* my_nad_nad_attr_name(SV* sv_n, SV* sv_attr){

    return newSVpvn( 
                     NAD_ANAME( ((nad_t) SvIV(SvRV(sv_n))), SvIV(sv_attr) ),
                     NAD_ANAME_L( ((nad_t) SvIV(SvRV(sv_n))), SvIV(sv_attr) )
                    );

}


SV* my_nad_nad_attr_val(SV* sv_n, SV* sv_attr){

    return newSVpvn( 
                     NAD_AVAL( ((nad_t) SvIV(SvRV(sv_n))), SvIV(sv_attr) ),
                     NAD_AVAL_L( ((nad_t) SvIV(SvRV(sv_n))), SvIV(sv_attr) )
                    );

}


SV* my_nad_nad_elem_name(SV* sv_n, SV* sv_elem){

    if (SvIV(sv_elem) < 0 )
            return newSVsv(&PL_sv_undef);

    return newSVpvn( 
                     NAD_ENAME( ((nad_t) SvIV(SvRV(sv_n))), SvIV(sv_elem) ),
                     NAD_ENAME_L( ((nad_t) SvIV(SvRV(sv_n))), SvIV(sv_elem) )
                    );

}


SV* my_nad_nad_cdata(SV* sv_n, SV* sv_elem){

    if (SvIV(sv_elem) < 0 )
            return newSVsv(&PL_sv_undef);

    return newSVpvn( 
                     NAD_CDATA( ((nad_t) SvIV(SvRV(sv_n))), SvIV(sv_elem) ),
                     NAD_CDATA_L( ((nad_t) SvIV(SvRV(sv_n))), SvIV(sv_elem) )
                    );

}


SV* my_nad_nad_uri(SV* sv_n, SV* sv_ns){

    return newSVpvn( 
                     NAD_NURI( ((nad_t) SvIV(SvRV(sv_n))), SvIV(sv_ns) ),
                     NAD_NURI_L( ((nad_t) SvIV(SvRV(sv_n))), SvIV(sv_ns) )
                    );

}


SV* my_nad_nad_uri_prefix(SV* sv_n, SV* sv_ns){

    return newSVpvn( 
                     NAD_NPREFIX( ((nad_t) SvIV(SvRV(sv_n))), SvIV(sv_ns) ),
                     NAD_NPREFIX_L( ((nad_t) SvIV(SvRV(sv_n))), SvIV(sv_ns) )
                    );

}


MODULE = Jabber::NADs	PACKAGE = Jabber::NADs	PREFIX = my_nad_

PROTOTYPES: DISABLE



SV *
my_nad_cache_new ( )

void
my_nad_cache_free (sv_nc)
	SV *	sv_nc

SV *
my_nad_nad_new (sv_nc)
	SV *	sv_nc

SV *
my_nad_copy (sv_n)
	SV *	sv_n

SV *
my_nad_insert_elem (sv_n, sv_startelem, sv_ns, sv_name, sv_cdata)
	SV *	sv_n
	SV *	sv_startelem
	SV *	sv_ns
	SV *	sv_name
	SV *	sv_cdata

void
my_nad_wrap_elem (sv_n, sv_startelem, sv_ns, sv_name)
	SV *	sv_n
	SV *	sv_startelem
	SV *	sv_ns
	SV *	sv_name

SV *
my_nad_append_elem (sv_n, sv_ns, sv_name, sv_depth)
	SV *	sv_n
	SV *	sv_ns
	SV *	sv_name
	SV *	sv_depth

SV *
my_nad_print (sv_n, sv_depth)
	SV *	sv_n
	SV *	sv_depth

void
my_nad_write (sv_n, sv_c)
	SV *	sv_n
	SV *	sv_c

void
my_nad_free (sv_n)
	SV *	sv_n

SV *
my_nad_find_elem (sv_n, sv_startelem, sv_ns, sv_name, sv_depth)
	SV *	sv_n
	SV *	sv_startelem
	SV *	sv_ns
	SV *	sv_name
	SV *	sv_depth

void
my_nad_append_cdata (sv_n, sv_cdata, sv_len, sv_depth)
	SV *	sv_n
	SV *	sv_cdata
	SV *	sv_len
	SV *	sv_depth

void
my_nad_append_cdata_head (sv_n, sv_elem, sv_cdata)
	SV *	sv_n
	SV *	sv_elem
	SV *	sv_cdata

void
my_nad_replace_cdata_head (sv_n, sv_elem, sv_cdata)
	SV *	sv_n
	SV *	sv_elem
	SV *	sv_cdata

void
my_nad_append_cdata_tail (sv_n, sv_elem, sv_cdata)
	SV *	sv_n
	SV *	sv_elem
	SV *	sv_cdata

void
my_nad_replace_cdata_tail (sv_n, sv_elem, sv_cdata)
	SV *	sv_n
	SV *	sv_elem
	SV *	sv_cdata

SV *
my_nad_find_attr (sv_n, sv_startelem, sv_ns, sv_name, sv_val)
	SV *	sv_n
	SV *	sv_startelem
	SV *	sv_ns
	SV *	sv_name
	SV *	sv_val

SV *
my_nad_get_attr (sv_n, sv_attr)
	SV *	sv_n
	SV *	sv_attr

void
my_nad_set_attr (sv_n, sv_startelem, sv_ns, sv_name, sv_val)
	SV *	sv_n
	SV *	sv_startelem
	SV *	sv_ns
	SV *	sv_name
	SV *	sv_val

SV *
my_nad_append_attr (sv_n, sv_ns, sv_name, sv_val)
	SV *	sv_n
	SV *	sv_ns
	SV *	sv_name
	SV *	sv_val

SV *
my_nad_add_namespace (sv_n, sv_ns)
	SV *	sv_n
	SV *	sv_ns

SV *
my_nad_find_namespace (sv_n, sv_elem, sv_uri, sv_prefix)
	SV *	sv_n
	SV *	sv_elem
	SV *	sv_uri
	SV *	sv_prefix

SV *
my_nad_find_scoped_namespace (sv_n, sv_uri, sv_prefix)
	SV *	sv_n
	SV *	sv_uri
	SV *	sv_prefix

AV *
my_nad_list_namespaces (sv_n)
	SV *	sv_n

SV *
my_nad_nad_attr_name (sv_n, sv_attr)
	SV *	sv_n
	SV *	sv_attr

SV *
my_nad_nad_attr_val (sv_n, sv_attr)
	SV *	sv_n
	SV *	sv_attr

SV *
my_nad_nad_elem_name (sv_n, sv_elem)
	SV *	sv_n
	SV *	sv_elem

SV *
my_nad_nad_cdata (sv_n, sv_elem)
	SV *	sv_n
	SV *	sv_elem

SV *
my_nad_nad_uri (sv_n, sv_ns)
	SV *	sv_n
	SV *	sv_ns

SV *
my_nad_nad_uri_prefix (sv_n, sv_ns)
	SV *	sv_n
	SV *	sv_ns

void
my_nad_find_children (sv_n, sv_elem)
	SV *	sv_n
	SV *	sv_elem
    INIT:
        int depth, el;
        nad_t nad;

    PPCODE:
        nad = ((nad_t) SvIV(SvRV(sv_n)));
        el = SvIV(sv_elem);
        // find the children of the given node = + 1
        if (el >= 0){
          depth = nad->elems[el].depth + 1;
          for(el = el + 1; el < nad->ecur; el++)
          {
             if (nad->elems[el].depth < depth)
                break;
             if (nad->elems[el].depth == depth){
               XPUSHs(sv_2mortal(newSViv(el)));
             }
          }
        }


void
my_nad_attrs (sv_n, sv_elem)
	SV *	sv_n
	SV *	sv_elem
    INIT:
        int attr, el;
        nad_t nad;

    PPCODE:
        nad = ((nad_t) SvIV(SvRV(sv_n)));
        el = SvIV(sv_elem);
        if (el >= 0 && el < nad->ecur){
          attr = nad->elems[el].attr;
          while (attr >= 0){
            XPUSHs(sv_2mortal(newSViv(attr)));
            attr = nad->attrs[attr].next;
          }
        }

