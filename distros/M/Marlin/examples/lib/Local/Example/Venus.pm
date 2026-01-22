use v5.36;

push @Local::Example::ALL, 'Local::Example::Venus';

sub strict::constructor ( $self, $data ) {
	use List::Util ();
	my @attrs = $self->meta->attrs->@*;
	for my $k ( sort keys %$data ) {
		die "Bad argument passed to constructor: $k"
			unless List::Util::any { $_ eq $k } @attrs;
	}
}

package Local::Example::Venus::Simple {
	use Venus::Class;
	attr 'foo';
	attr 'bar';
	
	sub BUILD ( $self, $data ) {
		$self->strict::constructor( $data );
	}
}

package Local::Example::Venus::NamedThing {
	use Venus::Class;
	use Venus::Check;
	
	my $ATTR = Venus::Check->new;
	
	attr 'name';
	$ATTR->attributes( name => 'string' );
	
	sub BUILD ( $self, $data ) {
		$ATTR->result( $self );
		$self->strict::constructor( $data );
	}
}

package Local::Example::Venus::DoesIntro {
	use Venus::Role;
	
	sub introduction ( $self ) {
		return sprintf( "Hi, my name is %s!", $self->name );
	}
	
	sub AUDIT ( $role, $into ) {
		die "$into is missing 'name'" unless $into->can( 'name' );
	}
	
	sub EXPORT {
		return [ 'introduction' ];
	}
}

package Local::Example::Venus::Person {
	use Venus::Class;
	
	base 'Local::Example::Venus::NamedThing';
	with 'Local::Example::Venus::DoesIntro';
	
	attr 'age';
	
	sub has_age ( $self ) {
		return exists $self->{age};
	}
	
	sub BUILD ( $self, $data ) {
		$self->SUPER::BUILD( $data );
		$self->strict::constructor( $data );
	}
}

package Local::Example::Venus::Employee {
	use Venus::Class;
	
	base 'Local::Example::Venus::Person';
	
	my $ATTR = Venus::Check->new;
	
	attr 'employee_id';
	$ATTR->attributes( employee_id => 'defined' );
	
	sub BUILD ( $self, $data ) {
		$self->SUPER::BUILD( $data ); # Not automatically called
		$ATTR->result( $self );
		$self->strict::constructor( $data );
	}
}

package Local::Example::Venus::Employee::Developer {
	use Venus::Class qw( base mask around );
	
	base 'Local::Example::Venus::Employee';
	
	mask 'languages';
	
	sub BUILD ( $self, $data ) {
		$self->SUPER::BUILD( $data ); # Not automatically called
		$self->languages( [] ) unless $data->{languages};
		$self->strict::constructor( $data );
	}
	
	sub get_languages ( $self ) {
		return $self->languages;
	}
	
	my $lang_check = Venus::Check->new;
	$lang_check->string;
	sub add_language ( $self, @lang ) {
		push $self->languages->@*, map { $lang_check->result( $_ ) } @lang;
	}
	
	sub all_languages ( $self ) {
		return $self->languages->@*;
	}
	
	sub clear_languages ( $self ) {
		$self->languages( [] );
	}
	
	around introduction => sub ( $next, $self, @args ) {
		my $orig = $self->$next( @args );
		if ( my @lang = $self->all_languages ) {
			return sprintf( "%s I know: %s.", $orig, join q[, ], @lang );
		}
		return $orig;
	};
}

1;
