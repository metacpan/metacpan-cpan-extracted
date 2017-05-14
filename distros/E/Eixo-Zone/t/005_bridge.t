use strict;
use Test::More;

use_ok("Eixo::Zone::Network::Ctl");
use_ok("Eixo::Zone::Artifact::NetworkNS");
use_ok("Eixo::Zone::Artifact::NetworkVeth");
use_ok("Eixo::Zone::Artifact::NetworkBridge");

my $test_ns = 'ns_' . int(rand(99999));
my $test_bridge = 'br_' . int(rand(99999));
my $test_bridge_ns = 'sbr_' . int(rand(99999));

my $ctl = "Eixo::Zone::Network::Ctl";

$ctl->setLOG;

eval{

	my $ns = Eixo::Zone::Artifact::NetworkNS->new(

		$test_ns, 

		$ctl

	);

	$ns->create;
	
	my $br = Eixo::Zone::Artifact::NetworkBridge->new(

		$test_bridge,

		$ctl

	);

	$br->create;

	ok($br->{f_created}, "Bridge's internal state is correct");

	ok($ctl->bridge_exists($test_bridge), "The Bridge has been created");
	$br->delete;

	ok(!$ctl->bridge_exists($test_bridge), "The Bridge has been deleted");

	my $br2 = Eixo::Zone::Artifact::NetworkBridge->new(

		$test_bridge_ns,

		$ctl

	);

	$br2->setns($test_ns);

	$br2->create;

	ok(!$ctl->bridge_exists($test_bridge_ns), "The bridge has been created but in a namespace");

	ok($ctl->bridge_exists_ns($test_bridge_ns, $test_ns), "The bridge exists in the namespace");

	$br2->delete;

	ok(!$ctl->bridge_exists_ns($test_bridge_ns, $test_ns), "The bridge has been correctly deleted from the namespace");


};
if($@){
	ok(undef, "ERROR: $@");
}

$ctl->ns_delete($test_ns) if(

	$ctl->ns_exists($test_ns)

);

$ctl->bridge_rm($test_bridge) if(

	$ctl->bridge_exists($test_bridge)
);

done_testing();
