use strict;
use warnings;
use ExtUtils::MakeMaker;
use 5.010;

my( $mm ) = $ExtUtils::MakeMaker::VERSION =~ /^([^_]+)/;

WriteMakefile(
    NAME                => 'HTML::TagHelper',
    AUTHOR              => 'Chenryn<rao.chenlin@gmail.com>',
    VERSION_FROM        => 'lib/HTML/TagHelper.pm',
    ABSTRACT_FROM       => 'lib/HTML/TagHelper.pm',
    PL_FILES            => {},
    MIN_PERL_VERSION    => '5.010000',
    PREREQ_PM => {
        'Test::More' => 0,
        'Moo' => 0,
        'HTML::Element' => 0,
        'HTML::Entities' => 0,
        'Carp' => 0,
        'DateTime' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'HTML-TagHelper-*' },
    ( $mm < 6.46
        ? ()
        : ( META_MERGE => {
                resources => {
                    repository => 'https://github.com/chenryn/HTML-TagHelper.git',
                },
                no_index => {directory => [qw/t/]},
            },
        )
    ),
);
