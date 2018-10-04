package IO::ReadHandle::Chain;

use v5.14;
use strict;
use warnings;

use Carp;
use Scalar::Util qw(reftype);
use Symbol qw(gensym);

=head1 NAME

B<IO::ReadHandle::Chain> - Chain several sources through a single file
read handle

=head1 VERSION

Version 1.2.2

=cut

use version; our $VERSION = version->declare('v1.2.2');

=head1 SYNOPSIS

    use IO::ReadHandle::Chain;

    open $ifh, '<', 'somefile.txt';
    $text = 'This is some text.';
    $cfh = IO::ReadHandle::Chain->new('file.txt', \$text, $ifh);
    print while <$cfh>;
    # prints lines from file 'file.txt', then lines from scalar $text,
    # then lines from file handle $ifh

    $line_number = $.; # cumulative line number from all sources

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
    $line_number = $cfh->input_line_number;
    $cfh->close;
    print "end!\n" if $cfh->eof;

    # specific to IO::ReadHandle::Chain:
    $current_source = $cfh->current_source;

    $cfh->set_field('mykey', $myvalue);
    $value = $cfh->get_field('mykey');
    $cfh->remove_field('mykey');

=head1 DESCRIPTION

This module chains any number of data sources (scalar, file, IO
handle) together for reading through a single file read handle.  This
is convenient if you have multiple data sources of which some are very
large and you need to pretend that they are all inside a single data
source.

Use the B<IO::ReadHandle::Chain> object for reading as you would any
other filehandle.

The module raises an exception if you try to C<write> or C<seek> or
C<tell> through an B<IO::ReadHandle::Chain>.

When reading by lines, then the input record separator
L<$E<sol>|perlvar/"$/"> is used to separate the data into lines.

The chain filehandle object does not close any of the file handles
that are passed to it as data sources.

An B<IO::ReadHandle::Chain> provides some methods that are not
available from a standard L<IO::Handle>:

The L</set_field>, L</get_field>, and L</remove_field> methods
manipulate fields in a private area of the object -- private in the
sense that the other methods of the module do not access that area;
It's all yours.

The L</current_source> method identifies the current source being read
from.

=head1 METHODS

=head2 new

  $cfh = IO::ReadHandle::Chain->new(@sources);

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
  my ( $class, @sources ) = @_;
  my $self = bless gensym(), ref($class) || $class;
  tie *$self, $self;
  return $self->open(@sources);
}

sub TIEHANDLE {
  return $_[0] if ref( $_[0] );
  my ( $class, @sources ) = @_;
  my $self = bless gensym(), $class;
  return $self->open(@sources);
}

# gets the specified field from the module's hash in the GLOB's hash
# part
sub _get {
  my ( $self, $field ) = @_;
  my $pkg = __PACKAGE__;
  return *$self->{$pkg}->{$field};
}

# sets the specified field in the module's hash in the GLOB's hash
# part to the specified value
sub _set {
  my ( $self, $field, $value ) = @_;
  my $pkg = __PACKAGE__;
  *$self->{$pkg}->{$field} = $value;
  return $self;
}

# if the $field is defined, then deletes the specified field from the
# module's hash in the object's hash part.  Otherwise, deletes the
# module's hash from the GLOB's hash part.
sub _delete {
  my ( $self, $field ) = @_;
  my $pkg = __PACKAGE__;
  if ( defined $field ) {
    delete *$self->{$pkg}->{$field};
  }
  else {
    delete *$self->{$pkg};
  }
  return $self;
}

=head2 close

  $cfh->close;
  close $cfh;

Closes the stream.  Closes any filehandles that the instance created,
but does not close any filehandles that were passed into the instance
as sources.

Returns the object.

=cut

sub close {
  my ($self) = @_;
  $self->_delete;
  return $self;
}

=head2 current_source

  $current_source = $cfh->current_source;

Returns text describing the source that the next input from the stream
will come from, or (at the end of the data) that the last input came
from.

For a source specified as a path name, returns that path name.

For a source specified as a filehandle, returns the result of calling
the C<current_source> method on that filehandle, unless it returns the
undefined value or the filehandle doesn't support the
C<current_source> method, in which case the current method returns the
stringified version of the filehandle.

For a source specified as a reference to a scalar, returns
C<SCALAR(...)> with the C<...> replaced with up to the first 10
characters of the scalar, with newlines replaced by spaces.

=cut

sub current_source {
  my ($self) = @_;
  my $source = $self->_get('source');
  return unless defined $source;
  if ( ref $source ) {
    if ( reftype($source) eq 'GLOB' ) {
      my $s = eval { $source->current_source };
      return defined($s) ? $s : "$source";
    }
    if ( reftype($source) eq 'SCALAR' ) {
      return sprintf( 'SCALAR(%.10s)', $$source =~ s/\n/ /gr );
    }
  }
  return $source;
}

=head2 eof

  $end_of_data = eof $cfh;
  $end_of_data = $cfh->eof;

Returns 1 when there is no (more) data to read from the stream, and
C<''> otherwise.

=cut

sub eof {
  return EOF(@_);
}

=head2 get_field

  $value = $cfh->get_field($field);
  $value = $cfh->get_field($field, $default);

Returns the value of the private field C<$field> from the filehandle.

If that field does not yet exist, and if C<$default> is not specified,
then does not modify the object and returns the undefined value.

If the field does not yet exist but C<$default> is specified, then
creates the field, assigns it the value C<$default>, and then returns
that value.

=cut

sub get_field {
  my ( $self, $field, $default ) = @_;
  my $href = $self->_get('_');
  if ( @_ >= 3 ) {    # $default specified
    if ( not $href ) {
      $href = {};
      $self->_set( '_', $href );
    }
    $href->{$field} //= $default;
  }
  else {              # no $default specified
    return unless $href;
  }
  return $href->{$field};
}

=head2 getc

  $char = $cfh->getc;
  $char = getc $ifh;

Returns the next character from the stream, or C<undef> if there are
no more characters.

=cut

sub getc {
  return GETC(@_);
}

=head2 getline

  $line = $cfh->getline;
  $line = <$cfh>;
  $line = readline $cfh;

Reads the next line from the stream.  The input record separator
(L<$E<sol>|perlvar/"$/">) or end-of-data mark the end of the line.

=cut

sub getline {
  my ($self) = @_;
  my $line = <$self>;
  return $line;
}

=head2 getlines

  @lines = $cfh->getlines;
  @lines = <$cfh>;

Reads all remaining lines from the stream.  The input record separator
(L<$E<sol>|perlvar/"$/">) or end-of-data mark the end of each line.

=cut

sub getlines {
  my ($self) = @_;
  my @lines = <$self>;
  return @lines;
}

=head2 input_line_number

  $line_number = $cfh->input_line_number;                # get
  $previous_value = $cfh->input_line_number($new_value); # set
  $line_number = $.;     # until next read from any filehandle

Returns the number of lines read through the filehandle, and makes
that number also available in the special variable L<$.|perlvar/$.>.
If no lines have been read yet, then returns the undefined value.

The line number is cumulative across all sources specified for the
B<IO::ReadHandle::Chain>.

If an argument is specified, then the method sets the current line
number to that value -- without changing the position in the stream.

=cut

sub input_line_number {
  my $self = shift;
  if (@_) {
    $self->_set( 'line_number', $_[0] );
  }
  return $self->_get('line_number');
}

=head2 open

  $cfh->open(@sources);

(Re)opens the B<IO::ReadHandle::Chain> object, for reading the
specified C<@sources>.  See L</new> for details about the C<@sources>.
Croaks if any of the sources are unacceptable.

Returns the B<IO::ReadHandle::Chain> on success.

=cut

sub open {
  my ( $self, @sources ) = @_;
  foreach my $source (@sources) {
    croak "Sources must be scalar, scalar reference, or file handle"
      if ref($source) ne ''
      and reftype($source) ne 'GLOB'
      and reftype($source) ne 'SCALAR';
  }

  # we must preserve the line number, but clear everything else
  my $line_number = $self->_get('line_number');
  $self->_delete;    # clear all
  $self->_set( line_number => $line_number );

  # store the new sources
  $self->_set( sources => \@sources );

  return $self;
}

=head2 read

  $cfh->read($buffer, $length, $offset);
  read $cfh, $buffer, $length, $offset;

Reads up to C<$length> characters from the stream into the C<$buffer>
at offset C<$offset>.  Returns the number of characters read, or 0
when there are no more characters.

=cut

sub read {
  return READ(@_);
}

=head2 remove_field

  $cfh->remove_field($field);

Removes the filehandle's private field with the specified name, if it
exists.  Returns the filehandle.

=cut

sub remove_field {
  my ( $self, $field ) = @_;
  my $href = $self->_get('_');
  if ($href) {
    delete $href->{$field};
  }
  return $self;
}

=head2 set_field

  $cfh->set_field($field, $value);

Sets the filehandle's private field with key C<$field> to the
specified C<$value>.  Returns the filehandle.

=cut

sub set_field {
  my ( $self, $field, $value ) = @_;
  my $href = $self->_get('_');
  if ( not $href ) {
    $self->_set( '_', $href = {} );
  }
  $href->{$field} = $value;
  return $self;
}

# Tie::Handle method implementations

sub EOF {
  my ($self) = @_;
  my $ifh = $self->_get('ifh');
  return '' if $ifh && not( $ifh->eof );

  while ( not( $self->_get('ifh') ) || $self->_get('ifh')->eof ) {
    if ( $self->_get('ifh') ) {
      $self->_delete('ifh');
    }
    my $sources_lref = $self->_get('sources');
    last unless $sources_lref && @{$sources_lref};
    my $source = shift @{$sources_lref};
    $self->_set( source => $source );
    if ( ( reftype($source) // '' ) eq 'GLOB' ) {
      $self->_set( ifh => $source );
    }
    elsif (
      ref($source) eq ''    # read from  file
      or reftype($source) eq 'SCALAR'
      )
    {                       # read from scalar
      CORE::open my $ifh, '<', $source or croak $!;
      $self->_set( ifh => $ifh );
    }
    else {
      croak 'Unsupported source type ' . ref($source);
    }
  }

  my $result;
  if ( $self->_get('ifh') ) {
    $result = '';
  }
  else {
    $result = 1;
  }
  $. = $self->_get('line_number');
  return $result;
}

sub READLINE {
  my ($self) = @_;
  if (wantarray) {
    my @lines = ();
    my $line;
    push @lines, $line while $line = $self->READLINE;
    return @lines;
  }
  else {
    if ( $self->EOF ) {
      $. = $self->_get('line_number');
      return;
    }

    # $self->EOF has lined up the next source in $self->{ifh}

    my $ifh  = $self->_get('ifh');
    my $line = <$ifh>;
    if ( $ifh->eof ) {

      # Does line end in the input record separator?  If yes, then
      # return the line.  If no, then attempt to append the first line
      # from the next source.
      while ( $line !~ m#$/$# ) {
        if ( $ifh->eof ) {
          last if $self->EOF;

          # $self->EOF has lined up the next source in $self->{ifh}
          $ifh = $self->_get('ifh');
        }
        $line .= <$ifh>;
      }
    }
    if ( defined $line ) {
      $self->_set( line_number => ( $self->_get('line_number') // 0 ) + 1 );
      $. = $self->_get('line_number');
    }
    return $line;
  }
}

sub READ {
  my ( $self, undef, $length, $offset ) = @_;
  my $bufref = \$_[1];
  $offset //= 0;

  # Adjust buffer for appending at $offset: Any previous contents
  # beyond that offset are lost.  If the buffer is not that long, then
  # pad with \0 until it is long enough.  (This is what CORE::read
  # does, too.)

  $$bufref //= '';
  my $l = length($$bufref);
  if ( $offset < 0 ) {
    $offset = $l - $offset;
    if ( $offset < 0 ) {

      # TODO: what does CORE::read do in this case?
      $offset = 0;
    }
  }
  if ( $offset < $l ) {

    # chop off everything beyond $offset
    substr $$bufref, $offset, $l - $offset, '';
  }
  elsif ( $offset > $l ) {

    # pad \0 until the offset
    $$bufref .= '\x0' x ( $offset - $l );
  }

  if ( $self->EOF ) {
    return 0;
  }

  # $self->EOF has lined up the next source in $self->{ifh}

  my $ifh = $self->_get('ifh');
  my $n = $ifh->read( $$bufref, $length, $offset );
  while ( $ifh->eof && $n < $length ) {
    last if $self->EOF;

    # $self->EOF has lined up the next source in $self->{ifh}
    $ifh = $self->_get('ifh');
    my $thisn = $ifh->read( $$bufref, $length - $n, $offset + $n );
    $n += $thisn;
  }
  return $n;
}

sub GETC {
  my ($self) = @_;
  my $buf = '';
  my $n = $self->READ( $buf, 1, 0 );
  return $n ? $buf : undef;
}

sub CLOSE {
  my ($self) = @_;
  if ( $self->{ifh} ) {
    delete $self->{ifh};
    @{ $self->{sources} } = ();
  }
  return;
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

Copyright 2017, 2018 Louis Strous.

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

=head1 SEE ALSO

L<IO::ReadHandle::Include>.

=cut

1;    # End of IO::ReadHandle::Chain
