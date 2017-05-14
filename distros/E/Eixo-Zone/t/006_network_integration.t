use strict;
use Test::More;

use Net::Ping;

use_ok("Eixo::Zone::Network::Ctl");
use_ok("Eixo::Zone::Artifact::NetworkNS");
use_ok("Eixo::Zone::Artifact::NetworkVeth");
use_ok("Eixo::Zone::Artifact::NetworkBridge");

my $test_ns = 'ns_' . int(rand(99999));
my $test_bridge = 'br_' . int(rand(99999));
my $test_bridge_ns = 'sbr_' . int(rand(99999));

my @veths;

my $ctl = "Eixo::Zone::Network::Ctl";

#$ctl->setLOG;

eval{

	# we create a namespace
	my $ns = Eixo::Zone::Artifact::NetworkNS->new(

		$test_ns,

		$ctl

	);

	$ns->create;

	ok($ns->integrity, "Namespace created");

	# we create 6 veths
	@veths = map {

		Eixo::Zone::Artifact::NetworkVeth->new(

			$_,

			$ctl
		)

	} qw(a b c d e f g h i j k l m n o p);

	my $i = 2;
	my $veth_net = "10.1.12.";

	my @nets;

	foreach(@veths){

		my $net = $veth_net . $i++;

		push @nets, $net;

		$_->create

			->up("A")

		  	->setns($test_ns, "B")

			->up("B")

			->addr($net . "/24", "B");
	}

	# we create a bridge
	my $br = Eixo::Zone::Artifact::NetworkBridge->new(

		$test_bridge,

		$ctl

	);

	$br->create;
	
	ok($br->integrity, "Bridge has been created");

	# we add all veths to the bridge
	$br->addif($_->{a}) foreach(@veths);

	# we set an ip for the brigde
	$br->setAddr($veth_net . "1/24");

	# we test connections
	my $ping = Net::Ping->new;
	
	my @tested = grep {

		print "pinging $_\n";

		$ping->ping($_, 1)	

	} @nets;

	ok(!(grep { !$_ } @tested), "All veths respond to ping");

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

foreach(@veths){

	$_->delete;
}

done_testing();
