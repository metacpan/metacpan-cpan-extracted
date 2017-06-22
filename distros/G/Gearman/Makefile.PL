use strict;
use warnings;

use ExtUtils::MakeMaker 6.48;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME     => "Gearman::Client",
    DISTNAME => "Gearman",
    AUTHOR   => 'Brad Fitzpatrick <brad@danga.com>',
    ABSTRACT =>
        "Client and worker libraries for gearman job dispatch dispatch. Server is in separate package.",
    VERSION_FROM     => "lib/Gearman/Client.pm",
    LICENSE          => 'perl',
    MIN_PERL_VERSION => '5.008001',
    BUILD_REQUIRES   => {
        "File::Which"       => 0,
        "IO::Socket::IP"    => 0,
        "IO::Socket::SSL"   => 0,
        "Perl::OSType"      => 0,
        "Proc::Guard"       => "0.07",
        "Storable"          => 0,
        "Test::Exception"   => 0,
        "Test::More"        => 0,
        "Test::TCP"         => "2.17",
        "Test::Timer"       => 0,
        "version"           => "0.77",
    },
    PREREQ_PM => {
        "Carp"            => 0,
        "IO::Select"      => 0,
        "IO::Socket::IP"  => 0,
        "IO::Socket::SSL" => 0,
        "List::MoreUtils" => 0,
        "POSIX"           => 0,
        "Scalar::Util"    => 0,
        "Socket"          => 0,
        "Storable"        => 0,
        "String::CRC32"   => 0,
        "Time::HiRes"     => 0,    # Usually core now
        "fields"          => 0,
        "version"         => "0.77",
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
            bugtracker =>
                { web => 'https://github.com/p-alik/perl-Gearman/issues' },
            repository => {
                type => 'git',
                url  => 'https://github.com/p-alik/perl-Gearman.git',
                web  => 'https://github.com/p-alik/perl-Gearman',
            },
        },
    },
);

1;
