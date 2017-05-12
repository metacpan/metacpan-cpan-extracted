use lib qw|./lib ./blib/lib|;
use strict;
use warnings;
use Haineko;
use Test::More;
use IO::Socket::INET;

my $servername = '127.0.0.1';
my $serverport = 2794;

my $nekosocket = undef;
my $htrequests = [];
my $methodargv = { 
    'PeerAddr' => $servername, 
    'PeerPort' => $serverport, 
    'proto'    => 'tcp',
};

if( -f 'tmp/make-author-test-1.json' ) {
    for my $e ( '/', '/neko', '/dump' ) {

        $nekosocket = IO::Socket::INET->new( %$methodargv );
        select $nekosocket; $| = 1;
        select STDOUT;
        isa_ok( $nekosocket, 'IO::Socket::INET' );

        $htrequests = [ sprintf( "GET %s HTTP/1.0\n\n", $e ) ];
        ok( $nekosocket->print( join( "\n", @$htrequests ) ), $e );
        like( $nekosocket->getline, qr|\AHTTP/1.0 200 OK|, '200 OK' );

        my $c = 0;
        while( my $r = $nekosocket->getline ) {
            $r =~ s/\r\n//;
            chomp $r;

            if( length $r == 0 && $c == 0 ) {
                $c = 1;
                next;
            }

            if( $c ) {
                # Content
                ok( length $r );

            } else {
                # Header
                like( $r, qr/:/, 'HTTP-HEADER => '.$r );
            }
        }
        $nekosocket->close();
    }

} else {
    ok(1);
}
done_testing();
__END__
