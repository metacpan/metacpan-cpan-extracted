use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'HTML::SocialMeta',
    AUTHOR           => q{Robert Acock <ThisUsedToBeAnEmail@gmail.com>},
    VERSION_FROM     => 'lib/HTML/SocialMeta.pm',
    ABSTRACT_FROM    => 'lib/HTML/SocialMeta.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
        'Test::Exception' => 0
    },
    PREREQ_PM => {
        'Moo' => '1.001001',
    	'List::MoreUtils' => '0.33',
       	'MooX::LazierAttributes' => '1.06',
       	'MooX::ValidateSubs' => '1.012001',
        'Type::Tiny' => '1.002000',
		'Coerce::Types::Standard' => '0.000004',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'HTML-SocialMeta-*' },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        x_contributors => [
            'Robert Haliday <robh@cpan.org>',
            'Jason McIntosh (JMAC) <jmac@jmac.org>'
        ],
        resources => {
            repository => {
                type => 'git',
                url => 'https://github.com/ThisUsedToBeAnEmail/HTML-SocialMeta.git',
                web => 'https://github.com/ThisUsedToBeAnEmail/HTML-SocialMeta'
            }
        }
    }
);
