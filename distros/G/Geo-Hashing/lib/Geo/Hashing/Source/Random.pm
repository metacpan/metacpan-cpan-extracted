#!/usr/bin/perl -w
#
# $Id: Random.pm 255 2008-06-21 03:48:46Z dan $
#

package Geo::Hashing::Source::Random;

use strict;
use warnings;
require Exporter;

our @ISA = qw/Exporter/;
our @EXPORT = qw/get_djia/;

=head1 NAME

Geo::Hashing::Source::Random - Use random values instead of DJIA opening values

=head1 SYNOPSIS

  use Geo::Hashing;
  my $g = new Geo::Hashing(source => 'random');
  printf "Today's random offset is at %.6f, %.6f.\n", $g->lat, $g->lon;

=head1 DESCRIPTION

  See documentation of Geo::Hashing.

=cut
sub get_djia {
  return 10000 + int(100*rand(3000))/100;
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
