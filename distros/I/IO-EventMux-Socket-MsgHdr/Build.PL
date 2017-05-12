use strict;
use warnings;

use Module::Build;

my $builder = Module::Build->new(
    module_name        => 'IO::EventMux::Socket::MsgHdr',
    license            => 'perl',
    dist_author        => 'Michael J. Pomraning <mjp@pilcrow.madison.wi.us>'
                         .'Troels Liebe Bentsen <troels@infopro.dk>',
    dist_version_from  => 'lib/IO/EventMux/Socket/MsgHdr.pm',
    create_readme      => 1,
    create_makefile_pl => 'passthrough',
    build_requires => {
        'Test::More'         => 0,
        'Socket'             => 0,
        'ExtUtils::CBuilder' => 0
    },
    requires => {
        'perl'     => '>= 5.8.0',
        'XSLoader' => 0,
        'Exporter' => 0,
    }, 
    include_dirs => ['-I.'],
    add_to_cleanup => [ 
        'IO-EventMux-Socket-MsgHdr*',
        'Makefile',
        'blib',
    ],
);

$builder->create_build_script();
