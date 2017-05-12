use Test::More tests => 5;

BEGIN { use_ok('LWP::UserAgent::ProxyAny'); }

my $ua = LWP::UserAgent::ProxyAny->new;
isa_ok( $ua, 'LWP::UserAgent::ProxyAny', 'new' );

printf "IEProxy=[%s]\n", $ua->get_ie_proxy;
pass( '$ua->get_ie_proxy;' );

$ua->env_proxy;
pass( '$ua->env_proxy;' );

$ua->set_proxy_by_name("127.0.0.1:8080");
pass( '$ua->set_proxy_by_name("127.0.0.1:8080");' );