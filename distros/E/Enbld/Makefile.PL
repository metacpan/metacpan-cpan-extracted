use 5.006;

use strict;
use warnings;

if ( $^O eq 'MSWin32' ) {
    die "Enbld can't run on windows platform.";
}

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Enbld',
    AUTHOR           => q{magnolia <magnolia.k@me.com>},
    VERSION_FROM     => 'lib/Enbld.pm',
    ABSTRACT_FROM    => 'lib/Enbld.pm',
    LICENSE          => 'perl',
    MIN_PERL_VERSION => 5.010001,

    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 6.66,
    },

    BUILD_REQUIRES => {
        'ExtUtils::MakeMaker' => 6.66,
    },

    TEST_REQUIRES => {
        'Test::More'        => 0.98,
        'Test::Output'      => 0,
        'Test::Exception'   => 0,
    },

    "EXE_FILES" => [
        "bin/enblder",
        "bin/chkenbld",
        "bin/getenbld",
    ],

    PREREQ_PM		=> {
        'version'               => 0.77,
        'autodie'               => 0,
        'parent'                => 0,
        'HTTP::Tiny'            => 0.041,
        'IO::Socket::SSL'       => 0,
        'Try::Lite'             => 0,
        'File::Copy::Recursive' => 0,
        'File::Spec'            => 0,
        'File::Basename'        => 0,
    },

	META_MERGE		=> {
        "meta-spec" => { version => 2 },

		"no_index" => {
			"directory" => [ "xt" ]
	    },

        "resources" => {
            "homepage" => "https://github.com/magnolia-k/Enbld",

            "bugtracker" => {
                "web" => "https://github.com/magnolia-k/Enbld/issues",
            },

            "repository" => {
                "type" => "git",
                "url"  => "https://github.com/magnolia-k/Enbld.git",
                "web"  => "https://github.com/magnolia-k/Enbld",
            },
        },
	},

    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Enbld-*' },
);

