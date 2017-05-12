use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'Google::Cloud::Speech',
    AUTHOR        => 'Prajith NDZ <prajith@ndimensionz.com, prajithpalakkuda@gmail.com>',
    VERSION_FROM  => 'lib/Google/Cloud/Speech.pm',
    ABSTRACT_FROM => 'lib/Google/Cloud/Speech.pm',
    PL_FILES      => {},
    PREREQ_PM     => {
        'Mojolicious'                => 0,
        'Mojo::UserAgent'            => 0,
        'MIME::Base64'               => 0,
        'Mojo::File'                 => 0,
        'Mojo::JWT::Google'          => 0,
        'Crypt::OpenSSL::RSA'        => 0,
        'Carp'                       => 0,
    },
    META_MERGE => {
        resources => {
            license     => 'http://dev.perl.org/licenses/',
            bugtracker  => 'https://github.com/Prajithp/p5-Google-Cloud-Speech/issues',
            repository  => 'https://github.com/Prajithp/p5-Google-Cloud-Speech',
        },
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'Google-Cloud-Speech*' },
);

1
