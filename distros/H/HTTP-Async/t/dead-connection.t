# Hello Edmund,
#
# Thanks for HTTP::Async! I have a question about it, that I cannot figure out
# myself. I'm playing with HTTP::Async in various corner cases, and there's one
# particular error I'm getting:
#
#  HTTP::Async object destroyed but still in use at a.pl line 0
#  HTTP::Async INTERNAL ERROR: 'id_opts' not empty at a.pl line 0
#
# and the code is

use strict;
use warnings;
use HTTP::Async;
use HTTP::Request;
use IO::Socket::INET;
use Time::HiRes;
use Net::EmptyPort ();

use Test::More tests => 10;

my $port         = Net::EmptyPort::empty_port();
my $abort_period = 3;

foreach my $arg_key (qw(timeout max_request_time)) {

    # open a socket that will accept connections but never respond
    my $sock = IO::Socket::INET->new(
        Listen    => 5,
        LocalAddr => 'localhost',
        LocalPort => $port,
        Proto     => 'tcp'
    ) || die "Could not open a socket on port '$port' - maybe in use?";
    ok $sock, "opened socket on port '$port'";

    my $async = HTTP::Async->new( $arg_key => $abort_period );
    ok $async, "creating async using $arg_key => $abort_period";

    my $req = HTTP::Request->new( GET => "http://localhost:$port/" );
    my $id = $async->add($req);
    ok $id, "Added request, given id '$id'";

    # set up time started and when it should end. Add one second to be generous.
    my $added_time      = time;
    my $should_end_time = $added_time + $abort_period + 1;

    my $res = undef;

    while (!$res) {
        $res = $async->wait_for_next_response(1);
        
        # Check that we have not been waiting too long.
        last if time > $should_end_time;
    }
    
    ok $res, "got a response";
    is $res->code, 504, "got faked up timeout response";
}

# I expected that $response should be defined and contain a fake 504 error.
# It's either I'm doing something wrong or ..?
#
#
# --
# Sincerely,
#
#        Dmitry Karasik
