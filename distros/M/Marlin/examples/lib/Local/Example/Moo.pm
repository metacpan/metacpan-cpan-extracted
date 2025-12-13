use v5.20.0;
use experimental 'signatures';
use Types::Common -lexical, -types;

push @Local::Example::ALL, 'Local::Example::Moo';

package Local::Example::Moo::NamedThing {
	use Moo;
	use MooX::StrictConstructor -late;
	use MooX::TypeTiny;
	
	has name => ( is => 'ro', isa => Str, required => 1 );
}

package Local::Example::Moo::DoesIntro {
	use Moo::Role;
	
	requires 'name';
	
	sub introduction ( $self ) {
		return sprintf( "Hi, my name is %s!", $self->name );
	}
}

package Local::Example::Moo::Person {
	use Moo;
	use MooX::StrictConstructor -late;
	
	extends 'Local::Example::Moo::NamedThing';
	with 'Local::Example::Moo::DoesIntro';
	
	has age => ( is => 'ro', predicate => 1 );
}

package Local::Example::Moo::Employee {
	use Moo;
	use MooX::StrictConstructor -late;
	
	extends 'Local::Example::Moo::Person';
	
	has employee_id => ( is => 'ro', required => 1 );
}

package Local::Example::Moo::Employee::Developer {
	use Moo;
	use MooX::StrictConstructor -late;
	use MooX::TypeTiny;
	use Sub::HandlesVia;
	
	extends 'Local::Example::Moo::Employee';
	
	has _languages => (
		init_arg    => undef,
		is          => 'lazy',
		reader      => 'get_languages',
		clearer     => 'clear_languages',
		isa         => ArrayRef[Str],
		default     => sub ($self) { [] },
		handles_via => 'Array',
		handles     => {
			add_language  => 'push',
			all_languages => 'elements',
		},
	);
	
	around introduction => sub ( $next, $self, @args ) {
		my $orig = $self->$next( @args );
		if ( my @lang = $self->all_languages ) {
			return sprintf( "%s I know: %s.", $orig, join q[, ], @lang );
		}
		return $orig;
	};
}

1;