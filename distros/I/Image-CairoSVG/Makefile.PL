use strict;
use warnings;
use ExtUtils::MakeMaker;

my $pm = 'lib/Image/CairoSVG.pm';
my $pod = 'lib/Image/CairoSVG.pod';
my $github = 'github.com/benkasminbullock/image-cairosvg';
my $repo = "https://$github";

WriteMakefile (
    NAME => 'Image::CairoSVG',
    VERSION_FROM => $pm,
    ABSTRACT_FROM => $pod,
    AUTHOR => 'Ben Bullock <bkb@cpan.org>',
    LICENSE => 'perl',
    PREREQ_PM => {
	# These are in Perl already.
	'Carp' => '0',
	'Math::Trig' => '0',
	# These may need to be installed by the user.
	'Cairo' => '0',
	'Image::SVG::Path' => '0.36',
	'XML::Parser' => '0',
    },
    EXE_FILES => [
	"script/svg2png",
    ],
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
	    prereqs => {
		test => {
		    recommends => {
			# The user can test the output image "looks
			# like" the target image with
			# F<t/image-similar.t> if the following two
			# modules are installed. Unfortunately,
			# changes in Cairo mean that exact comparisons
			# of pixels won't work, as discovered by
			# version 0.02:
			# http://matrix.cpantesters.org/?dist=Image-CairoSVG+0.02
			# If the two modules aren't installed,
			# F<t/image-similar.t> is completely skipped.
			'Image::PNG::Libpng' => '0.42',
			'Image::Similar' => '0.02',
		    },
		},
	    },
        },

    },
    MIN_PERL_VERSION => '5.006001',
);
