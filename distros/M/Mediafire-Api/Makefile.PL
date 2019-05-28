use 5.008001;
use strict;
use warnings;

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Mediafire::Api',
    LICENSE           => 'perl_5',
    AUTHOR            => 'Pavel Andryushin',
    VERSION_FROM      => 'lib/Mediafire/Api.pm', # finds $VERSION, requires EU::MM from perl >= 5.5
    PREREQ_PM         => {
        'URI::Escape'           => 3.31,
        'LWP::UserAgent'        => 6.27,
        'LWP::Protocol::https'  => 6.06,
        'JSON::XS'              => 3.04,
        'File::Basename'        => 2.84,
        'Encode'                => 2.60,
        'Carp'                  => 1.3301,
        'MIME::Detect'          => 0.10,
        'HTTP::Request'         => 6.00,
        'Crypt::Digest::SHA256' => 0.061,
    },
    META_MERGE   => {
          requires  => { perl => '5.008008' },
          resources => {
                license     => 'http://dev.perl.org/licenses/',
                repository  => 'https://github.com/vrag86/Mediafire-Api',
                bugtracker  => 'https://github.com/vrag86/Mediafire-Api/issues'
              },
        },
    AUTHOR            => 'vrag <vrag867@gmail.com>',
    LICENSE           => 'perl',
);
