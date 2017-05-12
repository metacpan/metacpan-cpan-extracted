package LeylandTestApp::Controller::Root;

use Moo;
use Leyland::Parser;
use namespace::clean;

with 'Leyland::Controller';

prefix { '' }

get '^/$' returns 'text/plain' {
	return "Index";
}

get '^/exception$' {
	$c->exception({ code => 400, error => 'This is a simple text exception' });
}

get '^/default_mime$' {
	return { default_mime => $c->config->{default_mime} };
}

get '^/template_with_default_layout$' returns 'text/html' {
	return $c->template('template.html', { name => 'Brandon Stark' });
}

get '^/template_with_different_layout$' returns 'text/html' {
	return $c->template('template.html', { name => 'Brandon Stark' }, 'layouts/different.html');
}

get '^/template_with_no_layout$' returns 'text/html' {
	return $c->template('template.html', { name => 'Brandon Stark' }, 0);
}

1;
