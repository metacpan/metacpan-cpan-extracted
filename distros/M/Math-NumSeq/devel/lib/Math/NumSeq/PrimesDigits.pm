# Copyright 2012, 2013, 2014 Kevin Ryde

# This file is part of Math-NumSeq.
#
# Math-NumSeq is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Math-NumSeq is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Math-NumSeq.  If not, see <http://www.gnu.org/licenses/>.

package Math::NumSeq::PrimesDigits;
use 5.004;
use strict;

use vars '$VERSION', '@ISA';
$VERSION = 72;
use Math::NumSeq::Base::Digits;
@ISA = ('Math::NumSeq::Base::Digits');

use Math::NumSeq 7; # v.7 for _is_infinite()
*_is_infinite = \&Math::NumSeq::_is_infinite;

use Math::NumSeq::Repdigits;
*_digit_split_lowtohigh = \&Math::NumSeq::Repdigits::_digit_split_lowtohigh;

use Math::NumSeq::Primes;

# uncomment this to run the ### lines
#use Smart::Comments;


# use constant name => Math::NumSeq::__('Primes Digits');
use constant description => Math::NumSeq::__('Digits of the primes.');
use constant default_i_start => 1;

use constant parameter_info_array =>
  [
   Math::NumSeq::Base::Digits->parameter_info_list,  # 'radix'
   {
    name        => 'order',
    share_key   => 'order_frs',
    type        => 'enum',
    default     => 'forward',
    choices     => ['forward','reverse','sorted'],
    choices_display => [Math::NumSeq::__('Forward'),
                        Math::NumSeq::__('Reverse'),
                        Math::NumSeq::__('Sorted'),
                       ],
    description => Math::NumSeq::__('Order for the digits within each integer.'),
   },
  ];

#------------------------------------------------------------------------------

my %oeis_anum = (
                 # but A033308 starts OFFSET=0 as decimal of a constant
                 # 'forward,10' => 'A033308'
                 # # OEIS-Catalogue: A033308
                );
sub oeis_anum {
  my ($self) = @_;
  return $oeis_anum{"$self->{order},$self->{radix}"};
}

#------------------------------------------------------------------------------

sub rewind {
  my ($self) = @_;
  $self->{'i'} = $self->i_start;
  $self->{'primes'} = Math::NumSeq::Primes->new;
  $self->{'pending'} = [ ];
}
sub next {
  my ($self) = @_;
  ### AllDigits next(): $self->{'i'}

  my $value;
  unless (defined ($value = shift @{$self->{'pending'}})) {
    my $pending = $self->{'pending'};
    (undef, my $n) = $self->{'primes'}->next
      or return;

    push @$pending, _digit_split_lowtohigh($n, $self->{'radix'});
    my $order = $self->{'order'};
    if ($order eq 'forward') {
      @$pending = reverse @$pending;
    } elsif ($order eq 'sorted') {
      @$pending = sort {$a<=>$b} @$pending;
    }
    $value = shift @$pending;
  }
  return ($self->{'i'}++, $value);
}

1;
__END__

=for stopwords Ryde Math-NumSeq radix

=head1 NAME

Math::NumSeq::PrimesDigits -- digits of the primes

=head1 SYNOPSIS

 use Math::NumSeq::PrimesDigits;
 my $seq = Math::NumSeq::PrimesDigits->new;
 my ($i, $value) = $seq->next;

=head1 DESCRIPTION

This is the digits of the primes,

    starting i=1 (for prime=2)
    2, 3, 5, 7, 1, 1, 1, 3, 1, 7, 1, 9, 2, 3, 2, 9, ...

                \--/  \--/  \--/  \--/  \--/  \--/
                 11    13    17    19    23    29

=head2 Order

The optional C<order> parameter (a string) can control the order of the
primes of each integer,

    order => "forward"     the default
    order => "reverse"
    order => "sorted"

"reverse" rearranges the values to reverse the digits within each prime, so
going from least significant digit.  For example 13 appears as 3,1.

    2, 3, 5, 7, 1, 1, 3, 1, 7, 1, 9, 1, 3, 2, 9, 2, ...

                \--/  \--/  \--/  \--/  \--/  \--/
                 11    13    17    19    23    29

"sorted" rearranges the values to sort the digits within each prime into
ascending order.

    2, ... 2, 9, 1, 3, 3, 7, 1, 4, 3, 4, 4, 7, 3, 5, ...

           \--/  \--/  \--/  \--/  \--/  \--/  \--/
            29    31    37    41    43    47    53

=head1 FUNCTIONS

See L<Math::NumSeq/FUNCTIONS> for behaviour common to all sequence classes.

=over 4

=item C<$seq = Math::NumSeq::Digit-E<gt>new ()>

=item C<$seq = Math::NumSeq::Digit-E<gt>new (radix =E<gt> $r, order =E<gt> $o)>

Create and return a new sequence object.

=item C<$bool = $seq-E<gt>pred($value)>

Return true if C<$value> occurs in the sequence, which simply means digits 0
to radix-1.

=back

=head1 SEE ALSO

L<Math::NumSeq>,
L<Math::NumSeq::Primes>,
L<Math::NumSeq::AllDigits>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-numseq/index.html>

=head1 LICENSE

Copyright 2012, 2013, 2014 Kevin Ryde

Math-NumSeq is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free
Software Foundation; either version 3, or (at your option) any later
version.

Math-NumSeq is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
Math-NumSeq.  If not, see <http://www.gnu.org/licenses/>.

=cut
