#!/usr/bin/env perl

use strict;
use warnings;
use lib 'lib';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'ImgurAPI::Client',
    AUTHOR       => 'Dillan Hildebrand',
    VERSION_FROM => 'lib/ImgurAPI/Client.pm',
    LICENSE      => 'MIT',
    PREREQ_PM    => {
        'JSON'                  => '2.90',
        'LWP::UserAgent'        => '6.05',
        'HTTP::Request::Common' => '6.07',
        'Data::Dumper'          => '2.154',
        'Scalar::Util'          => '1.42',
        'Mozilla::CA'           => '20240313',
        'Test::Exception'       => '0.43',
        'Test::More'            => '1.302162',
        'XML::LibXML'           => '2.0110',
    },
    META_MERGE => {
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/selftaught/ImgurAPI.git',
                web  => 'https://github.com/selftaught/ImgurAPI',
            }
        },
    }
);
