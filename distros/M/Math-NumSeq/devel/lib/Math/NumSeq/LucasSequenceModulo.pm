# Copyright 2012, 2013, 2014, 2016, 2019 Kevin Ryde

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


package Math::NumSeq::LucasSequenceModulo;
use 5.004;
use strict;

use vars '$VERSION', '@ISA';
$VERSION = 74;

use Math::NumSeq;
@ISA = ('Math::NumSeq');
*_is_infinite = \&Math::NumSeq::_is_infinite;

use Math::NumSeq::Modulo;
use Math::NumSeq::SpiroFibonacci;


# use constant name => Math::NumSeq::__('...');
use constant description => Math::NumSeq::__('Lucas sequence modulo.');
use constant default_i_start => 0;
use constant characteristic_smaller => 1;

use constant parameter_info_array =>
  [
   Math::NumSeq::SpiroFibonacci->parameter_info_hash->{'initial_0'},
   Math::NumSeq::SpiroFibonacci->parameter_info_hash->{'initial_1'},
   {
    name      => 'P',
    share_key => 'lucas_sequence_P',
    display   => Math::NumSeq::__('P'),
    type      => 'integer',
    default   => 1,
    width     => 3,
    description => Math::NumSeq::__('P multipler.'),
   },
   {
    name      => 'Q',
    share_key => 'lucas_sequence_Q',
    display   => Math::NumSeq::__('Q'),
    type      => 'integer',
    default   => -1,
    width     => 3,
    description => Math::NumSeq::__('Q multiplier.'),
   },
   Math::NumSeq::Modulo->parameter_info_hash->{'modulus'},
  ];

use constant values_min => 0;
sub values_max {
  my ($self) = @_;
  my $modulus = $self->{'modulus'};
  if (($self->{'P'} % $modulus) == 0
      && ($self->{'Q'} % $modulus) == 0
      && ($self->{'initial_0'} % $modulus) == 0
      && ($self->{'initial_1'} % $modulus) == 0) {
    return 0;
  }
  return abs($modulus) - 1;
}

sub characteristic_integer {
  my ($self) = @_;
  return (_is_integer($self->{'initial_0'})
          && _is_integer($self->{'initial_1'})
          && _is_integer($self->{'P'})
          && _is_integer($self->{'Q'}));
}
sub _is_integer {
  my ($n) = @_;
  return ($n == int($n));
}

#------------------------------------------------------------------------------
# A064737 fib mod 10 with carry added in too

my %oeis_anum = (
                 # OEIS-Catalogue array begin
                 '0,1,1,-1,10'           => 'A003893', # modulus=10
                 '0,1,1,-1,11,i_start=1' => 'A105955', # modulus=11 i_start=1
                 '0,1,1,-1,12'           => 'A089911', # modulus=12
                 # OEIS-Catalogue array end
                );

sub oeis_anum {
  my ($self) = @_;
  my $i_start = $self->i_start;
  return $oeis_anum{join(',',
                         @{$self}{  # hash slice
                           'initial_0',
                             'initial_1',
                               'P',
                                 'Q',
                                   'modulus'},
                         ($self->i_start != $self->default_i_start
                          ? ("i_start=$i_start")
                          : ()))};
}

#------------------------------------------------------------------------------

sub rewind {
  my ($self) = @_;
  my $modulus = $self->{'modulus'};
  $self->{'prev'}  = $self->{'initial_0'} % $modulus;
  $self->{'value'} =  $self->{'initial_1'} % $modulus;

  $self->{'i'} = $self->i_start;
  if (($self->{'i_start'}||0) == 1) {
    $self->next;
  }
}

sub next {
  my ($self) = @_;
  my $ret = $self->{'prev'};
  ($self->{'prev'},
   $self->{'value'})
    = ($self->{'value'},

       ($self->{'value'} * $self->{'P'} - $self->{'prev'} * $self->{'Q'})
       % $self->{'modulus'});

  return ($self->{'i'}++, $ret);
}

1;
__END__

=for stopwords Ryde Math-NumSeq

=head1 NAME

Math::NumSeq::LucasSequenceModulo -- number of applications of the PisanoPeriod until a fixed value

=head1 SYNOPSIS

 use Math::NumSeq::LucasSequenceModulo;
 my $seq = Math::NumSeq::LucasSequenceModulo->new;
 my ($i, $value) = $seq->next;

=head1 DESCRIPTION

This is the number of times the PisanoPeriod must be applied before reaching
an unchanging value.

    0, 4, 3, 2, 3, 1, 2, 2, 1, 2, 3, 1, 3, 2, 3, 1, 2, 1, 2, ...
    starting i=1

Per Fulton and Morris, repeatedly applying the PisanoPeriod eventually
reaches a value m which has PisanoPeriod(m)==m.  For example i=5 goes

    PisanoPeriod(5)=20
    PisanoPeriod(20)=60
    PisanoPeriod(60)=60
    PisanoPeriod(120)=120
    so value=3 applications until to reach unchanging 120

=head1 FUNCTIONS

See L<Math::NumSeq/FUNCTIONS> for behaviour common to all sequence classes.

=over 4

=item C<$seq = Math::NumSeq::LucasSequenceModulo-E<gt>new ()>

Create and return a new sequence object.

=back

=cut

# =head2 Random Access
# 
# =over
# 
# =item C<$value = $seq-E<gt>ith($i)>
# 
# ...
# 
# =back

=pod

=head1 SEE ALSO

L<Math::NumSeq>,
L<Math::NumSeq::Fibonacci>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-numseq/index.html>

=head1 LICENSE

Copyright 2012, 2013, 2014, 2016, 2019 Kevin Ryde

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
