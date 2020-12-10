use strict;
use warnings;
use ExtUtils::MakeMaker;
use ExtUtils::Constant;

use 5.008001;

use lib 'inc';
use CheckForLibPng;

# Set argument to any true value to get debugging messages.

my $vars = check_for_libpng (undef);

if (! $vars) {
    print STDERR "Libpng may not be present on this system.\n";
    exit;
}

my %wm = (
    NAME         => 'Image::PNG::Libpng',
    VERSION      => '0.49',
    ABSTRACT     => 'Perl interface to libpng',
    OBJECT       => 'Libpng.o',
    LIBS         => '-lpng',
    AUTHOR => 'Ben Bullock <bkb@cpan.org>',
    LICENSE => 'perl',
    META_MERGE => {
        resources => {
            "bugtracker" => "https://github.com/benkasminbullock/image-png-libpng/issues",
            "repository" => "https://github.com/benkasminbullock/image-png-libpng",
        },
        no_index => {
            directory => ['tmpl', 'build', 'inc'],
        },
	x_contributors => [
	    'Greg Kennedy <gregk@cpan.org>',
	    'Phil Perry <pmperry@cpan.org>',
	    'Petr Pisar',
	    'Aaron Crane <arc@cpan.org>',
	],
    },
    MIN_PERL_VERSION => '5.008001',
    EXE_FILES => ['script/pnginspect',],
#    OPTIMIZE => '-Wall -O',
);

if ($vars) {
    if ($vars->{inc}) {
	$wm{INC} = "$vars->{inc}";
    }
    if ($vars->{libs}) {
	$wm{LIBS} = "$vars->{libs}";
    }
}

WriteMakefile (%wm);

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
