use strict;
use IO::Capture::Stderr;
use Test::More;
use JSON::API;


{ # test regular URL
	my $api = JSON::API->new('http://myserver.com/');
	is($api->url('/api//path/'), 'http://myserver.com/api/path/', 'url() for basename with http://');
}

{ # test w/out http://
	my $api = JSON::API->new('myserver.com/');
	is($api->url('/api'), 'myserver.com/api', 'url() for basename without http://');
}

{ # test with https://
	my $api = JSON::API->new('https://myserver.com/');
	is($api->url('/api'), 'https://myserver.com/api', 'url() for basename with https://');
}

{ # test with :8080
	my $api = JSON::API->new('http://myserver.com:8080/');
	is($api->url('/api'), 'http://myserver.com:8080/api', 'url() for basename with :portnum');
}

{ # test json deserializing with valid json
	my $json = '{"name":"foo","value":"bar"}';
	my $api = JSON::API->new('test');
	is_deeply($api->_decode($json), {name =>'foo',value=>'bar'},
		'Good JSON returns hashref on decode');
}

{ # test json deserializing with invalid json
	my $json = 'blahblah{"';
	my $api = JSON::API->new('test');
	is_deeply($api->_decode($json), undef, 'Bad JSON returns undef on decode');
	like($api->errstr,
		qr/^malformed JSON string, neither /,
		'Bad JSON sets proper errstr'
	);
}


{ # test json serializing with valid obj
	my $obj = { name => 'foo' };
	my $api = JSON::API->new('test');
	is($api->_encode($obj), '{"name":"foo"}', 'Valid object gets serialized to JSON');
}

{ # test json serializing with invalid obj
	my $obj = 'asdf';
	my $api = JSON::API->new('test');
	is_deeply($api->_encode($obj), undef, 'Invalid object sent for serialization returns undef');
	is($api->errstr,
		'hash- or arrayref expected (not a simple scalar, use allow_nonref to allow this)',
		'Bad encode sets proper errstr'
	);
}

{ # test _debug prints to stderr
	my $capture = IO::Capture::Stderr->new();
	$capture->start;
	my $api = JSON::API->new('test', debug => 1);
	$api->_debug("my debug message");
	$capture->stop;
	is($capture->read, "my debug message\n", '_debug prints to STDERR when debug is set.');
}

{ # test _debug prints to stderr
	my $capture = IO::Capture::Stderr->new();
	$capture->start;
	my $api = JSON::API->new('test');
	$api->_debug("my debug message");
	$capture->stop;
	is($capture->read, undef, '_debug doesnt print to STDERR when debug is not set.');
}

{ # errstr
	my $api = JSON::API->new('test');
	$api->{error_string} = 'my test error';
	is($api->errstr, '', '$api->errstr returns empty string when no error present');
	$api->{has_error} = 1;
	is($api->errstr, 'my test error', '$api->errstr returns empty string when no error present');
}

{ # test server generation
	my $server = JSON::API->new('test')->_server('http://myhost.com:80');
	is($server, 'myhost.com:80', 'http://myhost.com:80 server is myhost.com:80');

	$server = JSON::API->new('test')->_server('http://myhost.com/');
	is($server, 'myhost.com', 'http://myhost.com/ server is myhost.com');

	$server = JSON::API->new('test')->_server('https://myhost.com:80');
	is($server, 'myhost.com:80', 'https://myhost.com:80 server is myhost.com:80');

	$server = JSON::API->new('test')->_server('https://myhost.com/');
	is($server, 'myhost.com', 'https://myhost.com/ server is myhost.com');

	$server = JSON::API->new('test')->_server('myhost.com:80');
	is($server, 'myhost.com:80', 'myhost.com:80 server is myhost.com:80');

	$server = JSON::API->new('test')->_server('myhost.com/');
	is($server, 'myhost.com', 'myhost.com/ server is myhost.com');

	$server = JSON::API->new('test')->_server('myhost.com:80/asdf');
	is($server, 'myhost.com:80', 'myhost.com:80/asdf server is myhost.com:80');

	$server = JSON::API->new('test')->_server('myhost.com/asdf/');
	is($server, 'myhost.com', 'myhost.com/asdf/ server is myhost.com');
}

{ # test was_success
	my $api = JSON::API->new('test');
	$api->{has_error} = 0;
	is($api->was_success, 1, "absence of has_error = success");

	$api->{has_error} = 1;
	is($api->was_success, 0, "presence of has_error = fail");
}

done_testing;
