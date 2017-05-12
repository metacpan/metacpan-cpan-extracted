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
BEGIN { use_ok('FlatFile::DataStore::Record') };

# need a datastore object

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

my $indicator = '+';
my $transind  = '+';
my $date      = 'WQ6A000';
my $transint  = 1;
my $keynum    = 0;
my $reclen    = 100;
my $fnum      = 1;
my $datapos   = 0;
my $prevfnum;  # not defined okay for create
my $prevseek;
my $nextfnum;
my $nextseek;
my $user_data = ':';

 # first, create a preamble object

 use FlatFile::DataStore::Preamble;

 my $preamble = FlatFile::DataStore::Preamble->new( {
     datastore => $ds,         # FlatFile::DataStore object
     indicator => $indicator,  # single-character crud flag
     transind  => $transind,   # single-character crud flag
     date      => $date,       # pre-formatted date
     transnum  => $transint,   # transaction number (integer)
     keynum    => $keynum,     # record sequence number (integer)
     reclen    => $reclen,     # record length (integer)
     thisfnum  => $fnum,       # file number (in base format)
     thisseek  => $datapos,    # seek position (integer)
     prevfnum  => $prevfnum,   # ditto these ...
     prevseek  => $prevseek,
     nextfnum  => $nextfnum,
     nextseek  => $nextseek,
     user      => $user_data,  # pre-formatted user-defined data
     } );

ok( $preamble, "FF::DS::Preamble->new()" );

 # then create a record object with the preamble contained in it

 use FlatFile::DataStore::Record;

 my $record = FlatFile::DataStore::Record->new( {
     preamble => $preamble,                 # i.e., a preamble object
     data     => "This is a test record.",  # actual record data
     } );

ok( $record, "FF::DS::Record->new()" );

# more pod

my $value = "This is a test.";

 $record->data(     $value ); # actual record data as a scalar ref

is( $record->data, $value, "data()" );

$value = $preamble;

 $record->preamble( $value ); # FlatFile::DataStore::Preamble object

$value = $record->preamble;

is( "$value", "$preamble", "preamble()" );

 $value = $record->user();
 is( $value, ":", "user()" );
 $value = $record->preamble_string();  # the 'string' attr of the preamble
 is( $value, $preamble->string, "preamble_string()" );
 $value = $record->indicator();
 is( $value, "+", "indicator()" );
 $value = $record->transind();
 is( $value, "+", "transind()" );
 $value = $record->date();
 is( $value, "2010-06-10 00:00:00", "date()" );
 $value = $record->transnum();
 is( $value, "1", "transnum()" );
 $value = $record->keynum();
 is( $value, "0", "keynum()" );
 $value = $record->reclen();
 is( $value, "100", "reclen()" );
 $value = $record->thisfnum();
 is( $value, "1", "thisfnum()" );
 $value = $record->thisseek();
 is( $value, "0", "thisseek()" );
 $value = $record->prevfnum();
 is( $value, undef, "prevfnum()" );
 $value = $record->prevseek();
 is( $value, undef, "prevseek()" );
 $value = $record->nextfnum();
 is( $value, undef, "nextfnum()" );
 $value = $record->nextseek();
 is( $value, undef, "nextseek()" );

 $record = $ds->create( $record );
 $value = $record->is_created();
 ok( $value, "is_created()" );

 $record = $ds->update( $record );
 $value = $record->is_updated();
 ok( $value, "is_updated()" );

 $record = $ds->delete( $record );
 $value = $record->is_deleted();
 ok( $value, "is_deleted()" );


}

__END__
