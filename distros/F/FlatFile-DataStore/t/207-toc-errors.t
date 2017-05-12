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
BEGIN {
    use_ok('FlatFile::DataStore');
};

my $name   = "example";
my $desc   = "Example FlatFile::DataStore";
# absurdly low tocmax
my $ok_uri = join( ';' =>
    qq'http://example.com?name=$name',
    qq'desc='.uri_escape($desc),
    qw(
        tocmax=1
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

my $ds = FlatFile::DataStore->new({
    name => $name,
    dir  => $dir,
    uri  => $ok_uri,
    });

#---------------------------------------------------------------------
{  # new():
   #     /Missing: datastore/
   #     /Missing parms: int or num/
   #     /Database exceeds configured size, tocfnum too long: $tocfnum/

    eval {
        my $toc =  FlatFile::DataStore::Toc->new({
            dummy => 1,
            });
    };
    like( $@, qr/Missing: datastore/, "new() Missing: datastore" );

    eval {
        my $toc =  FlatFile::DataStore::Toc->new({
            datastore => $ds,
            });
    };
    like( $@, qr/Missing: int or num/, "new() Missing: int or num" );

    # Note: the int and num parms denote the number of the datafile
    # that we want the toc entry for.  And when there's a tocmax,
    # we use it to determine which toc file the entry is in.  In the
    # process, we add 1 to the int or num, because toc file numbers
    # start with 1 (not 0).  If there isn't a tocmax, we'll never get
    # this error, because we don't calculate a tocfnum (we don't use
    # one).

    eval {
        my $toc =  FlatFile::DataStore::Toc->new({
            datastore => $ds,
            int       => 9,  # 9 + 1 = 10, which is too long
            });
    };
    like( $@, qr/Database exceeds configured size, tocfnum too long: 10/,
              q/Database exceeds configured size, tocfnum too long: $tocfnum/ );

    eval {
        my $toc =  FlatFile::DataStore::Toc->new({
            datastore => $ds,
            num       => 9,  # 9 + 1 = 10, which is too long
            });
    };
    like( $@, qr/Database exceeds configured size, tocfnum too long: 10/,
              q/Database exceeds configured size, tocfnum too long: $tocfnum/ );

}

__END__

