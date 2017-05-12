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

my $ds = FlatFile::DataStore->new({
    name => $name,
    dir  => $dir,
    uri  => $ok_uri,
    });

#---------------------------------------------------------------------
{  # new()/init():
   #     /Missing: datastore/
   #     /Missing: indicator/
   #     /Missing: transind/
   #     /Missing: $_/
   #     /Invalid value, $value, for: $_/
   #     /Value, $try, too long for: $_/
   #     /For indicator, $indicator, you may not set: $_/;
   #     /Something is wrong with preamble: $string/

    # datastore ...

    eval {
        my $preamble = FlatFile::DataStore::Preamble->new({ dummy => 1 });
    };
    like( $@, qr/Missing: datastore/, "new() Missing: datastore" );

    # Note: because of how the new() is organized, we'll get a 'missing'
    # error for indicator and transind first, regardless of where they
    # appear in the preamble.
    #
    # Otherwise, these test are arranged in preamble order based on the
    # uri specs.

    # indicator and transind ...

    eval {
        my $preamble = FlatFile::DataStore::Preamble->new({
            datastore => $ds,
            });
    };
    like( $@, qr/Missing: indicator/, "new() Missing: indicator" );

    eval {
        my $preamble = FlatFile::DataStore::Preamble->new({
            datastore => $ds,
            indicator => '#',
            });
    };
    like( $@, qr/Missing: transind/, "new() Missing: transind" );

    eval {
        my $preamble = FlatFile::DataStore::Preamble->new({
            datastore => $ds,
            indicator => '##',  # too long
            transind  => '=',   # need this to skip 'missing' error
            });
    };
    like( $@, qr/Invalid value, ##, for: indicator/,
              q/new() Invalid value, $value, for: indicator (too long)/ );

    eval {
        my $preamble = FlatFile::DataStore::Preamble->new({
            datastore => $ds,
            indicator => '!',
            transind  => '=',  # need this to skip 'missing' error
            });
    };
    like( $@, qr/Invalid value, !, for: indicator/,
              q/new() Invalid value, $value, for: indicator (bad char)/ );

    eval {
        my $preamble = FlatFile::DataStore::Preamble->new({
            datastore => $ds,
            indicator => '#',
            transind  => '##',  # too long
            });
    };
    like( $@, qr/Invalid value, ##, for: transind/,
              q/new() Invalid value, $value, for: transind (too long)/ );

    eval {
        my $preamble = FlatFile::DataStore::Preamble->new({
            datastore => $ds,
            indicator => '#',
            transind  => '!',
            });
    };
    like( $@, qr/Invalid value, !, for: transind/,
              q/new() Invalid value, $value, for: transind (bad char)/ );

    # date ...

    eval {
        my $preamble = FlatFile::DataStore::Preamble->new({
            datastore => $ds,
            indicator => '+',
            transind  => '+',
            });
    };
    like( $@, qr/Missing: date/, "new() Missing: date" );

    eval {
        my $preamble = FlatFile::DataStore::Preamble->new({
            datastore => $ds,
            indicator => '+',
            transind  => '+',
            date      => '2011-01-12',
            });
    };
    like( $@, qr/Invalid value, 2011-01-12, for: date/,
              q/new() Invalid value, $value, for: date/ );

    # transnum ...

    eval {
        my $preamble = FlatFile::DataStore::Preamble->new({
            datastore => $ds,
            indicator => '+',
            transind  => '+',
            date      => '20110112',
            });
    };
    like( $@, qr/Missing: transnum/, "new() Missing: transnum" );

    eval {
        my $preamble = FlatFile::DataStore::Preamble->new({
            datastore => $ds,
            indicator => '#',
            transind  => '=',
            date      => '20110112',
            transnum  => 100,  # too long
            });
    };
    like( $@, qr/Value, 100, too long for: transnum/,
              q/new() Value, $try, too long for: transnum/ );

    # keynum ...

    eval {
        my $preamble = FlatFile::DataStore::Preamble->new({
            datastore => $ds,
            indicator => '+',
            transind  => '+',
            date      => '20110112',
            transnum  => 1,
            });
    };
    like( $@, qr/Missing: keynum/, "new() Missing: keynum" );

    eval {
        my $preamble = FlatFile::DataStore::Preamble->new({
            datastore => $ds,
            indicator => '#',
            transind  => '=',
            date      => '20110112',
            transnum  => 1,
            keynum    => 100,  # too long
            });
    };
    like( $@, qr/Value, 100, too long for: keynum/,
              q/new() Value, $try, too long for: keynum/ );

    # reclen ...

    eval {
        my $preamble = FlatFile::DataStore::Preamble->new({
            datastore => $ds,
            indicator => '+',
            transind  => '+',
            date      => '20110112',
            transnum  => 1,
            keynum    => 0,
            });
    };
    like( $@, qr/Missing: reclen/, "new() Missing: reclen" );

    eval {
        my $preamble = FlatFile::DataStore::Preamble->new({
            datastore => $ds,
            indicator => '#',
            transind  => '=',
            date      => '20110112',
            transnum  => 1,
            keynum    => 0,
            reclen    => 100,  # too long
            });
    };
    like( $@, qr/Value, 100, too long for: reclen/,
              q/new() Value, $try, too long for: reclen/ );

    # thisfnum ...

    eval {
        my $preamble = FlatFile::DataStore::Preamble->new({
            datastore => $ds,
            indicator => '+',
            transind  => '+',
            date      => '20110112',
            transnum  => 1,
            keynum    => 0,
            reclen    => 42,
            });
    };
    like( $@, qr/Missing: thisfnum/, "new() Missing: thisfnum" );

    eval {
        my $preamble = FlatFile::DataStore::Preamble->new({
            datastore => $ds,
            indicator => '#',
            transind  => '=',
            date      => '20110112',
            transnum  => 1,
            keynum    => 0,
            reclen    => 42,
            thisfnum  => 10,  # too long
            });
    };
    like( $@, qr/Value, 10, too long for: thisfnum/,
              q/new() Value, $try, too long for: thisfnum/ );

    # thisseek ...

    eval {
        my $preamble = FlatFile::DataStore::Preamble->new({
            datastore => $ds,
            indicator => '+',
            transind  => '+',
            date      => '20110112',
            transnum  => 1,
            keynum    => 0,
            reclen    => 42,
            thisfnum  => 1,
            });
    };
    like( $@, qr/Missing: thisseek/, "new() Missing: thisseek" );

    eval {
        my $preamble = FlatFile::DataStore::Preamble->new({
            datastore => $ds,
            indicator => '#',
            transind  => '=',
            date      => '20110112',
            transnum  => 1,
            keynum    => 0,
            reclen    => 42,
            thisfnum  => 1,
            thisseek  => 10000,  # too long
            });
    };
    like( $@, qr/Value, 10000, too long for: thisseek/,
              q/new() Value, $try, too long for: thisseek/ );

    # prevfnum ...

    eval {
        my $preamble = FlatFile::DataStore::Preamble->new({
            datastore => $ds,
            indicator => '=',
            transind  => '=',
            date      => '20110112',
            transnum  => 1,
            keynum    => 0,
            reclen    => 42,
            thisfnum  => 1,
            thisseek  => 42,
            });
    };
    like( $@, qr/Missing: prevfnum/, "new() Missing: prevfnum" );

    eval {
        my $preamble = FlatFile::DataStore::Preamble->new({
            datastore => $ds,
            indicator => '+',
            transind  => '+',
            date      => '20110112',
            transnum  => 1,
            keynum    => 0,
            reclen    => 42,
            thisfnum  => 1,
            thisseek  => 42,
            prevfnum  => 1,
            });
    };
    like( $@, qr/For indicator, \+, you may not set: prevfnum/,
              q/new() For indicator, $indicator, you may not set: prevfnum/ );

    eval {
        my $preamble = FlatFile::DataStore::Preamble->new({
            datastore => $ds,
            indicator => '#',
            transind  => '=',
            date      => '20110112',
            transnum  => 1,
            keynum    => 0,
            reclen    => 42,
            thisfnum  => 1,
            thisseek  => 42,
            prevfnum  => 10,  # too long
            });
    };
    like( $@, qr/Value, 10, too long for: prevfnum/,
              q/new() Value, $try, too long for: prevfnum/ );

    # prevseek ...

    eval {
        my $preamble = FlatFile::DataStore::Preamble->new({
            datastore => $ds,
            indicator => '=',
            transind  => '=',
            date      => '20110112',
            transnum  => 1,
            keynum    => 0,
            reclen    => 42,
            thisfnum  => 1,
            thisseek  => 42,
            prevfnum  => 1,
            });
    };
    like( $@, qr/Missing: prevseek/, "new() Missing: prevseek" );

    eval {
        my $preamble = FlatFile::DataStore::Preamble->new({
            datastore => $ds,
            indicator => '+',
            transind  => '+',
            date      => '20110112',
            transnum  => 1,
            keynum    => 0,
            reclen    => 42,
            thisfnum  => 1,
            thisseek  => 42,
            # prevfnum  => 1,
            prevseek  => 0,
            });
    };
    like( $@, qr/For indicator, \+, you may not set: prevseek/,
              q/new() For indicator, $indicator, you may not set: prevseek/ );

    eval {
        my $preamble = FlatFile::DataStore::Preamble->new({
            datastore => $ds,
            indicator => '#',
            transind  => '=',
            date      => '20110112',
            transnum  => 1,
            keynum    => 0,
            reclen    => 42,
            thisfnum  => 1,
            thisseek  => 42,
            prevfnum  => 1,
            prevseek  => 10000,  # too long
            });
    };
    like( $@, qr/Value, 10000, too long for: prevseek/,
              q/new() Value, $try, too long for: prevseek/ );

    # nextfnum ...

    eval {
        my $preamble = FlatFile::DataStore::Preamble->new({
            datastore => $ds,
            indicator => '#',
            transind  => '=',
            date      => '20110112',
            transnum  => 1,
            keynum    => 0,
            reclen    => 42,
            thisfnum  => 1,
            thisseek  => 42,
            prevfnum  => 1,
            prevseek  => 0,
            });
    };
    like( $@, qr/Missing: nextfnum/, "new() Missing: nextfnum" );

    eval {
        my $preamble = FlatFile::DataStore::Preamble->new({
            datastore => $ds,
            indicator => '=',
            transind  => '=',
            date      => '20110112',
            transnum  => 1,
            keynum    => 0,
            reclen    => 42,
            thisfnum  => 1,
            thisseek  => 42,
            prevfnum  => 1,
            prevseek  => 0,
            nextfnum  => 1,
            });
    };
    like( $@, qr/For indicator, =, you may not set: nextfnum/,
              q/new() For indicator, $indicator, you may not set: nextfnum/ );

    eval {
        my $preamble = FlatFile::DataStore::Preamble->new({
            datastore => $ds,
            indicator => '#',
            transind  => '=',
            date      => '20110112',
            transnum  => 1,
            keynum    => 0,
            reclen    => 42,
            thisfnum  => 1,
            thisseek  => 42,
            prevfnum  => 1,
            prevseek  => 0,
            nextfnum  => 10,  # too long
            });
    };
    like( $@, qr/Value, 10, too long for: nextfnum/,
              q/new() Value, $try, too long for: nextfnum/ );

    # nextseek ...

    eval {
        my $preamble = FlatFile::DataStore::Preamble->new({
            datastore => $ds,
            indicator => '#',
            transind  => '=',
            date      => '20110112',
            transnum  => 1,
            keynum    => 0,
            reclen    => 42,
            thisfnum  => 1,
            thisseek  => 42,
            prevfnum  => 1,
            prevseek  => 0,
            nextfnum  => 1,
            });
    };
    like( $@, qr/Missing: nextseek/, "new() Missing: nextseek" );

    eval {
        my $preamble = FlatFile::DataStore::Preamble->new({
            datastore => $ds,
            indicator => '=',
            transind  => '=',
            date      => '20110112',
            transnum  => 1,
            keynum    => 0,
            reclen    => 42,
            thisfnum  => 1,
            thisseek  => 42,
            prevfnum  => 1,
            prevseek  => 0,
            # nextfnum  => 1,
            nextseek  => 84,
            });
    };
    like( $@, qr/For indicator, =, you may not set: nextseek/,
              q/new() For indicator, $indicator, you may not set: nextseek/ );

    eval {
        my $preamble = FlatFile::DataStore::Preamble->new({
            datastore => $ds,
            indicator => '#',
            transind  => '=',
            date      => '20110112',
            transnum  => 1,
            keynum    => 0,
            reclen    => 42,
            thisfnum  => 1,
            thisseek  => 42,
            prevfnum  => 1,
            prevseek  => 0,
            nextfnum  => 1,
            nextseek  => 10000,  # too long
            });
    };
    like( $@, qr/Value, 10000, too long for: nextseek/,
              q/new() Value, $try, too long for: nextseek/ );

    # user ...

    $ds->userdata( undef );  # finagle a 'missing user' error

    eval {
        my $preamble = FlatFile::DataStore::Preamble->new({
            datastore => $ds,
            indicator => '#',
            transind  => '=',
            date      => '20110112',
            transnum  => 1,
            keynum    => 0,
            reclen    => 42,
            thisfnum  => 1,
            thisseek  => 42,
            prevfnum  => 1,
            prevseek  => 0,
            nextfnum  => 1,
            nextseek  => 84,
            });
    };
    like( $@, qr/Missing: user/, "new() Missing: user" );

    eval {
        my $preamble = FlatFile::DataStore::Preamble->new({
            datastore => $ds,
            indicator => '#',
            transind  => '=',
            date      => '20110112',
            transnum  => 1,
            keynum    => 0,
            reclen    => 42,
            thisfnum  => 1,
            thisseek  => 42,
            prevfnum  => 1,
            prevseek  => 0,
            nextfnum  => 1,
            nextseek  => 84,
            user      => 'Hello, World',  # too long
            });
    };
    like( $@, qr/Value, Hello, World, too long for: user/,
              q/new() Value, $value, too long for: user/ );

    eval {
        my $preamble = FlatFile::DataStore::Preamble->new({
            datastore => $ds,
            indicator => '#',
            transind  => '=',
            date      => '20110112',
            transnum  => 1,
            keynum    => 0,
            reclen    => 42,
            thisfnum  => 1,
            thisseek  => 42,
            prevfnum  => 1,
            prevseek  => 0,
            nextfnum  => 1,
            nextseek  => 84,
            user      => 'Hey'.chr( 0x1F ),  # unprintable
            });
    };
    like( $@, qr/Invalid value, Hey., for: user/,
              q/new() Invalid value, $value, for: user/ );

    eval {
        my $preamble = FlatFile::DataStore::Preamble->new({
            datastore => $ds,
            indicator => '#',
            transind  => '=',
            date      => 'XXXXXXXX',  # gets by date validation (for now ...)
            transnum  => 1,
            keynum    => 0,
            reclen    => 42,
            thisfnum  => 1,
            thisseek  => 42,
            prevfnum  => 1,
            prevseek  => 0,
            nextfnum  => 1,
            nextseek  => 84,
            user      => 'Hey.',
            });
    };
    like( $@, qr/Something is wrong with preamble:/,
              q/new() Something is wrong with preamble: $string/ );

}

__END__
 
