use v5.20.0;
use experimental 'signatures';

push @Local::Example::ALL, 'Local::Example::Moose';

package Local::Example::Moose::NamedThing {
	use Moose;
	use MooseX::StrictConstructor;
	
	has name => ( is => 'ro', isa => 'Str', required => 1 );
	
	__PACKAGE__->meta->make_immutable;
}

package Local::Example::Moose::DoesIntro {
	use Moose::Role;
	
	requires 'name';
	
	sub introduction ( $self ) {
		return sprintf( "Hi, my name is %s!", $self->name );
	}
}

package Local::Example::Moose::Person {
	use Moose;
	use MooseX::StrictConstructor;
	
	extends 'Local::Example::Moose::NamedThing';
	with 'Local::Example::Moose::DoesIntro';
	
	has age => ( is => 'ro', predicate => 'has_age' );
	
	__PACKAGE__->meta->make_immutable;
}

package Local::Example::Moose::Employee {
	use Moose;
	use MooseX::StrictConstructor;
	
	extends 'Local::Example::Moose::Person';
	
	has employee_id => ( is => 'ro', required => 1 );
	
	__PACKAGE__->meta->make_immutable;
}

package Local::Example::Moose::Employee::Developer {
	use Moose;
	use MooseX::StrictConstructor;
	
	extends 'Local::Example::Moose::Employee';
	
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
