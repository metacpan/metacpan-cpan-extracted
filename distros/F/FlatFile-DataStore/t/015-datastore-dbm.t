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
BEGIN { use_ok('FlatFile::DataStore::DBM') };

my $name = "example";
my $desc = "Example FlatFile::DataStore";

use URI::Escape;

{
    use FlatFile::DataStore::DBM;

    tie my %dshash, 'FlatFile::DataStore::DBM', {
        name => $name,
        dir  => $dir,
        uri  => join( ';' =>
            "http://example.com?name=$name",
            "desc=" . uri_escape( $desc ),
            "defaults=medium",
            "user=" . uri_escape( '8- -~' ),
            "recsep=%0A",
        ),
    };

ok( tied(%dshash), "tied datastore dbm object" );

    # create a record

    my $id = "record_id1";

    my $record = $dshash{ $id } = { data => "Test record", user => "userdata" };
    my $record_number = $record->keynum;

ok( $record, "record object" );
is( $record_number, 0, "first record number" );

    my $try = tied(%dshash)->get_key( $record_number );

is( $try, $id, "get_key()" );

    # update it (have to "have" a record to update it)

    $record->data( "Updating the test record." );
    $dshash{ $id } = $record;

    # retrieve it

    $record = $dshash{ $id };

is( $record->data, "Updating the test record.", "update/retrieve" );

    # delete it

    delete $dshash{ $id };

ok( !(exists $dshash{ $id }), "deleted record -- exists?" );
ok( tied(%dshash)->retrieve( $record_number )->is_deleted, "deleted record -- retrieve()" );
ok( tied(%dshash)->retrieve_preamble( $record_number )->is_deleted, "deleted record -- retrieve_preamble()" );

# put one back
$record = $dshash{ $id } = $record;

my $record_data = "Some test record data.";
my $user_data   = "userdata";

 $id++;

 $record = $dshash{ $id } = $record_data;

is( $dshash{ $id }->data, $record_data, "scalar record data" );
is( $dshash{ $id }->user, "", "scalar record data ... user data default" );

 $id++;
 $record = $dshash{ $id } = { data => $record_data, user => $user_data };

is( $dshash{ $id }->data, $record_data, "href record data" );
is( $dshash{ $id }->user, $user_data, "href user data" );

 $id++;
 $record->data( $record_data );
 $record->user( $user_data );  # XXX wrong, user() is readonly
 $record = $dshash{ $id } = $record;

is( $dshash{ $id }->data, $record_data, "object record data" );
is( $dshash{ $id }->user, $user_data, "object user data" );

 # update
 $dshash{ $id } = { data => "xxx", user => "yyy" };

is( $dshash{ $id }->data, "xxx", "object record data (update)" );
is( $dshash{ $id }->user, "yyy", "object user data (update)" );

}

__END__

