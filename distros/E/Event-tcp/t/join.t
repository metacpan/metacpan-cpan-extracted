#!./perl
use strict;
use Test;
use Event qw(loop unloop);
use Event::type qw(tcplisten tcpsession);

my $debug=0;
if ($debug) {
    require NetServer::ProcessTop;
}

my $port = 7000 + int rand 2000;
my $pid;
if (($pid=fork) == 0) { # SERVER (child)
    'NetServer::ProcessTop'->import()
	if $debug;
    #sleep 1;

    my $finishing;
    my $api = [
	   { name => 'hello', reply=>'', code => sub { 'world' } },
	   {
	    name => 'tickle', req => 'n', reply => '', code => sub {
		'he' x $_[1]
	    }
	   },
	   { name => 'finishing', code => sub {
		 my ($o) = @_;
		 $finishing=1;
		 $o->rpc('ok', 1);
	     } },
	      ];

    Event->tcplisten(port => $port, cb => sub {
			 my ($w, $sock) = @_;
			 # warn "client on ".fileno($sock);
			 my $o = Event->tcpsession(desc => 'server',
						   fd => $sock, api => $api);
		     });

    Event->timer(desc => 'shutdown', interval => 1, cb => sub {
		     my $c = grep { ref eq 'Event::tcpsession' } Event::all_watchers;
		     unloop(0) if ($finishing and $c == 0);
		 });

    exit loop();

} else {  # CLIENT
    'NetServer::ProcessTop'->import()
	if $debug;
    # $Event::DebugLevel = 4;
    my $Tests = 14;
    plan test => $Tests;

    my $api = [
	   { name => 'ok', req => 'n', code => sub { ok $_[1] } },
	      ];

    my $c = Event->tcpsession(desc => 'client', port => $port, api => $api,
			      cb => sub {
				  my ($w) = @_;
				  $_[2] ||= 'ok';
				  my $fn = $w->fd? fileno($w->fd) : 'undef';
				  # warn "Status: fd=$fn $_[1], $_[2]\n";
			      });
    ok ref $c, 'Event::tcpsession';
    
    Event->timer(desc => 'break connection', after => 4, cb => sub {
		     $c->fd(undef);  # (oops! :-)
		     # $c->debug(1);
		     $c->now;        # otherwise wont notice
		     #warn "Broke connection in order to test recovery...\n";
		     $c->rpc('finishing');
		 });

    $c->rpc('hello', sub{ ok $_[1], 'world'; });

    my $tickled=1;
    Event->timer(interval => 1, cb => sub {
		     shift->w->cancel
			 if ++$tickled > 10;
		     my $expect = $tickled;
		     $c->rpc('tickle', sub {
				 my ($o,$got) = @_; 
				 ok $got, 'he' x $expect;
			     }, $tickled);
		 });

    Event->timer(desc => 'shutdown', interval => .5, cb => sub {
		     unloop if $Test::ntest > $Tests-1
		 });

    loop();
    $c->fd(undef);

    #warn "Waiting for $pid...";
    wait; ok !$?;
}
