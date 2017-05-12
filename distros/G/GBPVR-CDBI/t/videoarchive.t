#!perl -T

use Test::More;
use strict;
use warnings;

plan tests => 25;

use File::Spec;
use GBPVR::CDBI::VideoArchive::ArchiveTable;

my $db= File::Spec->rel2abs("t\\videoarchive.mdb");
ok($db, "found test db");
my $rc = GBPVR::CDBI::VideoArchive::ArchiveTable->db_setup(file => $db);
ok($rc, "got db handle");

my @rows = GBPVR::CDBI::VideoArchive::ArchiveTable->retrieve_all();
is(scalar(@rows), 1, "got exactly 1 row");
my $row = shift @rows;
is( ref($row), 'GBPVR::CDBI::VideoArchive::ArchiveTable', "item is an object");

is( $row->VideoFile, 'The Simpsons_20050517_19001930.mpg', "VideoFile matches" );
is( $row->Title, 'The Simpsons', "Title matches" );
is( $row->Description, 'Halloween vignettes spoof "The Shining," "Crime and Punishment" and "Soylent Green."', "Description matches" );
is( $row->StartTime, '7:00 PM', "StartTime matches" );
is( $row->RecordDate, '5/17/2005', "RecordDate matches" );
is( $row->ChannelName, '3 WATL', "ChannelName matches" );
is( $row->Viewed, '1', "Viewed matches" );
is( $row->UniqueID, 'EP0186930124', "UniqueID matches" );
is( $row->Genre, undef, "Genre matches" );
is( $row->Subtitle, 'Treehouse of Horror V', "Subtitle matches" );
is( $row->Runtime, '30', "Runtime matches" );
is( $row->Actors, undef, "Actors matches" );
is( $row->Rating, undef, "Rating matches" );
is( $row->Director, undef, "Director matches" );
is( $row->PosterImage, undef, "PosterImage matches" );
is( $row->InternetFetchCompleted, 0, "InternetFetchCompleted matches" );
is( $row->YearOfRelease, undef, "YearOfRelease matches" );
is( $row->Tagline, undef, "Tagline matches" );
is( $row->Writer, 'EP0186930124', "Writer matches" );
is( $row->ViewerRating, undef, "ViewerRating matches" );
is( $row->Votes, undef, "Votes matches" );

