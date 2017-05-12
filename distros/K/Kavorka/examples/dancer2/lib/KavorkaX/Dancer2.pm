use v5.14;

my @methods = qw( GET HEAD POST PATCH DELETE OPTIONS PUT );
my $methods = join('|', map quotemeta, @methods);

# Wire up KavorkaX::Dancer2 to be able to export not only
# Dancer-specific keywords, but also Kavorka built-ins.
#
package KavorkaX::Dancer2
{
	use Moo;
	extends qw( Kavorka );
	
	our @EXPORT      = ( @methods, qw( ANY prefix hook ), @Kavorka::EXPORT );
	our @EXPORT_OK   = ( @methods, qw( ANY prefix hook ), @Kavorka::EXPORT_OK );
	our %EXPORT_TAGS = (
		'http'    => [ @methods, qw( ANY ) ],
		'dancer'  => [ @methods, qw( prefix hook ) ],
		%Kavorka::EXPORT_TAGS,
	);
	
	our %IMPLEMENTATION = (
		prefix => 'KavorkaX::Dancer2::Sub::Prefix',
		hook   => 'KavorkaX::Dancer2::Sub::Hook',
	);
	
	sub guess_implementation
	{
		my $me = shift;
		my ($name) = @_;
		$IMPLEMENTATION{$name}
			or $me->SUPER::guess_implementation(@_)
			or 'KavorkaX::Dancer2::Sub::HTTP';
	}
}

# A role used by most of the KavorkaX::Dancer2 keywords.
# Instead of the sub name being a bareword, allows it to
# be a URL route or regexp. Stashes the sub name in the
# http_route attribute instead of declared_name attribute
# to protect it from attempts at package-qualification!
#
package KavorkaX::Dancer2::RoutingSub
{
	use Parse::Keyword;
	use Text::Balanced qw( extract_quotelike );
	
	use Moo::Role;
	with qw( Kavorka::Sub );
	
	has http_route   => (is => 'rwp');
	sub is_anonymous { 1 }
	sub install_sub  { die; }
	
	sub parse_subname
	{
		my $self = shift;
		$self->_set_declared_name('__ANON__');
		
		lex_read_space;
		my $peek = lex_peek(1000);
		
		my $route;
		# Quoted
		if ($peek =~ /\A(qr\b|qq\b|q\b|'|")/)
		{
			my ($quote) = extract_quotelike($peek);
			lex_read(length $quote);
			defined($quote) or Carp::croak("extract_quotelike failed!");
			$route = eval($quote);
		}
		# Bare
		elsif ($peek =~ /\A(\S+)\s/)
		{
			$route = $1;
			lex_read(length $route);
		}
		
		$self->_set_http_route($route);
		
		lex_read_space;
		();
	}
	
	sub http_route_variables
	{
		my $self  = shift;
		my $route = $self->http_route;
		return if ref($route);
		return if !defined($route);
		
		$route =~ m{:(\w+)}g;
	}
}

# A role used for GET, HEAD, etc. Allows comma-separated
# keywords when parsing the sub, injects a prelude that
# sets of lexical variables for variables found in the URL
# route, and performs suitable installation of the route.
#
package KavorkaX::Dancer2::Sub::HTTP
{
	use Parse::Keyword;
	
	use Moo;
	with qw( KavorkaX::Dancer2::RoutingSub );
	
	has http_methods => (is => 'ro', default => sub { [] });
	
	sub install_sub
	{
		my $self = shift;
		my $app  = $self->package->can('dancer_app')->();
		
		for my $method (map lc, @{$self->http_methods})
		{
			$app->add_route(
				method   => $method,
				regexp   => $self->http_route,
				code     => $self->body,
				options  => {},
			);
		}
		
		();
	}
	
	around parse => sub
	{
		my $next  = shift;
		my $class = shift;
		
		# This allows GET,HEAD /foo { ... }
		my @more_methods;
		lex_read_space;
		while (lex_peek eq ',')
		{
			lex_read(1);
			lex_read_space;
			Carp::Croak("Not a valid HTTP Method: ".lex_peek(12))
				unless lex_peek(12) =~ /\A($methods)/;
			
			push @more_methods, $1;
			lex_read( length $more_methods[-1] );
			lex_read_space;
		}
		
		my $self = $class->$next(@_);
		
		my $kw = $self->keyword;
		push @{$self->http_methods}, (lc $kw eq 'any') ? @methods : lc($kw);
		push @{$self->http_methods}, @more_methods;
		
		return $self;
	};
	
	sub http_prefix_variables
	{
		my $self  = shift;
		my $route = $KavorkaX::Dancer2::PREFIX;
		return if ref($route);
		return if !defined($route);
		
		$route =~ m{:(\w+)}g;
	}
	
	around inject_prelude => sub
	{
		my $next = shift;
		my $self = shift;
		
		my $prelude = $self->$next(@_);
		for my $var ( $self->http_route_variables )
		{
			$prelude .= sprintf('my $%s = params->{%s};', $var, B::perlstring($var));
		}
		for my $var ( $self->http_prefix_variables )
		{
			$prelude .= sprintf('$%s = params->{%s};', $var, B::perlstring($var));
		}
		$prelude .= '();';
		
		return $prelude;
	};
}

package KavorkaX::Dancer2::Sub::Prefix
{
	use Parse::Keyword;
	
	use Moo;
	with qw( KavorkaX::Dancer2::RoutingSub );
	
	sub install_sub
	{
		my $self = shift;
		my $app  = $self->package->can('dancer_app')->();
		
		return $app->lexical_prefix(
			$self->http_route,
			$self->body,
		);
	}
	
	around inject_prelude => sub
	{
		my $next = shift;
		my $self = shift;
		
		my $prelude = $self->$next(@_);
		for my $var ( $self->http_route_variables )
		{
			$prelude .= sprintf('my $%s;', $var);
		}
		$prelude .= '();';
		
		return $prelude;
	};
	
	around parse_body => sub
	{
		my $next = shift;
		my $self = shift;
		local $KavorkaX::Dancer2::PREFIX = $self->http_route;
		$self->$next(@_);
	};
}

package KavorkaX::Dancer2::Sub::Hook
{
	use Parse::Keyword;
	
	use Moo;
	with qw( Kavorka::Sub );
	
	sub is_anonymous { 1 }
	
	sub install_sub
	{
		my $self = shift;
		my $app  = $self->package->can('dancer_app')->();
		
		return $app->add_hook(
			Dancer2::Core::Hook->new(
				name => $self->declared_name,
				code => $self->body,
			),
		);
	}
	
	around inject_prelude => sub
	{
		my $next = shift;
		my $self = shift;
		
		my $prelude = $self->$next(@_);
		
		if ($self->declared_name eq 'after')
		{
			$prelude .= 'my $response = shift;();';
		}
		
		return $prelude;
	};
}

1;

