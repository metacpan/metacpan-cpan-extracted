package IO::ReadHandle::Chain;

use v5.12.0;
use strict;
use warnings;

use Carp;
use IO::Handle qw(input_record_separator);
use Scalar::Util qw(blessed reftype);
use Symbol qw(gensym);

=head1 NAME

IO::ReadHandle::Chain - Chain several sources through a single file
read handle

=head1 VERSION

Version 1.1.0

=cut

use version; our $VERSION = version->declare('v1.1.0');

=head1 SYNOPSIS

This module chains any number of data sources (scalar, file, IO
handle) together for reading through a single file read handle.

This is convenient if you have multiple data sources of which some are
very large and you need to pretend that they are all inside a single
data source.

Use the IO::ReadHandle::Chain object for reading as you would any
other file handle.

    use IO::ReadHandle::Chain;

    open $ifh, '<', 'somefile.txt';
    $text = 'This is some text.';
    $cfh = IO::ReadHandle::Chain->new('file.txt', \$text, $ifh);
    print while <$cfh>;
    # prints lines from file 'file.txt', then lines from scalar $text,
    # then lines from file handle $ifh

    @lines = <$cfh>;              # or get all lines at once

    # or read bytes instead
    $buffer = '';
    $bytecount = read($cfh, $buffer, 100);
    $bytecount = sysread($cfh, $buffer, 100);

    # or single characters
    $c = getc($cfh);

    close($cfh);

    # OO, too
    $line = $cfh->getline;
    @lines = $cfh->getlines;
    $bytecount = $cfh->read($buffer, $size, $offset);
    $bytecount = $cfh->sysread($buffer, $size, $offset);
    $c = $cfh->getc;
    $cfh->close;
    print "end!\n" if $cfh->eof;

You cannot write or seek through an IO::ReadHandle::Chain.

When reading by lines, then for each data source the associated input
record separator is used to separate the data into lines.

For any of the data sources that are file handles, when the end of the
associated data stream is reached, or if the chain filehandle object
is closed, then the object tries to reset the file handle's position
to what it was when the module started reading from the file handle.

The chain filehandle object does not close any of the file handles
that are passed to it as data sources.

=head1 SUBROUTINES/METHODS

=head2 new(@sources)

Creates a filehandle object based on the specified C<@sources>.  The
sources are read in the order in which they are specified.  To read
from a particular file, specify that file's path as a source.  To read
the contents of a scalar, specify a reference to that scalar as a
source.  To read from an already open file handle, specify that file
handle as a source.

Croaks if any of the sources are not a scalar, a scalar reference, or
a file handle.

=cut

sub new {
  my ($class, @sources) = @_;
  my $ifh = gensym();                            # get generic symbol
  tie(*$ifh, __PACKAGE__, @sources);             # calls TIEHANDLE
  return $ifh;
}

sub TIEHANDLE {
  my ($class, @sources) = @_;
  foreach my $source (@sources) {
    croak "Sources must be scalar, scalar reference, or file handle"
      if ref($source) ne ''
      and reftype($source) ne 'GLOB'
      and reftype($source) ne 'SCALAR';
  }
  return bless { sources => \@sources }, $class;
}

sub EOF {
  my ($self) = @_;
  return 0 if $self->{ifh} && not($self->{ifh}->eof);

  while (not($self->{ifh}) || $self->{ifh}->eof) {
    if ($self->{ifh}) {
      if (exists $self->{initial_position}) {
        # Try to reset the file handle's position.  It may fail, for
        # example if the file handle is not seekable.
        eval { seek $self->{ifh}, $self->{initial_position}, 0 };
        delete $self->{initial_position};
      }
      delete $self->{ifh};
    }
    last unless @{$self->{sources}};
    my $source = shift @{$self->{sources}};
    my $ifh;
    if ((reftype($source) // '') eq 'GLOB') {
      $self->{ifh} = $source;
      $self->{initial_position} = tell($source);
    } elsif (ref($source) eq ''                 # read from  file
             or reftype($source) eq 'SCALAR') { # read from scalar
      open my $ifh, '<', $source or croak $!;
      $self->{ifh} = $ifh;
    } else {
      croak 'Unsupported source type ' . ref($source);
    }
  }

  if ($self->{ifh}) {
    # figure out this file's input record separator
    my $old = select($self->{ifh});
    $self->{input_record_separator} = $/;
    select($old);
    return '';
  } else {
    return 1;
  }
}

sub READLINE {
  my ($self) = @_;
  if (wantarray) {
    my @lines = ();
    my $line;
    push @lines, $line while $line = $self->READLINE;
    return @lines;
  } else {
    return undef if $self->EOF;

    # $self->EOF has lined up the next source in $self->{ifh}

    my $ifh = $self->{ifh};
    my $line = <$ifh>;
    if ($ifh->eof) {
      # Does line end in $ifh's input record separator?  If yes, then
      # return the line.  If no, then attempt to append the first line
      # from the next source.
      while ($line !~ m/$self->{input_record_separator}$/) {
        if ($ifh->eof) {
          last if $self->EOF;
          # $self->EOF has lined up the next source in $self->{ifh}
          $ifh = $self->{ifh};
        }
        $line .= <$ifh>;
      }
    }
    return $line;
  }
}

sub READ {
  my ($self, undef, $length, $offset) = @_;
  my $bufref = \$_[1];
  $offset //= 0;

  if ($self->EOF) {
    $$bufref = '';
    return 0;
  }

  # $self->EOF has lined up the next source in $self->{ifh}

  my $ifh = $self->{ifh};
  my $n = $ifh->read($$bufref, $length, $offset);
  while ($n < $length) {
    last if $self->EOF;
    # $self->EOF has lined up the next source in $self->{ifh}
    $ifh = $self->{ifh};
    my $thisn = $ifh->read($$bufref, $length - $n, $offset + $n);
    $n += $thisn;
  }
  return $n;
}

sub GETC {
  my ($self) = @_;
  my $buf = '';
  my $n = $self->READ($buf, 1, 0);
  return $n? $buf: undef;
}

sub CLOSE {
  my ($self) = @_;
  if ($self->{ifh}) {
    if (exists $self->{initial_position}) {
      # Try to reset the file handle's position.  It may fail, for
      # example if the file handle is not seekable.
      eval { seek $self->{ifh}, $self->{initial_position}, 0 };
      delete $self->{initial_position};
    }
    delete $self->{ifh};
    delete $self->{input_record_separator};
    @{$self->{sources}} = ();
  }
  return;
}

sub PRINT {
  my ($self) = @_;
  croak "Cannot print via a " . blessed($self);
}

sub PRINTF {
  my ($self) = @_;
  croak "Cannot printf via a " . blessed($self);
}

sub WRITE {
  my ($self) = @_;
  croak "Cannot syswrite via a " . blessed($self);
}

sub SEEK {
  my ($self) = @_;
  croak "Cannot seek via a " . blessed($self);
}

=head1 AUTHOR

Louis Strous, C<< <lstrous at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-io-readhandle-chain at rt.cpan.org>, or through the web
interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=IO-ReadHandle-Chain>.
I will be notified, and then you'll automatically be notified of
progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc IO::ReadHandle::Chain

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=IO-ReadHandle-Chain>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/IO-ReadHandle-Chain>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/IO-ReadHandle-Chain>

=item * Search CPAN

L<http://search.cpan.org/dist/IO-ReadHandle-Chain/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2017 Louis Strous.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

1; # End of IO::ReadHandle::Chain
