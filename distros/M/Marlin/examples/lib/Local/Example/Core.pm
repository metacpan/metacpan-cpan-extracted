use v5.40.0;
use experimental 'class';
use Types::Common -lexical, -assert;

push @Local::Example::ALL, 'Local::Example::Core';

class Local::Example::Core::NamedThing {
	field $name :reader :param = die "Name is required";
	
	ADJUST {
		assert_Str $name;
	}
}

package Local::Example::Core::DoesIntro {
	use Role::Tiny;
	
	requires 'name';
	
	sub introduction ( $self ) {
		return sprintf( "Hi, my name is %s!", $self->name );
	}
}

class Local::Example::Core::Person
		:isa(Local::Example::Core::NamedThing) {
	
	field $age :reader :param = undef;
	
	use Role::Tiny::With;
	with 'Local::Example::Core::DoesIntro';
	
	method has_age () {
		return defined $age;
	}
}

class Local::Example::Core::Employee
		:isa(Local::Example::Core::Person) {
	
	field $employee_id :reader :param = die "Employee id is required";
}

class Local::Example::Core::Employee::Developer
		:isa(Local::Example::Core::Employee) {
	
	field $languages :reader(get_languages) = [];
	
	method add_language ( @lang ) {
		push $languages->@*, map { assert_Str $_ } @lang;
	}
	
	method all_languages () {
		return $languages->@*;
	}
	
	method clear_languages () {
		$languages = [];
	}
	
	method introduction ( @args ) {
		my $orig = $self->next::method( @args );
		if ( my @lang = $self->all_languages ) {
			return sprintf( "%s I know: %s.", $orig, join q[, ], @lang );
		}
		return $orig;
	};
}

1;
