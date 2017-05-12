package Math::BigInt::Random;

our $VERSION = 0.04;

use strict;
use warnings;
require Exporter;
our @ISA    = qw(Exporter);
our @EXPORT = qw(random_bigint);
use Carp qw(carp croak);
use Math::BigInt;

sub random_bigint {
    my (%args) = @_;
    my $max = $args{max} || 0;
    $max = Math::BigInt->new($max);
    my ($length_hex) = $args{length_hex};
    my ($length_bin) = $args{length_bin};
    my ($use_internet) = $args{use_internet};
    carp("hmm...two incompatible specs for length, will use hex") 
      if $length_hex and $length_bin;
    my $required_length = 0;
    croak "max must be > 0, but $max was specified" if $max < 0;
    if ( $max == 0 ) {
        $required_length = $args{length}
          or croak "Need a maximum or a length for the random number";
        my $digit  = '9';
        my $prefix = '';
        if ($length_hex) {
            $digit  = 'f';
            $prefix = '0x';
        }
        elsif ($length_bin) {
            $digit = '1';
            $prefix = '0b';
        }
        my $max_num_string = $prefix . ( $digit x $required_length );
        $max = Math::BigInt->new($max_num_string);
    }
    my $min = $args{min} || 0;
    $min = Math::BigInt->new($min);
    my $interval = $max - $min;
    croak "too narrow a range" if $interval <= 0;
    my $tries = 1000;
    $tries *= 16 if $length_bin;
    for ( my $i = 0 ; $i < $tries ; ++$i ) {
        my $rand_num =
          ( $interval < 0xfffff and !$use_internet )
          ? Math::BigInt->new( int rand($interval) )
          : bigint_rand($interval, $use_internet);
        $rand_num += $min;
        next if $rand_num > $max;
        my $num_length_10 = length $rand_num;
        my $num_length_16 = int length( $rand_num->as_hex() ) - 2;
        my $num_length_2  = int length( $rand_num->as_bin() ) - 2;
        next
          if $required_length
          and $length_hex
          and $num_length_16 != $required_length;
        next
          if $required_length
          and $length_bin
          and $num_length_2 != $required_length;
        next
          if $required_length
          and !$length_hex 
          and !$length_bin
          and $num_length_10 != $required_length;
        return $rand_num;
    }
    carp "Could not make random number $required_length size in $tries tries";
    return;
}

sub bigint_rand {
   my( $max, $use_internet ) = @_;
   my $as_hex       = $max->as_hex();
   my $len          = length($as_hex);           # include '0x' prefix
   my $bottom_quads = int( ( $len - 3 ) / 4 );
   my $top_quad_chunk = substr($as_hex, 0, $len - 4 * $bottom_quads);
   my $num = '0x';
   if($use_internet) {
      $num .= get_random_org_digits(hex $top_quad_chunk, 1);
      $num .= get_random_org_digits(65535, $bottom_quads);
    }
    else {
      $num .= get_random_hex_digits(hex $top_quad_chunk, 1);
      $num .= get_random_hex_digits(65535, $bottom_quads);
    }
    return Math::BigInt->new($num);
}

sub get_random_hex_digits {
    my($max, $count) = @_;
    return '' if $count < 1;
    my @digits;
    for(1 .. $count) { push @digits, int rand($max) }
    return assemble_digits(\@digits);
}

sub get_random_org_digits {
    my($max, $count) = @_;
    return if $count < 1;
    require LWP::Simple;
    my $request = "http://www.random.org/cgi-bin/randnum?num=$count&min=0&max=$max&col=1";
    my $page = LWP::Simple::get($request);
    my @digits = split /\s+/, $page;
    foreach (@digits) { $_ ^= int rand($max) }    
    return assemble_digits(\@digits);
}

sub assemble_digits {
    my $array = shift;
    my $retval;
    if(scalar(@$array) > 1) {
        foreach (@$array) { $retval .= sprintf( "%04x", $_ ) }
    }
    else { 
        $retval = sprintf( "%x", $array->[0] ) 
    }
    return $retval;
}


=head1 NAME

Math::BigInt::Random -- arbitrary sized random integers

=head1 DESCRIPTION

    Random number generator for arbitrarily large integers. 
    Uses the Math::BigInt module to handle the generated values.

    This module exports a single function called random_bigint, which returns 
    a single random Math::BigInt number of the specified range or size.  


=head1 SYNOPSIS

  use Math::BigInt;
  use Math::BigInt::Random qw/ random_bigint /;
 
  print "random by max : ",  random_bigint( max => '10000000000000000000000000'), "\n",
    "random by max and min : ", 
    random_bigint( min => '7000000000000000000000000', max => '10000000000000000000000000'), "\n",
    "random by length (base 10): ",   
    random_bigint( length => 20 ), "\n",
    "random by length (base 16) :",
    random_bigint( length_hex => 1, length => 20)->as_hex, "\n";
    "random by length (base 2) :",
    random_bigint( length_bin => 1, length => 319)->as_bin, "\n";
    "random from random.org" :",
    random_bigint( max => '3333333333333333000000000000000000000000', 
      min => '3333333333333300000000000000000000000000', use_internet => 1);
    
    

=head1 FUNCTION ARGUMENTS

=over 4

This module exports a single function called random_bigint, which returns 
a single random Math::BigInt of arbitrary size.  


Parameters to the function are given in paired hash style:

  max => $max,   
    the maximum integer that can be returned.  Either the 'max' or the 'length' 
    parameter is mandatory. If both max and length are given, only the 'max' 
    parameter will be used. Note that the max must be >= 1.
  
  min => $min,   
    which specifies the minimum integer that can be returned.  

  length => $required_length,
    which specifies the number of digits (with most significant digit not 0).  
    Note that if max is specified, length will be ignored.  However, if max is 
    not specified, length is a required argument.
  
  length_hex => 1,
    which specifies that, if length is used, the length is that of the base 16 
    number, not the base 10 number which is the default for the length.

  length_bin => 1,
    which specifies that, if length is used, the length is that of the base 2 
    number, not the base 10 number which is the default for the length. Note 
    that, due to discarding half the possible random numbers due to random 
    generation of a most significant place digit of 0, this method is about 
    half as efficient as when an exact maximum and minimum are given instead.
    
  use_internet => 1,
     which specifies that the random.org website will be used for random 
     number generation.  Note this is NOT secure, since anyone monitoring
     the connnection might be able to read the numbers that are received.
     It is quite random, however.

=back

=head2 Class Internal Methods and Functions

=over 4

=item assemble_digits

=item bigint_rand

=item get_random_hex_digits

=item get_random_org_digits

=item random_bigint
    
=back

=head1 AUTHOR

William Herrera (wherrera@skylightview.com)

=head1 COPYRIGHT

  Copyright (C) 2007 William Hererra.  All Rights Reserved.

  This module is free software; you can redistribute it and/or modify it
  under the same terms as Perl itself.

 
=cut

1;
