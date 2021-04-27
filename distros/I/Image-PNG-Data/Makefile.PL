use strict;
use warnings;
use ExtUtils::MakeMaker;

use Getopt::Long;
use Config qw/%Config/;

my $ok = GetOptions (
    check => \my $check,
    optimize => \my $optimize,
    "prefix=s" => \my $prefix,
);

use lib 'inc';
use CheckForLibPng;

my $vars = check_for_libpng (verbose => $check, prefix => $prefix,);

if (! $vars) {
    print STDERR "Libpng may not be present on this system.\n";
    exit;
}

my $pm = 'lib/Image/PNG/Data.pm';
my $pod = 'lib/Image/PNG/Data.pod';
my $github = 'github.com/benkasminbullock/image-png-data';
my $repo = "https://$github";

my %wm = (
    NAME => 'Image::PNG::Data',
    VERSION_FROM => $pm,
    ABSTRACT_FROM => $pod,
    AUTHOR => 'Ben Bullock <bkb@cpan.org>',
    LICENSE => 'perl',
    PREREQ_PM => {
	'Image::PNG::Libpng' => '0.56',
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
	    no_index => {
#		directory => ['tmpl', 'build', 'inc'],
		file => ['t/IPNGDT.pm'],
	    },

#	    homepage => 'http://',
        },
	
    },
    MIN_PERL_VERSION => '5.006001',
    OBJECT => 'Data.o',
    LIBS => '-lpng',
);
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
