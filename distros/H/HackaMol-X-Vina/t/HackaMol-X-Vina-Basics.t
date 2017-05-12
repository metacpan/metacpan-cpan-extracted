#!/usr/bin/env perl

use strict;
use warnings;
use Test::Moose;
use Test::More;
use Test::Fatal qw(lives_ok dies_ok);
use Test::Dir;
use Test::Warn;
use HackaMol::X::Vina;
use HackaMol;
use Math::Vector::Real;
use File::chdir;
use Cwd;

BEGIN {
    use_ok('HackaMol::X::Vina');
}

my $cwd = getcwd;

# coderef

{    # test HackaMol class attributes and methods

    my @attributes = qw(
                        mol map_in map_out receptor ligand save_mol 
                        center_x center_y center_z size_x size_y size_z
                        num_modes energy_range exhaustiveness seed cpu
                        center size
                       );
    my @methods    = qw(
                        build_command write_input map_input map_output 
                        dock dock_mol
                       );

    my @roles = qw(HackaMol::Roles::ExeRole HackaMol::Roles::PathRole);

    map has_attribute_ok( 'HackaMol::X::Vina', $_ ), @attributes;
    map can_ok( 'HackaMol::X::Vina', $_ ), @methods;
    map does_ok( 'HackaMol::X::Vina', $_ ), @roles;

}

my $mol = HackaMol::Molecule->new();
my $obj;

{    # test basic functionality

    lives_ok {
        $obj = HackaMol::X::Vina->new(
            receptor => 't/lib/receptor.pdbqt',
            ligand   => 't/lib/lig.pdbqt',
            center => V( 0,  1,  2 ),
            size   => V( 10, 11, 12 ),
        );
    }
    'barebones object lives';

    is( $obj->center_x, 0,  "center_x" );
    is( $obj->center_y, 1,  "center_y" );
    is( $obj->center_z, 2,  "center_z" );
    is( $obj->size_x,   10, "size_x" );
    is( $obj->size_y,   11, "size_y" );
    is( $obj->size_z,   12, "size_z" );
    is( $obj->out_fn, "lig_out.pdbqt"  , "output name default" );
    is($obj->in_fn, 'conf.txt', "default configuration file conf.txt" );

    lives_ok {
        $obj = HackaMol::X::Vina->new( 
            mol => $mol , 
            receptor => 't/lib/receptor.pdbqt',
            ligand   => 't/lib/lig.pdbqt',
            in_fn    => 'conf-1.txt',
            out_fn   => 'lig_out-1.pdbqt',
            center   => V( 0,  1,  2 ),
            size     => V( 10, 11, 12 ),
            exe      => "vina",
        );
    }
    'creation of an obj with mol';
    is( $obj->out_fn, "lig_out-1.pdbqt"  , "output name set" );
    is( $obj->in_fn, 'conf-1.txt', "config name set" );
    is( $obj->exe, 'vina', "exe set" );

    dir_not_exists_ok( "t/tmp", 'scratch directory does not exist yet' );

    is(
        $obj->command,
        $obj->exe . " --config " . $obj->in_fn,
        "command set to exe and input"
    );

    lives_ok {
        $obj = HackaMol::X::Vina->new(
            mol     => $mol,
            exe     => "vina",
            receptor => 't/lib/receptor.pdbqt', 
            ligand   => 't/lib/lig.pdbqt', 
            scratch => "t/tmp"
        );
    }
    'Test creation of an obj with exe in_fn and scratch';

    dir_exists_ok( $obj->scratch, 'scratch directory exists' );
    is(
        $obj->command,
        $obj->exe . " --config " . $obj->in_fn,
        "command set to exe and input"
    );
    is( $obj->scratch, "$cwd/t/tmp", "scratch directory" );
 
    $obj->scratch->remove_tree;
    dir_not_exists_ok( "t/tmp", 'scratch directory deleted' );

    lives_ok {
        $obj = HackaMol::X::Vina->new(
            mol     => $mol,
            exe     => "vina",
            scratch => "t/tmp",  
            receptor => 't/lib/receptor.pdbqt', 
            ligand   => 't/lib/lig.pdbqt', 
        );
    }
    'test building of an obj with exisiting scratch  and command attr';

    is(
        $obj->command,
        $obj->exe . " --config conf.txt" ,
        "command set to exe"
    );

    lives_ok {
        $obj = HackaMol::X::Vina->new(
            mol     => $mol,
            exe     => "vina",
            scratch => "t/tmp",  
            receptor => 't/lib/receptor.pdbqt', 
            ligand   => 't/lib/lig.pdbqt',
            command  => 'nonsense', 
       );
    }
    'test building of an obj with exisiting scratch  and command attr';

    is( $obj->command, "nonsense",
        "command attr not overwritten during build" );

    $obj->command( $obj->build_command );
    is( $obj->command, $obj->exe . " --config " . $obj->in_fn,
        "command reset" );

    $obj->scratch->remove_tree;
    dir_not_exists_ok( "t/tmp", 'scratch directory deleted' );

    lives_ok {
        $obj = HackaMol::X::Vina->new(
            mol        => $mol,
            exe        => "vina",
            in_fn      => "foo.inp",
            scratch    => "t/tmp",
            out_fn     => "foo.out",
            command    => "nonsense",
            exe_endops => "tackon",
            receptor => 't/lib/receptor.pdbqt', 
            ligand   => 't/lib/lig.pdbqt', 
        );
    }
    'test building of an obj with out_fn';

    $obj->command( $obj->build_command );
    is(
        $obj->command,
        $obj->exe . " --config " . $obj->in_fn->stringify,
        "big command ignores redirect to output"
    );

    $obj->scratch->remove_tree;
    dir_not_exists_ok( "t/tmp", 'scratch directory deleted' );

}

{    # test the map_in and map_out

    $obj = HackaMol::X::Vina->new(
        mol            => $mol,
        receptor       => 't/lib/receptor.pdbqt', 
        ligand         => 't/lib/lig.pdbqt', 
        in_fn          => "foo.inp",
        center         => V( 0, 1, 2 ),
        size           => V( 20, 20, 20 ),
        cpu            => 4,
        num_modes      => 1,
        exhaustiveness => 12,
        exe            => '~/bin/vina',
        scratch        => 't/tmp',
        homedir        => '.',
    );

    my $input = $obj->map_input; 
    $CWD = $obj->scratch;
    my $input2 = $obj->in_fn->slurp;
    is( $input, $input2,
        "input written to scratch is that returned by map_input" );
    $CWD = $obj->homedir;
    $obj->scratch->remove_tree;
    dir_not_exists_ok( "t/tmp", 'scratch directory deleted' );

}

done_testing();

