# File::Marker - check module loading and create testing directory

use Test::More 'no_plan';
use File::Spec::Functions;
use File::Temp 0.14;

#--------------------------------------------------------------------------#
# Fixtures
#--------------------------------------------------------------------------#

my $filename     = catfile( 't', 'testdata.txt' );
my $savefile     = File::Temp->new();
my $savefilename = $savefile->filename;

#--------------------------------------------------------------------------#
# build index of lines
#--------------------------------------------------------------------------#

require_ok('File::Marker');

ok( my $obj = File::Marker->new(), "creating new File::Marker object" );

ok( $obj->open( $filename, "<" ), "opening a data file with 'open'" );

my $i = 0;
my %lines;
while ( !$obj->eof ) {
    $obj->set_marker($i);
    $lines{ $i++ } = <$obj>;
}

#--------------------------------------------------------------------------#
# Save markers
#--------------------------------------------------------------------------#

ok( $obj->save_markers($savefilename), "saving markers to $savefilename" );

#--------------------------------------------------------------------------#
# clear and re-load markers
#--------------------------------------------------------------------------#

ok( $obj->open( $filename, "<" ), "reopening test data file and clearing markers" );

ok( $obj->load_markers($savefilename), "loading markers from $savefilename" );

for my $mark ( sort $obj->markers ) {
    next if $mark eq 'LAST';
    $obj->goto_marker($mark);
    is( <$obj>, $lines{$mark}, "line $mark matched" );
}

