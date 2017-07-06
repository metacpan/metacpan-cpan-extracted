use strict;
use warnings;
use ExtUtils::MakeMaker;
use ExtUtils::Constant;

use 5.008001;

use lib 'inc';
use CheckForLibPng;

my $vars = check_for_libpng (undef);

if (! $vars) {
    print STDERR "Libpng may not be present on this system.\n";
    exit;
}

WriteMakefile (
    NAME         => 'Image::PNG::Libpng',
    VERSION      => '0.44',
    ABSTRACT     => 'Perl interface to libpng',
    OBJECT       => 'Libpng.o',
    LIBS         => '-lpng',
#    INC          => $inc,
    AUTHOR => 'Ben Bullock <bkb@cpan.org>',
    LICENSE => 'perl',
    META_MERGE => {
        resources => {
            "bugtracker" => "https://github.com/benkasminbullock/image-png-libpng/issues",
            "repository" => "https://github.com/benkasminbullock/image-png-libpng",
        },
        no_index => {
            directory => ['tmpl', 'build'],
        },
    },
    MIN_PERL_VERSION => '5.008001',
    EXE_FILES => ['script/pnginspect',],
#    OPTIMIZE => '-Wall -O',
);

my @names;

ExtUtils::Constant::WriteConstants(
    NAME         => 'Image::PNG::Libpng',
    NAMES        => \@names,
    DEFAULT_TYPE => 'IV',
    C_FILE       => 'const-c.inc',
    XS_FILE      => 'const-xs.inc',
);

# Local variables:
# mode: perl
# End:
