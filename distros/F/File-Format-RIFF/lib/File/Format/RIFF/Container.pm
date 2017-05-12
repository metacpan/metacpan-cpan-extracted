package File::Format::RIFF::Container;
use base File::Format::RIFF::Chunk;


our $VERSION = '0.08';


use Carp;
use File::Format::RIFF::List;


sub new
{
   my ( $proto, $type, $id, $data ) = @_;
   my ( $self ) = $proto->SUPER::new( $id, $data );
   $self->type( defined $type ? $type : '    ' );
   return $self;
}


sub type
{
   my ( $self ) = shift;
   return $self->{type} unless ( @_ );
   my ( $type ) = shift;
   croak "Length of type must be 4" unless ( length( $type ) == 4 );
   $self->{type} = $type;
}


sub id
{
   my ( $self ) = shift;
   croak "Cannot set id of $self->{id} chunk" if ( @_ and exists $self->{id} );
   return $self->SUPER::id( @_ );
}


sub read
{
   my ( $proto ) = shift;
   delete $proto->{id} if ( ref( $proto ) );
   return $proto->SUPER::read( @_ );
}


sub total_size
{
   my ( $self ) = @_;
   return $self->SUPER::total_size + 4;
}


sub data
{
   my ( $self ) = shift;
   return @{ $self->{data} } unless ( @_ );
   my ( $data ) = @_;
   $data = [ ] unless ( defined $data and ref( $data ) eq 'ARRAY' );
   $self->{data} = [ ];
   $self->push( @$data );
}


sub numChunks
{
   my ( $self ) = @_;
   return scalar( @{ $self->{data} } );
}


sub size
{
   my ( $self ) = @_;
   my ( $sz ) = 0;
   map { $sz += $_->total_size } @{ $self->{data} };
   return $sz;
}


sub splice
{
   my ( $self, $offset, $length, @elts ) = @_;
   map { croak "Can only add Chunk or List elements"
      unless ( ref( $_ ) and $_->isa( 'File::Format::RIFF::Chunk' ) ) } @elts;
   return ( @_ > 3 )
      ? splice( @{ $self->{data} }, $offset, $length, @elts )
      : ( @_ == 3 )
         ? splice( @{ $self->{data} }, $offset, $length )
         : ( @_ == 2 )
            ? splice( @{ $self->{data} }, $offset )
            : splice( @{ $self->{data} } );
}


sub push
{
   my ( $self, @elts ) = @_;
   return $self->splice( scalar( @{ $self->{data} } ), 0, @elts );
}


sub pop
{
   my ( $self ) = @_;
   return $self->splice( -1 );
}


sub unshift
{
   my ( $self, @elts ) = @_;
   return $self->splice( 0, 0, @elts );
}


sub at
{
   my ( $self ) = shift;
   my ( $i ) = shift;
   return $self->splice( $i, 1, shift ) if ( @_ );
   return $self->{data}->[ $i ];
}


sub addChunk
{
   my ( $self ) = shift;
   my ( $chk ) = new File::Format::RIFF::Chunk( @_ );
   $self->push( $chk );
   return $chk;
}


sub addList
{
   my ( $self ) = shift;
   my ( $ctr ) = new File::Format::RIFF::List( @_ );
   $self->push( $ctr );
   return $ctr;
}


sub _read_header
{
   my ( $self, $fh ) = @_;
   $self->SUPER::_read_header( $fh );
   $self->{size} -= 4;
   $self->{type} = $self->_read_fourcc( $fh );
}


sub _write_header
{
   my ( $self, $fh ) = @_;
   $self->_write_fourcc( $fh, $self->{id} );
   $self->_write_size( $fh, $self->size + 4 );
   $self->_write_fourcc( $fh, $self->{type} );
}


sub _read_data
{
   my ( $self, $fh ) = @_;
   my ( $to_read ) = $self->{size};
   $self->{data} = [ ];
   while ( $to_read )
   {
      my ( $id ) = $self->_read_fourcc( $fh );
      croak "Embedded RIFF chunks not allowed" if ( $id eq 'RIFF' );
      my ( $subchunk ) = ( $id eq 'LIST' )
         ? File::Format::RIFF::List->read( $fh )
         : File::Format::RIFF::Chunk->read( $id, $fh );
      $to_read -= $subchunk->total_size;
      $self->push( $subchunk );
   }
}


sub _write_data
{
   my ( $self, $fh ) = @_;
   map { $_->write( $fh ) } @{ $self->{data} };
}


sub dump
{
   my ( $self, $max, $indent ) = @_;
   $max = 64 unless ( defined $max );
   $indent = 0 unless ( defined $indent and $indent > 0 );
   print join( '', "\t" x $indent ), 'id: ', $self->id, ' (',
      $self->type, ') size: ', $self->size, ' (', $self->total_size, ")\n";

   ++ $indent;
   map { $_->dump( $max, $indent ) } @{ $self->{data} };
}


sub shift
{
   my ( $self ) = @_;
   return $self->splice( 0, 1 );
}


1;


=pod

=head1 NAME

File::Format::RIFF::Container - RIFF Container (Lists and RIFFs)

=head1 SYNOPSIS

You should not instantiate a C<File::Format::RIFF::Container> directly;
instead, you should instantiate one of its subclasses: either a
L<File::Format::RIFF> object, or a L<File::Format::RIFF::List> object.

=head1 DESCRIPTION

C<File::Format::RIFF::Container> is a base class for both RIFF objects
and RIFF lists.  It is, essentially, an array of other RIFF lists and/or
RIFF chunks, and you can add, change, delete, and read them.

=head1 METHODS

=over 4

=item $type = $container->type;

Returns the type of C<$container>.

=item $container->type( $type );

Sets the type of C<$container>.  C<$type> must be a four character code, which
represents what data will be found in C<$container>.

=item $id = $container->id;

Returns the id of C<$container>.  C<$container> must be either a RIFF object
or a List object, so C<$id> will be 'RIFF' or 'LIST', respectively.

=item @data = $container->data;

Returns the RIFF chunks and/or RIFF lists contained by C<$container>.

=item $container->data( $data );

Clears out any existing RIFF chunks contained by C<$container> and replaces
them with C<$data>.  C<$data> must be an array reference containing some
number of RIFF lists and/or RIFF chunks.

=item $numChunks = $container->numChunks;

Returns the number of RIFF lists and/or RIFF chunks contained by
C<$container>.

=item $size = $container->size;

Returns the size (in bytes) of C<$container>'s data, when written to a file.

=item $total_size = $container->total_size;

Returns the total size (in bytes) that C<$container> will take up when
written out to a file.  Total size is the size of the data, plus 12 bytes
for the header.

=item @replaced = $self->splice( $offset, $length, @list );

=item $container->push( @chunks );

=item $chunk = $container->pop;

=item $container->unshift( @chunks );

=item $chunk = $container->shift;

C<splice>, C<push>, C<pop>, C<unshift>, and C<shift> operate analogously
to the same-named functions in core perl, acting on C<$container>'s array
of RIFF lists and/or RIFF chunks.  All items added must be RIFF lists or
RIFF chunks.

=item $chunk = $container->at( $i );

Returns the RIFF list or RIFF chunk at the C<$i>th position in
C<$container>'s array.

=item $container->at( $i, $chunk );

Sets the C<$i>th position in C<$container>'s array to C<$chunk>, replacing
the previous item.  C<$chunk> must be a RIFF list or a RIFF chunk.

=item $newChunk = $container->addChunk( $id, $data );

Creates a new RIFF chunk object with the given C<$id> and C<$data>, appending
it to C<$container>'s array.  Returns the just-created RIFF chunk.

=item $newList = $container->addList( $type, $data );

Creates a new List object with the given C<$type> and C<$data>, appending
it to C<$container>'s array.  Returns the just-created RIFF list.

=item $container->dump( $max );

Prints a string representation of C<$container> to STDOUT, recursively
printing contained items.  If a RIFF chunk's data is larger than C<$max> bytes,
prints '[...]' instead of the actual data.  If C<$max> is not specified or
C<undef>, it defaults to 64.

A RIFF chunk is rendered as:

id: E<lt>idE<gt> size: E<lt>sizeE<gt> (E<lt>total sizeE<gt>): E<lt>dataE<gt>

A RIFF container is rendered as:

id: E<lt>idE<gt> (E<lt>typeE<gt>) size: E<lt>sizeE<gt> (E<lt>total sizeE<gt>)

Items contained in the RIFF list are recursively printed on subsequent lines,
and are indented in one additional tab level.

=back

=head1 SEE ALSO

=over 4

=item L<File::Format::RIFF>

=item L<File::Format::RIFF::List>

=back

=head1 AUTHOR

Paul Sturm E<lt>I<sturm@branewave.com>E<gt>

=cut
