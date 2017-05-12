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

package Math::NumSeq::Plaindromes;
use 5.004;
use strict;

use vars '$VERSION', '@ISA';
$VERSION = 72;

use Math::NumSeq;
use Math::NumSeq::Base::IteratePred;
@ISA = ('Math::NumSeq::Base::IteratePred',
        'Math::NumSeq');
*_is_infinite = \&Math::NumSeq::_is_infinite;

use Math::NumSeq::Repdigits;
*_digit_split_lowtohigh = \&Math::NumSeq::Repdigits::_digit_split_lowtohigh;

# uncomment this to run the ### lines
#use Smart::Comments;


# use constant name => Math::NumSeq::__('...');
use constant description => Math::NumSeq::__('Numbers with non-decreasing digits, and options for related numbers.');
use constant i_start => 0;
use constant values_min => 0;

use constant parameter_info_array =>
  [ { name      => 'radix',
      share_key => 'radix_16',
      type      => 'integer',
      display   => Math::NumSeq::__('Radix'),
      default   => 16,
      minimum   => 2,
      width     => 3,
      description => Math::NumSeq::__('Radix, ie. base, for the values calculation.  Default is hexadecimal (base 16).'),
    },
  ];


#------------------------------------------------------------------------------
# cf 
#
# A023787 katadromes OFFSET=0
# A023754 plaindromes base13 OFFSET=0
# A023755 plaindromes base14 OFFSET=0
# A023756 plaindromes base15 OFFSET=0

my %oeis_anum = (
                 # plaindromes
                 13 => 'A023754',
                 14 => 'A023755',
                 15 => 'A023756',
                 16 => 'A023757',  # ascending
                 # OEIS-Catalogue: A023754 radix=13
                 # OEIS-Catalogue: A023755 radix=14
                 # OEIS-Catalogue: A023756 radix=15
                 # OEIS-Catalogue: A023757 radix=16

                 # nialpdromes
                 '3,descending' => 'A023759',
                 '4,descending' => 'A023760',
                 '13,descending' => 'A023768',
                 '14,descending' => 'A023769',
                 '15,descending' => 'A023770',
                 '16,descending' => 'A023771',

                 # metadromes (finite)
                 '4,strict-ascending' => 'A023773',
                 '5,strict-ascending' => 'A023774',
                 '6,strict-ascending' => 'A023775',
                 '7,strict-ascending' => 'A023776',
                 '8,strict-ascending' => 'A023777',

                 # karadromes
                 '5,strict-descending' => 'A023787',
                );
sub oeis_anum {
  my ($self) = @_;
  return $oeis_anum{$self->{'radix'}};
}

#------------------------------------------------------------------------------

sub pred {
  my ($self, $value) = @_;
  ### Plaindromes pred(): $n

  if ($value != int($value) || _is_infinite($value)) {
    return 0;
  }
  $value = abs($value);

  my @digits = _digit_split_lowtohigh($value, $self->{'radix'})
    or return 1;  # value=0 yes

  my $prev = shift @digits;
  while (defined (my $digit = shift @digits)) {
    if ($prev < $digit) {
      return 0;
    }
    $prev = $digit;
  }
  return 1;
}

1;
__END__

=for stopwords Ryde Math-PlanePath

=head1 NAME

Math::NumSeq::Plaindromes -- digits in ascending order, and similar

=head1 SYNOPSIS

 use Math::NumSeq::Plaindromes;
 my $seq = Math::NumSeq::Plaindromes->new;
 my ($i, $value) = $seq->next;

=head1 DESCRIPTION

I<In progress ...>

    1, 1, 1, 0, 1, 1, 0, 0, 1, 1, 1, 0, 0, 1, 0, 0, 1, ...

=head1 FUNCTIONS

See L<Math::NumSeq/FUNCTIONS> for behaviour common to all sequence classes.

=over 4

=item C<$seq = Math::NumSeq::Plaindromes-E<gt>new ()>

Create and return a new sequence object.

=item C<$bool = $seq-E<gt>pred($value)>

Return true if C<$value> is an integer with all digits ascending.

=back

=head1 SEE ALSO

L<Math::NumSeq>,
L<Math::NumSeq::Palindrome>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-numseq/index.html>

=head1 LICENSE

Copyright 2011, 2012, 2013, 2014 Kevin Ryde

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
