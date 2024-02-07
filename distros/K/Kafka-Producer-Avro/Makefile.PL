#!/usr/bin/env perl

use strict;
use warnings;
use 5.010;

use ExtUtils::MakeMaker;

if ( $^O eq 'MSWin32' || $^O eq 'solaris' ||  $^O eq 'cygwin' ) {
    print STDERR "OS unsupported: $^O\n";
    exit( 255 );
}

my $package = 'Kafka::Producer::Avro';
my $path_to_package = 'lib/Kafka/Producer/Avro.pm';

`perldoc -uT $path_to_package | pod2text - README`;
`perldoc -uT $path_to_package | pod2markdown - README.md`; # useful for GitHub repo home

my %config = (
    NAME                => $package,
    VERSION_FROM        => $path_to_package,  # finds $VERSION
    MIN_PERL_VERSION    => '5.010',
    PREREQ_PM           => {            # more to the list $Module::CoreList::version{5.010}
		'JSON::XS'					=> 'v4.30.0',
		'Kafka::Producer'			=> 'v1.8.0',
		'Avro::BinaryEncoder'		=> 'v1.10.1',
		'Avro::Schema'				=> 'v1.10.1',
		'Confluent::SchemaRegistry'	=> 'v1.0.0',
        'Memoize'                   => '0'
    },
    TEST_REQUIRES       => {            # more to the list $Module::CoreList::version{5.010}
		'Math::BigInt'				=> '1.89',
		'Test::Exception'			=> '0.43',
        'Time::HiRes'               => '0'
    },
    META_MERGE          => {
        no_index                => {
            directory               => [
                't',
                'inc',
            ]
        },
        'meta-spec'             => { version => 2 },
        resources               => {
            bugtracker              => {
               web                      => 'https://github.com/alivraghi/Kafka-Producer-Avro/issues',
            },
            homepage                => 'https://github.com/alivraghi/Kafka-Producer-Avro',
            repository              => {
                type                    => 'git',
                url                     => 'git@github.com/Kafka-Producer-Avro.git',
                web                     => 'https://github.com/alivraghi/Kafka-Producer-Avro.git',
            },
        },
    },
    ( $] >= 5.005 ?                             ## Add these new keywords supported since 5.005
        (
            ABSTRACT            => 'Avro message producer for Apache Kafka.',
            AUTHOR              => 'Alvaro Livraghi',
        ) : ()
    ),
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    realclean           => { FILES => "inc Kafka-Producer-Avro-*.tar.gz" },
    LICENSE             => 'perl',
#    NO_MYMETA           => 1,
);

ExtUtils::MakeMaker::WriteMakefile( %config );
