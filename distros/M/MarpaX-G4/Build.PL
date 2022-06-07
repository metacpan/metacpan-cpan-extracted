#!/usr/bin/perl -w

use Module::Build;

my $build = Module::Build->new
(
    module_name    => 'MarpaX::G4',
    dist_author    => 'Axel Zuber',
    dist_abstract  => 'Release 0.9 of MarpaX::G4',
    requires => {
                    'perl'          => '5.24.0',
                    'Marpa::R2'     => '8.0.0',
                    'Module::Build' => '0.4.2',
                },
    license        => 'lgpl3',
    create_readme  => 0,
);

$build->create_build_script;

exit
