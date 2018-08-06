package IO::ReadHandle::Include;

use 5.006;
use strict;
use warnings;

use Carp;
use Path::Class qw(file);
use Scalar::Util qw(blessed reftype);
use Symbol qw(gensym);

use parent qw(IO::Handle);

=head1 NAME

B<IO::ReadHandle::Include> - A filehandle for reading with include
facility

=head1 VERSION

Version 1.1

=cut

use version; our $VERSION = version->declare('v1.1');

=head1 SYNOPSIS

    use IO::ReadHandle::Include;

    open $ofh1, '>', 'extra.txt';
    print $ofh1 "Extra, extra!  Read all about it!\n";
    close $ofh1;

    open $ofh2, '>', 'file.txt';
    print $ofh2 <<EOD;
    The paperboy said:
    #include extra.txt
    and then he ran off.
    EOD
    close $ofh2;

    $ifh = IO::ReadHandle::Include
      ->new({ source => 'file.txt',
              include => qr/^#include (.*)$/) });
    print while <$ifh>;
    close $ifh;

    # prints:
    #
    # The paperboy said:
    # Extra, extra!  Read all about it!
    # and then he ran off.

=head1 DESCRIPTION

This module produces filehandles for reading from a source text file
and any number of included files, identified from include directives
found in the read text.

Filehandle functions/methods associated with writing cannot be used
with an B<IO::ReadHandle::Include> object.

=head2 INCLUDE DIRECTIVES AND THE READLINE FUNCTION

The include directives are identified through a regular expression
(L</new>).

  $ifh = IO::ReadHandle::Include->new({ include => $regex, ... });

If the text read from the source file matches the regular expression,
then, in the output, the part of the text matching the regular
expression is replaced with the contents of the identified include
file, if that include file exists.  This works recursively: The
included file can itself include other files, using the same format
for include directives.  If an include file does not exist, then the
include directive naming that file is not replaced.

The include file is identified by the text corresponding to a
particular capture group (C<< (?<include>...) >> or C<$1>) of the
regular expression.  For example, given the two lines of text

  #include foo.txt
  #include "bar.txt"

the regular expression

  qr/^#include (?|"(.*?)"|(.*))$/

identifies C<foo.txt> and C<bar.txt> as the include files through
C<$1>, and the regular expression

  qr/^#include ("?)(?<include>.*?)\g{1}$/

does the same through C<$+{include}>.

The text is transformed if a transformation code reference is defined
(L</set_transform>).  The final text is interpreted as the path to the
file to include at this point.

Text is read from the source file and the included files piece by
piece.  If you're unlucky, then the piece most recently read ends in
the middle of an include directive, and then the current module cannot
detect that include directive because it isn't complete yet.

To resolve this problem, the current module assumes that if the
regular expression matches the input record separator, then it must be
at the very end of the regular expression.  If any piece of text
ending with the input record separator does not match the regular
expression, then the current module concludes that that piece of text
does not contain an include directive.

This means that an include directive should not contain an input
record separator L<$E<sol>|perlvar/"$/"> (by default a newline),
except perhaps at the very end.  Otherwise the include directive may
not always be recognized.

This works well for the L<CORE::readline|perlfunc/readline> function,
for the L</getline> and L</getlines> methods, and for the angle
brackets operator (C<< <$ih> >>), which read text up to and including
the input record separator (or the end of the data, whichever comes
first).

=head2 INCLUDE DIRECTIVES AND THE READ FUNCTION

Function L<CORE::read|perlfunc/read> and method L</read> read up to a
user-selected number of characters from the source.  The read chunk of
text does not necessarily end with the input record separator, so it
might end in the middle of an include directive, and then the include
directive cannot be recognized.

To resolve this problem, the L</read> function/method when called on
an IO::ReadHandle::Include object by default quietly read beyond the
requested number of characters until the next input record separator
or the end of the data is seen, so it can properly detect and resolve
any include directives.  It then returns only up to the requested
number of characters, and remembers the remainder for the next call.

This means that if the source file or an include file contains no
input record separator at all and is read using the L</read>
function/method, then the entire contents of the source and/or include
file are read into memory at once.

When using the L</read> function/method to read the text, you don't
know beforehand how many lines of text you get.  This can be a problem
if the transformation of include path names from later lines of text
may depend on something seen in earlier lines of text.  Any change
that gets made to the transformation (via L</set_transform>) can apply
only to include directives that haven't been resolved yet -- so they
cannot apply to any include directives that were resolved while
processing the L</read> call that produced the text that indicates the
need to change the transformation.

In such a case, use the L</set_read_by_lines> method to indicate that
you want L</read> to return text that does not extend beyond the first
input record separator -- i.e., at most one line of text.  You may
then get fewer characters from a call to L</read> than you asked for,
even if there is still more text in the source.

=head2 LINE NUMBER

The value of the line number special variable L<$.|perlvar/$.> is
supposed to be equal to the number of lines read through the last used
filehandle, but for an B<IO::ReadHandle::Include>, that value is not
trustworthy.  It takes a lot more bookkeeping to make it trustworthy.

=head2 PRIVATE FIELDS

B<IO::ReadHandle::Include> objects support the use of private fields
stored within the object.  L</set_field> sets such a field,
L</get_field> queries it, and L</remove_field> removes it again.

These fields can be used, for example, to pass information from the
application using the object to the include path transformation code
(L</set_transform>) to guide the transformation.

The fields are private in the sense that an B<IO::ReadHandle::Include>
object does not itself access them, so they're all yours.

=head1 SUBROUTINES/METHODS

=head2 new

  $ifh = IO::ReadHandle::Include->new({ source => $source,
                                        include => $regex,
                                        transform => $coderef });

Creates an object that can be used as a filehandle for reading, with
include files.

The C<$source> is the path to the main file to read from, if it is a
scalar.  If it is a filehandle, then the main contents are read from
that filehandle.

The C<$regex> is a regular expression that identifies an include
directive.  If the regular expression defines a capture group called
C<include> (C<< (?<include>...) >>), then its value identifies the
file to include.  Otherwise, the first capture group identifies the
file to include.  If the include file path is relative, then it is
interpreted relative to the path of the file from which the include
directive was read.

The C<$coderef>, if specified, must be a reference to code,
i.e. C<\&foo> for a reference to function C<foo>, or C<sub { ... }>
for a reference to an anonymous block of code.  That code is used to
transform the path name of the include file.  The reference gets
called as

  $path = $coderef->($path, $ifh);

where C<$path> is the path name extracted from the include directive,
and C<$ifh> is the B<IO::ReadHandle::Include> object.  You can use the
latter, for example, to access the private area of the
B<IO::ReadHandle::Include> to assist the transformation
(L</get_field>).  The result of executing the code reference is used
as the path of the include file to open.

=cut

sub new {
  my ( $class, @args ) = @_;
  my $self = bless gensym(), ref($class) || $class;
  tie *$self, $self;
  return $self->open(@args);
}

# for Tie::Handle
sub TIEHANDLE {
  return $_[0] if ref( $_[0] );
  my ( $class, @args ) = @_;
  my $self = bless gensym(), $class;
  return $self->open(@args);
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
  my $pkg       = __PACKAGE__;
  my $old_value = *$self->{$pkg}->{$field};
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

  $ifh->close;
  close $ifh;

Closes the B<IO::ReadHandle::Include>.  Closes any internal
filehandles that the instance was using, but if the main source was
passed as a filehandle then that filehandle is not closed.

=cut

# for Tie::Handle, close the handle
sub CLOSE {
  my ($self) = @_;

  # close any included files
  1 while $self->_end_include;

  if ( reftype( $self->_get('main_source') ) eq '' ) {

    # the main source was passed as a scalar, so we opened its
    # filehandle
    my $ifh = $self->_get('ifh');
    if ($ifh) {
      close $ifh;
    }
  }    # otherwise the main source was passed as a filehandle; we don't
       # close it because we did not open it, either.
  $self->_delete;
}

=head2 current_source

  $current_source = $ifh->current_source;

Returns text describing the main source or include file that the next
input through B<IO::ReadHandle::Include> will come from, or (at the
end of the stream) that the last input came from.

For a main source specified as a path name, or for an included file,
returns the path name.

For a main source specified as a filehandle, returns the result of
calling the C<current_source> method on that filehandle, unless it
returns the undefined value or the filehandle doesn't support the
C<current_source> method, in which case the current method returns the
stringified version of the filehandle.

NOTE: The result of this method is not always accurate.  Currently, it
in fact describes the source that data will be I<read from> next, but
that is not always the source of the data that is I<returned> next,
because in some circumstances data gets buffered and returned only
later, when the source from where it came may already have run dry.

The results of this method are only accurate if (1) all of the data is
read by lines, and (2) the include directive always comes at the very
end of a line.

Making this method always accurate requires a lot more internal
bookkeeping.

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
  }
  return $source;
}

=head2 eof

  $end_of_data = eof $ifh;
  $end_of_data = $ifh->eof;

Returns 1 when there is no (more) data to read through the
B<IO::ReadHandle::Include>, and C<''> otherwise, similar to
L<CORE::eof|perlfunc/eof> and L<IO::Handle/eof>.

=cut

sub eof {
  return EOF(@_);
}

# for Tie::Handle: are we at the end of the data?
sub EOF {
  my ($self) = @_;
  my $buffer = $self->_get('buffer');
  return '' if $buffer;

  my $ifh = $self->_get('ifh');
  return '' if $ifh    # we've started reading
    && not( $ifh->eof );    # and aren't at the end of the current source

  # If we get here, then either we hadn't started reading yet, or else
  # we're at the end of the current source.

  if ($ifh) {    # we had started reading already,
                 # so the current source is exhausted.
    if ( not $self->_end_include ) {

      # we were reading from the main file
      return 1;
    }    # otherwise we were inside an include file and have now reverted
         # to the including file, and need to check if it is at EOF
  }
  else {    # haven't opened the main source yet, Do it now and
            # initialize appropriately
    my $source = $self->_get('source');
    if ( ref($source) && reftype($source) eq 'GLOB' ) {
      $ifh = $source;
    }
    else {
      CORE::open $ifh, '<', $source
        or croak "Cannot open '$source' for reading: $!";
    }
    $self->_set( ifh => $ifh )->_set( ifhs => [] )->_set( suffixes => [] )
      ->_set( sources => [] )->_set( buffer => '' );
  }
  return $self->EOF;
}

=head2 get_field

  $value = $ifh->get_field($field);
  $value = $ifh->get_field($field, $default);

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

=head2 getline

  $line = $ifh->getline;
  $line = <$ifh>;
  $line = readline $ifh;

Reads the next line from the B<IO::ReadHandle::Include>.  The input
record separator (L<$E<sol>|perlvar/"$/">) or end-of-data mark the end
of the line.

=head2 getlines

  @lines = $ifh->getlines;
  @lines = <$ifh>;

Reads all remaining lines from the B<IO::ReadHandle::Include>.  The
input record separator (L<$E<sol>|perlvar/"$/">) or end-of-data mark
the end of each line.

=cut

# for Tie::Handle, read a line
sub READLINE {
  my ($self) = @_;
  if (wantarray) {
    my @lines = ();
    while ( my $line = $self->READLINE ) {
      push @lines, $line;
    }
    return @lines;
  }
  else {
    return if $self->EOF;

    my $line = $self->_getline;
    while ( $line !~ m#$/$# ) {

      # no input record separator at the end; we must have reached the
      # end of the file -- maybe an included file.
      last if $self->EOF;
      $line .= $self->_getline;
    }
    if ( $line =~ $self->_get('include') ) {

      # the regex matched: include another file
      my $path = $+{include} // $1;
      croak "No include file path detected" unless $path;
      my $coderef = $self->_get('transform');
      if ($coderef) {
        $path = $coderef->( $path, $self );
      }
      $path = file($path);
      if ( $path->is_relative ) {

        # the path is relative; it is relative to the directory of the
        # including file
        $path = file( file( $self->_get('source') )->parent, $path );
      }
      if ( CORE::open my $newifh, '<', "$path" ) {
        my $suffix = substr( $line, $+[0] );    # text beyond the regex match
        push @{ $self->_get('suffixes') }, $suffix;    # save for later

        push @{ $self->_get('ifhs') }, $self->_get('ifh');    # save for later
        push @{ $self->_get('sources') },
          $self->_get('source');                              # save for later

        $self->_set( ifh => $newifh )    # current source is included file
          ->_set( source => $path );     # current source
        $line = substr( $line, 0, $-[0] )    # text before the regex match
          . $self->READLINE;    # append first line from included file
      }    # otherwise we leave the original text
    }
    return $line;
  }
}

=head2 input_line_number

  $line_number = $ifh->input_line_number;
  $line_number = $.;

Returns the number of lines read through the
B<IO::ReadHandle::Include> (first example) or through the last used
filehandle (second example).

NOTE: The result of this method is not always accurate, because the
current module may need to read ahead and buffer some data in order to
properly detect and resolve include directives.

The results of this method are accurate if (1) all of the data is read
by lines, and (2) the include directive always comes at the very end
of a line.

=head2 open

  $ih->open({ source => $source,
              include => $regex,
              transform => $coderef });

(Re)opens the B<IO::ReadHandle::Include> object.  See L</new> for
details about the arguments.

=cut

sub open {
  my ( $self, @args ) = @_;
  my $source;
  my $regex;
  my $coderef;
  if ( @args == 1 && ref( $args[0] ) && reftype( $args[0] ) eq 'HASH' ) {
    $source  = $args[0]->{source};
    $regex   = $args[0]->{include};
    $coderef = $args[0]->{transform};
  }
  else {
    croak "Expected a single argument, a reference to a hash.";
  }
  croak "Source must be a scalar or filehandle"
    if ref($source) ne ''
    and reftype($source) ne 'GLOB';
  croak "Include specification must be a regular expression"
    if not($regex)
    or reftype($regex) ne 'REGEXP';
  croak "Transform, if set, must be a code reference"
    if $coderef and reftype($coderef) ne 'CODE';
  $self->_set( source => $source )->_set( main_source => $source )
    ->_set( include => $regex )->_set( transform => $coderef );
  return $self;
}

# If we're reading from an included file, then act as if that included
# file is exhausted: close it, revert to the including file, and
# return 1.  Otherwise return 0.
sub _end_include {
  my ($self) = @_;
  my $ifh = $self->_get('ifh');
  if ($ifh) {    # already reading
    my $ifhs = $self->_get('ifhs');
    if (@$ifhs) {    # inside an include file
      close $ifh;    # close the included file
      $self->_set( ifh => pop @{$ifhs} )    # revert to including file
        ->_set(
        buffer => $self->_get('buffer') . pop @{ $self->_get('suffixes') } )
        ->_set( source => pop @{ $self->_get('sources') } );
      return 1;
    }    # otherwise we're in the main file
  }    # otherwise it's a no-op
  return 0;
}

# returns the next line of input, taking into account any buffered
# input.
sub _getline {
  my ($self) = @_;
  my $line   = '';
  my $buffer = $self->_get('buffer');
  if ($buffer) {
    $line = $buffer;
    $self->_set( buffer => '' );
    if ( $line =~ m#$/$# ) {
      return $line;
    }
  }
  my $ifh = $self->_get('ifh');
  if ( not CORE::eof($ifh) ) {

    # If I combine the next two statements into one, then <$ifh> is
    # evaluated in list context (i.e., read all remaining lines) and
    # then converted to scalar context (i.e., yield the number of
    # lines read).  This is not what we want, so keep them separate.
    my $nextline = <$ifh>;
    $line .= $nextline;
  }
  return $line;
}

=head2 read

  $ifh->read($buffer, $length, $offset);
  read $ifh, $buffer, $length, $offset;

Read up to C<$length> characters from the B<IO::ReadHandle::Include>
into the C<$buffer> at offset C<$offset>, similar to the
L<CORE::read|perlfunc/read> function.  Returns the number of
characters read, or 0 when there are no more characters.

If L</set_read_by_lines> is active, then the reading stops after the
first encountered input record separator (L<$E<sol>|perlvar/"$/">),
even if the requested number of characters has not been reached yet.

=cut

# for Tie::Handle, read bytes
sub READ {
  my ( $self, undef, $length, $offset ) = @_;
  my $bufref = \$_[1];
  $offset //= 0;

  # Adjust buffer for appending at $offset: Any previous contents
  # beyond that offset are lost.  If the buffer is not that long, then
  # pad with \0 until it is long enough.  (This is what CORE::read
  # does, too.)

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

  # we obtain data using READLINE, because only then can we reliably
  # detect include directives.  See main POD for an explanation.

  # calling READLINE updates the line number, which READ isn't
  # supposed to do.  Remember the current value, so we can restore it
  # later.
  my $old_dot = $.;

  my $line;
  my $n;
  if ( $self->_get('read_by_line') ) {

    # return at most a single line
    $line = $self->READLINE;
    $n    = length($line);
  }
  else {
    # return data until the requested number of characters is reached
    # or the data runs out.
    $line = '';
    $n    = 0;
    while ( $n < $length && not $self->EOF ) {
      $line .= $self->READLINE;
      $n = length($line);
    }
  }

  # restore old line number
  $. = $old_dot;

  if ( $n > $length ) {

    # we read more than was requested.  Remember the excess for next
    # time (managed by READLINE).  We divide $line into a first part
    # with the desired $length, and a second part beyond that length,
    # which we prepend to the buffer.
    $self->_set(
      buffer => substr( $line, $length, $n, '' ) . $self->_get('buffer') );
    $n = $length;
  }
  $$bufref .= $line;
  return $n;
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

=head2 seek

  seek $ifh, $pos, $whence;
  $ifh->seek($pos, $whence);

Sets the B<IO::ReadHandle::Include> filehandle's position, similar to
the L<CORE::seek|perlfunc/seek> function -- but at present the support
is very limited.

C<$whence> indicates relative to what the target position C<$pos> is
specified.  This can be 0 for the beginning of the data, 1 for the
current position, or 2 for the end of the data.

C<$pos> says how many bytes beyond the position indicated by
C<$whence> to set the filehandle to.  At present, C<$pos> must be
equal to 0, otherwise the method croaks.  So, the position can only be
set to the very beginning, the very end, or the current position.
Supporting more requires a lot more bookkeeping.

Returns 1 on success, false otherwise.

=cut

sub seek {
  return SEEK(@_);
}

# for Tie::Handle, seek.  We support only seeking to the beginning,
# end, or current position.  For anything else we'd need to do a lot
# of additional bookkeeping.
sub SEEK {
  my ( $self, $position, $whence ) = @_;
  if ( $position == 0 ) {
    if ( $whence != 1 ) {

      # seek to the very beginning or end

      # close any included files
      1 while $self->_end_include;
      return CORE::seek( $self->_get('ifh'), $position, $whence );
    }    # otherwise we seek to where we already are: a no-op
  }
  else {
    croak
      "Cannot seek to anywhere except here or the beginning or the end via a "
      . blessed($self);
  }
  return 1;
}

=head2 set_field

  $ifh->set_field($field, $value);

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

=head2 set_read_by_line

  $ifh->set_read_by_line($value);
  $ifh->set_read_by_line;

Configures whether L</read> can return more than a single line's worth
of data per call.

By default, a single L</read> call reads and returns data until the
requested number of characters has been read or until it runs out of
data, whichever comes first.  If C<set_read_by_line> is called without
an argument or with an argument that is a true value (e.g., 1), then
subsequent calls of L</read> return at most the next line, as defined
by the input record separator L<$E<sol>|perlvar/"S/"> -- or less, if
the requested number of characters has been reached.  If
C<set_read_by_line> is called with an argument that is a false value
(e.g., 0), then L</read> reverts to its default behavior.

=cut

sub set_read_by_line {
  my ( $self, $value ) = @_;
  $value //= 1;
  $self->_set( 'read_by_line', $value );
}

=head2 set_transform

  $ifh->set_transform($coderef);

Sets the transformation code reference, with the same purpose as the
C<transform> parameter of L</new>.  Returns the object.

=cut

sub set_transform {
  my ( $self, $coderef ) = @_;
  croak "Transform must be a code reference"
    unless ref($coderef) eq 'CODE';
  $self->_set( transform => $coderef );
  return $self;
}

=head1 AUTHOR

Louis Strous, C<< <lstrous at cpan.org> >>

=head1 BUGS

=head2 KNOWN BUGS

Resolving these bugs requires much more bookkeeping.

=over

=item

The result of L</input_line_number> (and L<$.|perlvar/$.>) may not be
accurate.

=item

The result of L</current_source> may not be accurate.

=item

L</seek> can only be used to go to the very beginning, the current
position, or the very end of the stream.

=item

L</tell> cannot be used on an B<IO::ReadHandle::Include>.

=back

=head2 REPORT BUGS

Please report any bugs or feature requests to
C<bug-io-readhandle-include at rt.cpan.org>, or through the web
interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=IO-ReadHandle-Include>.
I will be notified, and then you'll automatically be notified of
progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc IO::ReadHandle::Include


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=IO-ReadHandle-Include>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/IO-ReadHandle-Include>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/IO-ReadHandle-Include>

=item * Search CPAN

L<http://search.cpan.org/dist/IO-ReadHandle-Include/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2018 Louis Strous.

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

L<IO::ReadHandle::Chain>.

=cut

1;    # End of IO::ReadHandle::Include
