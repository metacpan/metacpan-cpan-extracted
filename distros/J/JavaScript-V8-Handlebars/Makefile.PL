use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

use lib 'inc';
use File::ShareDir::Install;

install_share module => 'JavaScript::V8::Handlebars' => 'share';

WriteMakefile(
    NAME             => 'JavaScript::V8::Handlebars',
    AUTHOR           => q{Robert Grimes <rmzgrimes@gmail.com>},
    VERSION_FROM     => 'lib/JavaScript/V8/Handlebars.pm',
    ABSTRACT_FROM    => 'lib/JavaScript/V8/Handlebars.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.010001,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'JavaScript::V8'    => 0,
        'File::Slurp'       => 0,
        'File::ShareDir'    => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'JavaScript-V8-Handlebars-*' },
		META_MERGE        => {
			"meta-spec" => { version => 2 },
			resources => {
				repository => {
					type => 'git',
					url => 'git://github.com/rmzg/JavaScript-V8-Handlebars.git',
					web => 'https://github.com/rmzg/JavaScript-V8-Handlebars',
				},
			},
		},

);

package MY;
use File::ShareDir::Install qw/postamble/;
