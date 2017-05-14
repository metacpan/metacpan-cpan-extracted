use strict;
use Test::More;

use_ok("Eixo::Zone::Driver");
use_ok("Eixo::Zone::Resume");
use_ok("Eixo::Zone::Artifact::PSInit");

SKIP:{

	skip "NO A MANO", 4 unless($ENV{A_MANO});

	my $r = Eixo::Zone::Resume->new;
	
	my $i = Eixo::Zone::Artifact::PSInit->new(
	
		sub {
	
			&test_process;
	
			exit 0;
	
		},
	
		$r,
	
		"Eixo::Zone::Driver"
	
	
	);
	
	$i->start;
	
	waitpid($i->{pid}, 0);
}

done_testing();

sub test_process{

	use Scalar::Util qw(blessed);

	no strict 'refs';

	ok(&Eixo::Zone::Driver::getPid() == 1, "I'm an init process");

	ok(defined(&{"main::zone_resume"}), "zone_resume is defined");

	my $resume = &zone_resume;

	ok($resume && blessed($resume) eq "Eixo::Zone::Resume", "I have access to my Resume object");

}
