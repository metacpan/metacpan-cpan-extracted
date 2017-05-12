use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'HTML::Element::Tiny',
    AUTHOR              => 'Hans Dieter Pearcey <hdp@cpan.org>',
    VERSION_FROM        => 'lib/HTML/Element/Tiny.pm',
    ABSTRACT_FROM       => 'lib/HTML/Element/Tiny.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'HTML-Element-Tiny-*' },
);
