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


package Math::OEIS::SortedFile;
use 5.006;
use strict;
use warnings;
use Carp 'croak';
use Search::Dict;
use Math::OEIS;

eval q{use Scalar::Util 'weaken'; 1}
  || eval q{sub weaken { $_[0] = undef }; 1 }
    || die "Oops, error making a weaken() fallback: $@";

our $VERSION = 12;

# singleton here results in a separate instance object in each derived subclass
use Class::Singleton;
our @ISA = ('Class::Singleton');
*_new_instance = __PACKAGE__->can('new');

# uncomment this to run the ### lines
# use Smart::Comments;


# Keep track of all instances which exist and on an ithread CLONE re-open
# filehandles in the instances so they have their own independent file
# positions in the new thread.
my %instances;
sub DESTROY {
  my ($self) = @_;
  delete $instances{$self+0};
}
sub CLONE {
  # my ($class) = @_;
  foreach my $self (values %instances) {
    $self->close;
  }
}

sub new {
  my $class = shift;
  my $self = bless { @_ }, $class;
  weaken($instances{$self+0} = $self);
  return $self;
}

sub default_filename {
  my ($self) = @_;
  return Math::OEIS->local_filename($self->base_filename);
}

sub filename {
  my ($self) = @_;
  if (ref $self && defined $self->{'filename'}) {
    return $self->{'filename'};
  }
  return $self->default_filename;
}
sub filename_or_empty {
  my ($self) = @_;
  my $filename = $self->filename;
  if (defined $filename) {
    return $filename;
  }
  return '';
}

sub fh {
  my ($self) = @_;
  if (! ref $self) { $self = $self->instance; }
  if (! exists $self->{'fh'}) {
    if (defined (my $filename = $self->filename)) {
      my $fh;
      if (open $fh, '<', $filename) {
        $self->{'fh'} = $fh;
      }
    }
  }
  return $self->{'fh'};
}
sub close {
  my ($self) = @_;
  if (my $fh = delete $self->{'fh'}) {
    if (! close $fh) {
      my $err = "$!";
      croak "Cannot close ",$self->filename_or_empty,": ",$err;
    }
  }
}

# $line is a line from the names or stripped file.
# Return the A-number string from the line such as "A000001",
# or empty string if unrecognised or a comment line etc.
sub line_to_anum {
  my ($self, $line) = @_;
  ### line_to_anum(): $line
  return ($line =~ /^(A\d{6,})/ ? $1 : '');
}

# $anum is an A-number string like "A000001".
# Return that number's line from the names or stripped file.
# If no such line then return undef.
# If a read error then croak.
sub anum_to_line {
  my ($self, $anum) = @_;
  ### $anum
  if (! ref $self) { $self = $self->instance; }
  my $fh = $self->fh || return undef;
  my $pos = Search::Dict::look ($fh, $anum,
                                { xfrm => sub {
                                    my ($line) = @_;
                                    ### $line
                                    my ($got_anum) = $self->line_to_anum($line)
                                      or return '';
                                    ### $got_anum
                                    return $got_anum;
                                  } });
  if ($pos < 0) {
    my $err = "$!";
    croak 'Error reading ',$self->filename_or_empty,': ',$err;
  }

  # Ensure the line is in fact the $anum requested, since a bad $anum causes
  # Search::Dict::look() to return the file position before where it would
  # be found if it were present.
  #
  my $line = readline $fh;
  ### found line: $line
  my $got_anum = $self->line_to_anum($line);
  ### $got_anum
  ### len: length($got_anum)
  ### which is anum: $self->line_to_anum($line)
  return ($self->line_to_anum($line) eq $anum
          ? $line
          : undef);
}

1;
__END__

=for stopwords Math OEIS Ryde

=head1 NAME

Math::OEIS::SortedFile - common parts of F<names> and F<stripped> file access

=head1 DESCRIPTION

This is an internal part of C<Math::OEIS::Names> and
C<Math::OEIS::Stripped>, not meant for external use.

=head1 SEE ALSO

L<Math::OEIS>,
L<Math::OEIS::Names>,
L<Math::OEIS::Stripped>

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
