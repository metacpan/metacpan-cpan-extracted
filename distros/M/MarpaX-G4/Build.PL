#!/usr/bin/perl -w

use Module::Build;

my @always_required = qw(
    Carp
    Cwd
    Data::Dumper
    File::Temp
    Test::More
    Time::Piece
);

my $build = Module::Build->new
(
    module_name    => 'MarpaX::G4',
    dist_author    => 'Axel Zuber',
    dist_abstract  => 'Release 1.0 of MarpaX::G4',
    dist_version   => '1.0.1',
    configure_requires => {
                    'Module::Build' => '0.4.2',
    },
    requires => {
                    'perl'          => '5.24.0',
                    'Marpa::R2'     => '8.0.0',
                },
    license        => 'lgpl3',
    create_readme  => 0,
);

$build->create_build_script;

exit
