package Mendoza;

use McBain;

get '/' => (
	description => 'Returns the name of the API',
	params => {
		message => { default => 'MEN-DO-ZAAAAAAAAAAAAA!!!!!!!!!!!' }
	},
	cb => sub {
		return $_[1]->{message};
	}
);

get '/query' => (
	params => {
		array => { array => 1, min_length => 2 }
	},
	cb => sub {
		return join(' ', @{$_[1]->{array}});
	}
);

get '/status' => (
	description => 'Returns the status of the API',
	cb => sub { shift->status }
);

sub new { bless { status => 'ALL IS WELL' }, shift };

sub status { shift->{status} }

1;
__END__
