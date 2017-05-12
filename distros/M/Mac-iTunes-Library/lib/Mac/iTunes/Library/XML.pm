package Mac::iTunes::Library::XML;

use 5.006;
use warnings;
use strict;
use Carp;

use Mac::iTunes::Library;
use Mac::iTunes::Library::Item;
use Mac::iTunes::Library::Playlist;
use XML::Parser 2.36;

require Exporter;
our @ISA = qw(Exporter);
our %EXPORT_TAGS = ( 'all' => [ qw() ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw( );

our $VERSION = '1.0';

=head1 NAME

Mac::iTunes::Library::XML - Perl extension for parsing an iTunes XML library

=head1 SYNOPSIS

  use Mac::iTunes::Library::XML;

  my $library = Mac::iTunes::Library::XML->parse( 'iTunes Music Library.xml' );
  print "This library has only " . $library->num() . "item.\n";

=head1 DESCRIPTION

A parser to read an iTunes XML library and create a Mac::iTunes::Library object.

=head2 NOTES ON iTUNES XML FORMAT

Whereas someone who understands how to use XML would write this:

  <Playlists>
      <Playlist>
          <Name>Library</Name>
          <Playlist ID>7</Playlist ID>
          <Visible>false</Visible>
          <Playlist Items>
              <Track ID>14</Track ID>
              <Track ID>21</Track ID>
              <Track ID>28</Track ID>
          </Playlist Items>
      </Playlist>
  </Playlists>

Instead, we get this from iTunes:

  <key>Playlists</key>
  <array>
      <dict>
          <key>Name</key><string>Library</string>
          <key>Master</key><true/>
          <key>Playlist ID</key><integer>201</integer>
          <key>Playlist Persistent ID</key><string>707F6A2CE6E601F5</string>
          <key>Visible</key><false/>
          <key>All Items</key><true/>
          <key>Playlist Items</key>
          <array>
              <dict>
                  <key>Track ID</key><integer>173</integer>
              </dict>
              <dict>
                  <key>Track ID</key><integer>175</integer>
              </dict>
              <dict>
                  <key>Track ID</key><integer>177</integer>
              </dict>
          </array>
      </dict>
  </array>

The iTunes XML format doesn't make it clear where the parser is in the library,
so to parser must keep track itself; this is done with the @stack array in
XML.pm, which is used to set $depth in each of the callback methods.

Here are the elements that can be found at any depth.  The depths are indexed
with 0 being outside of any element (before the very first start_element call),
1 would be within a single element (<plist> being the outermost of an iTunes
library file), 2 within the second element (<dict>), and so on.  Note that 
because the iTunes XML library format is so awesome, the name of a key
(contained within a <key> element, e.g. <key>Features</key>) occurs at the same
level as it's value (e.g. <integer>5</integer>).  Those XML elements
(e.g. <key>, <integer) occur at some level n, but the data which we care about
(e.g. 'Features', 5) are contained at level n+1.

=over 4

=item * Zeroth

   - <plist> element with version attribute

=item * First

   - Outermost <dict> element

=item * Second

   - <key> containing library metadata key name
   - <integer> containing library metadata
   - <string> containing library metadata
   - <true /> containing library metadata
   - <false /> containing library metadata

=item * Third

   - Library metadata (major/minor version, application version, etc.)
   - Tracks and Playlists keys
   - <dict> containing library tracks
   - <array> containing playlists

=item * Fourth

   - <key> with track ID
   - <dict> containing track data

=item * Fifth

   - <key> containing track/playlist metdata key name
   - <integer> containing track/playlist metdata key name
   - <string> containing track/playlist metdata key name
   - <date> containing track/playlist metdata key name

=item * Sixth

   - <dict> containing a single playlist track

=item * Seventh

   - <key> containing the string "Track ID"
   - <integer> containing a track ID

=back

=head1 EXPORT

None by default.

=head1 METHODS

=head2 parse( $libraryFile )

Parses an iTunes XML library and returns a Mac::iTunes::Library object.

=cut

# The current 'key' of an item information that we're in
my $curKey = undef;
# A Mac::iTunes::Library::Item that will be built and added to the library
my $item = undef;
# A Mac::iTunes::Library that will be built
my $library;
# Characters that we collect
my $characters = undef;
# Keep track of where we are; push on each element name as we hit it
my (@stack);
my ($inTracks, $inPlaylists, $inMajorVersion, $inMinorVersion,
        $inApplicationVersion, $inFeatures, $inMusicFolder,
        $inLibraryPersistentID) = undef;

sub parse {
    my $self = shift;
    my $xmlFile = shift;
    $library = Mac::iTunes::Library->new();

    my $parser = XML::Parser->new( Handlers => {
                        Start => \&start_element,
                        End => \&end_element,
                        Char => \&characters,
                    });
    $parser->parsefile( $xmlFile );
    return $library;
} #parse

### Parser start element
sub start_element {
    my ($expat, $element, %attrs) = @_;

    # Keep a trail of our depth
    push @stack, $element;
    # Note that our $depth is inside of the newly opened element
    my $depth = scalar(@stack);

    if ($depth == 0) {
    } elsif ($depth == 1) {
        # Hit the initial <plist version=""> tag
        if (defined $attrs{'version'}) {
            $library->version($attrs{'version'});
        }
    } elsif ($depth == 2) {
    } elsif ($depth == 3) {
        if($inPlaylists) {
        } else {
            if (($element eq 'true') or ($element eq 'false')) {
                $library->showContentRatings($element);
            }
        }
    } elsif ($depth == 4) {
        # We hit a new item in the XML; create a new object
        if($inPlaylists) {
            $item = Mac::iTunes::Library::Playlist->new() if ($element eq 'dict');
        } else {
            $item = Mac::iTunes::Library::Item->new() if ($element eq 'dict');
        }
    } elsif($depth == 5){
    }
} #start_element

### Parser end element
sub end_element {
    my ($expat, $element) = @_;

    # Note that our $depth is still "inside" this ending element
    my $depth = scalar(@stack);
    # Hit a closing element; prune the trail
    pop @stack;

    if ($depth == 0) {        # plist version
    } elsif ($depth == 1) {   # dict
    } elsif ($depth == 2) {
    } elsif ($depth == 3) {
        # Exiting a major section
        $inTracks = 0 if ($element eq 'dict');
        $inPlaylists = 0 if ($element eq 'array');

        if ($inMusicFolder and ($element eq 'string')) {
            $library->musicFolder($characters);
            $inMusicFolder = undef;
            $curKey = undef;
            $characters = undef;
        }
    } elsif ($depth == 4) {
        # Ending an item; add it to the library and clean up
        if( $inPlaylists ){
            if ($item) {
                $library->addPlaylist($item);
            }
        } else {
            if ($item) {
                $library->add($item);
            }
        }

        $item = undef if ($element eq 'dict');
    } elsif ($depth == 5) {
        # Set the attributes of the Mac::iTunes::Library::Item directly
        if ( $element =~ /(integer|string|date|data)/ ) {
            $item->{$curKey} = $characters;
            $characters = undef;
            $curKey = undef;
        } elsif ( $element =~ /true/ ) {
            $item->{$curKey} = 1;
            $curKey = undef;
        } elsif ( $element =~ /false/ ) {
            $item->{$curKey} = 0;
            $curKey = undef;
        }
    } elsif ($depth == 6){
    } elsif ($depth == 7){
        if ( $element =~ /(integer)/ ) {
            # print "Adding $curKey => $characters\n";

            my $track = $library->{'ItemsById'}{$characters};
            if( ref $track and $$track ){
                $item->addItem( $$track );
            } else {
                warn "Couldn't find track '$characters'\n";
            }

            $curKey = undef;
            $characters = undef;
        }
    }
} #end_element

### Parser element contents
sub characters {
    my ($expat, $string) = @_;
    my $depth = scalar(@stack);

    if ( $depth == 0 ) {        # plist version
    } elsif ( $depth == 1 ) {   # dict
    } elsif ( $depth == 2 ) {
    } elsif ( $depth == 3 ) {
        # Check the name of the element
        if ( $stack[$#stack] eq 'key' ) {
            # Lots of keys at this level
            if ($string eq 'Major Version') {
                $inMajorVersion = 1;
            } elsif ( $string eq 'Minor Version' ) {
                $inMinorVersion = 1;
            } elsif ( $string eq 'Application Version' ) {
                $inApplicationVersion = 1;
            } elsif ( $string eq 'Features' ) {
                $inFeatures = 1;
            } elsif ( $string eq 'Music Folder' ) {
                $inMusicFolder = 1;
            } elsif ( $string eq 'Library Persistent ID' ) {
                $inLibraryPersistentID = 1;
            } elsif ( $string eq 'Tracks' ) {
                $inTracks = 1;
            } elsif ( $string eq 'Playlists' ) {
                $inPlaylists = 1;
            }
        } elsif ( $stack[$#stack] =~ /(integer|string|true|false)/ ) {
            # TODO This is assumes that each of these come as a single chunk
            if ($inMajorVersion) {
                $library->majorVersion($string);
                $inMajorVersion = undef;
            } elsif ($inMinorVersion) {
                $library->minorVersion($string);
                $inMinorVersion = undef;
            } elsif ($inApplicationVersion) {
                $library->applicationVersion($string);
                $inApplicationVersion = undef;
            } elsif ($inFeatures) {
                $library->features($string);
                $inFeatures = undef;
            } elsif ($inMusicFolder) {
                # The music folder could be long; buffer it.
                $characters .= $string;
            } elsif ($inLibraryPersistentID) {
                $library->libraryPersistentID($string);
                $inLibraryPersistentID = undef;
            }
        }
    } elsif ( $depth == 4 ) {
    } elsif ( $depth == 5 ) {
        if ( $stack[$#stack] eq 'key' ) {
            # Grab the key's name; Normally comes in a single chunk, but accept multiple chunks
            $curKey .= $string;
        } elsif ( $stack[$#stack] =~ /(integer|string|date|data)/ ) {
            # Append it to the characters that we've gathered so far
            $characters .= $string;
        }
    } elsif ( $depth == 6 ) {
    } elsif ( $depth == 7 ) {
        if ( $stack[$#stack] eq 'key' ) {
            # Grab the key's name; Normally comes in a single chunk, but accept multiple chunks
            $curKey .= $string;
        } elsif ( $stack[$#stack] =~ /(integer|string|date)/ ) {
            # Append it to the characters that we've gathered so far
            $characters .= $string;
        }
    }
} #characters

# Clean up
sub DESTROY {
    # Nothing to do.
} #DESTROY

1;

=head1 SEE ALSO

L<Mac::iTunes::Library::Item>, L<Mac::iTunes::Library>,
L<Mac::iTunes::Library::Playlist>

=head1 AUTHOR

Drew Stephens <drew@dinomite.net>, http://dinomite.net

=head1 CONTRIBUTORS

=over4

=item *

Mark Grimes <mgrimes@cpan.org>, L<http://www.peculiarities.com>

=item *

Garrett Scott <garrett@gothik.org>, L<http://www.gothik.org>

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
