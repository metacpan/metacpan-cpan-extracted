use strict;
use Test::More tests => 10;
# use Log::Agent;
# logconfig( -level => 99 );

# Test the get_transport and get_transport_by_name accessors
BEGIN {
	use_ok( 'GSM::SMS::NBS' );
	use_ok( 'GSM::SMS::Config' );
}

SKIP: {
	my $cfg;

	eval {
		$cfg = GSM::SMS::Config->new( -check => 1 );
	};
	skip( "Config hinders test: $@", 2) if ($@);

	my $nbs = GSM::SMS::NBS->new;
	my $transport = $nbs->get_transport;

	isa_ok($transport,'GSM::SMS::Transport', 'get_transport returns transport object');

	my @transports = $transport->get_transports;
	my $cnt = 0;
	foreach my $t (@transports) {
		$cnt++;
		last if $cnt > 7;
		my $n = $t->get_name;
		my $tn = $transport->get_transport_by_name( $n );
		is( $tn, $t, "$n object can be retrieved via get_transport_by_name" ); 
	}
	for(;$cnt < 7; $cnt++) {
		is( 1, 1, "Dummy test" );
	}
	$nbs = undef;
}
