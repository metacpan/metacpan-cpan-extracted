use strict;
use warnings;

use ExtUtils::MakeMaker;

my %required_for_test = (
    'Test::SharedFork' => 0,
);

WriteMakefile(
    NAME              => 'Log::Dispatch::ZMQ',
    VERSION_FROM      => 'lib/Log/Dispatch/ZMQ.pm',
    ABSTRACT          => 'ZMQ backend for Log::Dispatch',
    PREREQ_PM         => {
        parent             => 0,
        ZMQ                => 0,
        'Log::Dispatch'    => 0,
        Carp               => 0,
        ($ExtUtils::MakeMaker::VERSION < 6.64 ? (%required_for_test) : ()),
    },
    ($] >= 5.005 ?
      (
      ($ExtUtils::MakeMaker::VERSION >= 6.64 ? (TEST_REQUIRES => \%required_for_test) : () ),
      AUTHOR         => 'Tomasz Czepiel <tjmc@cpan.org>') : ()),
    LICENSE           => 'perl',
    META_MERGE => {
        resources => {
            repository => 'git://github.com/tczepiel/perl-log-dispatch-zmq.git',
        },
    },
);
