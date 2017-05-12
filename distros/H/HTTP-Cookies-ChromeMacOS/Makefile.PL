use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'HTTP::Cookies::ChromeMacOS',
    AUTHOR           => q{MC Cheung <mc.cheung@aol.com>},
    VERSION_FROM     => 'lib/HTTP/Cookies/ChromeMacOS.pm',
    ABSTRACT_FROM    => 'lib/HTTP/Cookies/ChromeMacOS.pm',
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
      DBI => 0,
      "PBKDF2::Tiny" => 0,
      "Crypt::CBC" => 0,
      'Crypt::OpenSSL::AES' => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'HTTP-Cookies-ChromeMacOS-*' },
);
