use lib qw|./lib ./blib/lib|;
use strict;
use warnings;
use Haineko;
use Test::More;
use Haineko::JSON;
use IO::Socket::INET;
use Time::Piece;

my $servername = '127.0.0.1';
my $serverport = 2794;

my $nekosocket = undef;
my $htrequests = [];
my $emailfiles = [
    'tmp/make-author-test-1.json',
    'tmp/make-author-test-2.json',
    'tmp/make-author-test-3.json',
];
my $methodargv = { 
    'PeerAddr' => $servername, 
    'PeerPort' => $serverport, 
    'proto'    => 'tcp',
};

my $n = 0;
my $p = undef;

for my $e ( @$emailfiles ) {
    $n++;
    $p = sprintf( "[%02d] ", $n );
    $e = '../../'.$e unless -f $e;

    next unless -f $e;
    ok( -r $e, $p.'-r '.$e );
    ok( -s $e, $p.'-s '.$e );

    my $t = Time::Piece->new;
    my $c = 0;
    my $x = undef;
    my $y = undef;

    $x= Haineko::JSON->loadfile( $e );
    isa_ok( $x, 'HASH' );
    isa_ok( $x->{'rcpt'}, 'ARRAY' );
    isa_ok( $x->{'header'}, 'HASH' );

    $x->{'header'}->{'subject'} = sprintf( 
        "MAKE TEST: [%s %s] %s", $t->ymd, $t->hms, $x->{'header'}->{'subject'} );
    $y = Haineko::JSON->dumpjson( $x );
    ok( length $y, $p.'Haineko::JSON->dumpjson' );

    $htrequests = [];
    push @$htrequests, sprintf( "POST /submit HTTP/1.0\n" );
    push @$htrequests, sprintf( "Host: 127.0.0.1\n" );
    push @$htrequests, sprintf( "Content-Type: application/json\n" );
    push @$htrequests, sprintf( "Content-Length: %d\n\n", length $y );
    push @$htrequests, sprintf( "%s\n\n", $y );

    $nekosocket = IO::Socket::INET->new( %$methodargv );
    select $nekosocket; $| = 1;
    select STDOUT;
    isa_ok( $nekosocket, 'IO::Socket::INET' );

    ok( $nekosocket->print( join( '', @$htrequests ) ), $p.$e.' => /submit' );
    like( $nekosocket->getline, qr|\AHTTP/1.0 200 OK|, $p.'200 OK' );

    while( my $r = $nekosocket->getline ) {
        $r =~ s/\r\n//g; chomp $r;

        if( length $r == 0 && $c == 0 ) {
            $c = 1;
            next;

        } else {
            ok( length $r );
            # {
            #   "remoteport": 63216,
            #   "addresser": "localpart@example.jp",
            #   "remoteaddr": "127.0.0.1",
            #   "queueid": "r92DiQB039703GHu",
            #   "response": [
            #     {
            #       "code": 200,
            #       "host": "sendgrid.com",
            #       "port": 443,
            #       "rcpt": "recipient address"
            #       "command": "POST",
            #       "message": [
            #         "OK"
            #       ],
            #       "error": 0,
            #       "dsn": "2.0.0",
            #       "mailer": "SendGrid"
            #     },
            #   ],
            #   "useragent": null,
            #   "timestamp": {
            #     "datetime": "Wed Oct  2 13:44:26 2013",
            #     "unixtime": "1380689066"
            #   },
            #   "referer": null,
            #   "recipient": [
            #     "localpart@example.org"
            #   ]
            # }
            if( $c == 1 ) {
                # Content, Load as a JSON
                my $j = undef;
                my $s = undef;
                my $k = undef;

                $j = Haineko::JSON->loadjson( $r );
                isa_ok( $j, 'HASH' );

                ok( $j->{'queueid'}, $p.'queueid = '.$j->{'queueid'} );
                is( $j->{'referer'}, undef, $p.'referer = undef' );
                is( $j->{'useragent'}, undef, $p.'useragent = undef' );
                is( $j->{'addresser'}, $x->{'mail'}, $p.'addresser = '.$x->{'mail'} );
                is( $j->{'remoteaddr'}, '127.0.0.1', $p.'remoteaddr = 127.0.0.1' );
                ok( $j->{'remoteport'}, $p.'remoteport = '.$j->{'remoteport'} );

                $k = 'response';
                $s = $j->{ $k };
                isa_ok( $s, 'ARRAY' );
                for my $e ( @$s ) {
                    isa_ok( $e->{'message'}, 'ARRAY' );
                    like( $e->{'dsn'}, qr/\A2[.]\d[.]\d/, $p.sprintf( "%s->dsn = %s", $k, $e->{'dsn'} ) );
                    ok( $e->{'code'}, $p.sprintf( "%s->code = %d", $k, $e->{'code'} ) );
                    ok( $e->{'host'}, $p.sprintf( "%s->host = %s", $k, $e->{'host'} ) );
                    is( $e->{'error'}, 0, $p.sprintf( "%s->error = %d", $k, 0 ) );
                    ok( $e->{'mailer'}, $p.sprintf( "%s->mailer = %s", $k, ( $e->{'mailer'} || undef ) ) );
                    ok( $e->{'command'}, $p.sprintf( "%s->command = %s", $k, $e->{'command'} ) );
                    ok( $e->{'message'}->[0], $p.sprintf( "%s->message->[0] = %s", $k, $e->{'message'}->[0] ) );
                }

                $k = 'timestamp';
                $s = $j->{ $k };
                isa_ok( $s, 'HASH' );
                ok( $s->{'datetime'}, $p.sprintf( "%s->datetime = %s", $k, $s->{'datetime'} ) );
                ok( $s->{'unixtime'}, $p.sprintf( "%s->unixtime = %d", $k, $s->{'unixtime'} ) );
                
                $k = 'recipient';
                $s = $j->{ $k };
                isa_ok( $s, 'ARRAY' );
                for my $w ( @$s ) {
                    ok( $w, $p.sprintf( "%s = %s", $k, $w ) );
                }

            } else {
                # Header
                like( $r, qr/:/, $p.'HTTP-HEADER => '.$r );
            }
        }
    }

    $nekosocket->close();
}

ok(1);
done_testing();
__END__
