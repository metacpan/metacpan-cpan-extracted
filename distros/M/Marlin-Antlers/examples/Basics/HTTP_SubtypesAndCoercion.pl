BEGIN {{{ # Port of Moose::Cookbook::Basics::HTTP_SubtypesAndCoercion

package Request {
	use Marlin::Antlers;

	use HTTP::Headers  ();
	use Params::Coerce ();
	use URI            ();

	my $HTTP_Headers = InstanceOf->of( 'HTTP::Headers' )->plus_coercions(
		ArrayRef, sub { HTTP::Headers->new( $_ -> @* ) },
		HashRef,  sub { HTTP::Headers->new( $_ -> %* ) },
	);

	my $URI = InstanceOf->of( 'URI' )->plus_coercions(
		Object,   sub { Params::Coerce::coerce( 'URI', $_ ) },
		Str,      sub { URI->new( $_, 'http' ) },
	);

	my $Protocol = StrMatch[ qr/^HTTP\/[0-9]\.[0-9]$/ ];

	has base      => ( is => rw, isa => $URI, coerce => true );
	has uri       => ( is => rw, isa => $URI, coerce => true );
	has method    => ( is => rw, isa => Str, default => 'GET' );
	has protocol  => ( is => rw, isa => $Protocol );
	has headers   => ( is => rw, isa => $HTTP_Headers, coerce => true, default => sub { HTTP::Headers->new } );
}

}}};

use Test2::V0;
use Data::Dumper;

my $expected_headers = HTTP::Headers->new( bar => 1, baz => 2 );

{
	my $o = Request->new( headers => [ 'bar', 1, 'baz', 2 ] );
	is( $o->headers, $expected_headers );
}

{
	my $o = Request->new( headers => { bar => 1, baz => 2 } );
	is( $o->headers, $expected_headers );
}

done_testing;
