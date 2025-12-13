use v5.20.0;
use experimental 'signatures';
use Types::Common -lexical, -types, -assert, 'signature_for';

push @Local::Example::ALL, 'Local::Example::Tiny';

package Local::Example::Tiny::NamedThing {
	use Class::Tiny { name => sub { die "Name is required" } };
	
	sub EXPECTED_KEYS {
		return qr/\A(name)\z/;
	}
	
	sub BUILD ( $self, $args ) {
		my $expected = $self->EXPECTED_KEYS;
		die if grep !/$expected/, keys %$args;
		
		assert_Str( $args->{name} );
	}
}

package Local::Example::Tiny::DoesIntro {
	use Role::Tiny;
	
	requires 'name';
	
	sub introduction ( $self ) {
		return sprintf( "Hi, my name is %s!", $self->name );
	}
}

package Local::Example::Tiny::Person {
	use parent -norequire, 'Local::Example::Tiny::NamedThing';
	use Class::Tiny 'age';
	
	use Role::Tiny::With;
	with 'Local::Example::Tiny::DoesIntro';
	
	sub has_age ( $self ) {
		exists $self->{age};
	}

	sub EXPECTED_KEYS {
		return qr/\A(name|age)\z/;
	}
}

package Local::Example::Tiny::Employee {
	use parent -norequire, 'Local::Example::Tiny::Person';
	use Class::Tiny { employee_id => sub { "Employee id is required" } };

	sub EXPECTED_KEYS {
		return qr/\A(name|age|employee_id)\z/;
	}
}

package Local::Example::Tiny::Employee::Developer {
	use parent -norequire, 'Local::Example::Tiny::Employee';
	
	sub _languages;
	use Class::Tiny { '_languages' => sub { [] } };

	sub get_languages ( $self ) {
		$self->{_languages} //= [];
	}
	
	sub clear_languages ( $self ) {
		delete $self->{_languages};
	}
	
	use Sub::HandlesVia 'delegations';
	
	delegations(
		attribute   => [ 'get_languages', '{_languages}' ],
		handles_via => 'Array',
		handles     => {
			add_language  => 'push',
			all_languages => 'elements',
		}
	);
	
	signature_for add_language => (
		method => !!1,
		pos    => [ Str ],
	);
	
	sub introduction ( $self, @args ) {
		my $orig = $self->next::method( @args );
		if ( my @lang = $self->all_languages ) {
			return sprintf( "%s I know: %s.", $orig, join q[, ], @lang );
		}
		return $orig;
	}
}

1;
