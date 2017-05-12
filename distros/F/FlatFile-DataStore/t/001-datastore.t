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

{  # accessors

    my $uri = join( ';' =>
        qq'http://example.com?name=$name',
        qq'desc='.uri_escape($desc),
        qw(
            datamax=9_000
            recsep=%0A
            indicator=1-%2B%23%3D%2A%2D
            transind=1-%2B%23%3D%2A%2D
            date=8-yyyymmdd
            transnum=2-10
            keynum=2-10
            reclen=2-10
            thisfnum=1-10
            thisseek=4-10
            prevfnum=1-10
            prevseek=4-10
            nextfnum=1-10
            nextseek=4-10
            user=10-%20-%7E
        )
    );

    my $ds = FlatFile::DataStore->new(
        { dir  => $dir,
          name => $name,
          uri  => $uri,
        } );

    ok( $ds, "new()" );

    is( $ds->dir,         $dir,         "dir()"         );
    is( $ds->name,        $name,        "name()"        );
    is( $ds->desc,        $desc,        "desc()"        );
    is( $ds->datamax,     9_000,        "datamax()"     );
    is( $ds->recsep,      "\x0A",       "recseip()"     );
    is( $ds->indicator,   "1-+#=*-",    "indicator()"   );
    is( $ds->transind,    "1-+#=*-",    "transind()"    );
    is( $ds->date,        "8-yyyymmdd", "date()"        );
    is( $ds->transnum,    "2-10",       "transnum()"    );
    is( $ds->keynum,      "2-10",       "keynum()"      );
    is( $ds->reclen,      "2-10",       "reclen()"      );
    is( $ds->thisfnum,    "1-10",       "thisfnum()"    );
    is( $ds->thisseek,    "4-10",       "thisseek()"    );
    is( $ds->prevfnum,    "1-10",       "prevfnum()"    );
    is( $ds->prevseek,    "4-10",       "prevseek()"    );
    is( $ds->nextfnum,    "1-10",       "nextfnum()"    );
    is( $ds->nextseek,    "4-10",       "nextseek()"    );
    is( $ds->user,        "10- -~",     "user()"        );
    is( $ds->dateformat,  "yyyymmdd",   "dateformat()"  );
    is( $ds->fnumbase,    "10",         "fnumbase()"    );
    is( $ds->fnumlen,     1,            "fnumlen()"     );
    is( $ds->uri,         $uri,         "uri()"         );
    is( $ds->preamblelen, 41,           "preamblelen()" );
    is( $ds->translen,    2,            "translen()"    );
    is( $ds->transbase,   "10",         "transbase()"   );
    is( Dumper($ds->crud),
        "{'#' => 'oldupd','*' => 'olddel','+' => 'create','-' => 'delete','=' => 'update','create' => '+','delete' => '-','olddel' => '*','oldupd' => '#','update' => '='}",
        "crud()" );

    my $regx_string =
        quotemeta('(?').
        '(?:\^|-xism)'.  # (?^:...) replaces (?-xism:...) in Perl 5.13
        quotemeta(':([\+\#\=\*\-])([\+\#\=\*\-])([0-9]{8})([-0-9]{2})([-0-9]{2})([-0-9]{2})([-0-9])([-0-9]{4})([-0-9])([-0-9]{4})([-0-9])([-0-9]{4})([ -~]{10}))');

    like( $ds->regx,
        qr/$regx_string/,
        "regx()" );
    is( Dumper($ds->specs),
        "{'indicator' => [0,1,'+#=*-']}{'transind' => [1,1,'+#=*-']}{'date' => [2,8,'yyyymmdd']}{'transnum' => [10,2,'10']}{'keynum' => [12,2,'10']}{'reclen' => [14,2,'10']}{'thisfnum' => [16,1,'10']}{'thisseek' => [17,4,'10']}{'prevfnum' => [21,1,'10']}{'prevseek' => [22,4,'10']}{'nextfnum' => [26,1,'10']}{'nextseek' => [27,4,'10']}{'user' => [31,10,' -~']}",
        "specs()" );
}

#---------------------------------------------------------------------
{  # crud

    my( $y, $m, $d ) = sub{($_[5]+1900,$_[4]+1,$_[3])}->(localtime);
    my $yyyy_mm_dd   = sprintf "%04d-%02d-%02d", $y, $m, $d;
    my $yyyymmdd     = sprintf "%04d%02d%02d",   $y, $m, $d;

    my $ds = FlatFile::DataStore->new( {
        dir  => $dir,
        name => $name,
    } );

    ok( $ds, "new()" );

    my $user_data   = "Testing1";
    #                  ----+----1----+----2---- (reclen:24)
    my $record_data = "This is testing record1.";

    my $record = $ds->create({ data => $record_data, user => $user_data });
    is( Dumper($record),

        qq/bless( {'data' => \\'This is testing record1.','preamble' => bless( {'crud' => {'#' => 'oldupd','*' => 'olddel','+' => 'create','-' => 'delete','=' => 'update','create' => '+','delete' => '-','olddel' => '*','oldupd' => '#','update' => '='},'date' => '$yyyy_mm_dd','indicator' => '+','keynum' => 0,'reclen' => 24,'string' => '++${yyyymmdd}01002410000----------Testing1  ','thisfnum' => '1','thisseek' => 0,'transind' => '+','transnum' => 1,'user' => 'Testing1'}, 'FlatFile::DataStore::Preamble' )}, 'FlatFile::DataStore::Record' )/,
        "create()" );

    my $data = $record->data();
    is( $data, "This is testing record1.", "data()" );

    my $keynum = $record->keynum();
    is( $keynum, 0, "keynum()" );

    my $user = $record->user();
    is( $user, "Testing1", "user()" );

    my $string = $record->preamble_string();
    is( $string, "++${yyyymmdd}01002410000----------Testing1  ", "string()" );

    my $indicator = $record->indicator();
    is( $indicator, "+", "indicator()" );

    my $transind = $record->transind();
    is( $transind, "+", "transind()" );

    my $date = $record->date();
    is( $date, $yyyy_mm_dd, "date()" );

    my $reclen = $record->reclen();
    is( $reclen, 24, "reclen()" );

    my $transnum = $record->transnum();
    is( $transnum, 1, "transnum()" );

    my $thisfnum = $record->thisfnum();
    is( $thisfnum, "1", "thisfnum()" );

    my $thisseek = $record->thisseek();
    is( $thisseek, 0, "thisseek()" );

    my $record2 = $ds->retrieve( $keynum );
    my $recdump1 = Dumper $record;
    my $recdump2 = Dumper $record2;
    is( $recdump1, $recdump2, "retrieve()" );
    ok( $record->is_created, "is_created()" );
    ok( $record2->is_created, "is_created()" );

    my $updrec = $ds->update({ record => $record, data => "Updated Record", user => "Updated1" });

    my $rec_data = $updrec->data;
    is( $rec_data,    "Updated Record", "rec->data()" );
    is( $updrec->user, "Updated1",      "rec->user()" );
    ok( $updrec->is_updated, "is_updated()" );

    my $delrec = $ds->delete( $updrec );
    is( $delrec->indicator, $ds->crud()->{'delete'}, "deleted indicator()" );
    ok( $delrec->is_deleted, "is_deleted()" );

    $ds->userdata( "testing" );
    $record = $ds->create({ data => "Another test." });
    is( $record->user, "testing", "userdata()" );

    $record->data( "Yet another test." );
    $record = $ds->create( $record );
    $record2 = $ds->retrieve( $record->keynum );
    my $recdata  = $record->data;
    my $recdata2 = $record2->data;
    is( $recdata, $recdata2, "create( record )" );

    $record2 = $ds->create({ record => $record, user => 'other user' });
    is( $record2->user, 'other user', "create( record, user data )" );

    $record = $ds->create({ data => \"Apple", user => 'fruit' });
    is( $record->data, 'Apple', "create( scalar-ref, user data )" );
    is( $record->user, 'fruit', "create( scalar-ref, user data )" );
}

#---------------------------------------------------------------------
{  # misc

    my $ds = FlatFile::DataStore->new( {
        dir  => $dir,
        name => $name,
    } );

    ok( $ds, "new()" );

    # we want the newlines here:
    my $msg1 = "For testing retrieve_preamble()\n";
    my $msg2 = "For testing locate_record_data()\n";

    my $record = $ds->create({ data => "$msg1$msg2" });
    my $keynum = $record->keynum;
    my $preamble_string1 = $record->preamble_string;

    my $preamble = $ds->retrieve_preamble( $keynum );
    my $preamble_string2 = $preamble->string;

    is( $preamble_string1, $preamble_string2, "retrieve_preamble()" );

    my $buffer = '';

    # see POD:
    my( $fh, $pos, $len ) = $ds->locate_record_data( $keynum );
    my $got;
    while( <$fh> ) {
        last if ($got += length) > $len;  # in case we read the recsep
        # [do something with $_ ...]
        $buffer .= $_;
        last if $got == $len;
    }
    close $fh;

    is( $buffer, "$msg1$msg2", "locate_record_data()" );

}

