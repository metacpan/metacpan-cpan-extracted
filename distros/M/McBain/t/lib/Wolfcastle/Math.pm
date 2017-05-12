package Wolfcastle::Math;

use McBain -contextual;

get '/sum' => (
	description => 'Adds two integers from params',
	params => {
		one => { required => 1, integer => 1 },
		two => { required => 1, integer => 1 }
	},
	cb => sub {
		my ($c, $params) = @_;

		return $params->{one} + $params->{two};
	}
);

get '/diff' => (
	description => 'Subtracts two integers',
	params => {
		one => { required => 1, integer => 1 },
		two => { required => 1, integer => 1 }
	},
	cb => sub {
		my ($c, $params) = @_;

		if ($c->user->{name} eq 'ido') {
			return 5;
		}

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
		my ($c, $params) = @_;

		return $params->{one} * $params->{two};
	}
);

post '/factorial' => (
	description => 'Returns the factorial of a number',
	params => {
		num => { required => 1, integer => 1 }
	},
	cb => sub {
		my ($c, $params) = @_;

		return $params->{num} <= 1 ? 1 : $c->forward('GET:/math/mult', {
			one => $params->{num},
			two => $c->forward('POST:/math/factorial', { num => $params->{num} - 1 })
		});
	}
);

1;
__END__
