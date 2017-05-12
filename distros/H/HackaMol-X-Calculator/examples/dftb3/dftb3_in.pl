#!/usr/bin/env perl
# DMR May 27, 2014
#
#   perl examples/dftd3_in.pl
#
# generate input.. for dftb3, input is an xyz file with atom symbols (not numbers)
#
# See examples/dftd3.pl for full script that writes input,
# runs program, and processes output.

use Modern::Perl;
use HackaMol;
use HackaMol::X::Calculator;
use Path::Tiny;

my $hack = HackaMol->new( data => "examples/xyzs", );

foreach my $xyz ( grep {!/^symbol_/} $hack->data->children(qr/\.xyz$/) ) {

    my $mol = $hack->read_file_mol($xyz);
    my $sym_xyz = 'symbol_' . $xyz->basename;

    say $sym_xyz;
    my $Calc = HackaMol::X::Calculator->new(
        mol     => $mol,
        scratch => $hack->data,
        in_fn   => $sym_xyz,
        map_in  => sub { shift->mol->print_xyz( $sym_xyz ) }, # pass anonymous subroutine
    );

    $Calc->map_input;

}


