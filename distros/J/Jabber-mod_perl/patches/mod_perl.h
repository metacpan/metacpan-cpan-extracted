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

/*   Declare up the perl stuff    */
#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>

/* do this to make sure that the config.h of j2 is loaded first
   and not perls one */
#include "../config.h"
#include "sm.h"


// create my true and false
#ifndef false
typedef enum { false, true } mybool;
#endif

// fake up a definition of bool if it doesnt exist
#ifndef bool
typedef unsigned char    bool;
#endif

// no. of parms pased to interpreter initialisation
#define MOD_PERL_NO_PARMS 4

// only declared here so that compiling mod_perl doesnt complain - the 
// real business is happening in perlxsi.c
EXTERN_C void xs_init (pTHXo);

static PerlInterpreter *my_perl;

char* mod_perl_realname;
char* mod_perl_method_init = "Jabber::mod_perl::initialise";
char* mod_perl_method_onpacket = "Jabber::mod_perl::onPacket";
SV* sv_on_packet_subroutine = (SV*)NULL;
nad_t mod_perl_config;

char *embedding[] = { "", "-e", "1" };
char* use_mod_perl = "use Jabber::Reload; use Jabber::mod_perl;";


// must define these subroutines here to avoid including perl.h into 
void mod_perl_initialise(nad_t nad, mod_instance_t mi);
void mod_perl_run();
mod_ret_t mod_perl_onpacket(mod_instance_t mi, pkt_t pkt);
void my_modperl_write_nad(nad_t n);
char* mod_perl_callback(char *subroutine, char *parm1, char *parm2, char *parm3, char *parm4);
void mod_perl_destroy();
SV* mod_perl_eval_pv(char *subroutine);
void mod_perl_eval_sv(SV* subroutine);

// special function definitions for booting C Perl modules
XS(boot_Jabber__pkt);
XS(boot_Jabber__NADs);


/*----------------------------------------------------------------------------------*

  code generated from /usr/bin/perl -MExtUtils::Embed -e xsinit -- -std -o perlxsi.c
  to facilitate the loading of other modules with C extensions - this gives:

EXTERN_C void boot_DynaLoader (pTHXo_ CV* cv);

EXTERN_C void
xs_init(pTHXo);

*-----------------------------------------------------------------------------------*/

