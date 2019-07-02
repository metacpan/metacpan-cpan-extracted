#!/usr/bin/perl
#DistZilla: +PodWeaver
#PODNAME: srs_read.pl
#ABSTRACT: Read out SR830 lock-in amplifier

use 5.010;
use Lab::Moose;

unless ( @ARGV > 0 ) {
    print "Usage: $0 GPIB-address\n";
    exit;
}

my $gpib = $ARGV[0];

print "Reading status and signal r/phi from SR830 at GPIB address $gpib\n";

my $lia = instrument(
    type               => 'SR830',
    connection_type    => 'LinuxGPIB',
    connection_options => {pad => $gpib}
);

my $amp = $lia->get_amplitude();
say "Reference output amplitude: $amp V";

my $frq = $lia->get_frq();
say "Reference frequency: $frq Hz";

my $rphi = $lia->get_rphi();
say "Signal:  amplitude  r=$rphi->{r} V";
say "         phase    phi=$rphi->{phi} degree";

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

srs_read.pl - Read out SR830 lock-in amplifier

=head1 VERSION

version 3.682

=head1 srs_read.pl

Reads out reference amplitude, reference frequency, and current r and phi values
of a Stanford Research SR830 lock-in amplifier. The only command line parameter
is the GPIB address.

=head2 Usage example

  $ perl srs_read.pl 8

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by the Lab::Measurement team; in detail:

  Copyright 2011       Andreas K. Huettel
            2018       Andreas K. Huettel


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
