#!/usr/bin/perl
#
package Math::simpleRNG;
#
use strict;
use vars qw($VERSION @ISA @EXPORT_OK);
require Exporter;

@ISA = qw(Exporter);
@EXPORT_OK = qw(sRNG);

$VERSION = do { my @r = (q$Revision: 0.04 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

=head1 NAME

MATH::simpleRNG - simple Random Number Generator

=head1 SYNOPSIS

  use Math::simpleRNG qw (sRNG);
  $random = sRNG('seed1','seed2');

=head1 DESCRIPTION

This function uses George Marsaglia's Multiply With Carry algorithm 
to produce uniformly distributed unsigned integers.

=over 4

=item * $random = sRNG('seed1','seed2')

  input:	seed1	[optional]
		seed2	[optional]

  return:	an unsigned random integer 1 -> 2^32 -1

  Starting from a known set of non-zero seeds, the RNG
  will return a repeating set of pseudo random numbers.

  You may alter the pattern by periodically supplying 
  additional seed(s). If no seed is supplied or the seed
  integer portion of the seed is zero, system time() is
  used to seed the algorithm.

Note: for smaller numbers, i.e. 3-4 digit

  my $num = sRNG int(sRNG()/5000000);

=back

=cut

my($m_z,$m_w);

# generate uniformly distributed unsigned integers
# http://www.codeproject.com/Articles/25172/Simple-Random-Number-Generation
#
sub sRNG {
  my($s1,$s2) = @_;
  if ($s1 && int($s1)) {
    $m_z = int($s1);
  } elsif (!$m_z) {
    $m_z = time();
  }
  if ($s2 && int($s2)) {
    $m_w = int($s2);
  } elsif (!$m_w) {
    $m_w = time();
  }
  $m_z = 36969 * ($m_z & 0xffff) + ($m_z >> 16);
  $m_w = 18000 * ($m_w & 0xffff) + ($m_w >> 16);
# 32 bit integer version of ((($m_z << 16) & 0xffffffff) + ($m_w & 0xffffffff)) & 0xffffffff;
  (((($m_z & 0xffff) + ($m_w >> 16)) & 0xffff) << 16) + ($m_w & 0xffff);
}

=head1 AUTHOR

Michael Robinton <michael@bizsystems.com>

=head1 COPYRIGHT & LICENSE

Copyright 2013-2014, Michael Robinton <michael@bizsystems.com>

This module is licensed under the Code Project Open License (CPOL)
a copy of which is included with this distribution. A copy may also be
obtained at http://www.codeproject.com/info/cpol10.aspx

=head1 ACKNOWLEDGEMENTS

Thanks to John D. Cook for his article on the Simple RNG found here:
http://www.codeproject.com/Articles/25172/Simple-Random-Number-Generation

=head1 EXPORT_OK

	sRNG

=head1 DEPENDENCIES

	none

=cut

1;
