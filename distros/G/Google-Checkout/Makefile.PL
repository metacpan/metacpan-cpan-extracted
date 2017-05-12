use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Google-Checkout',
    AUTHOR              => 'Google Inc. <dzhuo@google.com>',
    VERSION_FROM        => 'lib/Google/Checkout/General/GCO.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'CGI' => 2.89,
        'LWP' => 5.65,
        'XML::Simple' => 2.09,
        'Crypt::SSLeay' => 0.45,
        'HTTP::Request' => 1.30,
        'HTTP::Headers' => 1.43,
        'Date::Manip' => 5.40,
        'Digest::HMAC_SHA1' => 1.01,
        'MIME::Base64' => 3.05,
        'XML::Writer' => 0.6
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Google-*' },
);
