use strict;
use Test::More;

use Net::Ping;

use_ok("Eixo::Zone::Network::Ctl");
use_ok("Eixo::Zone::Artifact::NetworkVeth");

my $test_ns = "ns_" . int(rand(99999));
my $test_veth = "v_" . int(rand(99999));
my $ctl = "Eixo::Zone::Network::Ctl";

my $EXTERNAL_NET = "10.1.10.1";
my $INTERNAL_NET = "10.1.10.2";

$ctl->setLOG;

eval{

	$ctl->ns_create($test_ns);

	my $v = Eixo::Zone::Artifact::NetworkVeth->new(

		$test_veth,

		$ctl

	);

	$v->create;

	ok($ctl->link_exists($test_veth . "_a"), "Link exists");
	ok($ctl->link_exists($test_veth . "_b"), "Link exists (2)");

	$v->setns($test_ns, "B");

	$ctl->link_up_ns("lo", $test_ns);

	ok(!$ctl->link_exists($test_veth . "_b"), "Link extreme is in ns");

	ok($v->{f_created}, "Veth internal state is correct");

	ok(	$v->{a} eq $test_veth . "_a" &&

		$v->{b} eq $test_veth . "_b",

		"Veth names are correct"
	);

	ok($v->{ns} && $v->{ns}->{b} eq $test_ns, "NS is correct for b");

	$v->up("A");
	$v->addr($EXTERNAL_NET . "/24" , "A");

	$v->up("B");
	$v->addr($INTERNAL_NET . "/24", "B");

	my $p = Net::Ping->new();

	ok($p->ping($INTERNAL_NET, 1), "Address have been correctly established");

};
if($@){
	ok(undef, "$@");
}

$ctl->ns_delete($test_ns) if(

	$ctl->ns_exists($test_ns)

);

$ctl->link_delete($test_veth . "_a") if(

	$ctl->link_exists($test_veth . "_a")

);


done_testing();
