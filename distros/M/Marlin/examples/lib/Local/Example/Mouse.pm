use v5.20.0;
use experimental 'signatures';

push @Local::Example::ALL, 'Local::Example::Mouse';

package Local::Example::Mouse::Simple {
	use Mouse;
	use MouseX::StrictConstructor;
	has foo => qw( is ro );
	has bar => qw( is ro );
}

package Local::Example::Mouse::NamedThing {
	use Mouse;
	use MouseX::StrictConstructor;
	
	has name => ( is => 'ro', isa => 'Str', required => 1 );
	
	__PACKAGE__->meta->make_immutable;
}

package Local::Example::Mouse::DoesIntro {
	use Mouse::Role;
	
	requires 'name';
	
	sub introduction ( $self ) {
		return sprintf( "Hi, my name is %s!", $self->name );
	}
}

package Local::Example::Mouse::Person {
	use Mouse;
	use MouseX::StrictConstructor;
	
	extends 'Local::Example::Mouse::NamedThing';
	with 'Local::Example::Mouse::DoesIntro';
	
	has age => ( is => 'ro', predicate => 'has_age' );
	
	__PACKAGE__->meta->make_immutable;
}

package Local::Example::Mouse::Employee {
	use Mouse;
	use MouseX::StrictConstructor;
	
	extends 'Local::Example::Mouse::Person';
	
	has employee_id => ( is => 'ro', required => 1 );
	
	__PACKAGE__->meta->make_immutable;
}

package Local::Example::Mouse::Employee::Developer {
	use Mouse;
	use MouseX::StrictConstructor;
	use MouseX::NativeTraits ();
	
	extends 'Local::Example::Mouse::Employee';
	
	has _languages => (
		init_arg    => undef,
		is          => 'ro',
		lazy        => 1,
		reader      => 'get_languages',
		clearer     => 'clear_languages',
		isa         => 'ArrayRef[Str]',
		default     => sub ($self) { [] },
		traits      => [ 'Array' ],
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
	
	__PACKAGE__->meta->make_immutable;
}

1;
