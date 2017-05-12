use strict;
use warnings;

use Test::More 'no_plan';
use URI::Escape;
use File::Path;
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

{  # new() pod

 my $ds = FlatFile::DataStore->new(
     { dir  => $dir,
       name => $name,
       uri  => join( ";" =>
           "http://example.com?name=$name",
           "desc=" . uri_escape( $desc ),
           "defaults=medium",
           "user=" . uri_escape( '8- -~' ),
           "recsep=%0A",
           ),
     } );

ok( $ds, "new(dir,name,uri)" );
}
{

 my $ds = FlatFile::DataStore->new(
     { dir  => $dir,
       name => $name,
     } );

ok( $ds, "new(dir,name)" );
}

