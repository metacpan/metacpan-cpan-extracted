#define PERL_CORE
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

/*
 * COPYRIGHT AND LICENCE
 *
 * Copyright (C) 2007,2008 WhitePages.com, Inc. with primary development by
 * Joshua ben Jore.
 *
 * This program is distributed WITHOUT ANY WARRANTY, including but not
 * limited to the implied warranties of merchantability or fitness for
 * a particular purpose.
 *
 * The program is free software.  You may distribute it and/or modify
 * it under the terms of the GNU General Public License as published
 * by the Free Software Foundation (either version 2 or any later
 * version) and the Perl Artistic License as published by O’Reilly
 * Media, Inc.  Please open the files named gpl-2.0.txt and Artistic
 * for a copy of these licenses.
 */


/*
 * Debugging diagnostics.
 */
#define DEBUG (!!EnbuggerDebugMode)
I32 EnbuggerDebugMode = 0;


/*
 * The ENBUGGER_DEBUG environment variable toggles debugging. It is
 * checked once during module loading.
 */
static void
set_debug_from_environment(pTHX)
{
  HV *env_hv;
  SV **svp;

  /* Fetch %ENV. */
  env_hv = get_hv("main::ENV",0);
  if ( ! env_hv ) {
    /* Does this ever happen? */
    Perl_croak(aTHX_ "Couldn't fetch %%ENV hash");
  }

  /* Fetch $ENV{ENBUGGER_DEBUG}. */
  svp = hv_fetch(env_hv,"ENBUGGER_DEBUG",0,0);
  if ( ! ( svp && *svp )) {
    EnbuggerDebugMode = 0;
    return;
  }
  
  EnbuggerDebugMode = SvTRUE( *svp );
}


/*
 * Set a nextstate/dbstate op's op_type and op_ppaddr.
 */
static void
alter_cop( pTHX_ SV *rv, I32 op_type )
{
  SV  *sv;
  COP *cop;


  /*
   * Validate that rv is a B::COP object and it has an IV to vetch.
   */
  if (!( sv_isobject(rv)
	 && sv_isa(rv, "B::COP")
	 && SvOK( sv = SvRV(rv) )
	 && SvIOK(sv) )) {
    if ( DEBUG ) {
      PerlIO_printf(Perl_debug_log, "Enbugger: SvOK(o)=%"UVuf" SvROK(o)=%"UVuf" SvIOK(SvRV(o))=%"UVuf"\n",
          SvOK(sv), SvROK(sv), SvIOK(SvRV(sv)));
    }
    Perl_croak(aTHX_ "Expecting a B::COP object");
  }


  /*
   * Change the type of the COP and the function pointer.
   *
   * TODO: stop hardcoding the values OP_DBSTATE and Perl_pp*. This
   * could be the result of a lookup function. It is allowed 
   */
  cop = INT2PTR( COP*, SvIV(sv) );
  cop->op_type = op_type;
  cop->op_ppaddr =
    op_type == OP_DBSTATE ? Perl_pp_dbstate : Perl_pp_nextstate;

  return;
}






/*
 * All future compilation will result in code without
 * breakpoints. This is typical for code that belongs to debuggers all
 * of which is ordinarily in the DB package.
 *
 * TODO: save off the old values. If the user ever wanted to change
 * these values outside of this module, we'd never know. We should.
 */
static void
compile_with_nextstate() {
  PL_ppaddr[OP_NEXTSTATE]
    = PL_ppaddr[OP_DBSTATE]
    = Perl_pp_nextstate;
}


/*
 * All future compilation will result in code with breakpoints.
 */
static void
compile_with_dbstate() {
  PL_ppaddr[OP_NEXTSTATE]
    = PL_ppaddr[OP_DBSTATE]
    = Perl_pp_dbstate;
}






MODULE = Enbugger PACKAGE = Enbugger PREFIX = Enbugger_

PROTOTYPES: DISABLE







=pod

Enable XS debugging.

=cut

void
Enbugger_debug( state )
        I32 state
    CODE:
        EnbuggerDebugMode = state;




=pod

Hooks or unhooks a given B::COP object.

=cut

void
Enbugger__nextstate_cop( o )
    SV * o
  CODE:
    alter_cop( aTHX_ o, OP_NEXTSTATE );

void
Enbugger__dbstate_cop( o )
    SV * o
  CODE:
    alter_cop( aTHX_ o, OP_DBSTATE );





=pod

From perl, state that future compilation will have or not have breakpoint dbstate ops.

=cut

void
Enbugger__compile_with_nextstate(class)
    SV *class
  CODE:
    compile_with_nextstate();

void
Enbugger__compile_with_dbstate(class)
    SV *class
  CODE:
    compile_with_dbstate();




=pod

A perl-available way to initialize various debugger variables like
PL_DBsub.

=cut

void
Enbugger_init_debugger( SV* class )
  CODE:
    if ( DEBUG ) {
      PerlIO_printf(Perl_debug_log,"Enbugger: Initializing debugger\n");
    }

    init_debugger();
    PL_perldb = PERLDB_ALL;




=pod

Sets RMAGIC on the %_<$filename hashes.

=cut

void
Enbugger_set_magic_dbfile(rv)
    SV *rv
  INIT:
    HV *hv;
  CODE:
    assert(SvROK(rv));

    hv = (HV*) SvRV(rv);
    assert(SVt_PVHV == SvTYPE(hv));
    hv_magic(hv, NULL, PERL_MAGIC_dbfile);




=pod

Sets up some things thatE<apos>ll be needed for debugging later on. These
may need to be moved into individual "off" and "on" functions so more
of the runtime is cleaned up after loading this module.

=cut

BOOT:
    set_debug_from_environment(aTHX);

    if ( PL_DBgv ) {
      if ( DEBUG ) {
        PerlIO_printf(Perl_debug_log,"Enbugger: Debugger is already loaded\n" );
      }
    }
    else {
      if ( DEBUG ) {
        PerlIO_printf(Perl_debug_log,"Enbugger: Initializing debugger during Enbugger boot\n");
      }
      
      /*
       * Copied right out ouf perl.c. I have no idea what this is used
       * for. I've got the idea that maybe something depends on this
       * so I'm including it for now or until I find out that I'm just
       * cargo-culting something inappropriate.
       */
      sv_setpvn(PERL_DEBUG_PAD(0), "", 0);  /* For regex debugging. */
      sv_setpvn(PERL_DEBUG_PAD(1), "", 0);  /* ext/re needs these */
      sv_setpvn(PERL_DEBUG_PAD(2), "", 0);  /* even without DEBUGGING */
      

      /*
       * It is *mandatory* to initialize the debugger before changing
       * PL_ppaddr. This is to avoid ever compiling code that uses
       * Perl_pp_dbstate without having the required PL_DBsingle, etc
       * variables
       *
       * This will need to be reinitialized again later when an actual
       * debugger is present.
       */
      init_debugger();
    }

MODULE = Enbugger PACKAGE = Enbugger::NYTProf PREFIX = Enbugger_NYTProf_

PROTOTYPES: DISABLE

void
Enbugger_NYTProf_instrument_op(... )
  INIT:
    SV *sv;
    OP *op;
    void *a;
    void *b;
  CODE:
    if (!( SvOK(ST(0))
           && SvROK(ST(0))
           && SvOK( sv = SvRV(ST(0)) )
           && SvIOK(sv) )) {
      return;
    }

    op = INT2PTR(OP*, SvIV(sv));
    if ( PL_ppaddr[op->op_type] != op->op_ppaddr ) {
      op->op_ppaddr = PL_ppaddr[op->op_type];
    }

MODULE = Enbugger PACKAGE = Enbugger PREFIX = Enbugger_

## Local Variables:
## mode: c
## mode: auto-fill
## End:
