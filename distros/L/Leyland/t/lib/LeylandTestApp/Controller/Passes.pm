package LeylandTestApp::Controller::Passes;

use Moo;
use Leyland::Parser;
use namespace::clean;

with 'Leyland::Controller';

prefix { '/passes' }

get '^/simple_pass' returns 'text/plain' {
	$c->stash->{pass} = 'simple pass';
	$c->pass
		if $c->params->{pass};
	return $c->stash->{pass};
}

del '^/simple_pass' returns 'text/plain' {
	$c->stash->{pass} = 'this should not be called';
}

get '^/simple_pass_i_say$' returns 'text/plain' {
	$c->stash->{pass} = 'simple pass i say';
}

1;