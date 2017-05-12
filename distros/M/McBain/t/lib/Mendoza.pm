package Mendoza;

use McBain;

get '/' => (
	description => 'Returns the name of the API',
	cb => sub {
		return 'MEN-DO-ZAAAAAAAAAAAAA!!!!!!!!!!!';
	}
);

get '/status' => (
	description => 'Returns the status of the API',
	cb => sub { shift->status }
);

get '/(pre|post)_route_test' => (
	cb => sub { 'asdf' }
);

pre_route {
	my ($api, $ns, $params) = @_;

	croak { code => 500, error => "pre_route doesn't like you" }
		if $ns eq 'GET:/pre_route_test';
};

post_route {
	my ($api, $ns, $result) = @_;

	$$result = 'post_route messed you up'
		if $ns eq 'GET:/post_route_test';
};

sub new { bless { status => 'ALL IS WELL' }, shift };

sub status { shift->{status} }

1;
__END__
