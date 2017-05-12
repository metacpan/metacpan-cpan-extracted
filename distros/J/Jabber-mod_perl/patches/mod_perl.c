/*
 * Jabber::mod_perl - mod_perl for jabberd
 * Copyright (c) 2002 Piers Harding
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA02111-1307USA
 */

#include "mod_perl.h"

  static PerlInterpreter *my_perl;  /***    The Perl interpreter    ***/



/*----------------------------------------------------------------------------------*

  initialise all the perl handlers that will be used by mod_perl
  pass them the configuration nad, and the element number pointing
  to the <mod_perl/> configuration node

*-----------------------------------------------------------------------------------*/

void mod_perl_initialise(nad_t nad, mod_instance_t mi)
{

    int result;
    int el;
    SV* sv_rvalue;
    SV* sv_init_subroutine;
    dSP;

    // initial the argument stack
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);

    // push the NAD onto the stack
    XPUSHs(
       sv_2mortal(
	 sv_bless(
           sv_setref_pv(newSViv(0), Nullch, (void *)nad),
	   gv_stashpv("Jabber::NADs", 0)
	   )
	 )
       );

    // push the instance no. of this module in the chain on
    XPUSHs( sv_2mortal( newSViv(mi->seq) ) );

    // push the chain type that we are in on to the stack
    switch ( mi->chain )
    {
      case chain_SESS_START:
        XPUSHs( sv_2mortal( newSVpv("SESS_START", 0) ) );
	break;
      case chain_SESS_END:
        XPUSHs( sv_2mortal( newSVpv("SESS_END", 0) ) );
	break;
      case chain_IN_SESS:
        XPUSHs( sv_2mortal( newSVpv("IN_SESS", 0) ) );
	break;
      case chain_IN_ROUTER:
        XPUSHs( sv_2mortal( newSVpv("IN_ROUTER", 0) ) );
	break;
      case chain_OUT_SESS:
        XPUSHs( sv_2mortal( newSVpv("OUT_SESS", 0) ) );
	break;
      case chain_OUT_ROUTER:
        XPUSHs( sv_2mortal( newSVpv("OUT_ROUTER", 0) ) );
	break;
      case chain_PKT_SM:
        XPUSHs( sv_2mortal( newSVpv("PKT_SM", 0) ) );
	break;
      case chain_PKT_USER:
        XPUSHs( sv_2mortal( newSVpv("PKT_USER", 0) ) );
	break;
      case chain_PKT_ROUTER:
        XPUSHs( sv_2mortal( newSVpv("PKT_ROUTER", 0) ) );
	break;
    }

    // push the module instance args on
    XPUSHs( sv_2mortal( newSVpv(mi->arg, 0) ) );

    // hunt down the handlers and push them onto the stack
    //el = nad_find_elem(nad, 0, -1,  "mod_perl", 1);

    // give the element no. for mod_perl
    //XPUSHs(sv_2mortal(newSViv(el)));
    //log_debug(ZONE, "mod_perl config is at el: %d", el);

    // push the Perl handler module names onto the stack
    //el = nad_find_elem(nad, el, -1, "handler", 1);
    //while(el >= 0)
    //{
    //   XPUSHs(sv_2mortal(newSVpvn(NAD_CDATA(nad, el), NAD_CDATA_L(nad, el))));
    //  log_debug(ZONE, "mod_perl handler is at el: %d", el);
    //   el = nad_find_elem(nad, el, -1, "handler", 0);
    //}

    // stash away the stack pointer
    PUTBACK;

    // do the perl call
    sv_init_subroutine = newSVpv(mod_perl_method_init, PL_na);
    log_debug(ZONE, "mod_perl - mod_perl_init: Calling routine: %s", SvPV(sv_init_subroutine,PL_na));
    result = perl_call_sv(sv_init_subroutine, G_EVAL | G_DISCARD );

    // disassemble the call results
    log_debug(ZONE, "mod_perl - mod_perl_init: Called routine: %s results: %d", SvPV(sv_init_subroutine,PL_na), result);
    if(SvTRUE(ERRSV))
        log_debug(ZONE, "mod_perl - mod_perl_init: perl call errored: %s", SvPV(ERRSV,PL_na));
    SPAGAIN;
    if (result > 0){
      sv_rvalue = POPs;
        log_debug(ZONE, "mod_perl - mod_perl_init: after call (%s): %d - %s", SvPV(sv_init_subroutine,PL_na), result, SvPV(sv_rvalue,SvCUR(sv_rvalue)));
    }
    PUTBACK;
    FREETMPS;
    LEAVE;

}


/*----------------------------------------------------------------------------------*

  do the onPacket callback - push the pkt oject onto the argument stack
  and the user must pass back HANDLED or PASS to hand back to the session
  manager (sm)

*-----------------------------------------------------------------------------------*/
mod_ret_t mod_perl_onpacket(mod_instance_t mi, pkt_t pkt)
{

    int result;
    SV* sv_rvalue;
    mod_ret_t retr;
    dSP;

    log_debug(ZONE, "mod_perl - mod_perl_onpacket");

    // initialising the argument stack
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);

    // push the pkt onto the stack
    XPUSHs(
       sv_2mortal(
	 sv_bless(
           sv_setref_pv(newSViv(0), Nullch, (void *)pkt),
	   gv_stashpv("Jabber::pkt", 0)
	   )
	 )
       );

    // push the instance no. of this module in the chain on
    XPUSHs( sv_2mortal( newSViv(mi->seq) ) );

    // push the chain type that we are in on to the stack
    switch ( mi->chain )
    {
      case chain_SESS_START:
        XPUSHs( sv_2mortal( newSVpv("SESS_START", 0) ) );
      	break;
      case chain_SESS_END:
        XPUSHs( sv_2mortal( newSVpv("SESS_END", 0) ) );
      	break;
      case chain_IN_SESS:
        XPUSHs( sv_2mortal( newSVpv("IN_SESS", 0) ) );
      	break;
      case chain_IN_ROUTER:
        XPUSHs( sv_2mortal( newSVpv("IN_ROUTER", 0) ) );
      	break;
      case chain_OUT_SESS:
        XPUSHs( sv_2mortal( newSVpv("OUT_SESS", 0) ) );
      	break;
      case chain_OUT_ROUTER:
        XPUSHs( sv_2mortal( newSVpv("OUT_ROUTER", 0) ) );
      	break;
      case chain_PKT_SM:
        XPUSHs( sv_2mortal( newSVpv("PKT_SM", 0) ) );
      	break;
      case chain_PKT_USER:
        XPUSHs( sv_2mortal( newSVpv("PKT_USER", 0) ) );
      	break;
      case chain_PKT_ROUTER:
        XPUSHs( sv_2mortal( newSVpv("PKT_ROUTER", 0) ) );
      	break;
    }

    // push the module instance args on
    XPUSHs( sv_2mortal( newSVpv(mi->arg, 0) ) );

    // stash the stack point
    PUTBACK;

    // do the onPacket call
    log_debug(ZONE, "mod_perl - mod_perl_onpacket: Calling routine: %s",
		    SvPV(sv_on_packet_subroutine,PL_na));
    result = perl_call_sv(sv_on_packet_subroutine, G_EVAL | G_SCALAR );

    // disassemble the results off the argument stack
    log_debug(ZONE, "mod_perl - mod_perl_onpacket: Called routine: %s results: %d",
		    SvPV(sv_on_packet_subroutine,PL_na),
		    result);
    if(SvTRUE(ERRSV))
        log_debug(ZONE, "mod_perl - mod_perl_onpacket: perl call errored: %s",
		       	SvPV(ERRSV,PL_na));
    SPAGAIN;

    // was this handled or passed?
    if (result > 0){
      sv_rvalue = POPs;
        log_debug(ZONE, "mod_perl - mod_perl_onpacket: after call (%s): returns(%d) - code(%s)",
		       	SvPV(sv_on_packet_subroutine,PL_na),
		       	result,
		       	SvPV(sv_rvalue,SvCUR(sv_rvalue)));
	if (SvIV(sv_rvalue) == 1){
          //pkt_free( pkt );
          log_debug(ZONE, "mod_perl - mod_perl_onpacket: PACKET HANDLED ");
          retr = mod_HANDLED;
        } else if (SvIV(sv_rvalue) == 2){
          retr = mod_PASS;
        } else {
          log_debug(ZONE, "mod_perl - mod_perl_onpacket: PACKET PASSED ");
          retr = mod_PASS;
        }
    } else {
        log_debug(ZONE, "mod_perl - mod_perl_onpacket: after call (%s): %d - NO RETURN BAD ERROR",
		       	SvPV(sv_on_packet_subroutine,PL_na),
		       	result);
	retr = mod_PASS;
    }
    PUTBACK;
    FREETMPS;
    LEAVE;

    return retr;

}


/*----------------------------------------------------------------------------------*

  Run the perl evaluated code snippet - return the scalar value result

*-----------------------------------------------------------------------------------*/
SV* mod_perl_eval_pv(char *subroutine)
{

    SV* my_sv;
    log_debug(ZONE, "mod_perl Perl eval (PV): %s", subroutine);
    my_sv = eval_pv(subroutine, FALSE );
    if(SvTRUE(ERRSV)) {
        log_debug(ZONE, "mod_perl Perl eval error (PV): %s", SvPV(ERRSV,PL_na));
	//exit(0);
    } else {
        log_debug(ZONE, "mod_perl Perl eval successful (PV)");
        return my_sv;
    }

}


/*----------------------------------------------------------------------------------*

  Clean up the interpreter at the end of the process life

*-----------------------------------------------------------------------------------*/
void mod_perl_destroy()
{

    perl_destruct(my_perl);
    perl_free(my_perl);
    log_debug(ZONE, "mod_perl has been cleaned up");

}



/*----------------------------------------------------------------------------------*

  sm mod_perl subroutine reference - registered for handling packets that arrive from 
  active users

*-----------------------------------------------------------------------------------*/
static mod_ret_t _mod_perl_in_sess(mod_instance_t mi, sess_t sess, pkt_t pkt)
{
    /* we want messages addressed to /mod_perl */
    log_debug(ZONE, "mod_perl_in_sess %d ", pkt->type);

    /* only allow access to <message/> <presence/> and <iq/> packets */
    if (pkt->type & pkt_MESSAGE || pkt->type & pkt_PRESENCE || pkt->type & pkt_IQ)
    {
	if (pkt->from != NULL){
            log_debug(ZONE, "mod_perl_in_sess - PROCESSING request of %d from %s",
	        	       	pkt->type, jid_full(pkt->from));
        } else {
            log_debug(ZONE, "mod_perl_in_sess - PROCESSING request of %d", pkt->type);
        }
        return mod_perl_onpacket(mi, pkt);
    } else {
        return mod_PASS;
    }

}



/*----------------------------------------------------------------------------------*

  sm mod_perl subroutine reference - registered for handling packets that arrive from 
  active users XXX

*-----------------------------------------------------------------------------------*/
//  mod_ret_t           (*out_sess)(mod_instance_t mi, sess_t sess, pkt_t pkt); **< out-sess handler *
static mod_ret_t _mod_perl_out_sess(mod_instance_t mi, sess_t sess, pkt_t pkt)
{
    /* we want messages addressed to /mod_perl */
    log_debug(ZONE, "mod_perl_out_sess %d ", pkt->type);

    /* only allow access to <message/> <presence/> and <iq/> packets */
    if (pkt->type & pkt_MESSAGE || pkt->type & pkt_PRESENCE || pkt->type & pkt_IQ)
    {
	if (pkt->from != NULL){
            log_debug(ZONE, "mod_perl_out_sess - PROCESSING request of %d from %s",
	        	       	pkt->type, jid_full(pkt->from));
        } else {
            log_debug(ZONE, "mod_perl_out_sess - PROCESSING request of %d", pkt->type);
        }
        return mod_perl_onpacket(mi, pkt);
    } else {
        return mod_PASS;
    }

}



/*----------------------------------------------------------------------------------*

  sm mod_perl subroutine reference - registered for handling packets that arrive from 
  active users

*-----------------------------------------------------------------------------------*/
//  mod_ret_t           (*in_router)(mod_instance_t mi, pkt_t pkt);             **< in-router handler *
static mod_ret_t _mod_perl_in_router(mod_instance_t mi, pkt_t pkt)
{
    /* we want messages addressed to /mod_perl */
    log_debug(ZONE, "mod_perl_in_router %d ", pkt->type);

    /* only allow access to <message/> <presence/> and <iq/> packets */
    if (pkt->type & pkt_MESSAGE || pkt->type & pkt_PRESENCE || pkt->type & pkt_IQ)
    {
	if (pkt->from != NULL){
            log_debug(ZONE, "mod_perl_in_router - PROCESSING request of %d from %s",
	        	       	pkt->type, jid_full(pkt->from));
        } else {
            log_debug(ZONE, "mod_perl_in_router - PROCESSING request of %d", pkt->type);
        }
        return mod_perl_onpacket(mi, pkt);
    } else {
        return mod_PASS;
    }

}



/*----------------------------------------------------------------------------------*

  sm mod_perl subroutine reference - registered for handling packets that arrive from 
  active users XXX

*-----------------------------------------------------------------------------------*/
//  mod_ret_t           (*out_router)(mod_instance_t mi, pkt_t pkt);            **< out-router handler *
static mod_ret_t _mod_perl_out_router(mod_instance_t mi, pkt_t pkt)
{
    /* we want messages addressed to /mod_perl */
    log_debug(ZONE, "mod_perl_out_router %d ", pkt->type);

    /* only allow access to <message/> <presence/> and <iq/> packets */
    if (pkt->type & pkt_MESSAGE || pkt->type & pkt_PRESENCE || pkt->type & pkt_IQ)
    {
	if (pkt->from != NULL){
            log_debug(ZONE, "mod_perl_out_router - PROCESSING request of %d from %s",
	        	       	pkt->type, jid_full(pkt->from));
        } else {
            log_debug(ZONE, "mod_perl_out_router - PROCESSING request of %d", pkt->type);
        }
        return mod_perl_onpacket(mi, pkt);
    } else {
        return mod_PASS;
    }

}



/*----------------------------------------------------------------------------------*

  sm mod_perl subroutine reference - registered for handling packets that are
  addressed directly to the host

*-----------------------------------------------------------------------------------*/
//  mod_ret_t           (*pkt_sm)(mod_instance_t mi, pkt_t pkt);                 **< pkt-sm handler *
static mod_ret_t _mod_perl_pkt_sm(mod_instance_t mi, pkt_t pkt)
{
    /* we want messages addressed to /mod_perl */
    log_debug(ZONE, "mod_perl_pkt_sm - saw a packet from %s - %d ", jid_full(pkt->from), pkt->type);

    /* only allow access to <message/> <presence/> and <iq/> packets */
    if (pkt->type & pkt_MESSAGE || pkt->type & pkt_PRESENCE || pkt->type & pkt_IQ)
    {
        log_debug(ZONE, "mod_perl_pkt_sm - PROCESSING request of %d from %s",
		       	pkt->type, jid_full(pkt->from));
        return mod_perl_onpacket(mi, pkt);
    } else {
        return mod_PASS;
    }

}



/*----------------------------------------------------------------------------------*

  sm mod_perl subroutine reference - registered for handling packets from the router
  to the user

*-----------------------------------------------------------------------------------*/
//  mod_ret_t           (*pkt_user)(mod_instance_t mi, user_t user, pkt_t pkt);  **< pkt-user handler *
static mod_ret_t _mod_perl_pkt_user(mod_instance_t mi, user_t user, pkt_t pkt)
{
    /* we want messages addressed to /mod_perl */
    log_debug(ZONE, "mod_perl_pkt_user - saw a packet from %s - %d ", jid_full(pkt->from), pkt->type);

    /* only allow access to <message/> <presence/> and <iq/> packets */
    if (pkt->type & pkt_MESSAGE || pkt->type & pkt_PRESENCE || pkt->type & pkt_IQ)
    {
        log_debug(ZONE, "mod_perl_pkt_user - PROCESSING request of %d from %s",
		       	pkt->type, jid_full(pkt->from));
        return mod_perl_onpacket(mi, pkt);
    } else {
        return mod_PASS;
    }

}



/*----------------------------------------------------------------------------------*

  sm mod_perl subroutine reference - registered for handling packets from the router
  to the user

*-----------------------------------------------------------------------------------*/
//  mod_ret_t           (*pkt_router)(mod_instance_t mi, pkt_t pkt);             **< pkt-router handler *
static mod_ret_t _mod_perl_pkt_router(mod_instance_t mi, pkt_t pkt)
{
    /* we want messages addressed to /mod_perl */
    log_debug(ZONE, "mod_perl_pkt_router ");
    log_debug(ZONE, "mod_perl_pkt_router - saw a packet from %s - %d ", jid_full(pkt->from), pkt->type);

    /* only allow access to <message/> <presence/> and <iq/> packets */
    if (pkt->type & pkt_MESSAGE || pkt->type & pkt_PRESENCE || pkt->type & pkt_IQ)
    {
        log_debug(ZONE, "mod_perl_pkt_router - PROCESSING request of %d from %s",
		       	pkt->type, jid_full(pkt->from));
        return mod_perl_onpacket(mi, pkt);
    } else {
        return mod_PASS;
    }

}




/*----------------------------------------------------------------------------------*

  sm mod_perl initialisation routine

*-----------------------------------------------------------------------------------*/
int mod_perl_init(mod_instance_t mi, char *arg)
{

    module_t mod = mi->mod;
    log_debug(ZONE, "mod_perl_init - init");

    if (!mod->init){
        log_debug(ZONE, "mod_perl_init - first time - initilise interpreter");
        my_perl = perl_alloc();
        perl_construct( my_perl );
        perl_parse(my_perl, xs_init, MOD_PERL_NO_PARMS, embedding, NULL);
        perl_run(my_perl);
        mod_perl_eval_pv(use_mod_perl);

        // initialise the pure C Perl modules
        log_debug(ZONE, "mod_perl_init - first time - boot the Perl modules");
        //boot_Jabber__pkt(Nullcv);
        //boot_Jabber__NADs(Nullcv);
	      boot_Jabber__pkt(my_perl, Nullcv);
	      boot_Jabber__NADs(my_perl, Nullcv);

        // setup the sv of onpacket code - parse the callback
        sv_on_packet_subroutine = newSVpv(mod_perl_method_onpacket, PL_na);
        sv_setpv(sv_on_packet_subroutine, mod_perl_method_onpacket);

        /*
	 * stash a copy of the config nad
         * need to register config nad mod->mm->sm->config->nad
         * look here for the modules to load
         * and what to run as the init handler
         */
        mod_perl_config = nad_copy(mod->mm->sm->config->nad);

        log_debug(ZONE, "mod_perl_init - Perl interpreter has been initialised");
    }

    
    log_debug(ZONE, "mod_perl_init - initialise module instance: %s", arg);

    // only registered for these chains so far
    switch ( mi->chain )
    {
      case chain_SESS_START:
//        mod->sess_start = _mod_perl_sess_start;
	      break;
      case chain_SESS_END:
//        mod->sess_end = _mod_perl_sess_end;
	      break;
      case chain_IN_SESS:
        mod->in_sess = _mod_perl_in_sess;
	      break;
      case chain_IN_ROUTER:
        mod->in_router = _mod_perl_in_router;
	      break;
      case chain_OUT_SESS:
        mod->out_sess = _mod_perl_out_sess;
	      break;
      case chain_OUT_ROUTER:
        mod->out_router = _mod_perl_out_router;
      	break;
      case chain_PKT_SM:
        mod->pkt_sm = _mod_perl_pkt_sm;
      	break;
      case chain_PKT_USER:
        mod->pkt_user = _mod_perl_pkt_user;
      	break;
      case chain_PKT_ROUTER:
        mod->pkt_router = _mod_perl_pkt_router;
      	break;
      case chain_USER_LOAD:
//        mod->user_load = _mod_perl_user_load;
      	break;
      case chain_USER_CREATE:
//        mod->user_create = _mod_perl_user_create;
      	break;
      case chain_USER_DELETE:
//        mod->user_delete = _mod_perl_user_delete;
      	break;
    }

/*
  int                 (*sess_start)(mod_instance_t mi, sess_t sess);      **< sess-start handler *
  void                (*sess_end)(mod_instance_t mi, sess_t sess);        **< sess-end handler *

  mod_ret_t           (*in_sess)(mod_instance_t mi, sess_t sess, pkt_t pkt);  **< in-sess handler *
  mod_ret_t           (*in_router)(mod_instance_t mi, pkt_t pkt);             **< in-router handler *

  mod_ret_t           (*out_sess)(mod_instance_t mi, sess_t sess, pkt_t pkt); **< out-sess handler *
  mod_ret_t           (*out_router)(mod_instance_t mi, pkt_t pkt);            **< out-router handler *

  mod_ret_t           (*pkt_sm)(mod_instance_t mi, pkt_t pkt);                 **< pkt-sm handler *
  mod_ret_t           (*pkt_user)(mod_instance_t mi, user_t user, pkt_t pkt);  **< pkt-user handler *

  mod_ret_t           (*pkt_router)(mod_instance_t mi, pkt_t pkt);             **< pkt-router handler *

  int                 (*user_load)(mod_instance_t mi, user_t user);            **< user-load handler *

  int                 (*user_create)(mod_instance_t mi, jid_t jid);            **< user-create handler *
  void                (*user_delete)(mod_instance_t mi, jid_t jid);            **< user-delete handler *


*/


    mod_perl_initialise(mod_perl_config, mi);

    log_debug(ZONE, "mod_perl_init - mod_perl has been initialised");

    return 0;
}
