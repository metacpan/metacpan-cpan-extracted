# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More;

BEGIN { use_ok( 'JSON::API' ); }

my $object = JSON::API->new('http://localhost/test');
isa_ok ($object, 'JSON::API');


{ # test creation w/out $base_url fails
	my $obj = JSON::API->new();
	is($obj, undef, "new() returns undef when no base_url set");
}

{ # test creation with special options
	my $obj = JSON::API->new('test', user => 'foo', pass => 'bar', realm => 'fubarland', debug => 0);
	isa_ok($obj, 'JSON::API', "Tests cover but don't exercise the extra options");
	$obj = JSON::API->new('test', user => 'foo', pass => 'bar', realm => '', debug => 0);
	isa_ok($obj, 'JSON::API', "Tests cover but don't exercise the extra options");
	$obj = JSON::API->new('test', user => 'foo', pass => '', realm => 'fubarland', debug => 0);
	isa_ok($obj, 'JSON::API', "Tests cover but don't exercise the extra options");
	$obj = JSON::API->new('test', user => '', pass => 'bar', realm => 'fubarland', debug => 0);
	isa_ok($obj, 'JSON::API', "Tests cover but don't exercise the extra options");
	$obj = JSON::API->new('test', user => '', pass => '', realm => 'fubarland', debug => 0);
	isa_ok($obj, 'JSON::API', "Tests cover but don't exercise the extra options");
	$obj = JSON::API->new('test', user => 'foo', pass => '', realm => '', debug => 0);
	isa_ok($obj, 'JSON::API', "Tests cover but don't exercise the extra options");
	$obj = JSON::API->new('test', user => '', pass => 'bar', realm => '', debug => 0);
	isa_ok($obj, 'JSON::API', "Tests cover but don't exercise the extra options");
}

done_testing;
