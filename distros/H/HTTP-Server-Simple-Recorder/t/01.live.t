use warnings;
use strict;
use Test::More tests => 20;

BEGIN { use_ok 'Test::HTTP::Server::Simple' }
BEGIN { use_ok 'HTTP::Server::Simple::CGI' }
BEGIN { use_ok 'Socket' }

# This script assumes that `localhost' will resolve to a local IP
# address that may be bound to,

use constant PORT => 13432;

unlink map "t/logs/rec.$_", qw/1.in 1.out 2.in 2.out/;

{
    my $s=MyServer->new(PORT);
    is($s->port(),PORT,"Constructor set port correctly");

    # XXX TODO FIXME should use File::Spec or whatever
    is($s->recorder_prefix, "t/logs/rec");

    my $url = $s->started_ok("start up the web server");

    select(undef,undef,undef,0.2); # wait a sec

    my $content=fetch("GET / HTTP/1.1", "");

    like($content, qr/Congratulations/, "Returns a page");

    $content=fetch("GET /monkey HTTP/1.1", "");

    like($content, qr/Congratulations/, "Returns a page");
}

{
    my $f = "t/logs/rec.1.in";
    ok((open my $fh, "<$f"), "found a log file") or diag("error opening $f: $!");

    binmode($fh);

    my $text = do { local $/; <$fh> };

    is($text, "GET / HTTP/1.1\015\012\015\012");
} 

{
    my $f = "t/logs/rec.2.in";
    ok((open my $fh, "<$f"), "found a log file") or diag("error opening $f: $!");

    binmode($fh);

    my $text = do { local $/; <$fh> };

    is($text, "GET /monkey HTTP/1.1\015\012\015\012");
} 

{
    my $f = "t/logs/rec.1.out";
    ok((open my $fh, "<$f"), "found a log file") or diag("error opening $f: $!");

    my $text = do { local $/; <$fh> };

    like($text, qr!^HTTP/1.0 200 OK!);
    like($text, qr!^Content-Type: text/html!m);
    like($text, qr!Congratulations!);
} 

{
    my $f = "t/logs/rec.2.out";
    ok((open my $fh, "<$f"), "found a log file") or diag("error opening $f: $!");

    my $text = do { local $/; <$fh> };

    like($text, qr!^HTTP/1.0 200 OK!);
    like($text, qr!^Content-Type: text/html!m);
    like($text, qr!Congratulations!);
}

# this function may look excessive, but hopefully will be very useful
# in identifying common problems
sub fetch {

    my @response;
    my $alarm = 0;
    my $stage = "init";

    my %messages =
	( "init" => "inner contemplation",
	  "lookup" => ("lookup of `localhost' - may be caused by a "
		       ."missing hosts entry or broken resolver"),
	  "sockaddr" => "call to sockaddr_in() - ?",
	  "proto" => ("call to getprotobyname() - may be caused by "
		      ."bizarre NSS configurations"),
	  "socket" => "socket creation",
	  "connect" => ("connect() - may be caused by a missing or "
			."broken loopback interface, or firewalling"),
	  "send" => "network send()",
	  "recv" => "collection of response",
	  "close" => "closing socket"
	);

    $SIG{ALRM} = sub {
	@response = "timed out during $messages{$stage}";
	$alarm = 1;
    };

    my ($iaddr, $paddr, $proto, $message);

    $message = join "", map { "$_\015\012" } @_;

    my %states =
	( 'init'     => sub { "lookup"; },
	  "lookup"   => sub { ($iaddr = inet_aton("localhost"))
				  && "sockaddr"			    },
	  "sockaddr" => sub { ($paddr = sockaddr_in(PORT, $iaddr))
				  && "proto"			    },
	  "proto"    => sub { ($proto = getprotobyname('tcp'))
				  && "socket"			    },
	  "socket"   => sub { socket(SOCK, PF_INET, SOCK_STREAM, $proto)
				  && "connect"			    },
	  "connect"  => sub { connect(SOCK, $paddr) && "send"	    },
	  "send"     => sub { (send SOCK, $message, 0) && "recv"    },
	  "recv"     => sub {
	      my $line;
	      while (!$alarm and defined($line = <SOCK>)) {
		  push @response, $line;
	      }
	      ($alarm ? undef : "close");
	  },
	  "close"    => sub { close SOCK; "done"; },
	);

    # this entire cycle should finish way before this timer expires
    alarm(5);

    my $next;
    $stage = $next
	while (!$alarm && $stage ne "done"
	       && ($next = $states{$stage}->()));

    warn "early exit from `$stage' stage; $!" unless $next;

    # bank on the test testing for something in the response.
    return join "", @response;


}

package MyServer;

use base qw/Test::HTTP::Server::Simple HTTP::Server::Simple::Recorder HTTP::Server::Simple::CGI/;

sub recorder_prefix { "t/logs/rec" } 
