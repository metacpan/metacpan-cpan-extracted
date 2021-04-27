use strict;
use warnings;
use ExtUtils::MakeMaker;
use ExtUtils::Constant;
use Getopt::Long;
use Config qw/%Config/;

my $ok = GetOptions (
    check => \my $check,
    optimize => \my $optimize,
    "prefix=s" => \my $prefix,
);

use 5.008001;

use lib 'inc';
use CheckForLibPng;

my $vars = check_for_libpng (verbose => $check, prefix => $prefix,);

if (! $vars) {
    print STDERR "Libpng may not be present on this system.\n";
    exit;
}

my %wm = (
    NAME         => 'Image::PNG::Libpng',
    VERSION      => '0.57',
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
	    file => ['t/IPNGLT.pm'],
        },
	x_contributors => [
	    # Alphabetical order
	    'Aaron Crane <arc@cpan.org>',
	    'Greg Kennedy <gregk@cpan.org>',
	    'Petr Pisar',
	    'Phil Perry <pmperry@cpan.org>',
	],
    },
    MIN_PERL_VERSION => '5.008001',
    EXE_FILES => ['script/pnginspect',],
);

if ($optimize) {
    warn "Optimizing is on";
    $wm{OPTIMIZE} = ' -g -Wall -O ';
}

if ($vars) {
    if ($vars->{inc}) {
	$wm{INC} = "$vars->{inc}";
    }
    if ($vars->{libs}) {
	$wm{LIBS} = "$vars->{libs}";
	# This overrides loading the library from /usr/local/lib by
	# putting the directory we want to use first.
	$wm{LDDLFLAGS} = "$vars->{libs} $Config{lddlflags}";
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
