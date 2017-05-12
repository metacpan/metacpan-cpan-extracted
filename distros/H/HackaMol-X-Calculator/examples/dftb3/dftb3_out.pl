#!/usr/bin/env perl
# DMR May 27, 2014
#
#   perl examples/dftd3_out.pl
#
# process the output
#
# See examples/dftd3.pl for full script that writes input,
# runs program, and processes output.

use Modern::Perl;
use HackaMol;
use HackaMol::X::Calculator;
use Path::Tiny;

my $hack = HackaMol->new( data => "examples/xyzs", );

foreach my $out ( $hack->data->children(qr/symbol_.+\.out$/) ) {

    my $Calc = HackaMol::X::Calculator->new(
        scratch => $hack->data,
        out_fn  => $out,
        map_out => \&output_map,

    );

    my $energy = $Calc->map_output(627.51);

    printf( "Energy from xyz file: %10.6f\n", $energy );

}

#  our function to map molec info from output

sub output_map {
    my $calc = shift;
    my $conv = shift;
    my $re   = qr/-\d+.\d+/; 
    my @energys  = $calc->out_fn->slurp =~ m /Edisp \/kcal,au:\s+${re}\s+(${re})/g;
    return ( $energys[-1] * $conv );
}
