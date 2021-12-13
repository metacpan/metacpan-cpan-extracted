package Lab::Moose::Instrument::ZI_HF2LI;
$Lab::Moose::Instrument::ZI_HF2LI::VERSION = '3.801';
#ABSTRACT: Zurich Instruments HF2LI Lock-in Amplifier

use v5.20;

use Moose;
use namespace::autoclean;

extends 'Lab::Moose::Instrument::ZI_MFLI';



__PACKAGE__->meta()->make_immutable();

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::Moose::Instrument::ZI_HF2LI - Zurich Instruments HF2LI Lock-in Amplifier

=head1 VERSION

version 3.801

=head1 SYNOPSIS

 use Lab::Moose;

 my $hfli = instrument(
     type => 'ZI_HF2LI',
     connection_type => 'Zhinst',
     oscillator => 1, # 0 is default
     connection_options => {
         host => '122.188.12.13',
         port => 8005, # Note: The MFLI uses port 8004
     });

 $hfli->set_frequency(value => 10000);

 # Set time constants of first two demodulators to 0.5 sec:
 $hfli->set_tc(demod => 0, value => 0.5);
 $hfli->set_tc(demod => 1, value => 0.5);

 # Read out demodulators:
 my $xy_0 = $hfli->get_xy(demod => 0);
 my $xy_1 = $hfli->get_xy(demod => 1);
 say "x_0, y_0: ", $xy_0->{x}, ", ", $xy_0->{y};

=head1 METHODS

Identical to L<Lab::Moose::Instrument::ZI_MFLI>.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by the Lab::Measurement team; in detail:

  Copyright 2020       Simon Reinhardt


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
