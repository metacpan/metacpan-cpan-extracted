use Kelp::Base -strict;
use Kelp;
use Kelp::Test;
use Test::More;
use HTTP::Request::Common;


my $app = Kelp->new( config_module => 'Config::Null' );
my $session;
my $fm_key = '__custom_fm_key__';
$app->load_module( 'FlashMessage', key => $fm_key );
$app->config_hash->{middleware} = ['Session'];

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
ok exists $session->{$fm_key}, 'exists flash session key';
ok $session->{$fm_key} eq 'hi', 'flash value found';

$t->request( GET '/fm2' );

ok !exists $session->{'km::flash'}, 'deleted flash session key';

done_testing;
