use strict;
use warnings;
use Module::Build;
use utf8;


my $builder = Module::Build->new(
    module_name         => 'File::Parser::Role',
    license             => 'perl',
    dist_author         => 'Torbjørn Lindahl <torbjorn.lindahl@gmail.com>',
    dist_version_from   => 'lib/File/Parser/Role.pm',
    requires => {
        'Moo'                  => '1.006001',
        'Moo::Role'            => '1.006001',
        'IO::String'           => '1.08',
        'Pod::Coverage::Moose' => '0.02',
        'Test::Most'           => '0.34',
        'Test::Perl::Critic'   => '1.02',
        'Test::Pod'            => '1.48',
        'Test::Pod::Coverage'  => '1.08',
        'Test::Output'         => '1.02',
        'Test::Warnings'       => '0.010',
        'MooX::Aliases'        => '0.001',
    },
    recommends => {
        'Path::Tiny'           => 0,
        'Mojo::Path'           => 0,
        'IO::All'              => 0,
    },
    add_to_cleanup      => [ 'File-Parser-Role-*' ],
);

$builder->create_build_script();
