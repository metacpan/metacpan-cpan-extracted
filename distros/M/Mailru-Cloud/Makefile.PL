use 5.008001;
use strict;
use warnings;

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Mailru::Cloud',
    LICENSE           => 'perl_5',
    AUTHOR            => 'Pavel Andryushin',
    VERSION_FROM      => 'lib/Mailru/Cloud.pm', # finds $VERSION, requires EU::MM from perl >= 5.5
    PREREQ_PM         => {
        'URI::Escape'           => 3.31,
        'LWP::UserAgent'        => 6.27,
        'LWP::Protocol::https'  => 6.06,
        'JSON::XS'              => 3.04,
        'File::Basename'        => 2.80,
        'Encode'                => 2.60,
        'IO::Socket::SSL'       => 2.002,
    },
    META_MERGE   => {
          requires  => { perl => '5.008008' },
          resources => {
                license     => 'http://dev.perl.org/licenses/',
                repository  => 'https://github.com/vrag86/perl-mailru-cloud-api',
                bugtracker  => 'https://github.com/vrag86/perl-mailru-cloud-api/issues'
              },
        },
    AUTHOR            => 'vrag <vrag867@gmail.com>',
    LICENSE           => 'perl',
);
