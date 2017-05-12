#!/usr/bin/perl
use Module::Build;
my $build = Module::Build->new(
    module_name         => 'Minecraft::RCON',
    license             => '',
    create_makefile_pl  => 'small',
    PL_files            => { 
        'Bin.PL' => 'bin/mcrcon.pl' 
    },
    requires            => {
        'perl'              => '5.8.8',
        'IO::Socket'        => '1.18',
        'Term::ANSIColor'   => '3.02',
    },
);

$build->create_build_script;

