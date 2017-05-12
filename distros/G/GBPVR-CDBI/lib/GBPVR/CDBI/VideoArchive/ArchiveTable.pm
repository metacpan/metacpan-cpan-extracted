package GBPVR::CDBI::VideoArchive::ArchiveTable;

use warnings;
use strict;

our $VERSION = '0.02';

use base 'GBPVR::CDBI::VideoArchive';
use GBPVR::CDBI::Programme;

__PACKAGE__->table('archivetable');
__PACKAGE__->columns(Primary => qw/VideoFile/ );
__PACKAGE__->columns(All => qw/
	Title Description StartTime RecordDate ChannelName Viewed
	UniqueID Genre Subtitle Runtime
	Actors Rating Director PosterImage 
	InternetFetchCompleted YearOfRelease Tagline
	Writer ViewerRating Votes / );

sub programme {
  my $obj = shift;
  my ($prog) = GBPVR::CDBI::Programme->search( unique_identifier => $obj->UniqueID );
  return $prog;
}

1;
__END__

=head1 NAME

GBPVR::CDBI::VideoArchive::ArchiveTable - VideoArchive.archivetable table

=head1 VERSION

Version 0.02

=head1 SYNOPSIS

=head1 ATTRIBUTES

VideoFile,
Title, Description, StartTime, RecordDate, ChannelName, Viewed,
UniqueID, Genre, Subtitle, Runtime,
Actors, Rating, Director, PosterImage,
InternetFetchCompleted, YearOfRelease, Tagline

=head1 METHODS

=head2 programme

Attempts to return the corresponding (via uniqueID) GBPVR::CDBI::Programme object.

=head1 AUTHOR

David Westbrook, C<< <dwestbrook at gmail.com> >>

=head1 COPYRIGHT & LICENSE

Copyright 2006 David Westbrook, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

