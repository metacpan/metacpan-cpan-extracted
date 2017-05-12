use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Minion::Command::minion::jobx',
    AUTHOR           => q{Bob Faist <bfaist@cpan.org>},
    VERSION_FROM     => 'lib/Minion/Command/minion/jobx.pm',
    ABSTRACT_FROM    => 'lib/Minion/Command/minion/jobx.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
	'Mojolicious'       => 6.0,
	'Minion'            => 5.0
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Minion-Command-minion-jobx-*' },
    META_MERGE        => {
	      'meta-spec' => { version => 2 },
	      resources => {
		    repository => {
		            type => 'git',
		            url => 'git://github.com/bfaist/Minion-Command-minion-jobx.git',
		            web => 'https://github.com/bfaist/Minion-Command-minion-jobx'
		        },
	  },
   },
);
