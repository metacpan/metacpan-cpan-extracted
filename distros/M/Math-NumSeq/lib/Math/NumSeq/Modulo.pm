# Copyright 2011, 2012, 2013, 2014, 2016, 2017, 2018 Kevin Ryde

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

package Math::NumSeq::Modulo;
use 5.004;
use strict;

use vars '$VERSION', '@ISA';
$VERSION = 73;

use Math::NumSeq;
use Math::NumSeq::Base::IterateIth;
@ISA = ('Math::NumSeq::Base::IterateIth',
        'Math::NumSeq');

# uncomment this to run the ### lines
#use Smart::Comments;

# use constant name => Math::NumSeq::__('Modulo');
sub description {
  my ($self) = @_;
  if (ref $self) {
    return Math::NumSeq::__('Remainder modulo ') . $self->{'modulus'};
  } else {
    return Math::NumSeq::__('Remainder to a given modulus.');
  }
}
use constant i_start => 0;

use constant characteristic_smaller => 1;
use constant characteristic_increasing => 0;
sub characteristic_integer {
  my ($self) = @_;
  return _is_integer($self->{'modulus'});
}
sub characteristic_modulus {
  my ($self) = @_;
  return $self->{'modulus'};
}
sub _is_integer {
  my ($n) = @_;
  return ($n == int($n));
}

use constant parameter_info_array =>
  [ { name        => 'modulus',
      type        => 'integer',
      display     => Math::NumSeq::__('Modulus'),
      default     => 13,
      minimum     => 1,
      width       => 3,
      description => Math::NumSeq::__('Modulus.'),
    } ];

use constant values_min => 0;
sub values_max {
  my ($self) = @_;
  return abs($self->{'modulus'}) - 1;
}

{
  my @oeis_anum = (
                   # OEIS-Catalogue array begin
                   undef,      # 0
                   undef,      # 1
                   'A000035',  # modulus=2  # 0,1,0,1,0,1,etc
                   'A010872',  # modulus=3
                   'A010873',  # modulus=4
                   'A010874',  # modulus=5
                   'A010875',  # modulus=6
                   'A010876',  # modulus=7
                   'A010877',  # modulus=8
                   'A010878',  # modulus=9
                   'A010879',  # modulus=10
                   'A010880',  # modulus=11
                   'A010881',  # modulus=12
                   undef,      # 13
                   'A070696',  # modulus=14
                   'A167463',  # modulus=15
                   'A130909',  # modulus=16

                   # OEIS-Catalogue array end
                  );
  $oeis_anum[1] = 'A000004'; # mod 1, 0,0,0,0,etc all zeros
  # OEIS-Other: A000004 modulus=1

  sub _modulus_to_anum {
    my ($modulus) = @_;
    return ($modulus == int($modulus)
            && $modulus > 0
            && $oeis_anum[$modulus]);
  }
}

sub oeis_anum {
  my ($self) = @_;
  return _modulus_to_anum($self->{'modulus'});
}

sub ith {
  my ($self, $i) = @_;
  ### Modulo ith(): "$i"
  return $i % $self->{'modulus'};
}

sub pred {
  my ($self, $value) = @_;
  return ($value >= 0
          && $value < $self->{'modulus'}
          && $value == int($value));
}

1;
__END__

=for stopwords Ryde Math-NumSeq

=head1 NAME

Math::NumSeq::Modulo -- remainders modulo of a given number

=head1 SYNOPSIS

 use Math::NumSeq::Modulo;
 my $seq = Math::NumSeq::Modulo->new (modulus => 123);
 my ($i, $value) = $seq->next;

=head1 DESCRIPTION

A simple sequence of remainders to a given modulus of a given number, for
example modulus 5 gives 0, 1, 2, 3, 4, 0, 1, 2, 3, 4, etc.

=head1 FUNCTIONS

See L<Math::NumSeq/FUNCTIONS> for behaviour common to all sequence classes.

=over 4

=item C<$seq = Math::NumSeq::Modulo-E<gt>new (modulus =E<gt> $number)>

Create and return a new sequence object.

=back

=head2 Random Access

=over

=item C<$value = $seq-E<gt>ith($i)>

Return C<$i % $modulus>.

=item C<$bool = $seq-E<gt>pred($value)>

Return true if C<$value> occurs as a remainder, so 0 E<lt>= C<$value> E<lt>=
modulus-1.

=back

=head1 SEE ALSO

L<Math::NumSeq>,
L<Math::NumSeq::Multiples>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-numseq/index.html>

=head1 LICENSE

Copyright 2010, 2011, 2012, 2013, 2014, 2016, 2017, 2018 Kevin Ryde

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
