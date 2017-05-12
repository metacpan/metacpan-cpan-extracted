# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

use strict;
use ExtUtils::MakeMaker;
use Config;
use File::Spec::Functions qw(catfile catdir);
use Cwd;

my $cwd = getcwd;
my $libmd = catdir $cwd, 'libmd';

my $arch = $Config{archname};
my $is_win32 = ($arch =~ /MSWin32/i && $Config{cc} eq 'cl');
my $is_387 = ($arch =~ /^i\d+-linux/i);
my $is_sol = ($arch =~ /sun4-solaris|sparc/i);
my $is_dar = ($arch =~ /darwin/i);
my $is_cyg = ($arch =~ /cygwin/i || ($arch =~ /MSWin32/i && !$is_win32));
my $is_vms = ($arch =~ /vms/i);
my $dmake  = ($Config{make} eq 'dmake');

######################################
# for dmake, fool WriteMakefile into thinking there's a libmd lib
if ($dmake) {
    my $lib = 'libmd' . $Config{lib_ext};
    my $dummy = catfile $libmd, $lib;
    open(DUMMY, ">$dummy") or die "Cannot create $dummy: $!";
    close DUMMY;
}
######################################

my @clean = qw(libmd/setprec.c libmd/mconf.h libmd/sqrt.c);

my %opts = (
    NAME => 'Math::Cephes',
    MYEXTLIB => "$libmd/libmd\$(LIB_EXT)",
    VERSION_FROM => 'lib/Math/Cephes.pm',
    OBJECT => 'Cephes_wrap.o arrays.o',
    INC => "-I$libmd",
    EXE_FILES => [ 'pmath' ],
    META_MERGE => {
        resources => {
            repository => 'https://github.com/shlomif/Math-Cephes',
        },
    },
    dist   => {
        SUFFIX   => 'gz',
        COMPRESS => 'gzip -9f',
    },
    clean => { FILES => "@clean"},
);

my $eu_version = $ExtUtils::MakeMaker::VERSION;
if ($eu_version >= 5.43) {
   $opts{ABSTRACT} = 'Perl interface to the math cephes library';
   # $opts{AUTHOR} = 'Randy Kobes <r.kobes@uwinnipeg.ca>';
   $opts{AUTHOR} = 'Shlomi Fish <shlomif@cpan.org>';
   $opts{CAPI} = 'TRUE' if $arch =~ /-object\b/i;
}

if ($eu_version >= 6.31) {
    $opts{LICENSE} = 'perl';
}

if ($eu_version >= 6.48) {
    $opts{MIN_PERL_VERSION} = '5.008';
}

my $mconf = catfile $libmd, 'mconf.h';
my %defs = (HAVE_LONG_DOUBLE => 'd_longdbl',
            SIZEOF_INT => 'intsize',
            RETSIGTYPE => 'd_voidsig',
            HAVE_MALLOC_H => 'i_malloc',
            HAVE_STRING_H => 'i_string',
            VOLATILE => 'd_volatile',
           );
my $vals = {RETSIGTYPE => {define => 'void', undef => 'int'},
            VOLATILE => {define => 'volatile', undef => ''},
           };

if ($is_win32 or $is_387 or $is_cyg) {
    $defs{IBMPC} = 1;
}
elsif ($is_sol) {
    $defs{WORDS_BIGENDIAN} = 1;
    $defs{FLOAT_WORDS_BIGENDIAN} = 1;
    $defs{UNK} = 1;
}
elsif ($is_dar) {
    require POSIX;
    my $machine = (POSIX::uname())[4];
    if ($machine eq 'i386' or $machine eq 'x86_64') {
        $defs{IBMPC} = 1;
    }
    else {
      $defs{WORDS_BIGENDIAN} = 1;
      $defs{FLOAT_WORDS_BIGENDIAN} = 1;
      $defs{MIEEE} = 1;
    }
}
elsif ($is_vms) {
    $defs{DEC} = 1;
}
else {
    $defs{UNK} = 1;
}
my $match = join '|', keys %defs;
open(MCONF, ">$mconf") or die "Cannot open $mconf: $!";
while (my $line = <DATA>) {
    if ($line =~ /\#define\s+($match)/) {
        my $def = $1;
        print MCONF fix_mconf($def, $defs{$def});
    }
    elsif ($line =~ /^\#define XPD/) {
        my $lds = $Config{longdblsize};
        my $xpd = ($is_387 and $lds and $lds == 12) ? '0,' : '';
        print MCONF qq{\#define XPD $xpd\n};
    }
    else {
        print MCONF $line;
    }
}
close MCONF;


WriteMakefile(%opts);

my $message;

if ($is_sol or $is_dar or $is_win32 or $is_387) {
  $message = <<"END";

A file libmd/mconf.h, which contains machine-dependent
definitions, has been used which is known to work with some
versions of $arch. If there are problems with
the tests, some manual editing of this file may be needed.

END
}

else {
    $message = <<'END';

The file libmd/mconf.h, which contains machine-dependent
definitions, may require some manual editing for your platform.

END
}

print $message;

sub fix_mconf {
    my ($what, $key) = @_;
    my $lookup = $Config{$key} ? $Config{$key} :
        ( ($key == 1) ? 'define' : 'undef' );
    my $string;
    my $val = $vals->{$what}->{$lookup};
    if ($lookup eq 'define') {
        $string = defined $val ?
            qq{\#define $what $val\n} : qq{\#define $what 1\n};
    }
    elsif ($lookup eq 'undef') {
        $string = defined $val ?
            qq{\#define $what $val\n} :
                qq{\#ifdef $what\n\#undef $what\n\#endif\n};
    }
    else {
        $string = qq{\#define $what $lookup\n};
    }
    return $string;
}

sub MY::postamble {
    my $postamble = '';

    if ($is_win32 && Win32::IsWin95()) {
        if ($Config{'make'} =~ /dmake/i) {
	        # dmake-specific
            $postamble .= <<"EOT";
\$(MYEXTLIB): $libmd/Makefile
\@[
	cd $libmd
	\$(MAKE) static
	cd ..
]
EOT
	    }
        elsif ($Config{'make'} =~ /nmake/i) {
	        #
            $postamble .= <<"EOT";
\$(MYEXTLIB): $libmd/Makefile
	cd $libmd
	\$(MAKE) static
	cd ..
EOT
           }
        }
    elsif ($^O ne 'VMS') {
        $postamble .= <<"EOT";

\$(MYEXTLIB): $libmd/Makefile
	cd $libmd && \$(MAKE) static
EOT
        }
    else {
        $postamble .= <<"EOT";

\$(MYEXTLIB) : ${libmd}descrip.mms
	set def $libmd
    $(MMS) static
    set def [-]
EOT
    }

    return $postamble;
}

__DATA__

/*
Cephes Math Library Release 2.3:  June, 1995
Copyright 1984, 1987, 1989, 1995 by Stephen L. Moshier
*/

/* Define if the `long double' type works.  */
#define HAVE_LONG_DOUBLE 1

/* Define as the return type of signal handlers (int or void).  */
#define RETSIGTYPE void

/* Define if you have the ANSI C header files.  */
#define STDC_HEADERS 1

/* Define if your processor stores words with the most significant
   byte first (like Motorola and SPARC, unlike Intel and VAX).  */
/* #define WORDS_BIGENDIAN */

/* Define if floating point words are bigendian.  */
/* #define FLOAT_WORDS_BIGENDIAN */

/* The number of bytes in a int.  */
#define SIZEOF_INT 4

/* Define if you have the <malloc.h> header file.  */
#define HAVE_MALLOC_H 1

/* Define if you have the <string.h> header file.  */
#define HAVE_STRING_H 1

/* Name of package */
#define PACKAGE "cephes"

/* Version number of package */
#define VERSION_CEPHES "2.7"

/* Constant definitions for math error conditions
 */

#define DOMAIN		1	/* argument domain error */
#define SING		2	/* argument singularity */
#define OVERFLOW	3	/* overflow range error */
#define UNDERFLOW	4	/* underflow range error */
#define TLOSS		5	/* total loss of precision */
#define PLOSS		6	/* partial loss of precision */

#define EDOM		33
#define ERANGE		34
/* Complex numeral.  */
typedef struct
	{
	double r;
	double i;
	} cmplx;

#ifdef HAVE_LONG_DOUBLE
/* Long double complex numeral.  */
typedef struct
	{
	long double r;
	long double i;
	} cmplxl;
#endif

/* Type of computer arithmetic */

/* PDP-11, Pro350, VAX:
 */
/* #define DEC 1 */

/* Intel IEEE, low order words come first:
 */
/* #define IBMPC 1 */

/* Motorola IEEE, high order words come first
 * (Sun 680x0 workstation):
 */
/* #define MIEEE 1 */

/* UNKnown arithmetic, invokes coefficients given in
 * normal decimal format.  Beware of range boundary
 * problems (MACHEP, MAXLOG, etc. in const.c) and
 * roundoff problems in pow.c:
 * (Sun SPARCstation)
 */
/* #define UNK 1 */

/* If you define UNK, then be sure to set BIGENDIAN properly. */
#ifdef FLOAT_WORDS_BIGENDIAN
#define BIGENDIAN 1
#else
#define BIGENDIAN 0
#endif

/* Define this `volatile' if your compiler thinks
 * that floating point arithmetic obeys the associative
 * and distributive laws.  It will defeat some optimizations
 * (but probably not enough of them).
 *
 */
/* #define VOLATILE volatile */

/* For 12-byte long doubles on an i386, pad a 16-bit short 0
 * to the end of real constants initialized by integer arrays.
 *
 * #define XPD 0,
 *
 * Otherwise, the type is 10 bytes long and XPD should be
 * defined blank (e.g., Microsoft C).
 *
 * #define XPD
 */
#define XPD 0,

/* Define to support tiny denormal numbers, else undefine. */
#define DENORMAL 1

/* Define to ask for infinity support, else undefine. */
#define INFINITIES 1

/* Define to ask for support of numbers that are Not-a-Number,
   else undefine.  This may automatically define INFINITIES in some files. */
#define NANS 1

/* Define to distinguish between -0.0 and +0.0.  */
#define MINUSZERO 1

/* Define 1 for ANSI C atan2() function
   See atan.c and clog.c. */
#define ANSIC 1

/* Get ANSI function prototypes, if you want them. */
#ifdef __STDC__
#define ANSIPROT
/* #include "protos.h" */
int mtherr();
#else
int mtherr();
#endif

/* Variable for error reporting.  See mtherr.c.  */
extern int merror;
