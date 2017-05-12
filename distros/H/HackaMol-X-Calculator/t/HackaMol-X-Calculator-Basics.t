#!/usr/bin/env perl

use strict;
use warnings;
use Test::Moose;
use Test::More;
use Test::Fatal qw(lives_ok dies_ok);
use Test::Dir;
use Test::Warn;
use HackaMol::X::Calculator;
use HackaMol;
use Math::Vector::Real;
use File::chdir;
use Cwd;

BEGIN {
    use_ok('HackaMol::X::Calculator');
}

my $cwd = getcwd;

# coderef

{    # test HackaMol class attributes and methods

    my @attributes = qw(mol map_in map_out);
    my @methods    = qw(map_input map_output);

    my @roles = qw(HackaMol::Roles::ExeRole HackaMol::Roles::PathRole);

    map has_attribute_ok( 'HackaMol::X::Calculator', $_ ), @attributes;
    map can_ok( 'HackaMol::X::Calculator', $_ ), @methods;
    map does_ok( 'HackaMol::X::Calculator', $_ ), @roles;

}

my $mol = HackaMol::Molecule->new();
my $obj;

{    # test basic functionality

    lives_ok {
        $obj = HackaMol::X::Calculator->new();
    }
    'creation without required mol lives';

    lives_ok {
        $obj = HackaMol::X::Calculator->new( mol => $mol );
    }
    'creation of an obj with mol';

    is( $obj->build_command, 0, "build_command set to 0 with no exe" );
    dir_not_exists_ok( "t/tmp", 'scratch directory does not exist yet' );

    lives_ok {
        $obj = HackaMol::X::Calculator->new( mol => $mol, exe => "foo.exe" );
    }
    'creation of an obj with exe';

    dir_not_exists_ok( "t/tmp", 'scratch directory does not exist yet' );

    is( $obj->command, $obj->exe, "command set to exe" );

    lives_ok {
        $obj = HackaMol::X::Calculator->new(
            mol     => $mol,
            exe     => "foo.exe <",
            in_fn   => "foo.inp",
            scratch => "t/tmp"
        );
    }
    'Test creation of an obj with exe in_fn and scratch';

    dir_exists_ok( $obj->scratch, 'scratch directory exists' );
    is(
        $obj->command,
        $obj->exe . " " . $obj->in_fn,
        "command set to exe and input"
    );
    is( $obj->scratch, "$cwd/t/tmp", "scratch directory" );

    lives_ok {
        $obj = HackaMol::X::Calculator->new(
            mol        => $mol,
            exe        => "foo.exe <",
            in_fn      => "foo.inp",
            scratch    => "t/tmp",
            command    => "nonsense",
            exe_endops => "tackon",
        );
    }
    'test building of an obj with exisiting scratch  and command attr';

    is( $obj->command, "nonsense",
        "command attr not overwritten during build" );
    $obj->command( $obj->build_command );
    is(
        $obj->command,
        $obj->exe . " " . $obj->in_fn . " " . $obj->exe_endops,
        "command reset"
    );

    $obj->scratch->remove_tree;
    dir_not_exists_ok( "t/tmp", 'scratch directory deleted' );

    lives_ok {
        $obj = HackaMol::X::Calculator->new(
            mol        => $mol,
            exe        => "foo.exe <",
            in_fn      => "foo.inp",
            scratch    => "t/tmp",
            out_fn     => "foo.out",
            command    => "nonsense",
            exe_endops => "tackon",
        );
    }
    'test building of an obj with out_fn';

    $obj->command( $obj->build_command );
    is(
        $obj->command,
        $obj->exe . " "
          . $obj->in_fn->stringify . " "
          . $obj->exe_endops . " > "
          . $obj->out_fn->stringify,
        "big command with redirect to output"
    );

    $obj->scratch->remove_tree;
    dir_not_exists_ok( "t/tmp", 'scratch directory deleted' );

}

{    # test the map_in and map_out

    $obj = HackaMol::X::Calculator->new(
        mol     => $mol,
        in_fn   => "foo.inp",
    );

    my @tv          = qw(1 2 3 4);
    my @def_map_in  = &{ $obj->map_in }(@tv);
    my @def_map_out = &{ $obj->map_out }(@tv);

    is_deeply( \@tv, \@def_map_in, 'default map_in returns what you send in' );
    is_deeply( \@tv, \@def_map_out,
        'default map_out returns what you send in' );

}

done_testing();

