#!perl
# this test can get confusing, so here's some explanation just in case
# we're testing the HTTP check using an internal HTTPD test (AnyEvent::HTTPD)
# we're checking two hosts (one localhost, one 127.0.0.1)
# each host will get a two requests
# the HTTPD should return success for the first, for each host
# and then a failure for the second, for each host
# this means that we'll see success on localhost and on 127.0.0.1
# then we'll see a failure on localhost and on 127.0.0.1
# the before() and result() callbacks are called on all of those

use strict;
use warnings;

use Test::More;

use AnyEvent;
use Juno::Check::HTTP;

{
    local $@ = undef;
    eval 'use Test::TCP';
    $@ and plan skip_all => 'Test::TCP is required for this test';
}

{
    local $@ = undef;
    eval 'use AnyEvent::HTTPD';
    $@ and plan skip_all => 'AnyEvent::HTTPD is required for this test';
}

plan tests => 29;

my $requests = 0;
my $goodbody = '<html><head><body>OK</body></head></html>';
my $badbody  = 'Fail';
my $port     = Test::TCP::empty_port();
my $httpd    = AnyEvent::HTTPD->new( port => $port );
$httpd->reg_cb (
    '/' => sub {
        my ( $httpd, $req ) = @_;

        # if we're on the 3rd request, let's fail it
        # this is after two successful ones that call:
        # before, result, success
        if ( ++$requests >= 3 ) {
            $req->respond(
                [ 400, 'failed', { 'Content-Type' => 'text/html' }, $badbody ]
            );

            # stop here
            return;
        }

        $req->respond( {
            content => [
                'text/html',
                $goodbody,
            ],
        } );
   },
);

my %match = ();

sub result_check {
    my ( $type, $check, $host, $got_body, $headers ) = @_;

    my $exp_body = $goodbody;
    my %results  = (
          'cache-control' => 'max-age=0',
          'connection'    => 'Keep-Alive',
          'content-type'  => 'text/html',
          'HTTPVersion'   => '1.0',
    );

    if ( $type eq 'fail' ) {
        $exp_body = $badbody;
        %results = (
            %results,
            'content-length' => 4,
            'Reason'         => 'failed',
            'Status'         => 400,
            'URL'            => "http://$host/",
        ),
    } else {
        %results = (
            %results,
            'content-length' => 41,
            'Reason'         => 'ok',
            'Status'         => 200,
            'URL'            => "http://$host/",
        ),
    }

    isa_ok( $check, 'Juno::Check::HTTP' );
    is( $got_body, $exp_body, 'Got body' );

    # possibly remove dates from headers because it can't be static
    delete $headers->{'date'};
    delete $headers->{'expires'};

    is_deeply( $headers, \%results, 'Got correct headers' );
};

my $cv    = AnyEvent->condvar;
my $check = Juno::Check::HTTP->new(
    interval => 0.1,
    hosts    => [ "localhost:$port", "127.0.0.1:$port" ],
    headers  => { 'Num' => 30, 'String' => 'hello' },

    # called twice for each host = x4
    # for good or bad
    on_before => sub {
        my ( $checker, $host ) = @_;
        isa_ok( $checker, 'Juno::Check::HTTP' );
        $match{'before'}{$host}++;
        $cv->end;
    },

    # called once for each host = x2
    on_success => sub {
        my ( $checker, $host ) = @_;
        $match{'success'}{$host}++;
        result_check( 'success', @_ );
        $cv->end;
    },

    # called twice for each host = x4
    # for good or bad
    on_result => sub {
        my ( $checker, $host ) = @_;
        $match{'result'}{$host}++;
        if ( $requests >= 3 ) {
            result_check( 'fail', @_ );
        } else {
            result_check( 'success', @_ );
        }

        $cv->end;
    },

    # called once for each host = x2
    on_fail => sub {
        my ( $checker, $host ) = @_;
        $match{'fail'}{$host}++;
        result_check( 'fail', @_ );
        $cv->end;
    },
);

# Before, Success, Result, Fail, twice each
# that's 8 callbacks that should run
$cv->begin for 1 .. ( 4 + 2 + 4 + 2 );

# start check
$check->run;

# wait for everything to resolve
$cv->recv;

# stop juno, just in case
$check->clear_watcher();

is_deeply(
    \%match,
    {
        before => {
            "127.0.0.1:$port" => 2,
            "localhost:$port" => 2,
        },

        success => {
            "127.0.0.1:$port" => 1,
            "localhost:$port" => 1,
        },

        result => {
            "127.0.0.1:$port" => 2,
            "localhost:$port" => 2,
        },

        fail => {
            "127.0.0.1:$port" => 1,
            "localhost:$port" => 1,
        },
    },
    'All callbacks called successfully',
);

