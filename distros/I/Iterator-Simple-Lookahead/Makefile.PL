use strict;
use warnings;
use ExtUtils::MakeMaker;
use v5.8;

my $mm_ver = $ExtUtils::MakeMaker::VERSION;
if ($mm_ver =~ /_/) {
    # developer release
    $mm_ver = eval $mm_ver;
    die $@ if $@;
}

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Iterator::Simple::Lookahead',
    VERSION_FROM      => 'lib/Iterator/Simple/Lookahead.pm',
    DISTNAME          => 'Iterator-Simple-Lookahead',
    ($] >= 5.005 ?       ## Add these new keywords supported since 5.005
        (
            ABSTRACT_FROM  => 'lib/Iterator/Simple/Lookahead.pm',
            AUTHOR         => 'Paulo Custodio <pscust@cpan.org>',
        ) : ()),
    PREREQ_PM         => {
		'Class::XSAccessor'			=> 1.18,
		'Iterator::Simple'			=> 0.06,
        'Test::More' 				=> 1.001014,
	},
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },

    ($mm_ver >= 6.48
        ? (MIN_PERL_VERSION => 5.008)
        : ()
    ),

    ($mm_ver >= 6.31 ? (LICENSE => 'perl_5_16') : ()),

    ($mm_ver <= 6.45
        ? ()
        : (META_MERGE => {
            'meta-spec' => { version => 2 },
            resources => {
                repository  => {
                    type => 'git',
                    url  => 'git://github.com/pauloscustodio/Iterator-Simple-Lookahead.git',
                    web  => 'https://github.com/pauloscustodio/Iterator-Simple-Lookahead',
                },
            },
          })
    ),

    clean               => { FILES => [ 'Iterator-Simple-Lookahead-*',
										'*.tmp',
										'*.bak',
									  ]
						   },
);
