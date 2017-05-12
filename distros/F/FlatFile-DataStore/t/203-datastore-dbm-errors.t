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
# XXX come back to this ...
# {  # TIEHASH() with bad DBM package
# 
#     # eval qq{require $dbm_package; 1} or croak qq/Can't use $dbm_package: $@/;
# 
# 
#     $FlatFile::DataStore::DBM::dbm_package  = "DUMMY_DBM_File";
# 
#     eval {
#         tie my %dshash, 'FlatFile::DataStore::DBM' => { dummy => 1 };
#     };
#     like( $@, qr/Can't use DUMMY_DBM_File:/,
#               q/TIEHASH() Can't use $dbm_package: $@/ );
# }
# 

#---------------------------------------------------------------------
{  # tie() with insufficient parms (really testing new()/init())

    eval {
        tie my %dshash, 'FlatFile::DataStore::DBM' => { dummy => 1 };
    };
    like( $@, qr/Need "dir" and "name"/, "tie() with insufficient parms" );
}

#---------------------------------------------------------------------
{  # FETCH():
   #     /Unsupported key format: $key/

    delete_tempfiles( $dir );

    tie my %dshash, 'FlatFile::DataStore::DBM' => {
        name => $name,
        dir  => $dir,
        uri  => $ok_uri,
        };

    $dshash{'first'} = { data => "This is a test." };

    # croak qq/Unsupported key format: $key/ if $key =~ /^_[0-9]+$/;

    eval {
        my $rec = $dshash{'_0'};
    };
    like( $@, qr/Unsupported key format: _0/,
              q/FETCH() Unsupported key format: $key/ );
}

#---------------------------------------------------------------------
{  # STORE():
   #     /Unsupported key format: $key/
   #     /Not a record object: $parms/
   #     /Record key number doesn't match key/
   #     /Unsupported ref type: $reftype/

    delete_tempfiles( $dir );

    tie my %dshash, 'FlatFile::DataStore::DBM' => {
        name => $name,
        dir  => $dir,
        uri  => $ok_uri,
        };

    my $rec = $dshash{'first'} = { data => "This is a test." };

    # croak qq/Unsupported key format: $key/ if $key =~ /^_[0-9]+$/;

    eval {
        $dshash{'_0'} = { data => 1 };
    };
    like( $@, qr/Unsupported key format: _0/,
              q/STORE() Unsupported key format: $key/ );

    # croak qq/Record key number doesn't match key/
    #     unless $keynum == $parms->keynum;

    # add a new record
    $rec = $dshash{'second'} = { data => "This is a test." };

    # update it with wrong key
    eval {
        $dshash{'first'} = $rec;
    };
    like( $@, qr/Record key number doesn't match key/,
              q/STORE() Record key number doesn't match key/ );

    # croak qq/Unsupported ref type: $reftype/;

    # aref is not acceptable for update
    eval {
        $dshash{'second'} = [ data => "This is a test." ];
    };
    like( $@, qr/Unsupported ref type:/,
              q/STORE() (update) Unsupported ref type: $reftype/ );

    # aref is not acceptable for create
    eval {
        $dshash{'third'} = [ data => "This is a test." ];
    };
    like( $@, qr/Unsupported ref type:/,
              q/STORE() (create) Unsupported ref type: $reftype/ );

}

#---------------------------------------------------------------------
{  # CLEAR():
   #     /Clearing the entire datastore is not supported/

    delete_tempfiles( $dir );

    tie my %dshash, 'FlatFile::DataStore::DBM' => {
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

#---------------------------------------------------------------------
{  # EXISTS():
   #     /Unsupported key format: $key/

    delete_tempfiles( $dir );

    tie my %dshash, 'FlatFile::DataStore::DBM' => {
        name => $name,
        dir  => $dir,
        uri  => $ok_uri,
        };

    $dshash{'first'} = { data => "This is a test." };

    # croak qq/Unsupported key format: $key/ if $key =~ /^_[0-9]+$/;

    eval {
        exists $dshash{'_0'};
    };
    like( $@, qr/Unsupported key format: _0/,
              q/EXISTS() Unsupported key format: $key/ );
}

#---------------------------------------------------------------------
{  # get_key():
   #     /Not a keynum: $keynum/

    delete_tempfiles( $dir );

    my $obj = tie my %dshash, 'FlatFile::DataStore::DBM' => {
        name => $name,
        dir  => $dir,
        uri  => $ok_uri,
        };

    $dshash{'first'} = { data => "This is a test." };

    # croak qq/Not a keynum: $keynum/
    #     unless defined $keynum and $keynum =~ /^[0-9]+$/;

    eval {
        $obj->get_key( 'dummy' );
    };
    like( $@, qr/Not a keynum:/,
              q/get_key() Not a keynum: $keynum/ );
}

#---------------------------------------------------------------------
{  # get_keynum():
   #     /Unsupported key format: $key/

    delete_tempfiles( $dir );

    my $obj = tie my %dshash, 'FlatFile::DataStore::DBM' => {
        name => $name,
        dir  => $dir,
        uri  => $ok_uri,
        };

    $dshash{'first'} = { data => "This is a test." };

    # croak qq/Unsupported key format: $key/ if $key =~ /^_[0-9]+$/;

    eval {
        $obj->get_keynum( '_0' );
    };
    like( $@, qr/Unsupported key format: _0/,
              q/get_keynum() Unsupported key format: $key/ );
}

#---------------------------------------------------------------------
{  # AUTOLOAD():
   #     /Unsupported method: $_/

    delete_tempfiles( $dir );

    my $obj = tie my %dshash, 'FlatFile::DataStore::DBM' => {
        name => $name,
        dir  => $dir,
        uri  => $ok_uri,
        };

    # create a record

    $dshash{'first'} = { data => "This is a test." };
    my $keynum = $obj->get_keynum( 'first' );

    # should succeed:

    my $test_name = $obj->name;
    is( $test_name, $name, q/name() (AUTOLOAD)/ );

    my $test_dir = $obj->dir;
    is( $test_dir, $dir, q/dir() (AUTOLOAD)/ );

    my $record = $obj->retrieve( $keynum );
    ok( $record, q/retrieve() (AUTOLOAD)/ );

    my $preamble = $obj->retrieve_preamble( $keynum );
    ok( $preamble, q/retrieve_preamble() (AUTOLOAD)/ );

    my( $fh, $pos, $len ) = $obj->locate_record_data( $keynum );
    ok( $fh, q/locate_record_data() (AUTOLOAD)/ );

    my @history = $obj->history( $keynum );
    ok( @history, q/history() (AUTOLOAD)/ );

    my $userdata   = $obj->userdata;
    is( $userdata, '', q/userdata() (AUTOLOAD)/ );

    my $howmany    = $obj->howmany;
    is( $howmany, 1, q/howmany() (AUTOLOAD)/ );

    my $lastkeynum = $obj->lastkeynum;
    is( $lastkeynum, 0, q/lastkeynum() (AUTOLOAD)/ );

    my $nextkeynum = $obj->nextkeynum;
    is( $nextkeynum, 1, q/nextkeynum() (AUTOLOAD)/ );

    eval {
        $obj->dummy();
    };
    like( $@, qr/Unsupported method:/,
              q/dummy() (AUTOLOAD) Unsupported method: $_/ );
}

__END__

