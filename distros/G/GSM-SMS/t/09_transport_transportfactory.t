use strict;
use Test::More tests => 2;

# test the Transport abstract base class

BEGIN {	use_ok( 'GSM::SMS::Transport' ) }

# can we correctly instantiate ...
my $t = GSM::SMS::Transport->new( -config_file => 't/transporttest.config' );
isa_ok( $t, 'GSM::SMS::Transport' );

