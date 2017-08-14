#!/usr/bin/perl
#-------------------------------------------------------------------------------
# Encode a positive integer using the specified digits and vice-versa
# Philip R Brenan at gmail dot com, Appa Apps Ltd, 2017
#-------------------------------------------------------------------------------
# podDocumentation

package Encode::Positive::Digits;
require v5.16.0;
use warnings FATAL => qw(all);
use strict;
use Carp;
use Math::BigInt;

our $VERSION = '20170811';

#1 Encode and decode

sub encode($$)                                                                  # Returns a string which expresses a positive integer in decimal notation as a string using the specified digits. The specified digits can be any characters chosen from the Unicode character set.
 {my ($number, $digits) = @_;                                                   # Decimal integer, encoding digits

  $number =~ m/\A\d+\Z/s or confess "$number is not a positive decimal integer";# Check the number to be encoded

  my @b = split //, $digits;                                                    # Check the encoding digits
  my $b = Math::BigInt->new(scalar @b);
  $b > 1 or confess
   "number of encoding digits supplied($b) too few, must be at least 2";

  return $b[0] if $number == 0;                                                 # A simple case

  my $n = Math::BigInt->new($number);                                           # Convert to BigInt
  my $e = '';                                                                   # Encoded version

  for my $position(0..4*length($number))                                        # Encoding in binary would take less than this number of digits
   {my $p = $b ** $position;
    next if $p < $n;
    return $b[1].($b[0] x $position) if $p == $n;
    for my $divide(reverse 0..$position-1)
     {my $P = $b ** $divide;
      my $D = int($n / $P);
      $e .= $b[$D];
      $n -= $P*$D;
     }
    return $e;
   }
 }

sub decode($$)                                                                  # Return the integer expressed in decimal notation corresponding to the value of the specified string considered as a number over the specified digits
 {my ($number, $digits) = @_;                                                   # Number to decode, encoding digits

  my @b = split //, $digits;
  my $b = @b;
  $b > 1 or confess
   "number of decoding digits supplied($b) too few, must be at least 2";

  my @n = split //, $number;
  my $n = @n;

  for(1..$n)                                                                    # Convert each digit to be decoded with its decimal equivalent
   {my $d = $n[$_-1];
    my $i = index($digits, $d);
    $i < 0 and confess "Invalid digit \"$d\" in number $number at position $_";
    $n[$_-1] = $i;
   }

  my $p = Math::BigInt->new(1);
  my $s = Math::BigInt->new(0);
  for(reverse @n)                                                               # Decode each digit
   {$s += $p * $_;
    $p *=  $b;
   }

  "$s"
 }

#-------------------------------------------------------------------------------
# Export
#-------------------------------------------------------------------------------

require Exporter;

use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

@ISA          = qw(Exporter);
@EXPORT       = qw();
@EXPORT_OK    = qw();
%EXPORT_TAGS  = (all=>[@EXPORT, @EXPORT_OK]);

# podDocumentation
=pod

=encoding utf-8

=head1 Name

Encode::Positive::Digits - Encode a positive integer using the specified digits and vice-versa

=head1 Synopsis

 use Encode::Positive::Digits;

 ok 101 == Encode::Positive::Digits::encode(  "5", "01");
 ok   5 == Encode::Positive::Digits::decode("101", "01");

 ok "hello world" eq Encode::Positive::Digits::encode(4830138323689, " abcdefghlopqrw");
 ok 4830138323689 == Encode::Positive::Digits::decode("hello world", " abcdefghlopqrw");

The numbers to be encoded or decoded can be much greater than 2**64 via support
from L<Math::BigInt>, such numbers should be placed inside strings to avoid
inadvertent truncation.

  my $n = '1'.('0'x999).'1';

  my $d = Encode::Positive::Digits::decode($n, "01");
  my $e = Encode::Positive::Digits::encode($d, "01");

  ok $n == $e

  ok length($d) ==  302;
  ok length($e) == 1001;
  ok length($n) == 1001;

=head1 Description

=head2 Encode and decode

=head3 encode

Returns a string which expresses a positive integer in decimal notation as a string using the specified digits. The specified digits can be any characters chosen from the Unicode character set.

  1  $number  Decimal integer
  2  $digits  Encoding digits

=head3 decode

Return the integer expressed in decimal notation corresponding to the value of the specified string considered as a number over the specified digits

  1  $number  Number to decode
  2  $digits  Encoding digits


=head1 Index


L<decode|/decode>

L<encode|/encode>

=head1 Installation

This module is written in 100% Pure Perl and, thus, it is easy to read, use,
modify and install.

Standard Module::Build process for building and installing modules:

  perl Build.PL
  ./Build
  ./Build test
  ./Build install

=head1 Author

L<philiprbrenan@gmail.com|mailto:philiprbrenan@gmail.com>

L<http://www.appaapps.com|http://www.appaapps.com>

=head1 Copyright

Copyright (c) 2016-2017 Philip R Brenan.

This module is free software. It may be used, redistributed and/or modified
under the same terms as Perl itself.

=cut


# Tests and documentation

sub test
 {my $p = __PACKAGE__;
  return if eval "eof(${p}::DATA)";
  my $s = eval "join('', <${p}::DATA>)";
  $@ and die $@;
  eval $s;
  $@ and die $@;
 }

test unless caller;

1;
# podDocumentation
__DATA__
use Test::More tests=>649;

if (1)
 {for my $i(0..127)
   {my $b = Encode::Positive::Digits::encode($i, "01");
    ok $b eq sprintf("%b", $i);
    ok "$i" eq Encode::Positive::Digits::decode($b, "01");
    my $x = Encode::Positive::Digits::encode($i, "0123456789abcdef");
    ok $x eq sprintf("%x", $i);
    ok "$i" eq Encode::Positive::Digits::decode($x, "0123456789abcdef");
    ok "$i" eq Encode::Positive::Digits::encode($i, "0123456789");
   }
 }

if (1)
 {ok 101 == Encode::Positive::Digits::encode(  "5", "01");
  ok   5 == Encode::Positive::Digits::decode("101", "01");
 }

if (1)
 {ok 4830138323689 == Encode::Positive::Digits::decode("hello world", " abcdefghlopqrw");
  ok "hello world" eq Encode::Positive::Digits::encode(4830138323689, " abcdefghlopqrw");
 }

if (1)
 {my $n = '1'.('0'x999).'1';

  my $d = Encode::Positive::Digits::decode($n, "01");
  my $e = Encode::Positive::Digits::encode($d, "01");

  ok length($d) ==  302;
  ok length($e) == 1001;
  ok length($n) == 1001;

  ok $d == '10715086071862673209484250490600018105614048117055336074437503883703510511249361224931983788156958581275946729175531468251871452856923140435984577574698574803934567774824230985421074605062371141877954182153046474983581941267398767559165543946077062914571196477686542167660429831652624386837205668069377';
  ok $n == $e
 }
