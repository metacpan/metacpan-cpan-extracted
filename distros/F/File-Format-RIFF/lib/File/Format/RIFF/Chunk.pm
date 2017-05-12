package File::Format::RIFF::Chunk;


our $VERSION = '0.09';


use bytes;
use Carp;


use vars qw/ $PACKFMT /;
BEGIN { $PACKFMT = 'V' }


sub new
{
   my ( $proto, $id, $data ) = @_;
   my ( $self ) = $proto->_new;
   $self->id( defined $id ? $id : '    ' );
   $self->data( $data );
   return $self;
}


sub _new
{
   my ( $proto ) = @_;
   my ( $class ) = ref( $proto ) || $proto;
   return bless { }, $class;
}


sub write
{
   my ( $self, $fh ) = @_;
   $self->_write_header( $fh );
   $self->_write_data( $fh );
}


sub id
{
   my ( $self ) = shift;
   return $self->{id} unless ( @_ );
   my ( $id ) = shift;
   croak "Length of id must be 4" unless ( length( $id ) == 4 );
   $self->{id} = $id;
}


sub data
{
   my ( $self ) = shift;
   return $self->{data} unless ( @_ );
   my ( $data ) = shift;
   $data = '' unless ( defined $data );
   $self->{size} = length( $self->{data} = $data );
}


sub size
{
   my ( $self ) = @_;
   return $self->{size};
}


sub total_size
{
   my ( $self ) = @_;
   my ( $sz ) = $self->size;
   return 8 + $sz + ( $sz % 2 );
}


sub _read_header
{
   my ( $self, $fh ) = @_;
   $self->{size} = $self->_read_size( $fh );
}


sub _write_header
{
   my ( $self, $fh ) = @_;
   $self->_write_fourcc( $fh, $self->{id} );
   $self->_write_size( $fh, $self->{size} );
}


sub _read_data
{
   my ( $self, $fh ) = @_;
   my ( $sz ) = $self->size;
   $self->_file_read( $fh, \$self->{data}, $sz );
   return unless ( $sz % 2 );

   my ( $x );
   $self->_file_read( $fh, \$x, 1 );
}


sub _write_data
{
   my ( $self, $fh ) = @_;
   $self->_file_write( $fh, $self->{data} );
   $self->_file_write( $fh, "\0" ) if ( $self->{size} % 2 );
}


sub _file_read
{
   my ( $proto, $fh, $ref, $expect ) = @_;
   my ( $got ) = read( $fh, $$ref, $expect );
   croak "File read error: $!" unless ( defined $got );
   croak "File read error: expected $expect bytes, got $got"
      unless ( $got == $expect );
}


sub _file_write
{
   my ( $proto, $fh, @data ) = @_;
   print { $fh } @data or croak 'Could not write to file';
}


sub _read_fourcc
{
   my ( $proto, $fh ) = @_;
   my ( $fourcc );
   $proto->_file_read( $fh, \$fourcc, 4 );
   return $fourcc;
}


sub _write_fourcc
{
   my ( $self, $fh, $fourcc ) = @_;
   $self->_file_write( $fh, $fourcc );
}


sub _read_size
{
   my ( $proto, $fh ) = @_;
   my ( $size );
   $proto->_file_read( $fh, \$size, 4 );
   return unpack( $PACKFMT, $size );
}


sub _write_size
{
   my ( $self, $fh, $size ) = @_;
   $self->_file_write( $fh, pack( $PACKFMT, $size ) );
}


sub dump
{
   my ( $self, $max, $indent ) = @_;
   $max = 64 unless ( defined $max );
   $indent = 0 unless ( defined $indent and $indent > 0 );
   print join( '', "\t" x $indent ), 'id: ', $self->id,
      ' size: ', $self->size, ' (', $self->total_size, '): ';
   ( $max and $self->size > $max ) ? print '[...]' : print $self->{data};
   print "\n";
}


sub read
{
   my ( $proto, $id, $fh ) = @_;
   my ( $self ) = ref( $proto ) ? $proto : $proto->_new;
   $self->id( $id );
   $self->_read_header( $fh );
   $self->_read_data( $fh );
   return $self;
}


1;


=pod

=head1 NAME

File::Format::RIFF::Chunk - a single RIFF chunk

=head1 SYNOPSIS

   use File::Format::RIFF;

   my ( $chunk ) = new File::Format::RIFF::Chunk;
   $chunk->id( 'stuf' );
   $chunk->data( 'here is some stuff' );

   ... some $container ...

   $container->push( $chunk );

=head1 DESCRIPTION

A C<File::Format::RIFF::Chunk> is a single chunk of data in a RIFF file.  It
has an identifier and one piece of scalar data.  The id must be a
four character code, and the data can be any piece of scalar data you wish
to store, in any format (it is treated as opaque binary data, so you must
interpret it yourself).

=head1 CONSTRUCTOR

=over 4

=item $chunk = new File::Format::RIFF::Chunk( $id, $data );

Creates a new File::Format::RIFF::Chunk object.  C<$id> is a four character
code that identifies the type of data.  If C<$id> is not specified, it
defaults to C<'    '> (four spaces).  C<$data> is a scalar, treated as
opaque binary data.  If C<$data> is C<undef> or not specified, it defaults
to ''.

=back

=head1 METHODS

=over 4

=item $id = $chunk->id;

Returns the id of C<$chunk>.

=item $chunk->id( 'abcd' );

Sets the id of C<$chunk>.  C<$id> must be a four character code that
identifies the type of data.

=item $data = $chunk->data;

Returns the data of C<$chunk>.

=item $chunk->data( $data );

Sets the data of C<$chunk>.  C<$data> is treated as a piece of opaque
binary data, not modified or interpreted in any way.

=item $size = $chunk->size;

Returns the size (in bytes) of C<$chunk>'s data.

=item $total_size = $chunk->total_size;

Returns the total size (in bytes) that C<$chunk> will take up when written
out to a file.  Total size is the size of the data, plus 8 bytes for the
header, plus 1 alignment byte if the data has an odd number of bytes (so that
the RIFF chunks will be word-aligned on disk).

=item $chunk->dump( $max );

Prints a string representation of C<$chunk> to STDOUT.  If the data is
larger than C<$max> bytes, prints '[...]' instead of the actual data.  If
C<$max> is not specified or C<undef>, it defaults to 64.

A RIFF chunk is rendered as:

id: E<lt>idE<gt> size: E<lt>sizeE<gt> (E<lt>total sizeE<gt>): E<lt>dataE<gt>

=back

=head1 AUTHOR

Paul Sturm E<lt>I<sturm@branewave.com>E<gt>

=cut
