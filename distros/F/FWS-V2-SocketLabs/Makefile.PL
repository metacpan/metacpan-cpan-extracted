use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'FWS::V2::SocketLabs',
    AUTHOR              => q{Nate Lewis <nlewis@gnetworks.com>},
    VERSION_FROM        => 'lib/FWS/V2/SocketLabs.pm',
    ABSTRACT_FROM       => 'lib/FWS/V2/SocketLabs.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'MIME::Lite' => 0,
        'MIME::Base64' => 0,
        'Authen::SASL' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'FWS-V2-SocketLabs-*' },
);
