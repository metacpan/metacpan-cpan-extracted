use Test::More;
use Data::Dumper;

use strict;

plan tests => 1						# use_ok
			+ 2						# my tests
	;

use_ok('HTML::Template::Pluggable');

{
	my $t = HTML::Template::Pluggable->new(
			scalarref	=> \q{nothing},
			debug		=> 0,

			);
	$t->add_trigger('before_output', sub { diag("trigger called with @_") if $_[0]->{options}->{debug} } );

	ok($t->output eq 'nothing');
}

{
	my $t = HTML::Template::Pluggable->new(
			scalarref	=> \q{<tmpl_var before_output>},
			debug		=> 0,

			);
	$t->add_trigger('before_output', sub { my $self = shift; $self->param('before_output' => 'before output'); } );

	ok($t->output eq 'before output');
}

__END__
