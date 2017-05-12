
#if !defined( PERL_REVISION ) && !defined( PATCHLEVEL )
#include <patchlevel.h>
#endif

#ifdef PERL_REVISION

#define HIPI_PERL_VERSION_EQ( V, S, P ) \
 ( ( PERL_REVISION == (V) ) && ( PERL_VERSION == (S) ) && ( PERL_SUBVERSION == (P) ) )

#define HIPI_PERL_VERSION_GE( V, S, P ) \
 ( ( PERL_REVISION > (V) ) || \
   ( PERL_REVISION == (V) && PERL_VERSION > (S) ) || \
   ( PERL_REVISION == (V) && PERL_VERSION == (S) && PERL_SUBVERSION >= (P) ) )

#else

#define HIPI_PERL_VERSION_EQ( V, S, P ) \
 ( ( 5 == (V) ) && ( PATCHLEVEL == (S) ) && ( SUBVERSION == (P) ) )

#define HIPI_PERL_VERSION_GE( V, S, P ) \
 ( ( 5 > (V) ) || \
   ( 5 == (V) && PATCHLEVEL > (S) ) || \
   ( 5 == (V) && PATCHLEVEL == (S) && SUBVERSION >= (P) ) )

#endif

#define HIPI_PERL_VERSION_LT( V, S, P ) !HIPI_PERL_VERSION_GE( V, S, P )

#if HIPI_PERL_VERSION_GE( 5, 16, 0 )
#define HIPI_MINIMUM_TARGET_JESSIE
#endif
