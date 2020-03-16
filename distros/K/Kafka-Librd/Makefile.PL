use 5.008;
use strict;
use warnings;
use Config;
use ExtUtils::MakeMaker 6.64;
use Alien::Librdkafka 0.9.3;
use Alien::Base::Wrapper qw( Alien::Librdkafka !export );
use File::Spec ();

WriteMakefile(
    NAME                => 'Kafka::Librd',
    AUTHOR              => q{Graham Ollis <plicease@cpan.org>},
    LICENSE             => 'perl',
    VERSION_FROM        => 'lib/Kafka/Librd.pm',
    ABSTRACT_FROM       => 'lib/Kafka/Librd.pm',
    OBJECT              => 'Rdkafka.o rdkafkaxs.o',
    PL_FILES            => {},
    PREREQ_PM => {
        'Exporter::Lite' => 0,
    },
    TEST_REQUIRES => {
        'Test::More' => 0.94,
    },
    CONFIGURE_REQUIRES => {
        'Alien::Base::Wrapper' => '0',
        'Alien::Librdkafka' => '0.9.3',
        'ExtUtils::MakeMaker' => 6.64,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Kafka-Librd-* const_xs.inc' },
    depend              => { 'Rdkafka.c' => 'const_xs.inc' },
    META_MERGE => {
        resources => {
            homepage   => 'https://github.com/plicease/Kafka-Librd',
            bugtracker => 'https://github.com/plicease/perl-Kafka-Librd/issues',
            repository => 'git://github.com/plicease/perl-Kafka-Librd',
            license    => 'http://dev.perl.org/licenses/',
        },
        x_contributors => [
            'Pavel Shaydo <zwon@cpan.org>',
            'Graham Ollis <plicease@cpan.org>',
        ],
    },
    Alien::Base::Wrapper->mm_args,
);

sub MY::postamble {
    "const_xs.inc : @{[ File::Spec->catfile(qw( utils generate_const.pl )) ]}\n" .
    "\t\$(FULLPERL) @{[ File::Spec->catfile(qw( utils generate_const.pl )) ]}\n";
}
