use v5.20.0;
use experimental 'signatures';

push @Local::Example::ALL, 'Local::Example::Plain';

package Local::Example::Plain::NamedThing {
	use mro 'c3';
	
	sub new ( $invocant, @args ) {
		my $class = ref($invocant) || $invocant;
		my %args = ( @args==1 and ref($args[0]) eq 'HASH' ) ? %{shift(@args)} : @args;
		
		my $self = bless( {}, $class );
		
		die "Expected name" if !exists $args{name};
		die if ( !defined $args{name} or ref $args{name} );
		$self->{name} = $args{name};
		
		if ( $class eq __PACKAGE__ ) {
			unless ( $args{__no_BUILD__} ) {
				our $BUILD_CACHE ||= do {
					no strict 'refs';
					my $linear_isa = mro::get_linear_isa($class);
					[ map { ( *{$_}{CODE} ) ? ( *{$_}{CODE} ) : () } map { "$_\::BUILD" } reverse @$linear_isa ];
				};
				$_->( $self, \%args ) for $BUILD_CACHE->@*;
			}
			my @unknown = grep !/\A(?:name)\z/, keys %args;
			die "Unknown parameters: @unknown" if @unknown;
		}
		
		return $self;
	}
	
	sub name ( $self ) {
		return $self->{name};
	}
}

package Local::Example::Plain::DoesIntro {
	sub introduction ( $self ) {
		return sprintf( "Hi, my name is %s!", $self->name );
	}
	sub WITH ( $role, $target=undef ) {
		no strict 'refs';
		$target //= caller;
		
		*{"$target\::$_"} = \&{"$role\::$_"} for qw/introduction/;
		
		my $next = $target->can('DOES');
		*{"$target\::DOES"} = sub ( $self, $query ) {
			$query eq $role or $self->$next( $query );
		};
		
		return;
	}
}

package Local::Example::Plain::Person {
	use mro 'c3';
	use parent -norequire, 'Local::Example::Plain::NamedThing';
	Local::Example::Plain::DoesIntro->WITH;

	sub new ( $invocant, @args ) {
		my $class = ref($invocant) || $invocant;
		my %args = ( @args==1 and ref($args[0]) eq 'HASH' ) ? %{shift(@args)} : @args;
		
		my $self = $invocant->SUPER::new( %args, __no_BUILD__ => 1 );
		
		$self->{age} = $args{age} if exists $args{age};
		
		if ( $class eq __PACKAGE__ ) {
			unless ( $args{__no_BUILD__} ) {
				our $BUILD_CACHE ||= do {
					no strict 'refs';
					my $linear_isa = mro::get_linear_isa($class);
					[ map { ( *{$_}{CODE} ) ? ( *{$_}{CODE} ) : () } map { "$_\::BUILD" } reverse @$linear_isa ];
				};
				$_->( $self, \%args ) for $BUILD_CACHE->@*;
			}
			my @unknown = grep !/\A(?:name|age)\z/, keys %args;
			die "Unknown parameters: @unknown" if @unknown;
		}
		
		return $self;
	}
	
	sub age ( $self ) {
		return $self->{age};
	}
	
	sub has_age ( $self ) {
		return exists $self->{age};
	}
}

package Local::Example::Plain::Employee {
	use mro 'c3';
	use parent -norequire, 'Local::Example::Plain::Person';
	
	sub new ( $invocant, @args ) {
		my $class = ref($invocant) || $invocant;
		my %args = ( @args==1 and ref($args[0]) eq 'HASH' ) ? %{shift(@args)} : @args;
		
		my $self = $invocant->SUPER::new( %args, __no_BUILD__ => 1 );
		
		die "Expected employee_id" if !exists $args{employee_id};
		$self->{employee_id} = $args{employee_id};
		
		if ( $class eq __PACKAGE__ ) {
			unless ( $args{__no_BUILD__} ) {
				our $BUILD_CACHE ||= do {
					no strict 'refs';
					my $linear_isa = mro::get_linear_isa($class);
					[ map { ( *{$_}{CODE} ) ? ( *{$_}{CODE} ) : () } map { "$_\::BUILD" } reverse @$linear_isa ];
				};
				$_->( $self, \%args ) for $BUILD_CACHE->@*;
			}
			my @unknown = grep !/\A(?:name|age|employee_id)\z/, keys %args;
			die "Unknown parameters: @unknown" if @unknown;
		}
		
		return $self;
	}
	
	sub employee_id ( $self ) {
		return $self->{employee_id};
	}
}

package Local::Example::Plain::Employee::Developer {
	use mro 'c3';
	use parent -norequire, 'Local::Example::Plain::Employee';

	sub new ( $invocant, @args ) {
		my $class = ref($invocant) || $invocant;
		my %args = ( @args==1 and ref($args[0]) eq 'HASH' ) ? %{shift(@args)} : @args;
		
		my $self = $invocant->SUPER::new( %args, __no_BUILD__ => 1 );
		
		if ( $class eq __PACKAGE__ ) {
			unless ( $args{__no_BUILD__} ) {
				our $BUILD_CACHE ||= do {
					no strict 'refs';
					my $linear_isa = mro::get_linear_isa($class);
					[ map { ( *{$_}{CODE} ) ? ( *{$_}{CODE} ) : () } map { "$_\::BUILD" } reverse @$linear_isa ];
				};
				$_->( $self, \%args ) for $BUILD_CACHE->@*;
			}
			my @unknown = grep !/\A(?:name|age|employee_id)\z/, keys %args;
			die "Unknown parameters: @unknown" if @unknown;
		}
		
		return $self;
	}
	
	sub get_languages ( $self ) {
		$self->{_languages} //= [];
	}
	
	sub clear_languages ( $self ) {
		delete $self->{_languages};
	}
	
	sub add_language ( $self, @langs ) {
		for my $lang ( @langs ) {
			die if ( !defined $lang or ref $lang );
		}
		push $self->get_languages->@*, @langs;
	}
	
	sub all_languages ( $self ) {
		return $self->get_languages->@*;
	}
	
	sub introduction ( $self, @args ) {
		my $orig = $self->SUPER::introduction( @args );
		if ( my @lang = $self->all_languages ) {
			return sprintf( "%s I know: %s.", $orig, join q[, ], @lang );
		}
		return $orig;
	}
}

1;
