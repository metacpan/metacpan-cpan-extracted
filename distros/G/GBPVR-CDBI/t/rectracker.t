#!perl -T

use Test::More;
use strict;
use warnings;

plan tests => 10;

use File::Spec;
use GBPVR::CDBI::RecTracker::RecordedShows;

my $db= File::Spec->rel2abs("t\\rectracker.mdb");
ok($db, "found test db");
my $rc = GBPVR::CDBI::RecTracker::RecordedShows->db_setup(file => $db);
ok($rc, "got db handle");

my @rows = GBPVR::CDBI::RecTracker::RecordedShows->retrieve_all();
is(scalar(@rows), 1, "got exactly 1 row");
my $row = shift @rows;
is( ref($row), 'GBPVR::CDBI::RecTracker::RecordedShows', "item is an object");

is( $row->name, 'The Simpsons', "name matches" );
is( $row->sub_title, 'Treehouse of Horror V', "sub_title matches" );
is( $row->description, 'Halloween vignettes spoof "The Shining," "Crime and Punishment" and "Soylent Green."', "description matches" );
is( $row->unqiue_id, 'EP0186930124', "unqiue_id (sic) matches" );
is( $row->startdate, '5/17/2005', "startdate matches" );

is( $row->unique_id, $row->unqiue_id, "unique_id matches unqiue_id" );

