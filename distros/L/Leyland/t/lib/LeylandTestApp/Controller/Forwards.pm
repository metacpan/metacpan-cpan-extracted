package LeylandTestApp::Controller::Forwards;

use Moo;
use Leyland::Parser;
use namespace::clean;

with 'Leyland::Controller';

prefix { '/forwards' }

get '^/simple_forward$' {
	$c->forward('/');
}

get '^/explicit_forward$' {
	$c->forward('DELETE:/articles/forwarded');
}

get '^/possibly_dangerous_forward$' {
	$c->forward('/articles/forwarded');
}

1;