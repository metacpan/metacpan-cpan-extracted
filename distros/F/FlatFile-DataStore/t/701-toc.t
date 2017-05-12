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
NOW:{ delete_tempfiles( $dir ) }
END { delete_tempfiles( $dir ) }

#---------------------------------------------------------------------
BEGIN { use_ok('FlatFile::DataStore::Toc') };

use FlatFile::DataStore;

my $name   = "example";
my $desc   = "Example FlatFile::DataStore";
my $recsep = "\x0A";

my $ds = FlatFile::DataStore->new(
    { dir  => $dir,
      name => $name,
      uri  => join( ";" =>
          "http://example.com?name=$name",
          "desc=".uri_escape($desc),
          "defaults=xsmall",
          "user=1-:",
          "recsep=".uri_escape($recsep) ),
    } );

ok( $ds, "FlatFile::DataStore->new()" );

{ # pod

 use FlatFile::DataStore::Toc;
 my $toc;

 $toc = FlatFile::DataStore::Toc->new(
     { int       => 10,
       datastore => $ds
     } );

    is( $toc->datafnum, 10, "datafnum()" );

 # or

 $toc = FlatFile::DataStore::Toc->new(
     { num       => "A",               # same as int=>10
       datastore => $ds
     } );

    is( $toc->datafnum, 10, "datafnum()" );

}

{ # accessors

    my $rec;
    my $toc = FlatFile::DataStore::Toc->new(
        { int => 0,
          datastore => $ds,
        } );

    # values for an empty datastore

    my $try = $toc->datastore;
    is( "$try", "$ds", "datastore()" );

    is( $toc->to_string, undef, "to_string() no data" );
    is( $toc->string, undef, "string()" );

    is( $toc->datafnum, 0,  "datafnum()" );
    is( $toc->keyfnum,  0,  "keyfnum()"  );
    is( $toc->tocfnum,  1,  "tocfnum()"  );
    is( $toc->numrecs,  0,  "numrecs()"  );
    is( $toc->keynum,   -1, "keynum()"   );
    is( $toc->transnum, 0,  "transnum()" );
    is( $toc->create,   0,  "create()"   );
    is( $toc->oldupd,   0,  "oldupd()"   );
    is( $toc->update,   0,  "update()"   );
    is( $toc->olddel,   0,  "olddel()"   );
    is( $toc->delete,   0,  "delete()"   );

    # now with some data

    $rec = $ds->create({ data => "This is a test.", user => ":" });
    $toc = FlatFile::DataStore::Toc->new(
        { int => 0,
          datastore => $ds,
        } );

    is( $toc->to_string, "1 1 1 01 00 01 01 00 00 00 00$recsep", "to_string() w/data" );
    is( $toc->to_string, $toc->string.$recsep, "to_string() eq string()" );

    is( $toc->datafnum, 1,  "datafnum()" );
    is( $toc->keyfnum,  1,  "keyfnum()"  );
    is( $toc->tocfnum,  1,  "tocfnum()"  );
    is( $toc->numrecs,  1,  "numrecs()"  );
    is( $toc->keynum,   0,  "keynum()"   );
    is( $toc->transnum, 1,  "transnum()" );
    is( $toc->create,   1,  "create()"   );
    is( $toc->oldupd,   0,  "oldupd()"   );
    is( $toc->update,   0,  "update()"   );
    is( $toc->olddel,   0,  "olddel()"   );
    is( $toc->delete,   0,  "delete()"   );

    # once more, but get the second line of the tocfile
    # (should be the same as the first)

    $rec = $ds->create({ data => "This is another test.", user => ":" });
    $toc = FlatFile::DataStore::Toc->new(
        { int => 1,
          datastore => $ds,
        } );

    is( $toc->to_string, "1 1 1 02 01 02 02 00 00 00 00$recsep", "to_string() w/more data" );
    is( $toc->to_string, $toc->string.$recsep, "to_string() eq string()" );

    is( $toc->datafnum, 1,  "datafnum()" );
    is( $toc->keyfnum,  1,  "keyfnum()"  );
    is( $toc->tocfnum,  1,  "tocfnum()"  );
    is( $toc->numrecs,  2,  "numrecs()"  );
    is( $toc->keynum,   1,  "keynum()"   );
    is( $toc->transnum, 2,  "transnum()" );
    is( $toc->create,   2,  "create()"   );
    is( $toc->oldupd,   0,  "oldupd()"   );
    is( $toc->update,   0,  "update()"   );
    is( $toc->olddel,   0,  "olddel()"   );
    is( $toc->delete,   0,  "delete()"   );

    # less data

    $rec = $ds->delete({ record => $rec, data => "Test deleted.", user => ":" });
    $toc = FlatFile::DataStore::Toc->new(
        { int => 0,
          datastore => $ds,
        } );

    is( $toc->to_string, "1 1 1 01 01 03 02 00 00 01 01$recsep", "to_string() w/less data" );
    is( $toc->to_string, $toc->string.$recsep, "to_string() eq string()" );

    is( $toc->datafnum, 1,  "datafnum()" );
    is( $toc->keyfnum,  1,  "keyfnum()"  );
    is( $toc->tocfnum,  1,  "tocfnum()"  );
    is( $toc->numrecs,  1,  "numrecs()"  );
    is( $toc->keynum,   1,  "keynum()"   );
    is( $toc->transnum, 3,  "transnum()" );
    is( $toc->create,   2,  "create()"   );
    is( $toc->oldupd,   0,  "oldupd()"   );
    is( $toc->update,   0,  "update()"   );
    is( $toc->olddel,   1,  "olddel()"   );
    is( $toc->delete,   1,  "delete()"   );

}


__END__
