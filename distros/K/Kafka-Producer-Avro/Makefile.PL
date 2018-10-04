#!/usr/bin/env perl

use strict;
use warnings;
use 5.010;

use Config;
use inc::Module::Install;

if ( $^O eq 'MSWin32' || $^O eq 'solaris' ||  $^O eq 'cygwin' ) {
    print STDERR "OS unsupported: $^O\n";
    exit( 255 );
}

readme_from('lib/Kafka/Producer/Avro.pm');

my %config = (
    NAME                => 'Kafka::Producer::Avro',
    VERSION_FROM        => 'lib/Kafka/Producer/Avro.pm',  # finds $VERSION
    MIN_PERL_VERSION    => '5.010',
    PREREQ_PM           => {            # more to the list $Module::CoreList::version{5.010}
		'JSON::XS'					=> '3.02',
		'Kafka::Producer'			=> '1.07',
		'Avro::BinaryEncoder'		=> 0,
		'Avro::Schema'				=> 0,
		'Confluent::SchemaRegistry'	=> '0.03'
    },
    TEST_REQUIRES       => {            # more to the list $Module::CoreList::version{5.010}
		'Math::BigInt'				=> '1.89',
		'Test::Exception'			=> '0.43'
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
