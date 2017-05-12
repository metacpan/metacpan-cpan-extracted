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

use URI::Escape;
my $datastore = FlatFile::DataStore::->new( {
    name => $name,
    dir  => $dir,
    uri  => join( ';' =>
        "http://example.com?name=$name",
        "desc=" . uri_escape( $desc ),
        "defaults=medium",
        "user=" . uri_escape( '8- -~' ),
        "recsep=%0A",
    ) }
);

{
    use FlatFile::DataStore;

    tie my %dshash, 'FlatFile::DataStore', {
        name => $name,
        dir  => $dir,
    };

ok( tied(%dshash), "tied datastore object" );

    # create a record (null string key says, "new record")

    my $record = $dshash{''} = { data => "Test record", user => "userdata" };
    my $record_number = $record->keynum;

ok( $record, "record object" );
is( $record_number, 0, "first record number" );

    # update it (have to "have" a record to update it)

    $record->data( "Updating the test record." );
    $dshash{ $record_number } = $record;

    # retrieve it

    $record = $dshash{ $record_number };

is( $record->data, "Updating the test record.", "update/retrieve" );

    # delete it

    delete $dshash{ $record_number };

ok( $dshash{ $record_number }->is_deleted, "deleted record" );

# put one back
$record = $dshash{ $record_number } = $dshash{ $record_number };

    # -or-
    tied(%dshash)->delete( $record );

ok( $dshash{ $record_number }->is_deleted, "deleted record" );

my $record_data = "Some test record data.";
my $user_data   = "userdata";

 $record = $dshash{''} = $record_data;

is( $dshash{ $record->keynum }->data, $record_data, "scalar record data" );
is( $dshash{ $record->keynum }->user, "", "scalar record data ... user data default" );

 $record = $dshash{''} = { data => $record_data, user => $user_data };

is( $dshash{ $record->keynum }->data, $record_data, "href record data" );
is( $dshash{ $record->keynum }->user, $user_data, "href user data" );

 $record->data( $record_data );
 $record->user( $user_data );
 $record = $dshash{''} = $record;

is( $dshash{ $record->keynum }->data, $record_data, "object record data" );
is( $dshash{ $record->keynum }->user, $user_data, "object user data" );

}
