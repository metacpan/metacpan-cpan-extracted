#include <EXTERN.h>
#include <perl.h>
#include "runops.h"

static PerlInterpreter *my_perl;

/* TODO: Work out why we can't build a dynamic dtperl on Solaris. I
 * expect it's something simple that I'm missing.
 */

#if defined (__SVR4) && defined (__sun)
/* Solaris */
static void *xs_init = NULL;
#else
/* Not Solaris */
EXTERN_C void boot_DynaLoader( pTHX_ CV * cv );

static void
xs_init( pTHX ) {
  static char file[] = __FILE__;
  dXSUB_SYS;
  newXS( "DynaLoader::boot_DynaLoader", boot_DynaLoader, file );
}
#endif

int
main( int argc, char **argv, char **env ) {
  int exit_status;

#ifdef PERL_GLOBAL_STRUCT
#define PERLVAR(var,type) /**/
#define PERLVARA(var,type) /**/
#define PERLVARI(var,type,init) PL_Vars.var = init;
#define PERLVARIC(var,type,init) PL_Vars.var = init;
#include "perlvars.h"
#undef PERLVAR
#undef PERLVARA
#undef PERLVARI
#undef PERLVARIC
#endif
      PERL_GPROF_MONCONTROL( 0 );

  PERL_SYS_INIT3( &argc, &argv, &env );

#if defined(USE_5005THREADS) || defined(USE_ITHREADS)
  PTHREAD_ATFORK( Perl_atfork_lock,
                  Perl_atfork_unlock, Perl_atfork_unlock );
#endif

  if ( !PL_do_undump ) {
    my_perl = perl_alloc(  );
    if ( !my_perl ) {
      exit( 1 );
    }
    perl_construct( my_perl );
    PL_perl_destruct_level = 0;
  }

  PL_exit_flags |= PERL_EXIT_DESTRUCT_END;

  exit_status = perl_parse( my_perl, xs_init, argc, argv, NULL );

  if ( !exit_status ) {
    runops_hook(  );
    perl_run( my_perl );
  }

  exit_status = perl_destruct( my_perl );

  perl_free( my_perl );

  PERL_SYS_TERM(  );

  exit( exit_status );
  return exit_status;
}
