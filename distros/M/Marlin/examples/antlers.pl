BEGIN {
	$INC{'Marlin/Antlers.pm'} = __FILE__;
	$INC{'Marlin/Antlers/Role.pm'} = __FILE__;
	
	package Marlin::Antlers;
	
	use v5.20;
	use experimental qw( signatures postderef lexical_subs );
	use feature ();
	use strict;
	use warnings;	
	
	use B::Hooks::AtRuntime qw( at_runtime after_runtime );
	use Class::Method::Modifiers qw( install_modifier );
	use Exporter::Tiny;
	use Import::Into;
	use Marlin ();
	use Marlin::Role ();
	use Marlin::Util ();
	use Types::Common -lexical, -all;
	
	our @ISA    = qw( Exporter::Tiny );
	our @EXPORT = qw( has extends with before after around fresh __FINALIZE__ );
	
	sub _exporter_validate_opts ( $me, $globals ) {
		
		my $pkg = $globals->{into};
		$globals->{installer} ||= $me->_exporter_lexical_installer( $globals );
		
		experimental->import::into( $pkg, qw( signatures postderef lexical_subs ) );
		feature->import::into( $pkg, qw( current_sub evalbytes fc say state unicode_eval unicode_strings ) );
		strict->import::into( $pkg );
		warnings->import::into( $pkg );
		
		Marlin::Util->import::into( $pkg, -lexical, -all );
		Types::Common->import::into( $pkg, -lexical, -all );
		
		my $kind = $globals->{role} ? 'Marlin::Role' : 'Marlin';
		my $args = $globals->{MARLIN} = {
			caller      => $pkg,
			this        => $pkg,
			parents     => [],
			roles       => [],
			attributes  => [],
			plugins     => [],
			delayed     => [],
			strict      => !( $globals->{sloppy} ),
			constructor => $globals->{constructor} // 'new',
			modifiers   => !!0,
		};
		my $mods = $globals->{MODIFY} = [];
		
		my $finalize = $globals->{FINALIZE} = sub () {
			state $finalized = 0;
			return if $finalized++;
			my $marlin = $kind->_new( $args );
			$marlin->store_meta;
			$marlin->do_setup;
			install_modifier( $pkg, @$_ ) for $mods->@*;
		};
		
		&after_runtime( $finalize );
	}
	
	sub _generate_has ( $me, $name, $value, $globals ) {
		return sub ( $names, @spec ) {
			
			is_ArrayRef $names
				or $names = [ $names ];
			assert_Str $_ for $names->@*;
			
			my $spec = ( @spec == 0 ) ? {} : ( @spec == 1 ) ? $spec[0] : { @spec };
			if ( is_Object $spec and $spec->DOES('Type::API::Constraint') ) {
				my $tc = $spec;
				$spec = {
					isa      => $tc,
					coerce   => !!( $tc->DOES('Type::API::Constraint::Coercible') and $tc->has_coercion ),
				};
			}
			elsif ( is_CodeRef $spec ) {
				$spec = {
					lazy     => !!1,
					builder  => $spec,
				};
			}
			
			for my $name ( $names->@* ) {
				my $default_init_arg = exists( $spec->{constant} ) ? undef : $name;
				push $globals->{MARLIN}{attributes}->@*, {
					is        => 'ro',
					init_arg  => $default_init_arg,
					%$spec,
					slot      => $name,
				};
			}
		};
	}

	sub _generate_extends ( $me, $name, $value, $globals ) {
		return sub ( @packages ) {
			
			assert_Str $_ for @packages;
			
			push $globals->{MARLIN}{parents}->@*,
				map [ split /\s+/ ],
				@packages;
		};
	}

	sub _generate_with ( $me, $name, $value, $globals ) {
		return sub ( @packages ) {
			
			assert_Str $_ for @packages;
			
			push $globals->{MARLIN}{roles}->@*,
				map [ split /\s+/ ],
				@packages;
		};
	}


	sub _generate_requires ( $me, $name, $value, $globals ) {
		return sub ( @methods ) {
			
			assert_Str $_ for @methods;
			
			$globals->{MARLIN}{requires} //= [];
			push $globals->{MARLIN}{requires}->@*, @methods;
		};
	}
	
	sub _generate_before ( $me, $name, $value, $globals ) {
		return $me->_for_cmm( before => $globals );
	}

	sub _generate_after ( $me, $name, $value, $globals ) {
		return $me->_for_cmm( after => $globals );
	}

	sub _generate_around ( $me, $name, $value, $globals ) {
		return $me->_for_cmm( around => $globals );
	}

	sub _generate_fresh ( $me, $name, $value, $globals ) {
		return $me->_for_cmm( fresh => $globals );
	}
	
	sub _for_cmm ( $me, $kind, $globals ) {
		return sub ( @names ) {
			
			my $coderef = pop @names;
			assert_CodeRef $coderef;
			
			push $globals->{MODIFY}->@*, [ $kind, @names, $coderef ];
		};
	}

	sub _generate___FINALIZE__ ( $me, $name, $value, $globals ) {
		return $globals->{FINALIZE};
	}
	
	package Marlin::Antlers::Role;
	
	use v5.20;
	use experimental qw( signatures postderef lexical_subs );
	use feature ();
	use strict;
	use warnings;	

	use Role::Tiny ();

	require Marlin::Antlers;
	our @ISA    = qw( Marlin::Antlers );
	our @EXPORT = qw( has with requires before after around __FINALIZE__ );
	
	sub import {
		my $me      = shift;
		my $globals = +{ @_ && ref($_[0]) eq q(HASH) ? %{+shift} : () };
		$globals->{role} = 1;
		delete $globals->{constructor};
		delete $globals->{sloppy};
		
		unshift @_, $globals;
		unshift @_, $me;
		goto &Exporter::Tiny::import;
	}

	sub _for_cmm ( $me, $kind, $globals ) {
		return sub ( @names ) {
			
			my $coderef = pop @names;
			assert_CodeRef $coderef;
			
			push @{$Role::Tiny::INFO{$globals->{into}}{modifiers}||=[]}, [ $kind, @names, $coderef ];
		};
	}
};

package Local::Wibble {
	use Marlin::Antlers::Role;
	after foo => sub ( $self ) { say "fetched foo" };
}

package Local::Wobble {
	use Marlin::Antlers::Role;
	with 'Local::Wibble';
}

package Local::Foo {
	use Marlin::Antlers;
	has foo => ();
}

package Local::FooBar {
	use Marlin::Antlers;
	extends 'Local::Foo';
	with 'Local::Wobble';
	has bar => Int;
}

my $x = Local::FooBar->new( foo => 2, bar => 3 );
print $x->foo, "\n";
