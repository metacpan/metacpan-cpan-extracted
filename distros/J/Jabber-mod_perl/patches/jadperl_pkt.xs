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


#include "jadperl.h"


/* create an error packet from an existing packet  */
SV* my_pkt_error(SV* sv_pkt, SV* sv_code, SV* sv_msg){

  pkt_t new_pkt;

  new_pkt =  pkt_error( ((pkt_t) SvIV(SvRV(sv_pkt))), SvIV(sv_code), SvPV(sv_msg, SvCUR(sv_msg)) );
  if (new_pkt == NULL){
    return newSVsv(&PL_sv_undef);
  } else {
    return 
         sv_bless(
           sv_setref_pv(newSViv(0), Nullch, (void *)new_pkt ),
           gv_stashpv("Jabber::pkt", 0)
         );
  }

}


/* swap a packet's to and from attributes */
SV* my_pkt_tofrom(SV* sv_pkt){

  pkt_t new_pkt;

  new_pkt =  pkt_tofrom( ((pkt_t) SvIV(SvRV(sv_pkt))) );
  if (new_pkt == NULL){
    return newSVsv(&PL_sv_undef);
  } else {
    return 
         sv_bless(
           sv_setref_pv(newSViv(0), Nullch, (void *)new_pkt ),
           gv_stashpv("Jabber::pkt", 0)
         );
  }

}

/* duplicate pkt, replacing addresses */
SV* my_pkt_dup(SV* sv_pkt, SV* sv_to, SV* sv_from){

  pkt_t new_pkt;

  new_pkt =  pkt_dup( ((pkt_t) SvIV(SvRV(sv_pkt))),
                      SvPV(sv_to, SvCUR(sv_to)),
                      SvPV(sv_from, SvCUR(sv_from)) );
  if (new_pkt == NULL){
    return newSVsv(&PL_sv_undef);
  } else {
    return 
         sv_bless(
           sv_setref_pv(newSViv(0), Nullch, (void *)new_pkt ),
           gv_stashpv("Jabber::pkt", 0)
         );
  }

}


/* reset a packet  */
SV* my_pkt_reset(SV* sv_pkt, SV* sv_elem){

  pkt_t new_pkt;

  new_pkt =  pkt_reset( ((pkt_t) SvIV(SvRV(sv_pkt))),
                      SvIV(sv_elem) );
  if (new_pkt == NULL){
    return newSVsv(&PL_sv_undef);
  } else {
    return 
         sv_bless(
           sv_setref_pv(newSViv(0), Nullch, (void *)new_pkt ),
           gv_stashpv("Jabber::pkt", 0)
         );
  }

}


/* create a new packet   */
SV* my_pkt_new(SV* sv_jp, SV* sv_nad, SV* sv_elem){

  pkt_t new_pkt;

  new_pkt =  pkt_new( ((jp_t) SvIV(SvRV(sv_jp))),
                      ((nad_t) SvIV(SvRV(sv_nad))),
                      SvIV(sv_elem) );
  if (new_pkt == NULL){
    return newSVsv(&PL_sv_undef);
  } else {
    return sv_setref_pv(newSViv(0), Nullch, (void *)new_pkt);
  }

}


/* free up the resources of a packet   */
void my_pkt_free(SV* sv_pkt){

  pkt_free( ((pkt_t) SvIV(SvRV(sv_pkt))) );

}


/* create a packet from scratch   */
SV* my_pkt_create(SV* sv_jp, SV* sv_elem, SV* sv_type, SV* sv_to, SV* sv_from){

  pkt_t new_pkt;

  new_pkt =  pkt_create( ((jp_t) SvIV(SvRV(sv_jp))),
                         SvPV(sv_elem, SvCUR(sv_elem)),
                         SvPV(sv_type, SvCUR(sv_type)),
                         SvPV(sv_to, SvCUR(sv_to)),
                         SvPV(sv_from, SvCUR(sv_from)) );
  if (new_pkt == NULL){
    return newSVsv(&PL_sv_undef);
  } else {
    return 
         sv_bless(
           sv_setref_pv(newSViv(0), Nullch, (void *)new_pkt ),
           gv_stashpv("Jabber::pkt", 0)
         );
  }

}


/* convenience - copy the packet id from src to dest */
void my_pkt_id(SV* sv_src, SV* sv_dest){

  pkt_id( ((pkt_t) SvIV(SvRV(sv_src))),
          ((pkt_t) SvIV(SvRV(sv_dest))) );

}


/* send a packet on its way   */
void  my_pkt_router(SV* sv_pkt){

  pkt_router( ((pkt_t) SvIV(SvRV(sv_pkt))) );

}


void my_pkt_sess(SV* sv_pkt, SV* sv_sess){

  // pkt_sess( ((pkt_t) SvIV(SvRV(sv_pkt))),
  //           ((sess_t) SvIV(SvRV(sv_sess))) );

}


/* extract the to address   */
SV* my_pkt_to(SV* sv_pkt){

  if (((pkt_t) SvIV(SvRV(sv_pkt)))->to != NULL){
      return newSVpv(jid_full(((pkt_t) SvIV(SvRV(sv_pkt)))->to), 0);
  } else {
    return newSVsv(&PL_sv_undef);
  }

}


/* extract the from address   */
SV* my_pkt_from(SV* sv_pkt){

  if (((pkt_t) SvIV(SvRV(sv_pkt)))->from != NULL){
      return newSVpv(jid_full(((pkt_t) SvIV(SvRV(sv_pkt)))->from), 0);
  } else {
    return newSVsv(&PL_sv_undef);
  }
}


/* extract the from address   */
SV* my_pkt_type(SV* sv_pkt){

  if (((pkt_t) SvIV(SvRV(sv_pkt)))->type & pkt_MESSAGE){
      return newSVpv("message", 0);
  } else if (((pkt_t) SvIV(SvRV(sv_pkt)))->type & pkt_PRESENCE){
      return newSVpv("presence", 0);
  } else if (((pkt_t) SvIV(SvRV(sv_pkt)))->type & pkt_IQ){
      return newSVpv("iq", 0);
  } else {
      return newSVpv("unknown", 0);
  }

}


/* extract the from address   */
SV* my_pkt_nad(SV* sv_pkt){

    return 
         sv_bless(
           sv_setref_pv(newSViv(0), Nullch,
              (void *)(((pkt_t) SvIV(SvRV(sv_pkt)))->nad) ),
           gv_stashpv("Jabber::NADs", 0)
         );

}


MODULE = Jabber::pkt	PACKAGE = Jabber::pkt	PREFIX = my_pkt_

PROTOTYPES: DISABLE


SV *
my_pkt_error (sv_pkt, sv_code, sv_msg)
	SV *	sv_pkt
	SV *	sv_code
	SV *	sv_msg

SV *
my_pkt_dup (sv_pkt, sv_to, sv_from)
	SV *	sv_pkt
	SV *	sv_to
	SV *	sv_from

SV *
my_pkt_reset (sv_pkt, sv_elem)
	SV *	sv_pkt
	SV *	sv_elem

SV *
my_pkt_new (sv_jp, sv_nad, sv_elem)
	SV *	sv_jp
	SV *	sv_nad
	SV *	sv_elem

void
my_pkt_free (sv_pkt)
	SV *	sv_pkt

SV *
my_pkt_create (sv_jp, sv_elem, sv_type, sv_to, sv_from)
	SV *	sv_jp
	SV *	sv_elem
	SV *	sv_type
	SV *	sv_to
	SV *	sv_from

void
my_pkt_id (sv_src, sv_dest)
	SV *	sv_src
	SV *	sv_dest

void
my_pkt_router (sv_pkt)
	SV *	sv_pkt

void
my_pkt_sess (sv_pkt, sv_sess)
	SV *	sv_pkt
	SV *	sv_sess

SV*
my_pkt_to (sv_pkt)
	SV *	sv_pkt

SV*
my_pkt_from (sv_pkt)
	SV *	sv_pkt

SV*
my_pkt_type (sv_pkt)
	SV *	sv_pkt

SV*
my_pkt_nad (sv_pkt)
	SV *	sv_pkt

