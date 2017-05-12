use strict;
use warnings;
use lib 'lib';
use HTTPEx::Declare;


my $count;
my $flag;
sub init {
    $count = 0;
    $flag  = '1978';
}
sub next_uri {
    my $req = shift;
    my $uri = $req->uri->clone;
    $uri->port( $flag eq '1978' ? '1977' : '1978' );
    $uri;
}
sub bad_request {
    my $req = shift;
    init;
    my $uri = next_uri($req);
    res( body => sprintf(qq{Bad Request!: <a href="%s">%s</a>}, $uri, $uri) );
}

sub handler {
    my $req = shift;
    my $port = $flag;
    return bad_request($req) if $flag eq $req->uri->port;

    $flag = $req->uri->port;
    $count++;

    my $uri = next_uri($req);
    print STDERR "ping-pong: $flag, $count\n";
    res( body => sprintf(qq{%s: %s<br /><a href="%s">%s</a>\n}, $flag, $count, $uri, $uri) );
}

interface POE => { port => 1977 };
run \&handler;

interface POE => { port => 1978 };
run \&handler;

init;
print "ping-pong start: \n";
POE::Kernel->run;
