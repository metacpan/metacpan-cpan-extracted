use strict;
use warnings;

use Test::More 'no_plan';
use File::Path;
use URI::Escape;
use Data::Dumper;
$Data::Dumper::Terse    = 1;
$Data::Dumper::Indent   = 0;
$Data::Dumper::Sortkeys = 1;

# If in a circle, a line,
# Hits the center, and runs spine to spine,
#   And the line's length is D,
#   The circumference will be,
# D times 3.14159

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

{  # new()/init()

    # new() with no parms
    my $ds = FlatFile::DataStore->new();
    ok( $ds, "new() with no parms" );

    # init() with insufficient parms
    eval {
        $ds->init({
            a => 1,  # dummy parms
        });
    };
    like( $@, qr/Need "dir" and "name"/, "init() with insufficient parms" );

    # init() with bad dir
    eval {
        $ds->init({
            name => $name,
            dir  => 3.14159,  # dummy dir
        });
    };
    like( $@, qr/Directory doesn't exist: 3.14159/, "init() with bad dir" );
}

#---------------------------------------------------------------------
{  # new() with insufficient parms (really testing init())

    eval {
        my $ds = FlatFile::DataStore->new({
            a => 1,  # dummy parms
        });
    };
    like( $@, qr/Need "dir" and "name"/, "new() with insufficient parms" );
}

#---------------------------------------------------------------------
{  # new() with bad dir (really testing init())

    eval {
        my $ds = FlatFile::DataStore->new({
            name => $name,
            dir  => 3.14159,  # dummy dir
        });
    };
    like( $@, qr/Directory doesn't exist: 3.14159/, "new() with bad dir" );
}

#---------------------------------------------------------------------
{  # init() 'Invalid URI file'

    delete_tempfiles( $dir );  # start fresh

    # create invalid dummy uri file
    my $uri_file = "$dir/$name.uri";

    open my $fh, '>', $uri_file or die "Can't open $uri_file: $!";

    # two lines (i.e., not one or four)
    print $fh "dummy\ndummy\n";

    close $fh or die "Problem closing $uri_file: $!";

    eval {
        my $ds = FlatFile::DataStore->new({
            name => $name,
            dir  => $dir,
        });
    };
    like( $@, qr/Invalid URI file: $uri_file/, "init() Invalid URI file" );
}

#---------------------------------------------------------------------
{  # init() 'URI MD5 check failed'

    delete_tempfiles( $dir );  # start fresh

    # create invalid dummy uri file
    my $uri_file = "$dir/$name.uri";

    open my $fh, '>', $uri_file or die "Can't open $uri_file: $!";

    # four lines, the third line will give us the error
    print $fh "dummy\ndummy\ndummy\ndummy\n";

    close $fh or die "Problem closing $uri_file: $!";

    eval {
        my $ds = FlatFile::DataStore->new({
            name => $name,
            dir  => $dir,
        });
    };
    like( $@, qr/URI MD5 check failed/, "init() URI MD5 check failed" );
}

#---------------------------------------------------------------------
{  # init() 'Object MD5 check failed'

    delete_tempfiles( $dir );  # start fresh

    use Digest::MD5 qw(md5_hex);
    my $dummy_md5 = md5_hex( 'dummy' );

    # create invalid dummy uri file
    my $uri_file = "$dir/$name.uri";

    open my $fh, '>', $uri_file or die "Can't open $uri_file: $!";

    # four lines, the fourth line will give us the error
    print $fh "dummy\ndummy\n$dummy_md5\ndummy\n";

    close $fh or die "Problem closing $uri_file: $!";

    eval {
        my $ds = FlatFile::DataStore->new({
            name => $name,
            dir  => $dir,
        });
    };
    like( $@, qr/Object MD5 check failed/, "init() Object MD5 check failed" );
}

#---------------------------------------------------------------------
{  # init() 'Problem with $uri_file'
   #     the idea here is that 'dummy' (on the second line) should
   #     not be 'eval-able' as a serialized object

    delete_tempfiles( $dir );  # start fresh

    use Digest::MD5 qw(md5_hex);
    my $dummy_md5 = md5_hex( 'dummy' );

    # create invalid dummy uri file
    my $uri_file = "$dir/$name.uri";

    open my $fh, '>', $uri_file or die "Can't open $uri_file: $!";

    # four lines, the second line will give us the error
    print $fh "dummy\ndummy\n$dummy_md5\n$dummy_md5\n";

    close $fh or die "Problem closing $uri_file: $!";

    eval {
        my $ds = FlatFile::DataStore->new({ name => $name, dir => $dir });
    };
    like( $@, qr/Problem with URI file, $uri_file/, "init() Problem with \$uri_file" );
}

#---------------------------------------------------------------------
{  # init(): uri file with only one line replaced by uri passed in
   #         Unrecognized parameter: $attr

    delete_tempfiles( $dir );  # start fresh

    # create okay dummy uri file
    my $uri_file = "$dir/$name.uri";

    open my $fh, '>', $uri_file or die "Can't open $uri_file: $!";

    # one line, dummy uri
    print $fh "dummy\n";

    close $fh or die "Problem closing $uri_file: $!";

    eval {
        my $ds = FlatFile::DataStore->new({
            name => $name,
            dir  => $dir,
            uri  => "http://example.com?dummy=1",  # dummy uri parm
            });
    };

    like( $@, qr/Unrecognized parameter: dummy/, 'init() Unrecognized parameter: $attr' );
}

#---------------------------------------------------------------------
{  # init(): 'fnum parameters differ'

    delete_tempfiles( $dir );  # start fresh

    # uri with thisfnum ne prev/nextfnum
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
            thisfnum=1-10 thisseek=4-10
            prevfnum=2-10 prevseek=4-10
            nextfnum=2-10 nextseek=4-10
            user=10-%20-%7E
        )
    );

    eval {
        my $ds = FlatFile::DataStore->new({
            name => $name,
            dir  => $dir,
            uri  => $uri,
            });
    };

    like( $@, qr/fnum parameters differ/, "init() fnum parameters differ" );
}

#---------------------------------------------------------------------
{  # init(): 'seek parameters differ'

    delete_tempfiles( $dir );  # start fresh

    # uri with thisseek ne prev/nextseek
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
            thisfnum=1-10 thisseek=4-10
            prevfnum=1-10 prevseek=5-10
            nextfnum=1-10 nextseek=5-10
            user=10-%20-%7E
        )
    );

    eval {
        my $ds = FlatFile::DataStore->new({
            name => $name,
            dir  => $dir,
            uri  => $uri,
            });
    };

    like( $@, qr/seek parameters differ/, "init() seek parameters differ" );
}

#---------------------------------------------------------------------
{  # init(): 'datamax too large'

    delete_tempfiles( $dir );  # start fresh

    # uri with overly large datamax
    # thisseek is 4-10 so datamax can't be larger than 9999
    my $uri = join( ';' =>
        qq'http://example.com?name=$name',
        qq'desc='.uri_escape($desc),
        qw(
            datamax=10_000
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

    eval {
        my $ds = FlatFile::DataStore->new({
            name => $name,
            dir  => $dir,
            uri  => $uri,
            });
    };

    like( $@, qr/datamax too large/, "init() datamax too large" );
}

#---------------------------------------------------------------------
{  # init(): 'Uninitialized attribute: $attr'

    delete_tempfiles( $dir );  # start fresh

    # uri without a user= parm
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
            thisfnum=1-10 thisseek=4-10
            prevfnum=1-10 prevseek=4-10
            nextfnum=1-10 nextseek=4-10
        )
    );

    eval {
        my $ds = FlatFile::DataStore->new({
            name => $name,
            dir  => $dir,
            uri  => $uri,
            });
    };

    like( $@, qr/Uninitialized attribute: user/,
              'init() Uninitialized attribute: $attr' );
}

#---------------------------------------------------------------------
{  # new() => init() => burst_query(): 'Parm duplicated in uri: $name'

    delete_tempfiles( $dir );  # start fresh

    # uri with duplicate datamax
    my $uri = join( ';' =>
        qq'http://example.com?name=$name',
        qq'desc='.uri_escape($desc),
        qw(
            datamax=9_000
            datamax=9_000
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

    eval {
        my $ds = FlatFile::DataStore->new({
            name => $name,
            dir  => $dir,
            uri  => $uri,
            });
    };

    like( $@, qr/Parm duplicated in uri: datamax/,
              'burst_query() Parm duplicated in uri: $name' );
}

#---------------------------------------------------------------------
{  # new() => init() => burst_query():
   #     "Value must be format 'length-parm: $name=$val'

    delete_tempfiles( $dir );  # start fresh

    # uri with invalid thisfnum
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
            thisfnum=dummy thisseek=4-10
            prevfnum=1-10 prevseek=4-10
            nextfnum=1-10 nextseek=4-10
            user=10-%20-%7E
        )
    );

    eval {
        my $ds = FlatFile::DataStore->new({
            name => $name,
            dir  => $dir,
            uri  => $uri,
            });
    };

    like( $@, qr/Value must be format 'length-parm': thisfnum=dummy/,
              q/burst_query() Value must be format 'length-parm': $name=$val/ );
}

#---------------------------------------------------------------------
{  # new() => init() => burst_query(): 'Unrecognized defaults: $want'

    delete_tempfiles( $dir );  # start fresh

    # uri with invalid defaults
    my $uri = join( ';' =>
        qq'http://example.com?name=$name',
        qq'desc='.uri_escape($desc),
        qw(
            recsep=%0A
            user=10-%20-%7E
            defaults=dummy
        )
    );

    eval {
        my $ds = FlatFile::DataStore->new({
            name => $name,
            dir  => $dir,
            uri  => $uri,
            });
    };

    like( $@, qr/Unrecognized defaults: dummy/,
              q/burst_query() Unrecognized defaults: $want/ );
}

#---------------------------------------------------------------------
{  # new() => init() => make_preamble_regx():
   #     'Invalid date length: $len'

    delete_tempfiles( $dir );  # start fresh

    # uri with invalid date
    my $uri = join( ';' =>
        qq'http://example.com?name=$name',
        qq'desc='.uri_escape($desc),
        qw(
            date=999-yyyymmdd

            datamax=9_000
            recsep=%0A
            indicator=1-%2B%23%3D%2A%2D
            transind=1-%2B%23%3D%2A%2D
            transnum=2-10
            keynum=2-10
            reclen=2-10
            thisfnum=1-10 thisseek=4-10
            prevfnum=1-10 prevseek=4-10
            nextfnum=1-10 nextseek=4-10
            user=10-%20-%7E
        )
    );

    eval {
        my $ds = FlatFile::DataStore->new({
            name => $name,
            dir  => $dir,
            uri  => $uri,
            });
    };

    like( $@, qr/Invalid date length: 999/,
              q/make_preamble_regx() Invalid date length: $len/ );
}

#---------------------------------------------------------------------
{  # new() => init() => make_preamble_regx():
   #     'Date length doesn't match format: $len-$parm'

    delete_tempfiles( $dir );  # start fresh

    # uri with invalid date (4 is okay, but not with yyyymmdd)
    my $uri = join( ';' =>
        qq'http://example.com?name=$name',
        qq'desc='.uri_escape($desc),
        qw(
            date=4-yyyymmdd

            datamax=9_000
            recsep=%0A
            indicator=1-%2B%23%3D%2A%2D
            transind=1-%2B%23%3D%2A%2D
            transnum=2-10
            keynum=2-10
            reclen=2-10
            thisfnum=1-10 thisseek=4-10
            prevfnum=1-10 prevseek=4-10
            nextfnum=1-10 nextseek=4-10
            user=10-%20-%7E
        )
    );

    eval {
        my $ds = FlatFile::DataStore->new({
            name => $name,
            dir  => $dir,
            uri  => $uri,
            });
    };

    like( $@, qr/Date length doesn't match format: 4-yyyymmdd/,
              q/make_preamble_regx() Date length doesn't match format: $len-$parm/ );
}

#---------------------------------------------------------------------
{  # new() => init() => make_crud():
   #     'Only single-character indicators supported'

    delete_tempfiles( $dir );  # start fresh

    # uri with invalid indicator length
    my $uri = join( ';' =>
        qq'http://example.com?name=$name',
        qq'desc='.uri_escape($desc),
        qw(
            datamax=9_000
            recsep=%0A
            indicator=999-%2B%23%3D%2A%2D
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

    eval {
        my $ds = FlatFile::DataStore->new({
            name => $name,
            dir  => $dir,
            uri  => $uri,
            });
    };

    like( $@, qr/Only single-character indicators supported/,
              q/make_crud() Only single-character indicators supported/ );
}

#---------------------------------------------------------------------
{  # new() => init() => make_crud():
   #     'Need five unique indicator characters'

    delete_tempfiles( $dir );  # start fresh

    # uri with invalid indicator values
    my $uri = join( ';' =>
        qq'http://example.com?name=$name',
        qq'desc='.uri_escape($desc),
        qw(
            datamax=9_000
            recsep=%0A
            indicator=1-abcdef
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

    eval {
        my $ds = FlatFile::DataStore->new({
            name => $name,
            dir  => $dir,
            uri  => $uri,
            });
    };

    like( $@, qr/Need five unique indicator characters/,
              q/make_crud() Need five unique indicator characters/ );
}

#---------------------------------------------------------------------
{  # new() => init() => initialize():
   #     'Can't initialize database (data files exist): $datafile'

    delete_tempfiles( $dir );  # start fresh

    # create dummy data file
    my $datafile = "$dir/$name.1.data";

    open my $fh, '>', $datafile or die "Can't open $datafile: $!";

    print $fh "dummy\n";  # we don't care what's in it

    close $fh or die "Problem closing $datafile: $!";

    eval {
        my $ds = FlatFile::DataStore->new({
            name => $name,
            dir  => $dir,
            uri  => $ok_uri,
            });
    };

    like( $@, qr/\QCan't initialize database (data files exist): $datafile/,
              q/initialize() Can't initialize database (data files exist): $datafile/ );

    unlink $datafile or die "Can't delete $datafile: $!";
}

#---------------------------------------------------------------------
{  # create(): 
   #     'Database exceeds configured size, keynum too long: $keynum'

    delete_tempfiles( $dir );  # start fresh

    # uri with absurdly small keynum limits
    my $uri = join( ';' =>
        qq'http://example.com?name=$name',
        qq'desc='.uri_escape($desc),
        qw(
            keynum=1-2

            indicator=1-%2B%23%3D%2A%2D
            transind=1-%2B%23%3D%2A%2D
            date=7-yymdttt
            transnum=1-10
            reclen=2-10
            thisfnum=1-10 thisseek=4-10
            prevfnum=1-10 prevseek=4-10
            nextfnum=1-10 nextseek=4-10
            user=10-%20-%7E
            recsep=%0A
        )
    );

    my $ds = FlatFile::DataStore->new({
        name => $name,
        dir  => $dir,
        uri  => $uri,
        });

    # should succeed
    $ds->create({ data => "This is a test" });  # keynum 0
    $ds->create({ data => "This is a test" });  # keynum 1

    # should fail
    eval {
        $ds->create({ data => "This is a test" });  # keynum 10
    };

    like( $@, qr/Database exceeds configured size, keynum too long: 10/,
              q/create() Database exceeds configured size, keynum too long: $keynum/ );
}

#---------------------------------------------------------------------
{  # retrieve(), retrieve_preamble(), locate_record_data():
   #     'Record doesn't exist: $keynum'

    delete_tempfiles( $dir );  # start fresh

    my $ds = FlatFile::DataStore->new({
        name => $name,
        dir  => $dir,
        uri  => $ok_uri,
        });

    eval {
        $ds->retrieve( 0 );
    };

    like( $@, qr/Record doesn't exist: 0/,
              q/retrieve() Record doesn't exist: $keynum/ );

    $ds->create({ data => "This is a test" });  # keynum 0
    $ds->create({ data => "This is a test" });  # keynum 1

    eval {
        $ds->retrieve( 2 );
    };

    like( $@, qr/Record doesn't exist: 2/,
              q/retrieve() Record doesn't exist: $keynum/ );

    eval {
        $ds->retrieve_preamble( 2 );
    };

    like( $@, qr/Record doesn't exist: 2/,
              q/retrieve_preamble() Record doesn't exist: $keynum/ );

    eval {
        $ds->locate_record_data( 2 );
    };

    like( $@, qr/Record doesn't exist: 2/,
              q/locate_record_data() Record doesn't exist: $keynum/ );
}

#---------------------------------------------------------------------
{  # update(), delete():
   #     'Must have at least a previous preamble for update/delete'
   #     'update/delete not allowed: $prevind'

    delete_tempfiles( $dir );  # start fresh

    my $ds = FlatFile::DataStore->new({
        name => $name,
        dir  => $dir,
        uri  => $ok_uri,
        });

    # data without a record or preamble object
    eval {
        $ds->update({ data => "This is a test" });
    };
    
    like( $@, qr/Must have at least a previous preamble for update/,
              q/update() Must have at least a previous preamble for update/ );

    eval {  # ditto
        $ds->delete({ data => "This is a test" });
    };
    
    like( $@, qr/Must have at least a previous preamble for delete/,
              q/delete() Must have at least a previous preamble for delete/ );

    my $rec = $ds->create({ data => "This is a test" });

    # save the location of that record
    my $fnum   = $rec->thisfnum;
    my $seek   = $rec->thisseek;

    # delete that record (which appends a new "delete record")
    $ds->delete( $rec );

    # now retrieve the original record by fnum and seek ...
    # because it was deleted, it's indicator (*) should make it
    # invalid to be updated or deleted -- which is what we're
    # after here

    $rec = $ds->retrieve( $fnum, $seek );

    # not allowed to update it or delete it again, because it's an
    # 'old' version (can only update or delete the 'current' one)
    eval {
        $rec = $ds->update({ data => "New data", record => $rec });
    };
    
    like( $@, qr/\Qupdate not allowed: */,
              q/update() update not allowed: $prevind/ );

    eval {
        $rec = $ds->delete({ data => "New data", record => $rec });
    };
    
    like( $@, qr/\Qdelete not allowed: */,
              q/update() delete not allowed: $prevind/ );
}

#---------------------------------------------------------------------
{  # normalize_parms() (via create(), update(), delete()): 
   #     'Bad call'
   #     'Parameter must be a hashref or a record object'
   #     'No record data'

    delete_tempfiles( $dir );  # start fresh

    my $ds = FlatFile::DataStore->new({
        name => $name,
        dir  => $dir,
        uri  => $ok_uri,
        });

    eval {
        $ds->create();  # no parm
    };

    like( $@, qr/Bad call/,
              q'normalize_parms()/create() Bad call' );

    eval {
        $ds->create( "This is a test" );  # bad parm
    };

    like( $@, qr/Parameter must be a hashref or a record object/,
              q'normalize_parms()/create() Parameter must be a hashref or a record object' );

    eval {
        $ds->create( {} );  # no record data
    };

    like( $@, qr/No record data/,
              q'normalize_parms()/create() No record data' );

    eval {
        $ds->update();  # no parm
    };

    like( $@, qr/Bad call/,
              q'normalize_parms()/update() Bad call' );

    eval {
        $ds->update( "This is a test" );  # bad parm
    };

    like( $@, qr/Parameter must be a hashref or a record object/,
              q'normalize_parms()/update() Parameter must be a hashref or a record object' );

    eval {
        $ds->update( {} );  # no record data
    };

    like( $@, qr/No record data/,
              q'normalize_parms()/update() No record data' );

    eval {
        $ds->delete();  # no parm
    };

    like( $@, qr/Bad call/,
              q'normalize_parms()/delete() Bad call' );

    eval {
        $ds->delete( "This is a test" );  # bad parm
    };

    like( $@, qr/Parameter must be a hashref or a record object/,
              q'normalize_parms()/delete() Parameter must be a hashref or a record object' );

    eval {
        $ds->delete( {} );  # no record data
    };

    like( $@, qr/No record data/,
              q'normalize_parms()/delete() No record data' );

}

#---------------------------------------------------------------------
{  # exists():
   #     'Need dir and name'

    delete_tempfiles( $dir );  # start fresh

    eval {
        FlatFile::DataStore->exists();  # no parm
    };

    like( $@, qr/Need dir and name/,
              q'exists() Need dir and name' );
}

#---------------------------------------------------------------------
{  # accessors ...
   # specs(): /Invalid omap:/
   # dir():   /Directory doesn't exist: $dir/

    delete_tempfiles( $dir );  # start fresh

    my $ds = FlatFile::DataStore->new();

    eval {
        $ds->specs( {} );  # invalid omap
    };

    like( $@, qr/Invalid omap:/,
              q'specs() Invalid omap:' );

    eval {
        $ds->dir( "$dir/3.14159" );  # dummy directory name
    };

    like( $@, qr/Directory doesn't exist:/,
              q/dir() Directory doesn't exist:/ );
}

#---------------------------------------------------------------------
{  # keyfile() via create():
   # (note: update() and delete() don't add lines to keyfiles, so
   #        they wouldn't generate this error)
   # /Database exceeds configured size, keyfnum too long: $keyfnum/

    delete_tempfiles( $dir );  # start fresh

    # uri with absurdly small keymax and fnum limits
    my $uri = join( ';' =>
        qq'http://example.com?name=$name',
        qq'desc='.uri_escape($desc),
        qw(
            keymax=2
            thisfnum=1-2 thisseek=4-10
            prevfnum=1-2 prevseek=4-10
            nextfnum=1-2 nextseek=4-10

            indicator=1-%2B%23%3D%2A%2D
            transind=1-%2B%23%3D%2A%2D
            date=7-yymdttt
            keynum=1-10
            transnum=1-10
            reclen=2-10
            user=10-%20-%7E
            recsep=%0A
        )
    );

    my $ds = FlatFile::DataStore->new({
        name => $name,
        dir  => $dir,
        uri  => $uri,
        });

    # should succeed
    $ds->create({ data => "This is a test" });  # example.1.key
    $ds->create({ data => "This is a test" });  # example.1.key

    # should fail (trying to write to example.10.key)
    eval {
        $ds->create({ data => "This is a test" });
    };

    like( $@, qr/Database exceeds configured size, keyfnum too long: 10/,
              q/keyfile() via create() Database exceeds configured size, keyfnum too long: $keyfnum/ );
}

#---------------------------------------------------------------------
{  # datafile() via create(), update(), delete():
   # /Record too long: $checksize > $datamax/
   # /Database exceeds configured size, fnum too long: $fnum/

    delete_tempfiles( $dir );  # start fresh

    # uri with absurdly small datamax and fnum limits
    my $uri = join( ';' =>
        qq'http://example.com?name=$name',
        qq'desc='.uri_escape($desc),
        qw(
            datamax=50
            thisfnum=1-2 thisseek=4-10
            prevfnum=1-2 prevseek=4-10
            nextfnum=1-2 nextseek=4-10

            indicator=1-%2B%23%3D%2A%2D
            transind=1-%2B%23%3D%2A%2D
            date=7-yymdttt
            keynum=1-10
            transnum=1-10
            reclen=2-10
            user=10-%20-%7E
            recsep=%0A
        )
    );

    my $ds = FlatFile::DataStore->new({
        name => $name,
        dir  => $dir,
        uri  => $uri,
        });

    eval {
        $ds->create({ data => "This is a test" });
    };

    like( $@, qr/Record too long:/,
              q/datafile() via create() Record too long:/ );

    # should succeed
    my $rec = $ds->create({ data => "testing" });  # example.1.data

    eval {
        $ds->update({ record => $rec, data => "This is a test" });
    };

    like( $@, qr/Record too long:/,
              q/datafile() via update() Record too long:/ );

    eval {
        $ds->delete({ record => $rec, data => "This is a test" });
    };

    like( $@, qr/Record too long:/,
              q/datafile() via delete() Record too long:/ );

    # should fail (trying to write to example.10.data)
    eval {
        $ds->create({ data => "testing" });
    };

    like( $@, qr/Database exceeds configured size, fnum too long: 10/,
              q/datafile() via create() Database exceeds configured size, fnum too long: $fnum/ );

    eval {  # ditto
        $ds->update({ record => $rec });
    };

    like( $@, qr/Database exceeds configured size, fnum too long: 10/,
              q/datafile() via update() Database exceeds configured size, fnum too long: $fnum/ );

    eval {  # ditto
        $ds->delete({ record => $rec });
    };

    like( $@, qr/Database exceeds configured size, fnum too long: 10/,
              q/datafile() via delete() Database exceeds configured size, fnum too long: $fnum/ );
}

#---------------------------------------------------------------------
{  # nexttransnum() via create(), update(), delete():
   # /Database exceeds configured size, transnum too long: $transnum/

    delete_tempfiles( $dir );  # start fresh

    # uri with absurdly small transnum limit
    my $uri = join( ';' =>
        qq'http://example.com?name=$name',
        qq'desc='.uri_escape($desc),
        qw(
            transnum=1-2

            indicator=1-%2B%23%3D%2A%2D
            transind=1-%2B%23%3D%2A%2D
            date=7-yymdttt
            keynum=1-10
            thisfnum=1-10 thisseek=4-10
            prevfnum=1-10 prevseek=4-10
            nextfnum=1-10 nextseek=4-10
            reclen=2-10
            user=10-%20-%7E
            recsep=%0A
        )
    );

    my $ds = FlatFile::DataStore->new({
        name => $name,
        dir  => $dir,
        uri  => $uri,
        });

    # should succeed (note, transaction numbers start at 1)
    my $rec = $ds->create({ data => "This is a test" });  # transaction 1

    # should fail (trying to use transaction 10)
    eval {
        $ds->create({ data => "This is a test" });
    };

    like( $@, qr/Database exceeds configured size, transnum too long:/,
              q/nexttransnum() via create() Database exceeds configured size, transnum too long: $transnum/ );

    eval {  # ditto
        $ds->update( $rec );
    };

    like( $@, qr/Database exceeds configured size, transnum too long:/,
              q/nexttransnum() via update() Database exceeds configured size, transnum too long: $transnum/ );

    eval {  # ditto
        $ds->delete( $rec );
    };

    like( $@, qr/Database exceeds configured size, transnum too long:/,
              q/nexttransnum() via delete() Database exceeds configured size, transnum too long: $transnum/ );
}

#---------------------------------------------------------------------
{  # burst_preamble():
   # /Something is wrong with preamble: $string/

    delete_tempfiles( $dir );  # start fresh

    my $ds = FlatFile::DataStore->new({
        name => $name,
        dir  => $dir,
        uri  => $ok_uri,
        });

    my $rec = $ds->create({ data => "This is a test" });
    my $preamble_string = $rec->preamble_string();

    # invalidate the string
    chop $preamble_string;

    eval {
        $ds->burst_preamble( $preamble_string );
    };

    like( $@, qr/Something is wrong with preamble:/,
              q/burst_preamble() Something is wrong with preamble: $string/ );

}

#---------------------------------------------------------------------
{  # update_preamble():
   #     /Unrecognized field: $_/
   #     /Invalid value for $_: $try/
   #     /Value of $_ too long: $try/
   #     /Something is wrong with preamble: $string/

    delete_tempfiles( $dir );  # start fresh

    # uri with values we want to test here
    my $uri = join( ';' =>
        qq'http://example.com?name=$name',
        qq'desc='.uri_escape($desc),
        qw(
            indicator=1-%2B%23%3D%2A%2D
            transind=1-%2B%23%3D%2A%2D
            date=4-yymd
            keynum=1-10
            transnum=1-10
            reclen=2-10
            thisfnum=1-10 thisseek=4-10
            prevfnum=1-10 prevseek=4-10
            nextfnum=1-10 nextseek=4-10
            user=4-%20-%7E
            recsep=%0A
        )
    );

    my $ds = FlatFile::DataStore->new({
        name => $name,
        dir  => $dir,
        uri  => $uri,
        });

    my $rec = $ds->create({ data => "This is a test" });
    my $preamble_string = $rec->preamble_string();

    # recsep isn't in the preamble
    eval {
        $ds->update_preamble( $preamble_string, { recsep => 'dummy' } );
    };

    like( $@, qr/Unrecognized field: recsep/,
              q/update_preamble() Unrecognized field: recsep/ );

    my $non_printable = chr( 0x1F );

    for( qw( indicator transind date user ) ) {
        eval {
            $ds->update_preamble( $preamble_string, { $_ => $non_printable } );
        };

        like( $@, qr/Invalid value for $_:/,
                  qq/update_preamble() Invalid value for $_:/ );
    }

    # these values are all too long ...
    for( { indicator => 'dummy' },
         { transind  => 'dummy' },
         { date      => 'dummy' },
         { user      => 'dummy' },
         { transnum  => 10      },
         { keynum    => 10      },
         { reclen    => 100     },
         { thisfnum  => 10      },
         { thisseek  => 10000   },
         { prevfnum  => 10      },
         { prevseek  => 10000   },
         { nextfnum  => 10      },
         { nextseek  => 10000   },
    ) {
        my( $this ) = keys %$_;
        eval {
            $ds->update_preamble( $preamble_string,  $_ );
        };

        like( $@, qr/Value of $this too long:/,
                  qq/update_preamble() Value of $this too long/ );
    }

    # invalidate the string
    chop $preamble_string;

    eval {
        $ds->update_preamble( $preamble_string );
    };

    like( $@, qr/Something is wrong with preamble:/,
              q/update_preamble() Something is wrong with preamble: $string/ );
}

__END__

