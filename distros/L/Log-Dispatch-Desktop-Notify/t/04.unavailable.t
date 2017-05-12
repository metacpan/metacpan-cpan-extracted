#!perl
use Test::More tests => 2;
use Mock::Quick;

our $unavailable_notify_mock;
BEGIN {
    $unavailable_notify_mock = qclass(
	-implement => 'Desktop::Notify',
	new => sub {
	    die "no Dbus available";
	}
	);
}

BEGIN { use_ok( 'Log::Dispatch::Desktop::Notify' ) };

subtest 'no Dbus' => sub {
    my $obj = Log::Dispatch::Desktop::Notify->new( min_level => 'warning' );
    isa_ok( $obj, 'Log::Dispatch::Null' );
};
