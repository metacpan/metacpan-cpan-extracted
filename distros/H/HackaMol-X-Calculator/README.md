HackaMol-X-Calculator
=====================

VERSION 0.01
========

please see *[HackaMol::X::Calculator on MetaCPAN](https://metacpan.org/release/DEMIAN/HackaMol-X-Calculator) for formatted documentation.

SYNOPSIS
========

       use HackaMol;
       use HackaMol::X::Calculator;
       use Path::Tiny;
       
       my $path = shift || die "pass path to gaussian outputs";
       
       my $hack = HackaMol->new( data => $path, );
       
       foreach my $out ( $hack->data->children(qr/\.out$/) ) {
  
           my $Calc = HackaMol::X::Calculator->new(
               out_fn  => $out,
               map_out => \&output_map,
           );
       
           my $energy = $Calc->map_output(627.51);
       
           printf( "%-40s: %10.6f\n", $Calc->out_fn->basename, $energy );
       
       }
       
       #  our function to map molec info from output
       
       sub output_map {
           my $calc = shift;
           my $conv = shift;
           my $re   = qr/-\d+.\d+/;
           my @energys = $calc->out_fn->slurp =~ m/SCF Done:.*(${re})/g;
           return ( $energys[-1] * $conv );
       }

DESCRIPTION
============

The HackaMol::X::Calculator extension generalizes molecular calculations using external programs. 
The Calculator class consumes the HackaMol::X::ExtensionRole role, which manage the running of executables... 
perhaps on files; perhaps in directories.  This extension is intended to provide a 
simple example of interfaces with external programs. This is a barebones use of the ExtensionRole that is 
intended to be flexible. See the examples and testing directory for use of the map_in and map_out functions
inside and outside of the map_input and map_output functions.  Extensions with more rigid and encapsulated 
APIs can evolve from this starting point. In the synopsis, a Gaussian output is processed for the SCF Done
value (a classic scripting of problem computational chemists).  See the examples and tests to learn how the 
calculator can be used to: 

  1. generate inputs 
  2. run programs
  3. process outputs

via interactions with HackaMol objects.

