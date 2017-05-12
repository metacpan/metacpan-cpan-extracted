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
BEGIN { use_ok('FlatFile::DataStore::Preamble') };

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

 my $string = $preamble->string();

is( $string, '++WQ6A00001001c10000----------:', "string()" );

 my $clone = FlatFile::DataStore::Preamble->new( {
     datastore => $ds,
     string    => $string
     } );

ok( $clone, "clone" );
is( $clone->string(), $preamble->string(), "clone" );

# accessors pod

# $preamble->string(    $value ); # full preamble string

is( $string, '++WQ6A00001001c10000----------:', "string()" );

# $preamble->indicator( $value ); # single-character crud indicator

is( $preamble->indicator(), '+', "indicator()" );

# $preamble->transind(  $value ); # single-character crud indicator

is( $preamble->transind(), '+', "transind()" );

# $preamble->date(      $value ); # date as YYYY-MM-DD

is( $preamble->date(), '2010-06-10 00:00:00', "date()" );

# $preamble->transnum(  $value ); # transaction number (integer)

is( $preamble->transnum(), 1, "transnum()" );

# $preamble->keynum(    $value ); # record sequence number (integer)

is( $preamble->keynum(), 0, "keynum()" );

# $preamble->reclen(    $value ); # record length (integer)

is( $preamble->reclen(), 100, "reclen()" );

# $preamble->thisfnum(  $value ); # file number (in base format)

is( $preamble->thisfnum(), '1', "thisfnum()" );

# $preamble->thisseek(  $value ); # seek position (integer)

is( $preamble->thisseek(), 0, "thisseek()" );

# $preamble->prevfnum(  $value ); # ditto these ...

is( $preamble->prevfnum(), undef, "prevfnum()" );

# $preamble->prevseek(  $value ); # 

is( $preamble->prevseek(), undef, "prevseek()" );

# $preamble->nextfnum(  $value ); # 

is( $preamble->nextfnum(), undef, "nextfnum()" );

# $preamble->nextseek(  $value ); # 

is( $preamble->nextseek(), undef, "nextseek()" );

# $preamble->user(      $value ); # pre-formatted user-defined data

is( $preamble->user(), ':', "user()" );

# $preamble->crud(      $value ); # hash ref of all crud indicators

is( Dumper($preamble->crud()),
    "{'#' => 'oldupd','*' => 'olddel','+' => 'create','-' => 'delete','=' => 'update','create' => '+','delete' => '-','olddel' => '*','oldupd' => '#','update' => '='}",
    "crud()" );

# more pod

ok( $preamble->is_created(), "is_created()" );

my $rec = $ds->create({ data => "This is a test", user => ":" });

ok( $rec->preamble->is_created(), "is_created()" );
ok( $rec->is_created(), "is_created()" );

$rec = $ds->update( $rec );

ok( $rec->preamble->is_updated(), "is_updated()" );
ok( $rec->is_updated(), "is_updated()" );

$rec = $ds->delete( $rec );

ok( $rec->preamble->is_deleted(), "is_deleted()" );
ok( $rec->is_deleted(), "is_deleted()" );

# print "Deleted!" if $preamble->is_deleted();

$preamble = $rec->preamble();
my $msg = "Deleted!" if $preamble->is_deleted();

is( $msg, "Deleted!", "is_deleted()" );

}
