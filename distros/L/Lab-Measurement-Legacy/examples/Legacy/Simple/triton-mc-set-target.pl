#!/usr/bin/perl

use strict;
use Lab::Instrument::OI_Triton;
use 5.010;

################################

my $t = Lab::Instrument::OI_Triton->new( connection_type => 'Socket', );

my $temp = $t->get_T();
print "MC temperature is $temp K\n";

say $t->enable_control();

say $t->set_T(0.036);

say $t->disable_control();

1;

=pod

=encoding utf-8

=head1 triton-mc.pl

Sets an OI dilution refrigerator to regulate the temperature to 30mK
(using sensor 5 and heater 1, as per default in OI_Triton.pm)

=head2 Usage example

  $ perl triton-mc-set-target.pl
  
=head2 Author / Copyright

  (c) Andreas K. Hüttel 2016

=cut
