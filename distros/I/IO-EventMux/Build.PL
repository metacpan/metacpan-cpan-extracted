use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name        => 'IO::EventMux',
    license            => 'perl',
    dist_author        => 'Jonas Jensen <jonas@infopro.dk>'
                         .',Troels Liebe Bentsen <troels@infopro.dk>',
    dist_version_from  => 'lib/IO/EventMux.pm',
    create_readme      => 1,
    create_makefile_pl => 'passthrough',
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'perl'                         => '>= 5.8.0',
        'Carp'                         => 0,
        'Socket'                       => 0,
        'IO::Select'                   => 0,
        'IO::Socket'                   => 0,
        'Scalar::Util'                 => 0,
        'Fcntl'                        => 0,
        'Errno'                        => 0,
        'IO::EventMux::Socket::MsgHdr' => 0,
    }, 
    add_to_cleanup => [ 
        'IO-EventMux-*',
        'Makefile',
        'blib',
    ],
);

$builder->create_build_script();
