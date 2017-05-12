use Test::Most;
use Test::MockModule;
use Google::reCAPTCHA;

subtest 'successful response - IPv4' => sub {
	my $mock_ua = Test::MockModule->new('LWP::UserAgent');
	$mock_ua->mock('post', sub {
		return bless {}, "HTTP::Response";	
	});

	my $mock_response = Test::MockModule->new('HTTP::Response');
	$mock_response->mock('decoded_content', sub {
		return '{ "success": true }';
	});

	$mock_response->mock('is_success', sub {
		return 1;
	});

	my $captcha = Google::reCAPTCHA->new(secret => 'test');
	my $success = $captcha->siteverify(response => 'test', remoteip => '192.168.1.1');
	ok $success, 'successfull result';
};

subtest 'successful response - IPv6' => sub {
	my $mock_ua = Test::MockModule->new('LWP::UserAgent');
	$mock_ua->mock('post', sub {
		return bless {}, "HTTP::Response";	
	});

	my $mock_response = Test::MockModule->new('HTTP::Response');
	$mock_response->mock('decoded_content', sub {
		return '{ "success": true }';
	});

	$mock_response->mock('is_success', sub {
		return 1;
	});

	my $captcha = Google::reCAPTCHA->new(secret => 'test');
	my $success = $captcha->siteverify(response => 'test', remoteip => '2001:0000:4136:e378:8000:63bf:3fff:fdd2');
	ok $success, 'successfull result';
};

subtest 'croaks if error codes present' => sub {
	my $mock_ua = Test::MockModule->new('LWP::UserAgent');
	$mock_ua->mock('post', sub {
		return bless {}, "HTTP::Response";	
	});

	my $mock_response = Test::MockModule->new('HTTP::Response');
	$mock_response->mock('decoded_content', sub {
		return '{ "success": false, "error-codes": [ "missing-input-secret" ] }';
	});

	$mock_response->mock('is_success', sub {
		return 1;
	});

	my $captcha = Google::reCAPTCHA->new(secret => 'test');

	throws_ok {
		$captcha->siteverify(response => 'test', remoteip => '192.168.1.1');
	} qr/API Error: missing-input-secret/, 'Api error thrown';

};

subtest 'croaks if missing secret' => sub {
	throws_ok {
		my $captcha = Google::reCAPTCHA->new();
	} qr/Mandatory parameter 'secret' missing in call/, 'Module error thrown';
};

subtest 'croaks if empty secret' => sub {
        throws_ok {
                my $captcha = Google::reCAPTCHA->new(secret => '');
        } qr/he 'secret' parameter \(""\) to Google::reCAPTCHA::new did not pass the 'is a secret key' callback/, 'Module error thrown';
};

subtest 'croaks if missing response' => sub {
        my $captcha = Google::reCAPTCHA->new(secret => 'test');

        throws_ok {
                $captcha->siteverify(remoteip => '192.168.1.1');
        } qr/Mandatory parameter 'response' missing in call/, 'Module error thrown';
};

subtest 'croaks if not valid ipv4 or ipv6' => sub {
        my $captcha = Google::reCAPTCHA->new(secret => 'test');

        throws_ok {
                $captcha->siteverify(remoteip => 'failed');
        } qr/did not pass the 'is a remote ipv4 or ipv6 address' callback/, 'Module error thrown';
};

subtest 'croaks if empty response' => sub {
	my $captcha = Google::reCAPTCHA->new(secret => 'test');

        throws_ok {
                $captcha->siteverify(response => '', remoteip => '192.168.1.1');
        } qr/The 'response' parameter \(""\) to Google::reCAPTCHA::siteverify did not pass the 'is a response code' callback/, 'Module error thrown';
};

subtest 'non-successful http request' => sub {
	my $mock_ua = Test::MockModule->new('LWP::UserAgent');
	$mock_ua->mock('post', sub {
		return bless {}, "HTTP::Response";	
	});

	my $mock_response = Test::MockModule->new('HTTP::Response');
	$mock_response->mock('is_success', sub {
		return 0;
	});
	$mock_response->mock('code', sub {
		return 500;
	});

	my $captcha = Google::reCAPTCHA->new(secret => 'test');

	throws_ok {
		$captcha->siteverify(response => 'test', remoteip => '192.168.1.1');
	} qr/HTTP Request failed with status 500/, 'Api error thrown';

};

done_testing;
