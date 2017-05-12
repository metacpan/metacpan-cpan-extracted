use lib qw(inc);
use Devel::CheckLib;

# Prompt the user here for any paths and other configuration

check_lib_or_exit(
    # fill in what you prompted the user for here
    lib => [qw()]
);


use strict;
use warnings;
use ExtUtils::MakeMaker;

use 5.008001;

use lib 'inc';

use Devel::CheckLib;

check_lib_or_exit (lib => 'png', header => 'png.h');
check_lib_or_exit (lib => 'cairo', header => 'cairo/cairo.h');

my %prereqs = (
        'ExtUtils::Depends'   => 0.2,
        'ExtUtils::PkgConfig' => 1.0,
);

my $pm = 'lib/Image/PNG/Cairo.pm';
my $pod = 'lib/Image/PNG/Cairo.pod';
my $github = 'github.com/benkasminbullock/image-png-cairo';
my $repo = "https://$github";

my %extreqs = (
        'cairo' => '1.0.0',
);

while ((my $module, my $version) = each(%prereqs)) {
    unless (eval "use $module $version; 1" ) {
	print "This module requires $module to install itself.\n";
    }
}

my %cairo_cfg;

eval {
    %cairo_cfg = ExtUtils::PkgConfig->find ("cairo >= $extreqs{cairo}");
};

if ($@ ne '') {
    warn $@;
    exit 0;
}


my $dep = ExtUtils::Depends->new ('Cairo');
$dep->set_inc ($cairo_cfg{cflags});
$dep->set_libs ($cairo_cfg{libs});

WriteMakefile (
    NAME => 'Image::PNG::Cairo',
    VERSION_FROM => $pm,
    ABSTRACT_FROM => $pod,
    AUTHOR => 'Ben Bullock <bkb@cpan.org>',
    LICENSE => 'perl',
    PREREQ_PM => {
	'Image::PNG::Libpng' => '0.31',
	'Cairo' => '0',
    },
    META_MERGE => {
	'meta-spec' => {
	    version => 2,
	},
        resources => {
            repository => {
		type => 'git',
		url => "git://$github.git",
		web => $repo,
	    },
            bugtracker => {
		web => "$repo/issues",
	    },
#	    homepage => 'http://',
        },
	prereqs => {
	    configure => {
		requires => {%prereqs},
	    },
	},
    },
    OBJECT => 'Cairo.o',
    MIN_PERL_VERSION => '5.008001',
    $dep->get_makefile_vars,
);
