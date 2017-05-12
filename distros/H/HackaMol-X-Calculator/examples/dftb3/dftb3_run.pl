#!/usr/bin/env perl
# DMR May 27, 2014
#
#   perl examples/dftd3_run.pl
#
# run the program, generate output
#
# See examples/dftd3.pl for full script that writes input,
# runs program, and processes output.
use Modern::Perl;
use HackaMol;
use HackaMol::X::Calculator;
use Path::Tiny;

my $hack = HackaMol->new( data => "examples/xyzs", );

foreach my $xyz ( $hack->data->children(qr/symbol_.+\.xyz$/) ) {

    my $in  = $xyz->basename ;  
    my $out = $in =~ s/\.xyz/\.out/r; 

    my $Calc = HackaMol::X::Calculator->new(
        scratch    => $hack->data,
        in_fn      => $in,
        out_fn     => $out,
        exe        => '~/bin/dftd3',
        exe_endops => '-func b3pw91 -bj',
    );

    $Calc->capture_sys_command;

}

