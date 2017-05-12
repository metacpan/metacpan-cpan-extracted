#!/usr/bin/env perl
# DMR April 9, 2014
#   
#   perl readpdb_select_write.pl some.pdb   
#
# reads pdb (via shift of @ARGV) 
# prints a selection to STDOUT
#
# useful for overlaying visualizations with general selections in VMD
# or whatever. All accomplished without creating any variables to show
# some object method chaining. 
#

use Modern::Perl;
use HackaMol;

HackaMol::Molecule -> new (
    atoms=>[
            grep {
                   $_->name eq "N"  or
                   $_->name eq "O"  or
                   $_->name eq "C"  or
                   $_->name eq "CA" or
                   $_->bfact > 0.25
                 } HackaMol -> new -> read_file_atoms(shift)
           ]
) -> print_pdb;

