#!/usr/bin/perl -w
#
# $Id: Peeron.pm 255 2008-06-21 03:48:46Z dan $
#

package Geo::Hashing::Source::Peeron;

use strict;
use warnings;
use Carp;
require Exporter;
use LWP::Simple qw/$ua get/;

=head1 NAME

Geo::Hashing::Source::Peeron - Retrieve DJIA opening values from irc.peeron.com

=head1 SYNOPSIS

  use Geo::Hashing;
  my $g = new Geo::Hashing(source => 'peeron');
  printf "Today's offset is at %.6f, %.6f.\n", $g->lat, $g->lon;

=head1 DESCRIPTION

  See documentation of Geo::Hashing.

=cut

$ua->agent("Geo::Hashing/" . $Geo::Hashing::VERSION);
my $URL = "http://irc.peeron.com/xkcd/map/data/%04d/%02d/%02d";

our @ISA = qw/Exporter/;
our @EXPORT = qw/get_djia/;

sub get_djia {
  my $self = shift;
  my $date = shift;

  croak "Invalid call to get_djia - missing date!" unless $date;

  my ($y, $m, $d) = split /-/, $date, 3;
  croak "Invalid year $y" unless $y and $y >= 1928;
  croak "Invalid month $m" unless $m and $m >= 1 and $m <= 12;
  croak "Invalid day $d" unless $d and $d >= 1 and $m <= 31;

  my $page = get(sprintf($URL, $y, $m, $d));

  return $page;
}

=head1 AUTHOR

Dan Boger, E<lt>zigdon@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Dan Boger

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
1;
