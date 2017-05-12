use strict;
use warnings;
use ExtUtils::MakeMaker;

use lib 'inc';

use Devel::CheckLib;

check_lib_or_exit (lib => 'png', header => 'png.h');

my $pm = 'lib/Image/PNG/QRCode.pm';
my $pod = 'lib/Image/PNG/QRCode.pod';
my $github = 'github.com/benkasminbullock/image-png-qrcode';
my $repo = "https://$github";

WriteMakefile (
    NAME => 'Image::PNG::QRCode',
    VERSION_FROM => $pm,
    ABSTRACT_FROM => $pod,
    AUTHOR => 'Ben Bullock <bkb@cpan.org>',
    LICENSE => 'gpl_3',
    PREREQ_PM => {
    },
    LIBS => '-lpng',
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
    },
    MIN_PERL_VERSION => '5.006001',
    OBJECT => 'QRCode.o qrencode.o qrpng.o',
    #    OPTIMIZE => '-Wall -g -O',
    EXE_FILES => ['script/qrpng',],
);
