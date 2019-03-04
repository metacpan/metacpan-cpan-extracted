use strict;
use warnings;
use ExtUtils::MakeMaker;
use v5.8;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              	=> 'Iterator::Simple::Lookahead',
    VERSION_FROM      	=> 'lib/Iterator/Simple/Lookahead.pm',
    DISTNAME          	=> 'Iterator-Simple-Lookahead',
    PREREQ_PM         	=> {
		'Class::Accessor'			=> 0.51,
		'Iterator::Simple'			=> 0.07,
        'Test::More' 				=> 1.001014,
	},
	ABSTRACT_FROM		=> 'lib/Iterator/Simple/Lookahead.pm',
	AUTHOR         		=> 'Paulo Custodio <pscust@cpan.org>',
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
	MIN_PERL_VERSION	=> 5.8.0,
	LICENSE 			=> 'perl_5',
	META_MERGE 			=> {
            resources => {
                repository  => {
                    type => 'git',
                    url  => 'git://github.com/pauloscustodio/perl-Iterator-Simple-Lookahead.git',
                    web  => 'https://github.com/pauloscustodio/perl-Iterator-Simple-Lookahead',
                },
            },
          },
    clean               => { FILES => [ 'Iterator-Simple-Lookahead-*',
										'*.tmp',
										'*.bak',
									  ]
						   },
);
