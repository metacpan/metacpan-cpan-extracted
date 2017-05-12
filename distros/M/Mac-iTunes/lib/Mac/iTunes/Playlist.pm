package Mac::iTunes::Playlist;
use strict;
use warnings;

use vars qw($VERSION);

$VERSION = '1.23';

=head1 NAME

Mac::iTunes::Playlist

=head1 SYNOPSIS

	use Mac::iTunes::Playlist;

	my $playlist = Mac::iTunes::Playlist->new( @items );

=head1 DESCRIPTION

**This module is unmaintained**


=head2 METHODS

=over 4

=item new( TITLE, ARRAYREF )

=cut

sub new
	{
	my $class = shift;
	my $title = shift;
	my $items = shift || [] ; # should be a reference

	return unless defined $title;
	return if ref $title;
	return unless UNIVERSAL::isa( $items, 'ARRAY' );

	my $self = { title  => $title,
	             _items => $items,
	           };

	bless $self, $class;

	return $self;
	}

=item new_from_directory( TITLE, DIRECTORY )

Create a playlist from all of the MP3 files in the named
directory.

=cut

my @mp3_find_temp;

sub _mp3_find
	{
	require File::Spec;

	if( /.mp3$/ )
		{
		push @mp3_find_temp, File::Spec->catfile( $File::Find::dir, $_ );
		}
	}

# we need this wrapper to initialize the class variable
# @mp3_file_temp.  if i can find another way to do this
# i can get rid of this.
sub _find
	{
	my $directory = shift;

	return unless -d $directory;

	require File::Find;

	@mp3_find_temp = ();

	File::Find::find( \&_mp3_find, $directory );

	\@mp3_find_temp;
	}

sub new_from_directory
	{
	my $class     = shift;
	my $title     = shift;
	my $directory = shift;

	my $array = _find( $directory );

	my @items = ();
	foreach my $file ( @$array )
		{
		my $item = Mac::iTunes::Item->new( { file => $file } );

		push @items, $item;
		}

	$class->new( $title, \@items );
	}

=item title

Returns the title of the playlist.

=cut

sub title
	{
	my $self = shift;

	$self->{title} = shift if @_;

	return $self->{title};
	}

=item items

In list context, returns a list of the items in the playlist.

In scalar context, returns the number of items in the playlist.

=cut

sub items
	{
	my $self = shift;

	my @items = @{ $self->{_items} };

	return wantarray ? @items : scalar @items;
	}

=item next_item

Not implemented

=cut

sub next_item
	{
	my $self = shift;

	$self->_not_implemented;
	}

=item previous_item

Not implemented

=cut

sub previous_item
	{
	my $self = shift;

	$self->_not_implemented;
	}

=item add_item( OBJECT )

Adds the Mac::iTunes::Item object to the playlist.

Returns undef or the empty list if the argument is not
a Mac::iTunes::Item object.

=cut

sub add_item
	{
	my $self = shift;
	my $item = shift;

	return unless UNIVERSAL::isa( $item, 'Mac::iTunes::Item' );

	push @{ $self->{_items} }, $item;
	}

=item delete_item( INDEX )

Deletes the item at index INDEX (counting from zero).

Returns false is the INDEX is greater than the index
of the last item.  Returns true otherwise.

=cut

sub delete_item
	{
	my $self  = shift;
	my $index = shift;

	my $count = $self->items;

	return unless $index > $count;

	splice @{ $self->{_items} }, $index, 1;
	}

=item merge( PLAYLIST )

Adds the items in PLAYLIST to the current playlist and returns
the number of items added.

Returns undefined (or the empty list) if the argument is not the right
sort of object.  Returns 0 if no items were added (which might not
be an error).

This method does a deep copy of the Items object.  Identical items
show up as different objects in each playlist so that the playlists
do not refer to each other.

=cut

sub merge
	{
	my $self     = shift;
	my $playlist = shift;

	return unless UNIVERSAL::isa( $playlist, __PACKAGE__ );

	my $count = 0;

	foreach my $item ( $playlist->items )
		{
		my $copy = $item->copy;
		$count++ if $self->add_item( $item );
		}

	return $count;
	}

=item random_item

In scalar context, returns a random item from the playlist.

In list context, returns the item, the index of the item, and
the total count of items.

Returns false or the empty list if the playlist has no items.

=cut

sub random_item
	{
	my $self = shift;

	my $count = $self->items;

	return unless $count;

	my $index = int( rand( $count ) );
	my $item  = ${ $self->{_items} }[ $index ];

	return wantarray ? ( $item, $index, $count ) : $item;
	}

=item copy

Return a deep copy of the playlist.  The returned object will not
refer (as in, point to the same data) as the original object.

=cut

sub copy
	{
	my $self = shift;

	my $ref = {};

	foreach my $key ( qw(title) )
		{
		$ref->{$key} = $self->{$key};
		}

	my @items = ();
	foreach my $item ( qw(_items) )
		{
		push @items, $item->copy;
		}

	$ref->{_items} = \@items;

	return $ref;
	}

=back

=head2 Publisher

=over 4

=item publish( FORMAT [, FIELDS_REF [, ORDER_REF ] ] )

Output the playlist in some format.

Not implemented.

=cut

my @Publish_fields = [ qw() ];
my $Default_fields = [ @Publish_fields ];
my $Default_order  = [ @Publish_fields ];

sub publish
	{
	my $self     = shift;
	my $fields   = shift || $Default_fields;
	my $order    = shift || $Default_order;

	unless( UNIVERSAL::isa( $fields, 'ARRAY' ) )
		{
		carp();
		}

	unless( UNIVERSAL::isa( $order, 'ARRAY' ) )
		{
		carp();
		}

	}

=back

=cut

sub _not_implemented
	{
	require Carp;

	my $function = (caller(1))[3];

	Carp::croak( "$function is unimplemented" );
	}

"See why 1984 won't be like 1984";

=head1 SOURCE AVAILABILITY

This source is in GitHub:

	https://github.com/CPAN-Adopt-Me/MacOSX-iTunes.git

=head1 SEE ALSO

L<Mac::iTunes>, L<Mac::iTunes::Item>

=head1 TO DO

* everything - the list of things already done is much shorter.

=head1 AUTHOR

brian d foy,  C<< <bdfoy@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2002-2007 brian d foy.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
