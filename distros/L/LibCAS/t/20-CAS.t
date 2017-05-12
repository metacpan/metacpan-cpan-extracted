#!perl -T

use lib qw(. ..);

use Data::Dumper;
use LWP::UserAgent;
use Test::More;
use URI;
use URI::QueryParam;

BEGIN {
    use_ok( 'LibCAS::Client' ) || BAIL_OUT("Failed to load LibCAS::Client");
}

diag( "Testing AuthenCAS $LibCAS::Client::VERSION, Perl $], $^X" );

my $Cas;
my $Server  = "https://localhost/cas";
my $Service = "http://myapp.com/path/to/my/app.html";
my $Ticket  = "My_Ticket";
my $User = 'user1';
my $Pass = 'user1';

test_new($Server);
test_login_url();
test_login_url_service($Service);
test_login_url_service_undef();
test_login_url_renew_true();
test_login_url_renew_false();
test_login_url_gateway_true();
test_login_url_gateway_false();
test_login_url_all_set($Service);
test_logout_url();
test_logout_url_param($Service);
test_validate_url_good($Service, $Ticket);
test_validate_url_bad($Service);
test_service_validate_url_good($Service, $Ticket);
test_service_validate_url_bad($Ticket);
test_proxy_validate_url_good($Service, $Ticket);
test_proxy_validate_url_bad();
test_proxy_url_good($Service, $Ticket);
test_proxy_url_bad($Service);

SKIP: {
	my $r;
	my $res = $Cas->do_http_request($Server);

	skip "Can not talk to CAS server: ".$@, 3, if ! $res;
	
	# Tests we know that will fail...
	$r = $Cas->validate(service => $Service, ticket => $Ticket);
	ok($r->is_failure(), "validate") || diag(Dumper($r));

	$r = $Cas->service_validate(service => $Service, ticket => $Ticket);
	ok($r->is_failure(), "service_validate") || diag(Dumper($r));

	$r = $Cas->proxy_validate(service => $Service, ticket => $Ticket, pgtUrl => $Service);
	ok($r->is_failure(), "proxy_validate") || diag(Dumper($r));
	
	# Tests that should succeed
	$r = $Cas->authenticate(username => $User, password => $Pass);
	ok($r->is_success(), "authenticate");
	can_ok($r, 'user') && diag('Authenticated user '.$r->user());
}

done_testing();


sub test_new {
	my $server = shift;

	$Cas = LibCAS::Client->new(cas_url => $server);
	isa_ok($Cas, 'LibCAS::Client') || BAIL_OUT("Doesn't look like a LibCAS::Client object");
#	diag(Dumper($Cas));
}

sub test_login_url {
	my $url = $Cas->login_url;
	ok($url, "test_login_url");
#	diag($url);
}

sub test_login_url_service {
	my $svc = shift;

	my $url = $Cas->login_url(service => $svc);
	my $uri = URI->new($url);

	ok(grep('service', $uri->query_param), "test_login_service");
#	diag($url);
}

sub test_login_url_service_undef {
	my $url = $Cas->login_url(service => undef);
	my $uri = URI->new($url);

	ok(! grep('service', $uri->query_param), "test_login_service_undef");
#	diag($url);
	
	$url = $Cas->login_url(service => '');
	$uri = URI->new($url);
	ok(! grep('service', $uri->query_param), "test_login_service_undef");
#	diag($url);
}

sub test_login_url_renew_true {
	my $url = $Cas->login_url(renew => 1);
	my $uri = URI->new($url);
	
	ok(grep('renew', $uri->query_param), "test_login_url_renew_true");
#	diag($url);
	
	$url = $Cas->login_url(renew => 'true');
	$uri = URI->new($url);
	
	ok(grep('renew', $uri->query_param), "test_login_url_renew_true");
#	diag($url);
	
	$url = $Cas->login_url(renew => 'yes');
	$uri = URI->new($url);
	
	ok(grep('renew', $uri->query_param), "test_login_url_renew_true");
#	diag($url);
	
	$url = $Cas->login_url(renew => 'y');
	$uri = URI->new($url);
	
	ok(grep('renew', $uri->query_param), "test_login_url_renew_true");
#	diag($url);
}

sub test_login_url_renew_false {
	my $url = $Cas->login_url(renew => undef);
	my $uri = URI->new($url);
	
	ok(! grep('renew', $uri->query_param), "test_login_url_renew_false");
#	diag($url);
}

sub test_login_url_gateway_true {
	my $url = $Cas->login_url(gateway => 1);
	my $uri = URI->new($url);
	
	ok(grep('gateway', $uri->query_param), "test_login_url_gateway_true");
#	diag($url);
	
	$url = $Cas->login_url(gateway => 'true');
	$uri = URI->new($url);
	
	ok(grep('gateway', $uri->query_param), "test_login_url_gateway_true");
#	diag($url);
	
	$url = $Cas->login_url(gateway => 'yes');
	$uri = URI->new($url);
	
	ok(grep('gateway', $uri->query_param), "test_login_url_gateway_true");
#	diag($url);
	
	$url = $Cas->login_url(gateway => 'y');
	$uri = URI->new($url);
	
	ok(grep('gateway', $uri->query_param), "test_login_url_gateway_true");
#	diag($url);
}

sub test_login_url_gateway_false {
	my $url = $Cas->login_url(gateway => undef);
	my $uri = URI->new($url);
	
	ok(! grep('gateway', $uri->query_param), "test_login_url_gateway_false");
#	diag($url);
}

sub test_login_url_all_set {
	my $svc = shift;

	my $url = $Cas->login_url(gateway => '1', renew => 'y', service => $svc);
	my $uri = URI->new($url);
	
	ok(grep('gateway', $uri->query_param), "test_login_url_all_set");
	ok(grep('renew', $uri->query_param), "test_login_url_all_set");
	ok(grep('service', $uri->query_param), "test_login_url_all_set");
#	diag($url);
}

sub test_logout_url {
	my $url = $Cas->logout_url();
	
	ok($url, "test_logout_url");
#	diag($url);
}

sub test_logout_url_param {
	my $svc = shift;
	
	my $url = $Cas->logout_url(url => $svc);
	my $uri = URI->new($url);
	
	ok(grep('url', $uri->query_param), "test_logout_url_param");
#	diag($url);
}

sub test_validate_url_good {
	my ($svc, $tkt) = @_;
	
	my $url = $Cas->validate_url(service => $svc, ticket => $tkt);
	
	if (! $url) {
		fail("test_validate_url_good");
		diag($@);
	} else {
		my $uri = URI->new($url);
	
		ok(grep('service', $uri->query_param), "test_validate_url_good");
		ok(grep('ticket', $uri->query_param), "test_validate_url_good");
#		diag($url);
	}
}

sub test_validate_url_bad {
	my ($svc, $tkt) = @_;
	
	my $url = $Cas->validate_url(service => $svc, ticket => $tkt);
	
	if (! $url) {
		pass("test_validate_url_bad");
#		diag($@);
	} else {
		fail("test_validate_url_bad");
	}
}

sub test_service_validate_url_good {
	my ($svc, $tkt) = @_;
	
	my $url = $Cas->service_validate_url(service => $svc, ticket => $tkt, renew => 1);
	
	if (! $url) {
		fail("test_service_validate_url_good");
		diag($@);
	} else {
		my $uri = URI->new($url);
		
		ok(grep('service', $uri->query_param), "test_service_validate_url_good");
		ok(grep('ticket', $uri->query_param), "test_service_validate_url_good");
#		diag($url);
	}
}

sub test_service_validate_url_bad {
	my ($svc, $tkt) = @_;
	
	my $url = $Cas->service_validate_url(service => $svc, ticket => $tkt, renew => "yes");
	
	if (! $url) {
		pass("test_service_validate_url_bad");
#		diag($@);
	} else {
		fail("test_service_validate_url_bad");
	}
}

sub test_proxy_validate_url_good {
	my ($svc, $tkt) = @_;
	
	my $url = $Cas->proxy_validate_url(service => $svc, ticket => $tkt, renew => 0, pgtUrl => "PxyTicket");
	
	if (! $url) {
		fail("test_proxy_validate_url_good");
		diag($@);
	} else {
		my $uri = URI->new($url);
		
		ok(grep('service', $uri->query_param), "test_proxy_validate_url_good");
		ok(grep('ticket', $uri->query_param), "test_proxy_validate_url_good");
#		diag($url);
	}
}

sub test_proxy_validate_url_bad {
	my ($svc, $tkt) = @_;
	
	my $url = $Cas->proxy_validate_url(service => $svc, ticket => $tkt, renew => "t");
	
	if (! $url) {
		pass("test_proxy_validate_url_bad");
#		diag($@);
	} else {
		fail("test_proxy_validate_url_bad");
	}
}

sub test_proxy_url_good {
	my ($svc, $tkt) = @_;
	
	my $url = $Cas->proxy_url(pgt => $tkt, targetService => $svc);
	
	if (! $url) {
		fail("test_proxy_url_good");
		diag($@);
	} else {
		my $uri = URI->new($url);
		
		ok(grep('pgt', $uri->query_param), "test_proxy_url_good");
		ok(grep('targetService', $uri->query_param), "test_proxy_url_good");
#		diag($url);
	}
}

sub test_proxy_url_bad {
	my ($svc, $tkt) = @_;
	
	my $url = $Cas->proxy_url(pgt => $tkt, targetService => $svc);
	
	if (! $url) {
		pass("test_proxy_url_bad");
#		diag($@);
	} else {
		fail("test_proxy_url_bad");
	}
}