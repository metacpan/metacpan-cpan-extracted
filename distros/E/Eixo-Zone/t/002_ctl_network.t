use strict;
use Test::More;

use_ok("Eixo::Zone::Network::Ctl");

my $veth = 'veth_' . int(rand(99999));
my $ns = 'ns_' . int(rand(99999));

my $ctl = "Eixo::Zone::Network::Ctl";

#$ctl->setLOG;

eval{

	$ctl->ns_create($ns);

	ok($ctl->ns_exists($ns), "The network namespace was created");

	$ctl->link_create($veth . "_a" , $veth . "_b");

	ok($ctl->link_exists($veth . "_a"), "Veth pair was created");

	ok($ctl->link_exists($veth . "_b"), "Veth pair was created (2)");

	$ctl->link_setns($veth . "_b", $ns);

	ok(!$ctl->link_exists($veth . "_b"), "Veth pair was set to the ns");

};
if($@){
	ok(undef, "Error $@");
}

$ctl->ns_delete($ns) if($ctl->ns_exists($ns));

$ctl->link_delete($veth . "_a") if($ctl->link_exists($veth . "_a"));

done_testing;
