use strict;
use Test::More tests => 6;

# test the TransportRouter abstract base class

BEGIN {	use_ok( 'GSM::SMS::TransportRouter::TransportRouter' ) }
my $t = GSM::SMS::TransportRouter::TransportRouter->new();
isa_ok( $t, 'GSM::SMS::TransportRouter::TransportRouter' );

# test the simple router
BEGIN { use_ok( 'GSM::SMS::TransportRouter::Simple' ) }
my $s = GSM::SMS::TransportRouter::Simple->new();
isa_ok( $s, 'GSM::SMS::TransportRouter::Simple' );

# call to the base class must fail - abstract!
my @transport_list = ( 	FakeTransport->new( 0 ),
						FakeTransport->new( 0 ),
						FakeTransport->new( 1 ),
						FakeTransport->new( 0 )
					 );

eval {
	$t->route( 'test', @transport_list );
}; 
ok( $@, 'Abstract route must fail!' );

# call to Simple must succeed
ok( $s->route( 'test', @transport_list ), 'Simple router must pass' );

package FakeTransport;

sub new {
	my ($proto, $has) = @_;

	my $self = { _has_route => $has };

	bless $self, ref($proto) || $proto;
}

sub has_valid_route { $_[0]->{_has_route}; }

sub get_name { ref($_[0]); }

1;
