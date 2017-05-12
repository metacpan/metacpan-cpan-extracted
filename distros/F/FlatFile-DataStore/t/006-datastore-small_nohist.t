use strict;
use warnings;

use Test::More 'no_plan';
use File::Path;
use URI::Escape;
use Data::Dumper;
$Data::Dumper::Terse    = 1;
$Data::Dumper::Indent   = 0;
$Data::Dumper::Sortkeys = 1;

#---------------------------------------------------------------------
# tempfiles cleanup

sub delete_tempfiles {
    my( $dir ) = @_;
    return unless $dir;

    for( glob "$dir/*" ) {
        if( -d $_ ) { rmtree( $_ ) }
        else        { unlink $_ or die "Can't delete $_: $!" }
    }
}

my $dir;
BEGIN {
    $dir  = "./tempdir";
    unless( -e $dir ) {
        mkdir $dir or die "Can't mkdir $dir: $!";
    }
}
NOW:  { delete_tempfiles( $dir ) }
END   { delete_tempfiles( $dir ) }

#---------------------------------------------------------------------
BEGIN { use_ok('FlatFile::DataStore') };

my $name = "example";
my $desc = "Example FlatFile::DataStore";

{

 my $ds = FlatFile::DataStore->new(
     { dir  => $dir,
       name => $name,
       uri  => join( ";" =>
           "http://example.com?name=$name",
           "desc=".uri_escape($desc),
           "defaults=small_nohist",
           "user=1-:",
           "recsep=%0A",
           ),
       userdata => ':',
     } );

my @recs;
push @recs, $ds->create({ data => 'Test Record 1' });
push @recs, $ds->create({ data => 'Test Record 2' });
push @recs, $ds->create({ data => 'Test Record 3' });

for( my $i = 0; $i < 2; $i++ ) {
    my $rec = $ds->retrieve( $i );
    is( $rec->data, $recs[$i]->data, "small_nohist rec data" );
}
}
