#!/usr/bin/env perl
# DMR May 27, 2014
#
#   perl examples/g09_pdb.pl ~/some/path
#
# pull energies from a directory (~/some/path) of Gaussian outputs
# and print in kcal/mol.
#
# The regex in output_map will return the last match. This is relevant
#   for optimizations that will print an energy for each step. As
#   an exercise, create a new script, based on this one, that takes
#   output files from optimization runs (~/some/path/*_opt.out) and
#   calculates the energy difference between the initial structure and
#   the final structure.
#

use Modern::Perl;
use HackaMol;
use HackaMol::X::Calculator;
use Path::Tiny;

my $path = shift || die "pass path to gaussian outputs";

my $hack = HackaMol->new( data => $path, );

foreach my $out ( $hack->data->children(qr/opt\.out$/) ) {

    my $Calc = HackaMol::X::Calculator->new(
        out_fn  => $out,
        map_out => \&output_map,
    );

    my $energy = $Calc->map_output(627.51);

    printf( "%-40s: %10.2f\n", $Calc->out_fn->basename, $energy );

}

#  our function to pull the final energy from an output

sub output_map {
    my $calc = shift;
    my $conv = shift;
    my $re   = qr/-\d+.\d+/;

    # match the slurped string for regex matched
    # multiple scf dones for optimizations... take last one
    # http://perldoc.perl.org/perlop.html#Regexp-Quote-Like-Operators
    my @energys = $calc->out_fn->slurp =~ m/SCF Done:.*(${re})/g;
    return ( $energys[-1] * $conv );
}
