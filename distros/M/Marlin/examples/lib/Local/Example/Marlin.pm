use v5.20.0;
use experimental 'signatures';
use Marlin::Util -lexical, -all;
use Types::Common -lexical, -types;

push @Local::Example::ALL, 'Local::Example::Marlin';

package Local::Example::Marlin::NamedThing {
	use Marlin -strict, 'name!' => Str;
}

package Local::Example::Marlin::DoesIntro {
	use Role::Tiny;
	
	requires 'name';
	
	sub introduction ( $self ) {
		return sprintf( "Hi, my name is %s!", $self->name );
	}
}

package Local::Example::Marlin::Person {
	use Marlin
		-strict,
		-extends => [ 'Local::Example::Marlin::NamedThing' ],
		-with    => [ 'Local::Example::Marlin::DoesIntro' ],
		qw( age? );
}

package Local::Example::Marlin::Employee {
	use Marlin
		-strict,
		-extends => [ 'Local::Example::Marlin::Person' ],
		qw( employee_id! );
}

package Local::Example::Marlin::Employee::Developer {
	use Marlin
		-strict,
		-extends => [ 'Local::Example::Marlin::Employee' ],
		-modifiers,
		_languages => {
			is          => lazy,
			isa         => ArrayRef[Str],
			init_arg    => undef,
			reader      => 'get_languages',
			clearer     => 'clear_languages',
			default     => [],
			handles_via => 'Array',
			handles     => {
				add_language  => 'push',
				all_languages => 'elements',
			}
		};
		
	around introduction => sub ( $next, $self, @args ) {
		my $orig = $self->$next( @args );
		if ( my @lang = $self->all_languages ) {
			return sprintf( "%s I know: %s.", $orig, join q[, ], @lang );
		}
		return $orig;
	};
}

1;
