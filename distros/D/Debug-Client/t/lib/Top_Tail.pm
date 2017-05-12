package t::lib::Top_Tail;

use strict;
use warnings FATAL => 'all';

use parent qw(Test::Class);
use Test::More;
use Test::Deep;

# startup methods are run before every test method.
sub startup : Test(4) {
	my $self = shift;

	use_ok( 't::lib::Debugger');
	ok( start_script('t/eg/14-y_zero.pl'), 'start script' );
	ok( $self->{debugger} = start_debugger(), 'start debugger' );
	ok( $self->{debugger}->get, 'get debugger' );

}

# teardown methods are run after every test method.
sub teardown : Test(2) {
	my $self = shift;

	like( $self->{debugger}->run, qr/Debugged program terminated/, 'Debugged program terminated' );
	like( $self->{debugger}->quit, qr/1/, 'debugger quit' );

}

1;

__END__

