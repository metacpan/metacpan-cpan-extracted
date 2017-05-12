package File::Format::RIFF::List;
use base File::Format::RIFF::Container;


our $VERSION = '0.08';


sub new
{
   my ( $proto, $type, $data ) = @_;
   return $proto->SUPER::new( $type, 'LIST', $data );
}


sub read
{
   my ( $proto, $fh ) = @_;
   return $proto->SUPER::read( 'LIST', $fh );
}


1;


=pod

=head1 NAME

File::Format::RIFF::List - a single RIFF list

=head1 SYNOPSIS

   use File::Format::RIFF;
   my ( $list ) = new File::Format::RIFF::List;
   $list->type( 'stuf' );
   $list->addChunk( abcd => 'a bunch of data' );
   $list->addList( 'alst' )->addChunk( xyzw => 'more data' );
   print $list->numChunks, "\n";

   ... some $container ...

   $container->push( $list );

=head1 DESCRIPTION

A C<File::Format::RIFF::List> is a list of data in a RIFF file.  It has an
identifier, a type, and an array of data.  The id is always 'LIST'.  The
type must be a four character code, and the data is an array of other RIFF
lists and/or RIFF chunks.

=head1 CONSTRUCTOR

=over 4

=item $list = new File::Format::RIFF::List( $type, $data );

Creates a new File::Format::RIFF::List object.  C<$type> is a four character
code that identifies the type of this RIFF list.  If C<$type> is not
specified, it defaults to C<'    '> (four spaces).  C<$data> must be an
array reference containing some number of RIFF lists and/or RIFF chunks.
If C<$data> is C<undef> or not specified, then the new list object is
initialized empty.

=back

=head1 SEE ALSO

=over 4

C<File::Format::RIFF::List> inherits from C<File::Format::RIFF::Container>,
so all methods available for Containers can be used on RIFF lists.  A
Container essentially contains an array of RIFF lists and/or RIFF chunks.
See the L<File::Format::RIFF::Container> man page for more information.

=back

=head1 AUTHOR

Paul Sturm E<lt>I<sturm@branewave.com>E<gt>

=cut
