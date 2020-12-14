use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'HTTP::WebTest::Plugin::Sticky',
    AUTHOR              => 'Hugo Salgado H. <huguei@cpan.org>',
    VERSION_FROM        => 'lib/HTTP/WebTest/Plugin/Sticky.pm',
    ABSTRACT_FROM       => 'lib/HTTP/WebTest/Plugin/Sticky.pm',
    PL_FILES            => {},
    SIGN                => 1,
    PREREQ_PM => {
        'Test::More' => 0,
        'HTML::TokeParser' => 0,
        'HTTP::WebTest' => 0,
    },
    META_MERGE        => {
      'meta-spec' => { version => 2 },
      resources   => {
         bugtracker => {
            "web" => "https://todo.sr.ht/~huguei/perl-HTTP-WebTest-Plugin-Sticky"
         },
         repository => {
            type => 'mercurial',
            url => 'https://hg.sr.ht/~huguei/perl-HTTP-WebTest-Plugin-Sticky',
            web => 'https://hg.sr.ht/~huguei/perl-HTTP-WebTest-Plugin-Sticky'
         }
      }
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'HTTP-WebTest-Plugin-Sticky-*' },
);
