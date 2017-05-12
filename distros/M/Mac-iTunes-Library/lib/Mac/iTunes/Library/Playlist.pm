package Mac::iTunes::Library::Playlist;

use 5.006;
use warnings;
use strict;
use Carp;

require Exporter;
our @ISA = qw(Exporter);
our %EXPORT_TAGS = ( 'all' => [ qw() ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw( );

our $VERSION = '1.0';

=head1 NAME

Mac::iTunes::Library::Playlist - Perl extension for representing a playlist
(list of items by Track ID) within an iTunes library.

=head1 SYNOPSIS

  use Mac::iTunes::Library::Playlist;

  # Let's create a few simple items
  my @items = (
          Mac::iTunes::Library::Item->new('Track ID' => 3),
          Mac::iTunes::Library::Item->new('Track ID' => 4),
          );
  # Create a playlist
  my $smartInfo =<< 'EOF';
  AQEAAwAAAAIAAAAZAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
  AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
  AAAAAA==
  EOF

  my $smartCriteria =<< 'EOF';
  U0xzdAABAAEAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
  AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
  AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABkAAAABAAAAAAAAAAAAAAAAAAAAAAAA
  AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABEAAAAAAAAAGQAAAAAAAAAAAAAAAAAAAAB
  AAAAAAAAAGQAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAA=
  EOF
  my $playlist = Mac::iTunes::Library::Playlist->new(
            'Name' => '5 Stars',
            'Playlist ID' => '10073',
            'Playlist Persistent ID' => '2E2D1396AF1DED73',
            'All Items' => 'true',
            'Smart Info' => $smartInfo,
            'Smart Criteria' => $smartCriteria,
            'Playlist Items' => @items,
        );

  # Add another item to that playlist
  my $item = Mac::iTunes::Library::Item->new( 'Track ID' => 7 );
  $playlist->addItem( $item );

  # Get all of the items in the playlist
  my @items = $playlist->items();

  # Get an item by it's ID
  $item = $playlist->item(3);

=head1 DESCRIPTION

A data structure for representing a playlist within an iTunes
library.  Use this along with Mac::iTunes::Library to create an iTunes library
from which other information can be gleaned.

=head1 EXPORT

None by default.

=head1 METHODS

=head2 new()

Creates a new Mac::iTunes::Playlist object that can store all of the data of an
iTunes library playlist.

  my $playlist = Mac::iTunes::Playlist->new();

The constructor can also be called with any number of attributes defined in
a hash:

  my $smartInfo =<< 'EOF';
  AQEAAwAAAAIAAAAZAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
  AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
  AAAAAA==
  EOF

  my $smartCriteria =<< 'EOF';
  U0xzdAABAAEAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
  AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
  AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABkAAAABAAAAAAAAAAAAAAAAAAAAAAAA
  AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABEAAAAAAAAAGQAAAAAAAAAAAAAAAAAAAAB
  AAAAAAAAAGQAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAA=
  EOF

  # A few simple items
  my @items = (
          Mac::iTunes::Library::Item->new('Track ID' => 2),
          Mac::iTunes::Library::Item->new('Track ID' => 3),
          Mac::iTunes::Library::Item->new('Track ID' => 4),
          );

  my $playlist = Mac::iTunes::Playlist->new(
        'Name' => '5 Stars',
        'Playlist ID' => '10073',
        'Playlist Persistent ID' => '2E2D1396AF1DED73',
        'All Items' => 'true',
        'Smart Info' => $smartInfo,
        'Smart Criteria' => $smartCriteria,
        'Playlist Items' => @items,
        );

=cut

sub new {
    my $class = shift;
    my %params = @_;

    my $self = {
        'Name' => undef,
        'Playlist ID' => undef,
        'Playlist Persistent ID' => undef,
        'All Items' => undef,
        'Smart Info' => undef,
        'Smart Criteria' => undef,
        'Playlist Items' => [],
    };

    bless $self, $class;

    # Deal with parameters
    if ( exists( $params{'Name'} ) ) {
        name( $self, $params{'Name'} );
    } if ( exists( $params{'Playlist ID'} ) ) {
        playlistID( $self, $params{'Playlist ID'} );
    } if ( exists( $params{'Playlist Persistent ID'} ) ) {
        playlistPersistentID( $self, $params{'Playlist Persistent ID'} );
    } if ( exists( $params{'All Items'} ) ) {
        allItems( $self, $params{'All Items'} );
    } if ( exists( $params{'Smart Info'} ) ) {
        smartInfo( $self, $params{'Smart Info'} );
    } if ( exists( $params{'Smart Criteria'} ) ) {
        smartCriteria( $self, $params{'Smart Criteria'} );
    } if ( exists( $params{'Playlist Items'} ) ) {
        addItems( $self, $params{'Playlist Items'} );
    }

    return $self;
} #new

# Clean up
sub DESTROY {
# Nothing to do.
} #DESTROY

=head2 name( name )

Get/set the name attribute for this playlist.

=cut

sub name {
    my $self = shift;

    if (@_) {
        my $name = shift;
        $self->{'Name'} = $name;
    }

    return $self->{'Name'};
} #name

=head2 playlistID( id )

Get/set the Playlist ID attribute for this playlist.

=cut

sub playlistID {
    my $self = shift;

    if (@_) {
        my $id = shift;
        $self->{'Playlist ID'} = $id;
    }

    return $self->{'Playlist ID'};
} #playlistID

=head2 playlistPersistenID( id )

Get/set the Playlist Persistent ID attribute for this playlist.

=cut

sub playlistPersistentID {
    my $self = shift;

    if (@_) {
        my $id = shift;
        $self->{'Playlist Persistent ID'} = $id;
    }

    return $self->{'Playlist Persistent ID'};
} #playlistPersistentID

=head2 allItems( 0|1 )

Get/set the All Items attribute for this playlist.

=cut

sub allItems {
    my $self = shift;

    if (@_) {
        my $allItems = shift;
        return carp "All items must be 0 or 1." unless ($allItems =~ /^[01]$/);
        $self->{'All Items'} = $allItems;
    }

    return $self->{'All Items'};
} #allItems

=head2 smartInfo( smartInfo )

Get/set the Smart Info attribute for this playlist.

=cut

sub smartInfo {
    my $self = shift;

    if (@_) {
        my $smartInfo = shift;
        $self->{'Smart Info'} = $smartInfo;
    }

    return $self->{'Smart Info'};
} #smartInfo

=head2 smartCriteria( smartInfo )

Get/set the Smart Criteria attribute for this playlist.

=cut

sub smartCriteria {
    my $self = shift;

    if (@_) {
        my $smartCriteria = shift;
        $self->{'Smart Criteria'} = $smartCriteria;
    }

    return $self->{'Smart Criteria'};
} #smartCriteria

=head2 num()

Get the number of elements in this playlist.

=cut

sub num {
    my $self = shift;

    return scalar(@{$self->{'items'}});
} #num

=head2 addItem( Mac::iTunes::Library::Item )

Add an item to this playlist; duplicates are allowed

=cut

sub addItem {
    my $self = shift;
    my $item = shift;

    return carp "Need a Mac::iTunes::Library::Item object."
        unless ($item->isa('Mac::iTunes::Library::Item'));

    push @{$self->{'items'}}, $item;
    # TODO: shouldn't this be referencing a track already in the lib?
} #addItem

=head2 addItems( Mac::iTunes::Library::Item )

Add an array of items to this playlist; duplicates are allowed

=cut

sub addItems {
    my $self = shift;
    my $items = shift;

    # Complain if there are any non-item objects
    unless (grep {$_->isa('Mac::iTunes::Library::Item')} @{$items}) {
        return carp "Given an array containig items that are not all " .
            "Mac::iTunes::Library::Item objects.";
    }

    push @{$self->{'items'}}, @{$items};
} #addItems

=head2 items()

Get an array of the items in the playlist.

=cut

sub items {
    my $self = shift;

    return @{$self->{'items'}};
} #items

=head2 item( trackID )

Get an item by it's trackID

=cut

sub item {
    my $self = shift;
    my $id = shift;

    # There may be duplicates
    my @items = grep {$_->trackID() == $id} @{$self->{'items'}};

    return $items[0];
} #item

1;

=head1 SEE ALSO

L<Mac::iTunes::Library>, L<Mac::iTunes::Library::Item>

=head1 AUTHOR

Drew Stephens <drew@dinomite.net>, http://dinomite.net

=head1 CONTRIBUTORS

=over 4

=item *

Mark Grimes <mgrimes@cpan.org>, L<http://www.peculiarities.com>

=back

=head1 SOURCE REPOSITORY

http://mac-itunes.googlecode.com

=head1 SVN INFO

$Revision: 90 $

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007-2008 by Drew Stephens

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
__END__
