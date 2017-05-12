use strict;
use Test::More tests => 3;

use LWP::UserAgent;                                                                        
use LWP::Protocol;
use HTTP::Daemon;
use HTTP::Status;
use POSIX;


use_ok('LWPx::TimedHTTP');

eval { LWP::Protocol::implementor('http', 'LWPx::TimedHTTP') };  
is($@,'');


my $d   = HTTP::Daemon->new || die "Couldn't start an HTTP::Daemon";
my $pid; 

eval { $pid = fork; };



SKIP : {
    skip "No fork so cannot test against local server", 1 if $@;

    # parent 
    if ($pid) {

        while (my $c = $d->accept) {
            #sleep(1);
            while (my $r = $c->get_request) {
                if ($r->method eq 'GET' and $r->url->path eq "/sleeptest") {
                    #sleep(1);
                    $c->send_file_response($0);
                } else {
                    $c->send_error(RC_FORBIDDEN)
                }
                last;
            }
            $c->close;
            undef($c);
            last;
        }
        waitpid($pid, 0);
        POSIX::_exit(0);
        
    } else {
        # child
        my $ua = new LWP::UserAgent;                                                                                                
        my $response = $ua->get($d->url."sleeptest"); 
        my $t = $response->header('Client-Request-Transmit-Time');
        ok(defined($t), "Got Client-Request-Transmit-Time"); 
        POSIX::_exit(0);
    }
}
