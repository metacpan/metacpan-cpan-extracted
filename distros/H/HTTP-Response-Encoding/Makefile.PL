use 5.008001;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'HTTP::Response::Encoding',
    AUTHOR              => 'Dan Kogai <dankogai@dan.co.jp>',
    VERSION_FROM        => 'lib/HTTP/Response/Encoding.pm',
    ABSTRACT_FROM       => 'lib/HTTP/Response/Encoding.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Encode'         => 2.00,
        'Test::More'     => 0,
	# 'HTTP::Message'  => 5.827,
        'HTTP::Response' => 0,
      },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'HTTP-Response-Encoding-*' },
);
