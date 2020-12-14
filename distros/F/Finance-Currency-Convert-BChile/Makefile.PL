use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Finance::Currency::Convert::BChile',
    AUTHOR              => 'Hugo Salgado <hsalgado@vulcano.cl>',
    VERSION_FROM        => 'lib/Finance/Currency/Convert/BChile.pm',
    ABSTRACT_FROM       => 'lib/Finance/Currency/Convert/BChile.pm',
    PL_FILES            => {},
    SIGN                => 1,
    PREREQ_PM => {
        'Test::More'       => 0,
        'LWP::UserAgent'   => 0,
        'HTML::TokeParser' => 0,
    },
    META_MERGE        => {
      'meta-spec' => { version => 2 },
      resources   => {
         bugtracker => {
            "web" => "https://todo.sr.ht/~huguei/perl-Finance-Currency-Convert-BChile"
         },
         repository => {
            type => 'mercurial',
            url => 'https://hg.sr.ht/~huguei/perl-Finance-Currency-Convert-BChile',
            web => 'https://hg.sr.ht/~huguei/perl-Finance-Currency-Convert-BChile'
         }
      }
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Finance-Currency-Convert-BChile-*' },
);

