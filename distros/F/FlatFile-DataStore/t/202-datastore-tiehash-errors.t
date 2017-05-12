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

my $name   = "example";
my $desc   = "Example FlatFile::DataStore";
my $ok_uri = join( ';' =>
    qq'http://example.com?name=$name',
    qq'desc='.uri_escape($desc),
    qw(
        recsep=%0A
        indicator=1-%2B%23%3D%2A%2D
        transind=1-%2B%23%3D%2A%2D
        date=8-yyyymmdd
        transnum=2-10
        keynum=2-10
        reclen=2-10
        thisfnum=1-10 thisseek=4-10
        prevfnum=1-10 prevseek=4-10
        nextfnum=1-10 nextseek=4-10
        user=10-%20-%7E
    )
);

#---------------------------------------------------------------------
{  # tie() with insufficient parms (really testing new()/init())

    eval {
        tie my %dshash, 'FlatFile::DataStore' => { dummy => 1 };
    };
    like( $@, qr/Need "dir" and "name"/, "tie() with insufficient parms" );
}

#---------------------------------------------------------------------
{  # STORE():
   #     /Unsupported key format: $key/
   #     /Not a record object: $parms/
   #     /Record key number, $keynum, doesn't match key: $key/
   #     /Unsupported ref type: $reftype/

    delete_tempfiles( $dir );

    tie my %dshash, 'FlatFile::DataStore' => {
        name => $name,
        dir  => $dir,
        uri  => $ok_uri,
        };

    my $rec = $dshash{''} = { data => "This is a test." };
    my $rec_num = $rec->keynum;

    # croak qq/Unsupported key format: $key/
    #     unless $key =~ /^[0-9]+$/ and $key <= $nextkeynum;

    eval {
        $dshash{'dummy'} = { data => "This is a test." };
    };
    like( $@, qr/Unsupported key format: dummy/,
              q/STORE() Unsupported key format: $key (not 0-9)/ );

    my $bad_rec_num = $rec_num + 2;  # can't skip keynums

    eval {
        $dshash{ $bad_rec_num } = { data => "This is a test." };
    };
    like( $@, qr/Unsupported key format:/,
              q/STORE() Unsupported key format: $key (> nextkeynum)/ );

    # croak qq/Not a record object: $parms/
    #     unless $reftype and $reftype =~ /Record/;

    eval {
        $dshash{ $rec_num } = { data => "This is a test." };
    };
    like( $@, qr/Not a record object:/,
              q/STORE() Not a record object: $parms/ );

    # croak qq/Record key number, $keynum, doesn't match key: $key/
    #     unless $key == $keynum;

    # add a new record
    $rec         = $dshash{''} = { data => "This is a test." };
    $rec_num     = $rec->keynum;
    $bad_rec_num = $rec_num - 1;

    # update it with wrong record number
    eval {
        $dshash{ $bad_rec_num } = $rec;
    };
    like( $@, qr/Record key number, $rec_num, doesn't match key: $bad_rec_num/,
              q/STORE() Record key number, $keynum, doesn't match key: $key/ );

    # croak qq/Unsupported ref type: $reftype/;

    # aref is not acceptable
    eval {
        $dshash{''} = [ data => "This is a test." ];
    };
    like( $@, qr/Unsupported ref type:/,
              q/STORE() Unsupported ref type: $reftype/ );

}

#---------------------------------------------------------------------
{  # CLEAR():
   #     /Clearing the entire datastore is not supported/

    delete_tempfiles( $dir );

    tie my %dshash, 'FlatFile::DataStore' => {
        name => $name,
        dir  => $dir,
        uri  => $ok_uri,
        };

    # croak qq/Clearing the entire datastore is not supported/;

    eval {
        %dshash = ();
    };
    like( $@, qr/Clearing the entire datastore is not supported/,
              q/STORE() Clearing the entire datastore is not supported/ );

}

__END__

