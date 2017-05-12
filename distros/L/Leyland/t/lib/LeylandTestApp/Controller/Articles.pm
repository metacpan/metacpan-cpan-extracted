package LeylandTestApp::Controller::Articles;

use Moo;
use Leyland::Parser;
use namespace::clean;

with 'Leyland::Controller';

prefix { '/articles' }

del '^/(\w+)$' {
	my $id = shift;

	return { del => $id };
}

get '^/(\w+)$' {
	my $id = shift;

	return { get => $id };
}

1;
