use strict;
use warnings;

use lib "./inc";

use Test::Run::Builder;

my $build = Test::Run::Builder->new(
    'module_name' => "IO::Socket::INET6",
    dist_version_from   => 'lib/IO/Socket/INET6.pm',
    dist_abstract => 'Object interface for AF_INET/AF_INET6 domain sockets',
    'requires' =>
    {
        'Carp' => 0,
        'Errno' => 0,
        'Exporter' => 0,
        'IO::Socket' => 0,
        'Socket' => 0,
        'Socket6' => "0.12",
        'perl' => '5.008',
        'strict' => 0,
        'warnings' => 0,
    },
    build_requires =>
    {
        'Test::More' => 0,
    },
    configure_requires =>
    {
        'Module::Build' => '0.36',
    },
    'license' => "perl",
    create_makefile_pl => 'traditional',
    meta_merge =>
    {
        resources =>
        {
            repository => "https://bitbucket.org/shlomif/perl-io-socket-inet6",
        },
        keywords =>
        [
            "inet6",
            "input",
            "internet",
            "ipv6",
            "network",
            "networking",
            "output",
            "socket",
            "sockets",
        ],
    },
);

$build->create_build_script;
