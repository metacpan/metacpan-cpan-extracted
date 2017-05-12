use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Inline::Ruby::dRuby::Client',
    AUTHOR              => 'Yuichi Tateno <hotchpotch@gmail.com>',
    VERSION_FROM        => 'lib/Inline/Ruby/dRuby/Client.pm',
    ABSTRACT_FROM       => 'lib/Inline/Ruby/dRuby/Client.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'version'    => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Inline-Ruby-dRuby-Client-*' },
);
