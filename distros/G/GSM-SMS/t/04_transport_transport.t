use strict;
use Test::More tests => 2;

# test the Transport abstract base class

BEGIN {	use_ok( 'GSM::SMS::Transport::Transport' ) }

# can we correctly instantiate ...
my $t = GSM::SMS::Transport::Transport->new(
							-name => 'test',
							-match => '.*'
														);
isa_ok( $t, 'GSM::SMS::Transport::Transport' );

