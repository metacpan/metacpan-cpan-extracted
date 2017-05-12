use Kelp::Base -strict;
use Kelp;
use Kelp::Test;
use Test::More;
use HTTP::Request::Common;

my $app = Kelp->new(mode => 'test');
my $session;

$app->add_route( '/fm1', sub { 
	my $self = shift;
	$self->flash_message('hi'); #set up
	$session = $self->req->env->{'psgix.session'};
});

$app->add_route( '/fm2', sub { 
	my $self = shift;
	$self->flash_message; #consume
	$session = $self->req->env->{'psgix.session'};
});

my $t = Kelp::Test->new( app => $app );

can_ok $app, 'flash_message';
ok $app->config_hash->{middleware}->[0] eq 'Session', 'session middleware loaded';

$t->request( GET '/fm1' );

ok defined $session, 'session found';
ok exists $session->{'km::flash'}, 'exists flash session key';
ok $session->{'km::flash'} eq 'hi', 'flash value found';

$t->request( GET '/fm2' );

ok !exists $session->{'km::flash'}, 'deleted flash session key';

done_testing;
