#!/usr/bin/perl
#
# Computes the Fibonacci sequence using the fast algorithm:  F(n) ~ g^n/sqrt(5),
# where g is the golden ratio and ~ stands for "take the nearest integer."
#
# Copyright (c) 1999-2000, Vipul Ved Prakash <mail@vipul.net>
# This code is free software distributed under the same license as Perl itself.
# $Id: Fibonacci.pm,v 1.5 2001/04/28 20:41:15 vipul Exp $

package Math::Fibonacci;
use strict;
use vars qw($VERSION @ISA @EXPORT_OK);
use POSIX qw(log10 ceil floor); 
require Exporter;
@ISA = qw(Exporter);
( $VERSION )  = '$Revision: 1.5 $' =~ /\s(\d+\.\d+)\s/; 

@EXPORT_OK = qw(term series decompose isfibonacci);

sub g ()     { "1.61803398874989" }  # golden ratio

sub term     { nearestint ((g ** shift) / sqrt(5)) } # nth term of the seq

sub series   { return map(term($_), 1..shift) } # n terms of the seq


sub decompose {                      # decomposes any integer into the sum of
                                     # members of the fibonacci sequence.
    my ($int) = @_;
    my $sum = decomp ($int);
    return @$sum;

}

sub decomp { 
    my ($a, $sum) = @_; 
    my $n = nearestint ((log10($a) + log10(sqrt(5)))/log10(g));
    my $fibn = term($n);
       if ( $fibn == $a ) { push @$sum, $a; return $sum } 
    elsif ( $fibn < $a  ) { push @$sum, $fibn; decomp( $a-$fibn, $sum ) }
    elsif ( $a < $fibn  ) { my $fibn1 = term($n-1); push @$sum, $fibn1; 
                            decomp( $a - $fibn1, $sum ) }
};


sub isfibonacci { 
    
    my $a = shift;
    my $n = nearestint ((log10($a) + log10(sqrt(5)))/log10(g));
    return $a == term($n) ? $n : 0;

}

sub nearestint {
    my $v = shift;
    my $f = floor($v); my $c = ceil($v);
    ($v-$f) < ($c-$v) ? $f : $c;
}


# routines to implement term and series with the familiar additive algorithm.

sub a_term     { return $_[0] < 3 ? 1 : a_term($_[0]-1) + a_term ($_[0]-2) }

sub a_series   {
    my @series = map(a_term($_), 1..shift);
    \@series;
}


1;


=head1 NAME

Math::Fibonacci - Fibonacci numbers.

=head1 VERSION

    $Revision: 1.5 $

=head1 SYNOPSIS

    use Math::Fibonacci qw(term series decompose);

    my $term = term ( 42 );
    my @series = series ( 42 );
    my @sum = decompose ( 65535 );

=head1 DESCRIPTION

This module provides a few functions related to Fibonacci numbers.

=head1 EXPORTS ON REQUEST

term(), series() decompose(), isfibonacci()

=head1 FUNCTIONS

=over 4

=item B<term($n)> 

Returns the $n-th term of the Fibonacci sequence. The term is computed
using the fast algorithm: C<F(n) ~ g^n/sqrt(5)>, where g is the golden
ratio and ~ means "take the nearest integer".

=item B<series($n)> 

Computes and returns the first $n Fibonacci numbers.

=item B<decompose($int)> 

Decomposes $int into the sum of Fibonacci numbers. Returns the list of
Fibonacci numbers.  

=item B<isfibonacci($int)>

Returns the sequence number of $int if it is a Fibonacci number or a
non-true value if it is not.

=head1 AUTHOR

Vipul Ved Prakash, E<lt>mail@vipul.netE<gt>

=head1 LICENSE 

Copyright (c) 1999-2001, Vipul Ved Prakash.  

This code is free software; you can redistribute it and/or modify it under
the ARTISTIC license (a copy is included in the distribution) or under the
same terms as Perl itself.

=cut

