#!/usr/bin/perl

use strict;
use Lab::Instrument::OI_Triton;

################################

my $t = new Lab::Instrument::OI_Triton( connection_type => 'Socket', );

my $temp = $t->get_temperature(5);

print "MC temperature is $temp K\n";

1;

=pod

=encoding utf-8

=head1 triton-mc.pl

Queries temperature sensor 5 of an OI Triton dilution refrigerator.

=head2 Usage example

  $ perl triton-mc.pl
  
=head2 Author / Copyright

  (c) Andreas K. Hüttel 2014

=cut
