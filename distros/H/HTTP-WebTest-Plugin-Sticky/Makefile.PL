use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'HTTP::WebTest::Plugin::Sticky',
    AUTHOR              => 'Hugo Salgado H. <huguei@cpan.org>',
    VERSION_FROM        => 'lib/HTTP/WebTest/Plugin/Sticky.pm',
    ABSTRACT_FROM       => 'lib/HTTP/WebTest/Plugin/Sticky.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'HTML::TokeParser' => 0,
        'HTTP::WebTest' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'HTTP-WebTest-Plugin-Sticky-*' },
);
