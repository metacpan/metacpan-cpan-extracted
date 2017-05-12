package Math::EMA;

use 5.008003;
use strict;
use warnings;

our $VERSION = '0.03';

our @attributes;
BEGIN {
  # define attributes and implement accessor methods
  @attributes=qw/alpha ema/;
  for( my $i=0; $i<@attributes; $i++ ) {
    my $method_num=$i;
    ## no critic
    no strict 'refs';
    *{__PACKAGE__.'::'.$attributes[$method_num]}=
      sub : lvalue {$_[0]->[$method_num]};
    ## use critic
  }
}

sub new {
  my $class=ref($_[0]) || $_[0];

  my $I=bless []=>$class;
  $I->alpha=exp(log(0.001)/10);

  for( my $i=1; $i<@_; $i+=2 ) {
    $I->{$_[$i]}=$_[$i+1];
  }

  return $I;
}

sub set_param {
  my ($I, $count, $weight)=@_;

  $I->alpha=exp(log($weight)/$count);
}

sub add {
  my ($I, $value)=@_;

  $I->ema=defined($I->ema) ? (1-$I->alpha)*$value + $I->alpha*$I->ema : $value;
}

1;
__END__

=encoding utf8

=head1 NAME

Math::EMA - compute the exponential moving average

=head1 SYNOPSIS

  use Math::EMA;
  my $avg=Math::EMA->new(alpha=>0.926119, ema=>$initial_value);
  $avg->set_param($iterations, $end_weight);
  $avg->alpha=$new_alpha;
  $avg->ema=$new_value;
  $avg->add($some_value);
  my $ema=$avg->ema;

=head1 DESCRIPTION

This module computes an exponential moving average by the following formula

  avg(n+1) = (1 - alpha) * new_value + alpha * avg(n)

where alpha is a number between 0 and 1.

That means a new value influences the average with a certain weight (1-alpha).
That weight then exponentially vanes when other values are added.

=head2 How to choose alpha?

The value of alpha determines how fast a given value vanes but it never
completely drops out. Assume you can define a limit say after 10
iterations the weight of a certain value should be 1% or 0.01. Then

               _____
         _10  /     `
 alpha =  \  / 0.01   = exp( log(0.01) / 10 )
           \/

=head2 Methods

=head3 Math::EMA-E<gt>new( key=E<gt>value, ... )

creates a new C<Math::EMA> object. Parameters are passed as C<< key=>value >>
pairs. Currently these keys are recognized:

=over 4

=item * alpha

initializes alpha. Alpha must be in the range from 0 to 1.

=item * ema

initializes the average. If an uninitialized ema is used the first
value being added initializes it.

=back

=head3 $obj-E<gt>alpha

set or retrieve the current alpha

=head3 $obj-E<gt>ema

set or retrieve the current average

=head3 $obj-E<gt>set_param($iterations, $end_weight)

computes alpha from the passed values. After C<$iterations> new values a
certain value should have a weight of C<$end_weight> in the average.

=head1 SEE ALSO

L<http://en.wikipedia.org/wiki/Moving_average#Exponential_moving_average>

L<http://en.wikipedia.org/wiki/Exponential_smoothing#The_exponential_moving_average>

=head1 AUTHOR

Torsten Förtsch, E<lt>torsten.foertsch@gmx.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Torsten Foertsch

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
