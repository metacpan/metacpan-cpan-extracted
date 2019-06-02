# Copyright 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017, 2019 Kevin Ryde

# This file is part of Math-OEIS.
#
# Math-OEIS is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Math-OEIS is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Math-OEIS.  If not, see <http://www.gnu.org/licenses/>.


package Math::OEIS::Stripped;
use 5.006;
use strict;
use warnings;
use Carp 'croak';

use Math::OEIS::SortedFile;
our @ISA = ('Math::OEIS::SortedFile');

# uncomment this to run the ### lines
# use Smart::Comments;

our $VERSION = 11;

use constant base_filename => 'stripped';

# Maximum number of decimal digits which fit within a Perl UV integer.
# For example a 32-bit IV goes up to 2^31-1 = 2147483647 and in that case
# _IV_DECIMAL_DIGITS_MAX is 9 since values up to and including 9 digits
# fit into a UV.  Some 10 digit values fit too, but not all 10 digits.
#
use constant _IV_DECIMAL_DIGITS_MAX => length((~0)>>1)-1;

sub new {
  my $class = shift;
  return $class->SUPER::new (use_bigint => 'if_necessary',
                             @_);
}

sub anum_to_values_str {
  my ($self, $anum) = @_;
  ### Stripped anum_to_values_str(): $anum

  my $line = $self->anum_to_line($anum);
  if (! defined $line) { return undef; }

  my ($got_anum, $values_str) = $self->line_split_anum($line)
    or return undef;  # draft sequence ,, treated same as no such A-number

  return $values_str;
}

sub anum_to_values {
  my ($self, $anum) = @_;
  if (! ref $self) { $self = $self->instance; }
  my @values;
  my $values_str = $self->anum_to_values_str($anum);
  if (defined $values_str) {
    @values = $self->values_split($values_str);
  }
  return @values;
}

sub values_split {
  my ($self, $values_str) = @_;
  if (! ref $self) { $self = $self->instance; }

  my @values = split /,/, $values_str;
  if (my $use_bigint = $self->{'use_bigint'}) {
    foreach my $value (@values) {
      if ($use_bigint eq '1'
          || ($use_bigint eq 'if_necessary'
              && length($value) > _IV_DECIMAL_DIGITS_MAX)) {
        $value = $self->bigint_class_load->new($value);  # mutate array
      }
    }
  }
  return @values;
}

# Not documented yet.
# Return a class name which is the BigInt class to use for values from the
# stripped file.  This class has been loaded ready for use.
sub bigint_class_load {
  my ($self) = @_;
  return ($self->{'bigint_class_load'} ||= do {
    require Module::Load;
    my $bigint_class = $self->bigint_class;
    Module::Load::load($bigint_class);
    ### $bigint_class
    $bigint_class
  });
}

# Not documented yet.
# Return a class name which is the BigInt class to use for values from the
# stripped file.  This is the C<bigint_class> specified in the object, or
# default C<'Math::BigInt'>.
#
# If you want a particular Math::BigInt back-end then have a usual
#     use Math::BigInt try => 'GMP';
# or similar in your mainline code.  No C<try> is applied here since it is a
# global.
#
sub bigint_class {
  my ($self) = @_;
  return ($self->{'bigint_class'} || 'Math::BigInt');
}

sub line_split_anum {
  my ($self, $line) = @_;
  ### Stripped line_split_anum(): $line
  $line =~ /^(A\d+)(\s+)(,+)([-0-9].*?)(\s|,)*$/
    or return;  # no match of comment line "# ..." or maybe a blank
  if (length($3) > 1) {
    # initial ,, is empty values for a draft sequence
  }

  # use substr() to preserve taintedness of input $line
  return (substr($line,0,length($1)),
          substr($line,
                 length($1)+length($2)+length($3),
                 length($4)));
}

1;
__END__

=for stopwords Math OEIS lookup Oopery filename filehandle bignum runtime Ryde

=head1 NAME

Math::OEIS::Stripped - read the OEIS F<stripped> file

=head1 SYNOPSIS

 my @values = Math::OEIS::Stripped->anum_to_values('A123456');

=head1 DESCRIPTION

This is an interface to the big OEIS F<stripped> file.  The file should be
downloaded and unzipped to F<~/OEIS/stripped>,

    cd ~/OEIS
    wget http://oeis.org/stripped.gz
    gunzip stripped.gz

F<stripped> is a very large file containing each A-number and its sample
values.  There's usually about 180 characters worth of sample values but
possibly less or more.

The F<stripped> file is sorted by A-number so C<anum_to_values()> is a text
file binary search (currently implemented with L<Search::Dict>).

Terms of use for the stripped file data can be found at (Creative Commons
Attribution Non-Commercial 3.0 at the time of writing)

=over

L<http://oeis.org/wiki/The_OEIS_End-User_License_Agreement>

=back

=head1 FUNCTIONS

=over

=item C<@values = Math::OEIS::Stripped-E<gt>anum_to_values($anum)>

=item C<$values_str = Math::OEIS::Stripped-E<gt>anum_to_values_str($anum)>

Return the values from the F<stripped> file for C<$anum> (a string) such as
"A000001".

C<anum_to_values()> returns a list of values, or an empty list if no such
A-number.

Values bigger than a Perl integer are converted to C<Math::BigInt> so as to
be exact in numeric operations, such as comparisons C<==> or C<E<gt>=>.

C<anum_to_values_str()> returns a string like "1,2,3,4", or C<undef> if no
such A-number.  The stripped file has leading and trailing commas on its
values list but these are removed here for convenience of subsequent
C<split> or similar.

In the past, draft sequences were in the stripped with an empty values list
",,".  The return for them is an empty list, reckoning "no such A-number"
when no values yet.

If running in C<perl -T> taint mode then C<$values_str> and each value
string in C<@values> is tainted in the usual way for reading from a file.
Values converted to C<Math::BigInt> do not keep a notion of taintedness, but
C<Math::BigInt> should validate as digits which is in the spirit of
untainting after checking.

=item C<Math::OEIS::Stripped-E<gt>close()>

Close the F<stripped> file handle, or do nothing if already closed or never
opened.

=back

=head2 Oopery

=over

=item C<$obj = Math::OEIS::Stripped-E<gt>new (key =E<gt> value, ...)>

Create and return a new C<Math::OEIS::Stripped> object to read an OEIS
F<stripped> file.  The optional key/value parameters can be

    filename     => $filename       # default ~/OEIS/stripped
    fh           => $filehandle

    use_bigint   => string
                      "if_necessary", # default
                      0,              # never
                      1,              # always
    bigint_class => $classname        # default "Math::BigInt"

C<filename> defaults to F<~/OEIS/stripped> per
C<Math::OEIS-E<gt>local_directories()>.  Another filename can be given, or
an open filehandle.  If a handle is given then C<filename> may be used for
diagnostics and so can be helpfully given too.

C<use_bigint> controls conversion of values to bignum objects in
C<anum_to_values()> etc.  Default C<"if_necessary"> converts values bigger
than a Perl integer, or option 1 or 0 for always or never convert.  When not
converted, each value is a string suitable for any string operation but
possibly not numeric operations.

C<bigint_class> is the module name for bignum conversion.  It is
C<require>'d when needed and values are created by
C<$classname-E<gt>new("123")>.  If the class has runtime options, such as
C<Math::BigInt> choice of back-ends, then set that up from mainline code.

=item C<@values = $obj-E<gt>anum_to_values($anum)>

=item C<$values_str = $obj-E<gt>anum_to_values_str($anum)>

Return the values from the F<stripped> file for an C<$anum> string such as
"A000001", like the class method described above.

=item C<$filename = $obj-E<gt>filename()>

Return the filename from C<$obj>.

=item C<$filename = Math::OEIS::Stripped-E<gt>default_filename()>

=item C<$filename = $obj-E<gt>default_filename()>

Return the default filename which is used if no C<filename> or C<fh> option
is given.  C<default_filename()> can be called either as a class method or
object method.

=item C<$obj-E<gt>close()>

Close the F<stripped> file handle, or do nothing if already closed.

=item C<($anum,$values_str) = Math::OEIS::Stripped-E<gt>line_split_anum($line)>

Split a line of the stripped file into A-number and values string.  C<$line>
should be like

    A123456 ,1,6,9,-23,65,17,-5,997,

Leading and trailing comma (and any trailing newline) are stripped so
C<$values_str> is like "1,2,3".

If C<$line> is not A-number and values like this then return an empty list.
The stripped file starts with some comment lines (C<#>) and they get this
empty return.

In the past, draft sequences were included in the stripped file with empty
values list.  They are reckoned non-lines since no values, so empty return.

=item C<@values = Math::OEIS::Stripped-E<gt>values_split($values_str)>

=item C<@values = $obj-E<gt>values_split($values_str)>

C<$values_str> is a string of integers and commas like "123,-456,789".
Return them split to a list of integers.

This a C<split()> on commas, but with the C<use_bigint> option applied to
the result.  See C<new()> above on that option.

=back

=head1 SEE ALSO

C<Math::OEIS>,
C<Math::OEIS::Names>

OEIS files page L<http://oeis.org/allfiles.html>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-oeis/index.html>

=head1 LICENSE

Copyright 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017, 2019 Kevin Ryde

Math-OEIS is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free
Software Foundation; either version 3, or (at your option) any later
version.

Math-OEIS is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
Math-OEIS.  If not, see L<http://www.gnu.org/licenses/>.

=cut
