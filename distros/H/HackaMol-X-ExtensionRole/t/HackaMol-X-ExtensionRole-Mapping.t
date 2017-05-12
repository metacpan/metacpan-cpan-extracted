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

  sub BUILD {
    my $self = shift;

    if ( $self->has_scratch ) {
        $self->scratch->mkpath unless ( $self->scratch->exists );
    }
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

my $cwd = getcwd;
my $mol = HackaMol::Molecule->new();
my $obj;
my $expect = '#hf/sto-3g test

hartree fock calculation with STO-3G basis

0 1
O   0.000000  0.117958  0.000000
H   0.761499 -0.471830  0.000000
H  -0.761499 -0.471830  0.000000

';

my $header = '#hf/sto-3g test

hartree fock calculation with STO-3G basis

';

$mol->push_atoms(
    HackaMol::Atom->new(
        Z      => 8,
        coords => [ V( 0.000000, 0.117958, 0.000000 ) ]
    )
);
$mol->push_atoms(
    HackaMol::Atom->new(
        Z      => 1,
        coords => [ V( 0.761499, -0.471830, 0.000000 ) ]
    )
);
$mol->push_atoms(
    HackaMol::Atom->new(
        Z      => 1,
        coords => [ V( -0.761499, -0.471830, 0.000000 ) ]
    )
);

# generate an input file familiar to chemists
my $map_in = sub {
    my $calc   = shift;    # this is the Calculator object
    my $header = shift;
    my ( $q, $mult ) = ( shift, shift );
    my @atoms =
      map { sprintf( "%-s %10.6f%10.6f%10.6f\n", $_->symbol, @{ $_->xyz } ) }
      $calc->mol->all_atoms;
    my $input = $header;
    $input .= "$q $mult\n";
    $input .= $_ foreach @atoms;
    $input .= "\n";
    $calc->in_fn->spew($input);
    return $input;
};

# copy the input to ouput
my $command = "cp foo.inp foo.out";

# some fictional output
my $map_out = sub {
    my $calc = shift;    # this is the Calculator object
    my $mvr  = shift;
    my @lines = grep { m/\d\.\d{6}/ } $calc->out_fn->lines;
    my @atoms = map {
        my @atbit = split;
        HackaMol::Atom->new(
            symbol => $atbit[0],
            coords => [ V( @atbit[ 1, 2, 3 ] ) + $mvr ]
          )
    } @lines;

    my $molnew = HackaMol::Molecule->new( atoms => [@atoms] );
    return abs( $calc->mol->COM - $molnew->COM );
};

$obj = Test::Extension->new(
    mol     => $mol,
    map_in  => $map_in,
    in_fn   => "foo.inp",
    map_out => $map_out,
    out_fn  => "foo.out",
    command => $command,
);

$obj->map_input( $header, 0, 1 );
my $input = $obj->in_fn->slurp;
is( $input, $expect, "input written in home as expected" );
$obj->capture_sys_command;
my $distance = $obj->map_output( V( 2, 2, 2 ) );
my $output = $obj->out_fn->slurp;
is( $output, $expect, "command cp input output" );
is( sprintf( "%.4f", $distance ),
    sprintf( "%.4f", sqrt(12) ), "output mapped" );

$obj->in_fn->remove;
$obj->out_fn->remove;

dir_not_exists_ok( "t/tmp", 'scratch directory does not exist' );

{    # test writing input in scratch!

    $obj = Test::Extension->new(
        mol => $mol,

        #map_in => $map_in,
        #in_fn  => "foo.inp",
        scratch => "t/tmp",
    );

    $obj = Test::Extension->new(
        mol => $mol,

        #map_in => $map_in,
        in_fn   => "foo.inp",
        out_fn  => "foo.out",
        scratch => "t/tmp",
    );

    $obj = Test::Extension->new(
        mol     => $mol,
        map_in  => $map_in,
        map_out => $map_out,

        #in_fn  => "foo.inp",
        scratch => "t/tmp",
    );

    $obj = Test::Extension->new(
        mol     => $mol,
        map_in  => $map_in,
        in_fn   => "foo.inp",
        map_out => $map_out,
        out_fn  => "foo.out",
        scratch => "t/tmp",
        homedir => ".",

        #command => $command,
    );

    my $input0 = $obj->map_input( $header, 0, 1 );
    $CWD = $obj->scratch;
    my $input1 = $obj->in_fn->slurp;

    is( $input0, $expect, "input as expected" );
    is( $input1, $expect, "input written in scratch as expected" );

    my ( $stdout, $stderr, $exit ) = $obj->capture_sys_command;
    is( $stdout, 0, 'return 0 if no command' );
    $obj->command($command);
    ( $stdout, $stderr, $exit ) = $obj->capture_sys_command;

    my $distance = $obj->map_output( V( 1, 1, 1 ) );
    my $output = $obj->out_fn->slurp;
    is( $output, $expect, "command cp input output" );

    is(
        sprintf( "%.4f", $distance ),
        sprintf( "%.4f", sqrt(3) ),
        "output mapped"
    );

    isnt( $obj->out_fn->exists, undef, "output exists" );
    $obj->out_fn->remove;
    is( $obj->out_fn->exists, undef, "output removed" );
    ( $stdout, $stderr, $exit ) = $obj->capture_sys_command($command);
    $output = $obj->out_fn->slurp;
    is( $output, $expect, "capture_sys_command with passed command" );

    is(
        sprintf( "%.4f", $distance ),
        sprintf( "%.4f", sqrt(3) ),
        "output mapped"
    );

    $obj->command( "cat " . $obj->in_fn );
    ( $stdout, $stderr, $exit ) = $obj->capture_sys_command;
    is( $stdout, $expect, "captured output from cat input" );

    $CWD = $obj->homedir;
    $obj->scratch->remove_tree;

    dir_not_exists_ok( "t/tmp", 'scratch directory deleted' );

}

done_testing();

