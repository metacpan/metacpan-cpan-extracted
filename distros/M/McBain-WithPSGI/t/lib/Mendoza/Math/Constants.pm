package Mendoza::Math::Constants;

use McBain;

get '/' => (
	cb => sub {
		return "I CAN HAZ CONSTANTS";
	}
);

get '/pi' => (
	cb => sub {
		return 3.14159265359;
	}
);

get '/(golden_ratio|euler\'s_number)' => (
	cb => sub {
		my ($self, $params, $constant) = @_;

		if ($constant eq 'golden_ratio') {
			return 1.61803398874;
		} else {
			return 2.71828;
		}
	}
);

1;
__END__
