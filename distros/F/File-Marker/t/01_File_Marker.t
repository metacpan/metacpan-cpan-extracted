# File::Marker - check module loading and create testing directory

use Test::More 'no_plan';
use File::Spec::Functions;

my $filename = catfile( 't', 'testdata.txt' );

require_ok('File::Marker');

my $obj = File::Marker->new();
isa_ok( $obj, 'File::Marker' );
isa_ok( $obj, 'IO::File' );

#--------------------------------------------------------------------------#
# opening and closing files; readline
#--------------------------------------------------------------------------#

my $line1 = "one\n";

ok( $obj->open( $filename, "<" ), "opening a data file with 'open'" );

is( scalar <$obj>, $line1, "file contents correct" );

ok( $obj->close, "closing data file" );

ok( $obj = File::Marker->new( $filename, "<" ), "opening a data file with 'new'" );

is( scalar <$obj>, "one\n", "first line contents correct" );

#--------------------------------------------------------------------------#
# marking and jumping
#--------------------------------------------------------------------------#
my $expected_line;

ok( $obj->set_marker("line2"), "marking current position at line 2" );

ok( $expected_line = <$obj>, "reading line 2" );

ok( $obj->goto_marker("line2"), "jumping back to the marker for line 2" );

is( scalar <$obj>, $expected_line, "reading line 2 again" );

#--------------------------------------------------------------------------#
# special marker 'LAST'
#--------------------------------------------------------------------------#

ok( $obj->set_marker("line3"), "setting a marker for line 3" );

ok( $expected_line = <$obj>, "reading line 3" );

ok( $obj->goto_marker("line3"), "jumping back to the marker for line 3" );

ok( $obj->goto_marker("line2"), "jumping back to the marker for line 2" );

ok( $obj->goto_marker("LAST"),
    "jumping back to the special 'LAST' marker (i.e. line 3)" );

is( scalar <$obj>, $expected_line, "reading line 3 again" );

eval { $obj->set_marker('LAST') };
like( $@, qr/LAST/, "got error trying to set 'LAST'" );

#--------------------------------------------------------------------------#
# list of markers
#--------------------------------------------------------------------------#

my @expected_markers = sort qw( line2 line3 LAST );

is_deeply( [ sort $obj->markers() ],
    \@expected_markers, "got correct list of existing markers" );

#--------------------------------------------------------------------------#
# reset on new file and LAST on new file
#--------------------------------------------------------------------------#

ok( $obj->open( $filename, "<" ), "reopening test data file" );

eval { $obj->goto_marker("line3") };
like( $@, qr/line3/, "reopening clears tags (got error jumping to line 3 tag)" );

is( scalar <$obj>, $line1, "reading line 1 again" );

ok( $obj->goto_marker("LAST"),
    "jumping back to the special 'LAST' marker (without any prior jumps)" );

is( scalar <$obj>, $line1, "reading line 1 again" );

#--------------------------------------------------------------------------#
# failures on closed filehandles
#--------------------------------------------------------------------------#

ok( close $obj, "closing filehandle" );

eval { $obj->set_marker('mark') };
like( $@, qr/closed/, "got error trying to set marker for closed filehandle" );

eval { $obj->goto_marker('LAST') };
like( $@, qr/closed/, "got error trying to goto marker for closed filehandle" );

#--------------------------------------------------------------------------#
# no memory leaks
#--------------------------------------------------------------------------#

is( File::Marker->_object_count,
    1, "Confirm only one object in memory storage (no leaks)" );
