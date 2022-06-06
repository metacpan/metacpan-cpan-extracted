# Copyright 2011, 2012, 2013, 2014, 2016, 2019, 2020 Kevin Ryde

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


# characteristic('increasing')
# characteristic('integer')
#    only by reading the whole file
#    assume seekable



package Math::NumSeq::File;
use 5.004;
use strict;
use Carp;
use POSIX ();

use vars '$VERSION', '@ISA';
$VERSION = 75;

use Math::NumSeq;
@ISA = ('Math::NumSeq');
*_to_bigint = \&Math::NumSeq::_to_bigint;

# uncomment this to run the ### lines
#use Smart::Comments;


# use constant name => Math::NumSeq::__('File');
use constant i_start => 0;
use constant description => Math::NumSeq::__('Numbers from a file');
use constant parameter_info_array =>
  [ { name    => 'filename',
      type    => 'filename',
      display => Math::NumSeq::__('Filename'),
      width   => 40,
      default => '',
    } ];

my $max_value = POSIX::FLT_RADIX() ** (POSIX::DBL_MANT_DIG()-5);
if ((~0 >> 1) > $max_value) {
  $max_value = (~0 >> 1);
}
my $min_value = -$max_value;

sub rewind {
  my ($self) = @_;
  ### Values-File rewind()

  if ($self->{'fh'}) {
    _seek ($self, 0);
  } else {
    my $filename = $self->{'filename'};
    if (defined $filename && $filename !~ /^\s*$/) {
      my $fh;
      ($] >= 5.006
       ? open $fh, '<', $filename
       : open $fh, "< $filename")
        or croak "Cannot open ",$filename,": ",$!;
      $self->{'fh'} = $fh;
    }
  }
  $self->{'i'} = $self->i_start - 1;
}

sub next {
  my ($self) = @_;
  my $fh = $self->{'fh'} || return;
  for (;;) {
    my $line = readline $fh;
    if (! defined $line) {
      ### EOF ...
      return;
    }

    if ($line =~ /^\s*(-?\d+)(\s+(-?(\d+(\.\d*)?|\.\d+)))?/) {
      my ($i, $value);
      if (defined $3) {
        $i = $self->{'i'} = $1;
        $value = $3;
      } else {
        $i = ++$self->{'i'};
        $value = $1;
      }

      # large integer values returned as Math::BigInt
      if (($value > $max_value || $value < $min_value)
          && $value !~ /\./) {
        $value = _to_bigint($value);
      }

      return ($i, $value);
    }
  }
}

sub _seek {
  my ($self, $pos) = @_;
  seek ($self->{'fh'}, $pos, 0)
    or croak "Cannot seek $self->{'filename'}: $!";
}

1;
__END__

=for stopwords Ryde Math-NumSeq NumSeq

=head1 NAME

Math::NumSeq::File -- sequence read from a file

=head1 SYNOPSIS

 use Math::NumSeq::File;
 my $seq = Math::NumSeq::File->new (filename => 'foo.txt');
 my ($i, $value) = $seq->next;

=head1 DESCRIPTION

A sequence of values read from a file.  This is designed to read a file of
numbers in NumSeq style.

The intention is to be flexible about the file format and to auto-detect as
far as possible.  Currently the only format is plain text, either a single
value per line, or a pair i and value.

    123                   # value per line
    456

    1  123                # i and value per line
    2  456

=head1 FUNCTIONS

See L<Math::NumSeq/FUNCTIONS> for behaviour common to all sequence classes.

=over 4

=item C<$seq = Math::NumSeq::File-E<gt>new (filename =E<gt> $filename)>

Create and return a new sequence object to read C<$filename>.

=back

=head1 SEE ALSO

L<Math::NumSeq>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-numseq/index.html>

=head1 LICENSE

Copyright 2011, 2012, 2013, 2014, 2016, 2019, 2020 Kevin Ryde

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
