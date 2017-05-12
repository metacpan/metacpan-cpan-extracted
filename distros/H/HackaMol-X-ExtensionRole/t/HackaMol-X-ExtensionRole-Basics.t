#!/usr/bin/env perl
{
  package Test::Extension;
  use Moose;
  use MooseX::StrictConstructor;
  use Moose::Util::TypeConstraints;
  use namespace::autoclean;

  with qw(HackaMol::X::ExtensionRole);

  sub _build_map_in{
    my $sub_cr = sub { return (@_) };
    return $sub_cr;
  }

  sub _build_map_out{
    my $sub_cr = sub { return (@_) };
    return $sub_cr;
  }

  sub build_command {
    # exe -options file.inp -moreoptions > file.out
    my $self = shift;
    return 0 unless $self->exe;
    my $cmd;
    $cmd = $self->exe;
    $cmd .= " " . $self->in_fn->stringify    if $self->has_in_fn;
    $cmd .= " " . $self->exe_endops          if $self->has_exe_endops;
    $cmd .= " > " . $self->out_fn->stringify if $self->has_out_fn;

    # no cat of out_fn because of options to run without writing, etc
    return $cmd;
  }

}

use strict;
use warnings;
use Test::Moose;
use Test::More;
use Test::Fatal qw(lives_ok dies_ok);
use Test::Dir;
use Test::Warn;
use HackaMol;
use Math::Vector::Real;
use File::chdir;
use Cwd;

BEGIN {
    use_ok('Test::Extension');
}

my $cwd = getcwd;

# coderef

{    # test HackaMol class attributes and methods

    my @attributes = qw(mol map_in map_out);
    my @methods    = qw(map_input map_output);

    my @roles = qw(HackaMol::ExeRole HackaMol::PathRole);

    map has_attribute_ok( 'Test::Extension', $_ ), @attributes;
    map can_ok( 'Test::Extension', $_ ), @methods;
    map does_ok( 'Test::Extension', $_ ), @roles;

}

my $mol = HackaMol::Molecule->new();
my $obj;

{    # test basic functionality
    dir_not_exists_ok( "t/tmp", 'scratch directory doesnt exist' );

    lives_ok {
        $obj = Test::Extension->new();
    }
    'creation without required mol lives';

    lives_ok {
        $obj = Test::Extension->new( mol => $mol );
    }
    'creation of an obj with mol';

    is( $obj->build_command, 0, "build command returns 0 with no exe" );

    lives_ok {
        $obj = Test::Extension->new( mol => $mol, exe => "foo.exe" );
    }
    'creation of an obj with exe';
    
    dir_not_exists_ok( "t/tmp", 'scratch directory does not exist yet' );

    is( $obj->build_command, $obj->exe, "build command returns exe" );

    lives_ok {
        $obj = Test::Extension->new(
            mol     => $mol,
            exe     => "foo.exe <",
            in_fn   => "foo.inp",
            scratch => "t/tmp"
        );
    }
    'Test creation of an obj with exe in_fn and scratch';

    is(
        $obj->build_command,
        $obj->exe . " " . $obj->in_fn->stringify,
        "build command with input"
    );

    is( $obj->scratch, "$cwd/t/tmp", "scratch directory" );

    lives_ok {
        $obj = Test::Extension->new(
            mol        => $mol,
            exe        => "foo.exe <",
            in_fn      => "foo.inp",
            scratch    => "t/tmp",
            command    => "nonsense",
            exe_endops => "tackon",
        );
    }
    'test building of an obj exe_endops command attr';

    is(
        $obj->build_command,
        $obj->exe . " " . $obj->in_fn . " " . $obj->exe_endops,
        "build command with exe_endops"
    );


    lives_ok {
        $obj = Test::Extension->new(
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

    dir_not_exists_ok( "t/tmp", 'scratch directory never created' );

}

{    # test the map_in and map_out

    $obj = Test::Extension->new(
        mol     => $mol,
        in_fn   => "foo.inp",
    );

    my @tv          = qw(1 2 3 4);
    my @def_map_in  = &{ $obj->map_in }(@tv);
    my @def_map_out = &{ $obj->map_out }(@tv);

    is_deeply( \@tv, \@def_map_in, 'default map_in returns what you send in' );
    is_deeply( \@tv, \@def_map_out,
        'default map_out returns what you send in' );
 
    dir_not_exists_ok( "t/tmp", 'scratch directory never created' );

}

done_testing();

