package Mendoza::Math;

use McBain;

get '/' => (
	cb => sub {
		return "MATH IS AWESOME";
	}
);

get '/sum' => (
	description => 'Adds two integers from params',
	params => {
		one => { required => 1, integer => 1 },
		two => { required => 1, integer => 1 }
	},
	cb => sub {
		my ($api, $params) = @_;

		return $params->{one} + $params->{two};
	}
);

get '/sum/(\d+)/(\d+)' => (
	description => 'Adds two integers from path',
	cb => sub {
		my ($api, $params, $one, $two) = @_;

		return $one + $two;
	}
);

get '/diff' => (
	description => 'Subtracts two integers',
	params => {
		one => { required => 1, integer => 1 },
		two => { required => 1, integer => 1 }
	},
	cb => sub {
		my ($api, $params) = @_;

		return $params->{one} - $params->{two};
	}
);

get '/mult' => (
	description => 'Multiplies two integers',
	params => {
		one => { required => 1, integer => 1 },
		two => { required => 1, integer => 1 }
	},
	cb => sub {
		my ($api, $params) = @_;

		return $params->{one} * $params->{two};
	}
);

post '/factorial' => (
	description => 'Returns the factorial of a number',
	params => {
		num => { required => 1, integer => 1 }
	},
	cb => sub {
		my ($api, $params) = @_;

		return $params->{num} <= 1 ? 1 : $api->forward('GET:/math/mult', {
			one => $params->{num},
			two => $api->forward('POST:/math/factorial', { num => $params->{num} - 1 })
		});
	}
);

get '/pre_route_test' => (
	cb => sub { 'asdf' }
);

pre_route {
	my ($api, $ns, $params) = @_;

	croak { code => 500, error => "math pre_route doesn't like you" }
		if $ns eq 'GET:/math/pre_route_test';
};

1;
__END__
