/*
	gen-stat.c
	$Id: gen-stat.c,v 1.5 2006/06/28 11:54:00 fedorov Exp $

	Outputs <sys/stat.h> constants to stdout
	as Perl constant functions

	(C) 2004,2006 Dmitry A. Fedorov <fedorov@cpan.org>
	Copying policy: GNU LGPL
*/

#include <stdio.h>
#include <sys/stat.h>
#include <sys/types.h>

#ifdef _HAVE_SYS_SYSMACROS_H
# include <sys/sysmacros.h>
#endif


#undef P
#undef CONCAT
#undef CONCAT1
#undef  STRING
#undef XSTRING
#undef VERBATIM


/* + shamelessly stolen from other source headers */

#if defined(__STDC__) || defined(__cplusplus) || defined(c_plusplus)
	/* ANSI C or C++ */
# define P(protos)	protos
# define CONCAT1(x,y)	x ## y
# define CONCAT(x,y)	CONCAT1(x,y)
# define  STRING(x)	#x /* stringify without expanding x */
# define XSTRING(x)	STRING(x) /* expand x, then stringify */
#else
	/* traditional C, no prototypes */
# define VERBATIM(x) x

# define P(protos)	()
# define CONCAT(x,y)	VERBATIM(x)VERBATIM(y)
# define  STRING(x)	"x"
# define XSTRING(x)	STRING(x)
#endif

/* - shamelessly stolen from other source headers */


static void pr(const char *name, unsigned long value)
{
    printf("sub %-12s () { 0%06lo }\n", name, value);
}

static void prundef(const char *name)
{
    printf("sub %-12s () { undef }\n", name);
}

#if defined(__STDC__) || defined(__cplusplus) || defined(c_plusplus)
	/* ANSI C or C++ */
#	define PR(x)	pr( #x , x )
#else
	/* traditional C, no prototypes */
#	define PR(x)	pr( "x" , x )
#endif

static void constants(void)
{
    PR(S_IFMT  );
    PR(S_IFDIR );
    PR(S_IFCHR );
    PR(S_IFBLK );
    PR(S_IFREG );
#ifdef S_IFIFO
    PR(S_IFIFO );
#endif
#ifdef S_IFLNK
    PR(S_IFLNK );
#endif
#ifdef S_IFSOCK
    PR(S_IFSOCK);
#endif

    printf("\n");

    PR(S_IRWXU);
    PR(S_IRUSR);
    PR(S_IWUSR);
    PR(S_IXUSR);
    PR(S_ISUID);

    printf("\n");

    PR(S_IRWXG);
    PR(S_IRGRP);
    PR(S_IWGRP);
    PR(S_IXGRP);
    PR(S_ISGID);

    printf("\n");

    PR(S_IRWXO);
    PR(S_IROTH);
    PR(S_IWOTH);
    PR(S_IXOTH);
    PR(S_ISVTX);

    printf("\n");
}


#ifdef _HAVE_MAJOR_MINOR

#define MASK(bit) ( ((unsigned long)1) << (bit) )

static void test(unsigned long (*f)(unsigned long),
		 unsigned long *_mask, unsigned int *_shift)
{
    unsigned int shift;
    unsigned long mask, old_mask;

    for(shift=0; mask=MASK(shift), f(mask) == 0; ++shift)
	;

    *_shift=shift;

    for(*_mask=0, old_mask=0;
	(mask=MASK(shift)) > old_mask;
	++shift, old_mask=mask
       )
    {
	if ( f(mask) != 0 )
	    *_mask |= mask;
    }
}


static unsigned long Major( unsigned long dev )
{
    return major(dev);
}

static unsigned long Minor( unsigned long dev )
{
    return minor(dev);
}

#endif /* _HAVE_MAJOR_MINOR */


int main(void)
{
#ifdef _HAVE_MAJOR_MINOR
    unsigned long major_mask , minor_mask;
    unsigned int  major_shift, minor_shift;

    test( Major, &major_mask, &major_shift );
    test( Minor, &minor_mask, &minor_shift );

    pr("MAJOR_MASK" , major_mask );
    pr("MAJOR_SHIFT", major_shift);
    pr("MINOR_MASK" , minor_mask );
    pr("MINOR_SHIFT", minor_shift);
#else
    prundef("MAJOR_MASK" );
    prundef("MAJOR_SHIFT");
    prundef("MINOR_MASK" );
    prundef("MINOR_SHIFT");
#endif /* _HAVE_MAJOR_MINOR */

    printf("\n");

    constants();
    printf("\n1;\n");

    return 0;
}
