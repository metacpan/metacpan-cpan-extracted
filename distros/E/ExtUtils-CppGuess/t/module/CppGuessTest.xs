#ifdef _WIN32
#include <windows.h>
#endif

#if defined (__SVR4) && defined (__sun)
#include <sys/vnode.h>
#endif

#include <string>

typedef std::string std__string;

#include <config.h>
#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>

// Perl likes to pollute your namespace
#undef bool
#if defined( PERL_IMPLICIT_CONTEXT )
#undef abort
#undef clearerr
#undef close
#undef eof
#undef exit
#undef fclose
#undef feof
#undef ferror
#undef fflush
#undef fgetpos
#undef fopen
#undef form
#undef fputc
#undef fputs
#undef fread
#undef free
#undef freopen
#undef fseek
#undef fsetpos
#undef ftell
#undef fwrite
#undef getc
#undef getenv
#undef malloc
#undef open
#undef read
#undef realloc
#undef rename
#undef seekdir
#undef setbuf
#undef setvbuf
#undef tmpfile
#undef tmpnam
#undef ungetc
#undef vform
#undef vfprintf
#undef write
#endif // defined( PERL_IMPLICIT_SYS )

int silly_test( int value )
{
    return 2 * value + 1;
}

std::string useless_test( const std::string& a, const std::string& b )
{
    return a + b;
}

MODULE=CppGuessTest PACKAGE=CppGuessTest

PROTOTYPES: DISABLE

int
silly_test( int value )

std::string
useless_test( std::string a, std::string b )
