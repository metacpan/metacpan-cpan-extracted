use strict;
use Test::More tests => 3;

use LWP::UserAgent;                                                                        
use HTTP::Daemon;
use HTTP::Status;
use POSIX;


use_ok('LWPx::TimedHTTP', qw(:autoinstall));   

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
        ok(defined($response->header('Client-Response-Server-Time')), "Got a Client-Response-Server-Time"); 
        ok(defined($response->header('Client-Request-Dns-Time')), "Got a Client-Request-Dns-Time"); 
        POSIX::_exit(0);
}


}
