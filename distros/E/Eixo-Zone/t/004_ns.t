use strict;
use Test::More;

use_ok("Eixo::Zone::Network::Ctl");
use_ok("Eixo::Zone::Artifact::NetworkNS");

my $test_ns = 'ns_' . int(rand(99999));

my $ctl = "Eixo::Zone::Network::Ctl";

eval{

	my $ns = Eixo::Zone::Artifact::NetworkNS->new(

		$test_ns, 

		$ctl

	);

	$ns->create;

	ok($ctl->ns_exists($test_ns), "NS has been created");

	ok($ns->{f_created}, "NS's internal state is correct");

	$ns->delete();

	ok(!$ctl->ns_exists($test_ns), "NS has been deleted");

};
if($@){
	ok(undef, "ERROR: $@");
}

$ctl->ns_delete($test_ns) if(

	$ctl->ns_exists($test_ns)

);


done_testing();
