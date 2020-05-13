#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2011-2015 -- leonerd@leonerd.org.uk

package IO::Async::FileStream;

use strict;
use warnings;

our $VERSION = '0.77';

use base qw( IO::Async::Stream );

use IO::Async::File;

use Carp;
use Fcntl qw( SEEK_SET SEEK_CUR );

=head1 NAME

C<IO::Async::FileStream> - read the tail of a file

=head1 SYNOPSIS

 use IO::Async::FileStream;

 use IO::Async::Loop;
 my $loop = IO::Async::Loop->new;

 open my $logh, "<", "var/logs/daemon.log" or
    die "Cannot open logfile - $!";

 my $filestream = IO::Async::FileStream->new(
    read_handle => $logh,

    on_initial => sub {
       my ( $self ) = @_;
       $self->seek_to_last( "\n" );
    },

    on_read => sub {
       my ( $self, $buffref ) = @_;

       while( $$buffref =~ s/^(.*\n)// ) {
          print "Received a line $1";
       }

       return 0;
    },
 );

 $loop->add( $filestream );

 $loop->run;

=head1 DESCRIPTION

This subclass of L<IO::Async::Stream> allows reading the end of a regular file
which is being appended to by some other process. It invokes the C<on_read>
event when more data has been added to the file. 

This class provides an API identical to L<IO::Async::Stream> when given a
C<read_handle>; it should be treated similarly. In particular, it can be given
an C<on_read> handler, or subclassed to provide an C<on_read> method, or even
used as the C<transport> for an L<IO::Async::Protocol::Stream> object.

It will not support writing.

To watch a file, directory, or other filesystem entity for updates of other
properties, such as C<mtime>, see also L<IO::Async::File>.

=cut

=head1 EVENTS

The following events are invoked, either using subclass methods or CODE
references in parameters.

Because this is a subclass of L<IO::Async::Stream> in read-only mode, all the
events supported by C<Stream> relating to the read handle are supported here.
This is not a full list; see also the documentation relating to
L<IO::Async::Stream>.

=head2 $ret = on_read \$buffer, $eof

Invoked when more data is available in the internal receiving buffer.

Note that C<$eof> only indicates that all the data currently available in the
file has now been read; in contrast to a regular L<IO::Async::Stream>, this
object will not stop watching after this condition. Instead, it will continue
watching the file for updates.

=head2 on_truncated

Invoked when the file size shrinks. If this happens, it is presumed that the
file content has been replaced. Reading will then commence from the start of
the file.

=head2 on_initial $size

Invoked the first time the file is looked at. It is passed the initial size of
the file. The code implementing this method can use the C<seek> or
C<seek_to_last> methods to set the initial read position in the file to skip
over some initial content.

This method may be useful to skip initial content in the file, if the object
should only respond to new content added after it was created.

=cut

sub _init
{
   my $self = shift;
   my ( $params ) = @_;

   $self->SUPER::_init( $params );

   $params->{close_on_read_eof} = 0;

   $self->{last_size} = undef;

   $self->add_child( $self->{file} = IO::Async::File->new(
      on_devino_changed => $self->_replace_weakself( 'on_devino_changed' ),
      on_size_changed   => $self->_replace_weakself( 'on_size_changed' ),
   ) );
}

=head1 PARAMETERS

The following named parameters may be passed to C<new> or C<configure>, in
addition to the parameters relating to reading supported by
L<IO::Async::Stream>.

=head2 filename => STRING

Optional. If supplied, watches the named file rather than the filehandle given
in C<read_handle>. The file will be opened by the constructor, and then
watched for renames. If the file is renamed, the new filename is opened and
tracked similarly after closing the previous file.

=head2 interval => NUM

Optional. The interval in seconds to poll the filehandle using C<stat(2)>
looking for size changes. A default of 2 seconds will be applied if not
defined.

=cut

sub configure
{
   my $self = shift;
   my %params = @_;

   foreach (qw( on_truncated on_initial )) {
      $self->{$_} = delete $params{$_} if exists $params{$_};
   }

   foreach (qw( interval )) {
      $self->{file}->configure( $_ => delete $params{$_} ) if exists $params{$_};
   }
   if( exists $params{filename} ) {
      $self->{file}->configure( filename => delete $params{filename} );
      $params{read_handle} = $self->{file}->handle;
   }
   elsif( exists $params{handle} or exists $params{read_handle} ) {
      my $handle = delete $params{handle};
      defined $handle or $handle = delete $params{read_handle};

      $self->{file}->configure( handle => $handle );
      $params{read_handle} = $self->{file}->handle;
   }

   croak "Cannot have a write_handle in a ".ref($self) if defined $params{write_handle};

   $self->SUPER::configure( %params );

   if( $self->read_handle and !defined $self->{last_size} ) {
      my $size = (stat $self->read_handle)[7];

      $self->{last_size} = $size;

      local $self->{running_initial} = 1;
      $self->maybe_invoke_event( on_initial => $size );
   }
}

=head1 METHODS

=cut

# Replace IO::Async::Handle's implementation
sub _watch_read
{
   my $self = shift;
   my ( $want ) = @_;

   if( $want ) {
      $self->{file}->start if !$self->{file}->is_running;
   }
   else {
      $self->{file}->stop;
   }
}

sub _watch_write
{
   my $self = shift;
   my ( $want ) = @_;

   croak "Cannot _watch_write in " . ref($self) if $want;
}

sub on_devino_changed
{
   my $self = shift or return;

   $self->{renamed} = 1;
   $self->debug_printf( "read tail of old file" );
   $self->read_more;
}

sub on_size_changed
{
   my $self = shift or return;
   my ( $size ) = @_;

   if( $size < $self->{last_size} ) {
      $self->maybe_invoke_event( on_truncated => );
      $self->{last_pos} = 0;
   }

   $self->{last_size} = $size;

   $self->debug_printf( "read_more" );
   $self->read_more;
}

sub read_more
{
   my $self = shift;

   sysseek( $self->read_handle, $self->{last_pos}, SEEK_SET ) if defined $self->{last_pos};

   $self->on_read_ready;

   $self->{last_pos} = sysseek( $self->read_handle, 0, SEEK_CUR ); # == systell

   if( $self->{last_pos} < $self->{last_size} ) {
      $self->loop->later( sub { $self->read_more } );
   }
   elsif( $self->{renamed} ) {
      $self->debug_printf( "reopening for rename" );

      $self->{last_size} = 0;

      if( $self->{last_pos} ) {
         $self->maybe_invoke_event( on_truncated => );
         $self->{last_pos} = 0;
         $self->loop->later( sub { $self->read_more } );
      }

      $self->configure( read_handle => $self->{file}->handle );
      undef $self->{renamed};
   }
}

sub write
{
   carp "Cannot ->write from a ".ref($_[0]);
}

=head2 seek

   $filestream->seek( $offset, $whence )

Callable only during the C<on_initial> event. Moves the read position in the
filehandle to the given offset. C<$whence> is interpreted as for C<sysseek>,
should be either C<SEEK_SET>, C<SEEK_CUR> or C<SEEK_END>. Will be set to
C<SEEK_SET> if not provided.

Normally this would be used to seek to the end of the file, for example

 on_initial => sub {
    my ( $self, $filesize ) = @_;
    $self->seek( $filesize );
 }

=cut

sub seek
{
   my $self = shift;
   my ( $offset, $whence ) = @_;

   $self->{running_initial} or croak "Cannot ->seek except during on_initial";

   defined $whence or $whence = SEEK_SET;

   sysseek( $self->read_handle, $offset, $whence );
}

=head2 seek_to_last

   $success = $filestream->seek_to_last( $str_pattern, %opts )

Callable only during the C<on_initial> event. Attempts to move the read
position in the filehandle to just after the last occurrence of a given match.
C<$str_pattern> may be a literal string or regexp pattern. 

Returns a true value if the seek was successful, or false if not. Takes the
following named arguments:

=over 8

=item blocksize => INT

Optional. Read the file in blocks of this size. Will take a default of 8KiB if
not defined.

=item horizon => INT

Optional. Give up looking for a match after this number of bytes. Will take a
default value of 4 times the blocksize if not defined.

To force it to always search through the entire file contents, set this
explicitly to C<0>.

=back

Because regular file reading happens synchronously, this entire method
operates entirely synchronously. If the file is very large, it may take a
while to read back through the entire contents. While this is happening no
other events can be invoked in the process.

When looking for a string or regexp match, this method appends the
previously-read buffer to each block read from the file, in case a match
becomes split across two reads. If C<blocksize> is reduced to a very small
value, take care to ensure it isn't so small that a match may not be noticed.

This is most likely useful for seeking after the last complete line in a
line-based log file, to commence reading from the end, while still managing to
capture any partial content that isn't yet a complete line.

 on_initial => sub {
    my $self = shift;
    $self->seek_to_last( "\n" );
 }

=cut

sub seek_to_last
{
   my $self = shift;
   my ( $str_pattern, %opts ) = @_;

   $self->{running_initial} or croak "Cannot ->seek_to_last except during on_initial";

   my $offset = $self->{last_size};

   my $blocksize = $opts{blocksize} || 8192;

   defined $opts{horizon} or $opts{horizon} = $blocksize * 4;
   my $horizon = $opts{horizon} ? $offset - $opts{horizon} : 0;
   $horizon = 0 if $horizon < 0;

   my $re = ref $str_pattern ? $str_pattern : qr/\Q$str_pattern\E/;

   my $prev = "";
   while( $offset > $horizon ) {
      my $len = $blocksize;
      $len = $offset if $len > $offset;
      $offset -= $len;

      sysseek( $self->read_handle, $offset, SEEK_SET );
      sysread( $self->read_handle, my $buffer, $blocksize );

      # TODO: If $str_pattern is a plain string this could be more efficient
      # using rindex
      if( () = ( $buffer . $prev ) =~ m/$re/sg ) {
         # $+[0] will be end of last match
         my $pos = $offset + $+[0];
         $self->seek( $pos );
         return 1;
      }

      $prev = $buffer;
   }

   $self->seek( $horizon );
   return 0;
}

=head1 TODO

=over 4

=item *

Move the actual file update watching code into L<IO::Async::Loop>, possibly as
a new watch/unwatch method pair C<watch_file>.

=item *

Consider if a construction-time parameter of C<seek_to_end> or C<seek_to_last>
might be neater than a small code block in C<on_initial>, if that turns out to
be the only or most common form of use.

=back

=cut

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
