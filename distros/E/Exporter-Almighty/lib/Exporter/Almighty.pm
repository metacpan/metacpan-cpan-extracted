use 5.012;
use strict;
use warnings;

package Exporter::Almighty;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.001003';

use parent qw( Exporter::Tiny );

my @builtins;
BEGIN { @builtins = qw( is_bool created_as_string created_as_number ) };
use if $] lt '5.036000', 'builtins::compat' => @builtins;
use if $] ge '5.036000', 'builtin' => @builtins;
no if $] ge '5.036000', 'warnings' => qw( experimental::builtin );

use B                 qw( perlstring );
use Carp              qw( croak );
use Eval::TypeTiny    qw( eval_closure set_subname );
use Exporter::Tiny    qw( mkopt );
use Import::Into;
use Module::Runtime   qw( require_module module_notional_filename );
use Type::Registry    qw();
use Types::Common     qw(
	-sigs
	-types
	assert_Ref       is_Ref
	assert_ArrayRef  is_ArrayRef
	assert_HashRef   is_HashRef
	is_NonEmptySimpleStr
);

sub _exporter_validate_opts {
	my ( $me, $options ) = @_;
	my $into  = $options->{into};
	my $setup = $options->{setup};
	strict->import::into( $into );
	warnings->import::into( $into );
	$me->setup_for( $into, $setup );
}

# Subclasses may wish to provide a subclass of Exporter::Tiny here.
sub base_exporter {
	return 'Exporter::Tiny';
}

sub standard_package_variables {
	my ( $me, $into ) = @_;
	no strict 'refs';
	return (
		\@{"$into\::ISA"},
		\@{"$into\::EXPORT"},
		\@{"$into\::EXPORT_OK"},
		\%{"$into\::EXPORT_TAGS"},
	);
}

signature_for setup_for => (
	method  => 1,
	head    => [ NonEmptySimpleStr ],
	named   => [
		tag    => Optional[HashRef],
		also   => Optional[ArrayRef],
		enum   => Optional[HashRef[ArrayRef]],
		class  => Optional[ArrayRef],
		role   => Optional[ArrayRef],
		duck   => Optional[HashRef[ArrayRef]],
		type   => Optional[ArrayRef],
		const  => Optional[HashRef],
	],
);

sub setup_for {
	my ( $me, $into, $setup ) = @_;
	$INC{ module_notional_filename($into) } //= __FILE__;
	my @steps = $me->steps( $into, $setup );
	for my $step ( @steps ) {
		$me->$step( $into, $setup );
	}
	return;
}

# Subclasses can wrap this to easily add and remove steps.
sub steps {
	my ( $me, $into, $setup ) = @_;
	my @steps;
	push @steps, 'setup_exporter_for';
	push @steps, 'setup_reexports_for'            if $setup->{also};
	push @steps, 'setup_enums_for'                if $setup->{enum};
	push @steps, 'setup_classes_for'              if $setup->{class};
	push @steps, 'setup_roles_for'                if $setup->{role};
	push @steps, 'setup_ducks_for'                if $setup->{duck};
	push @steps, 'setup_types_for'                if $setup->{type};
	push @steps, 'setup_constants_for'            if $setup->{const};
	push @steps, 'finalize_export_variables_for';
	return @steps;
}

sub setup_exporter_for {
	my ( $me, $into, $setup ) = @_;
	
	my ( $into_ISA, undef, undef, $into_EXPORT_TAGS ) =
		$me->standard_package_variables( $into );
	
	# Set up @ISA in caller package.
	my $base = $me->base_exporter( $into, $setup );
	push @$into_ISA, $base unless $into->isa( $base );
	
	# Set up %EXPORT_TAGS in caller package.
	my %tags = %{ $setup->{tag} // {} };
	for my $tag_name ( keys %tags ) {
		my @exports = @{ assert_ArrayRef $tags{$tag_name} };
		$tag_name =~ s/^[-:]//;
		push @{ $into_EXPORT_TAGS->{$tag_name} //= [] }, @exports;
	}
	
	return;
}

sub setup_reexports_for {
	my ( $me, $into, $setup ) = @_;
	
	my $next = $into->can( '_exporter_validate_opts' );
	
	my $optlist = mkopt( $setup->{also} );
	require_module( $_->[0] ) for @$optlist;
	
	my $method_name = "$into\::_exporter_validate_opts";
	my $method_code = sub {
		my ( $class, $opts ) = @_;
		is_NonEmptySimpleStr( my $caller = $opts->{into} ) or return;
		for my $also ( @$optlist ) {
			my ( $module, $args ) = @$also;
			$module->import::into( $caller, @{ $args // [] } );
		}
		goto $next if $next;
	};
	no strict 'refs';
	*$method_name = set_subname $method_name => $method_code;
}

sub setup_enums_for {
	my ( $me, $into, $setup ) = @_;
	
	require Type::Tiny::Enum;
	my $reg = Type::Registry->for_class( $into );
	$me->_ensure_isa_type_library( $into );
	
	my %tags = %{ assert_HashRef $setup->{enum} // {} };
	for my $tag_name ( keys %tags ) {
		my $values = $tags{$tag_name};
		$tag_name =~ s/^[-:]//;
		my $type_name = $tag_name;
		$tag_name = lc $tag_name;
		
		Type::Tiny::Enum->import( { into => $into }, $type_name, $values );
		$into->add_type( $reg->lookup( $type_name ) );
	}
	
	return;
}

sub setup_classes_for {
	my ( $me, $into, $setup ) = @_;
	require Type::Tiny::Class;
	$me->_setup_classes_or_roles_for( $into, $setup, 'class', 'Type::Tiny::Class' );
}

sub setup_roles_for {
	my ( $me, $into, $setup ) = @_;
	require Type::Tiny::Role;
	$me->_setup_classes_or_roles_for( $into, $setup, 'role', 'Type::Tiny::Role' );
}

sub _setup_classes_or_roles_for {
	my ( $me, $into, $setup, $kind, $tt_class ) = @_;
	
	my $reg = Type::Registry->for_class( $into );
	$me->_ensure_isa_type_library( $into );
	
	my $optlist = mkopt( $setup->{$kind} );
	for my $dfn ( @$optlist ) {
		( my $pkg_name  = ( $dfn->[1] //= {} )->{$kind} // $dfn->[0] );
		( my $type_name = ( $dfn->[1] //= {} )->{name}  // $dfn->[0] ) =~ s/:://g;
		$tt_class->import( { into => $into }, @$dfn );
		$into->add_type( $reg->lookup( $type_name ) );
		eval { require_module( $pkg_name ) };
	}
	
	return;
}

sub setup_ducks_for {
	my ( $me, $into, $setup ) = @_;
	
	require Type::Tiny::Duck;
	my $reg = Type::Registry->for_class( $into );
	$me->_ensure_isa_type_library( $into );
	
	my %types = %{ assert_HashRef $setup->{duck} // {} };
	for my $type_name ( keys %types ) {
		my $values = $types{$type_name};
		Type::Tiny::Duck->import( { into => $into }, $type_name, $values );
		$into->add_type( $reg->lookup( $type_name ) );
	}
	
	return;
}

sub setup_types_for {
	my ( $me, $into, $setup ) = @_;
	
	my $reg = Type::Registry->for_class( $into );
	$me->_ensure_isa_type_library( $into );
	
	my $optlist = mkopt( $setup->{type} );
	my @extends = ();
	for my $dfn ( @$optlist ) {
		my ( $lib, $list ) = @$dfn;
		eval { require_module( $lib ) };
		if ( is_ArrayRef $list ) {
			for my $type_name ( @$list ) {
				$into->add_type( $lib->get_type( $type_name ) );
			}
		}
		else {
			push @extends, $lib;
		}
	}
	
	if ( @extends ) {
		require Type::Utils;
		my $wrapper = eval "sub { package $into; &Type::Utils::extends; }";
		$wrapper->( @extends );
	}
	
	return;
}

sub _ensure_isa_type_library {
	my ( $me, $into ) = @_;
	return if $into->isa( 'Type::Library' );
	my ( $old_isa ) = $me->standard_package_variables( $into );
	my $new_isa = [];
	my $saw_exporter_tiny = 0;
	for my $pkg ( @$old_isa ) {
		if ( $pkg eq 'Exporter::Tiny' ) {
			push @$new_isa, 'Type::Library';
			$saw_exporter_tiny++;
		}
		else {
			push @$new_isa, $pkg;
		}
	}
	push @$new_isa, 'Type::Library' unless $saw_exporter_tiny;
	@$old_isa = @$new_isa;
}

sub setup_constants_for {
	my ( $me, $into, $setup ) = @_;
	
	my ( $into_ISA, undef, undef, $into_EXPORT_TAGS ) =
		$me->standard_package_variables( $into );

	my %tags = %{ assert_HashRef $setup->{const} // {} };
	for my $tag_name ( keys %tags ) {
		my %exports = %{ assert_HashRef $tags{$tag_name} };
		$tag_name =~ s/^[-:]//;
		push @{ $into_EXPORT_TAGS->{$tag_name}   //= [] }, sort keys %exports;
		push @{ $into_EXPORT_TAGS->{'constants'} //= [] }, sort keys %exports;
		$me->make_constant_subs( $into, \%exports );
	}
	
	return;
}

sub make_constant_subs {
	my ( $me, $into, $constants ) = @_;
	
	for my $key ( keys %$constants ) {
		my $value = $constants->{$key};
		my $full_name = "$into\::$key";
		
		my $coderef;
		if ( is_Ref $value ) {
			$coderef = eval_closure(
				source      => 'sub () { $value }',
				environment => { '$value' => \$value },
			);
		}
		else {
			$coderef = eval sprintf(
				'sub () { %s %s }',
				is_bool( $value ) ? '!!' : ( created_as_number( $value ) ? '0+' : '' ),
				perlstring( $value ),
			);
		}
		
		no strict 'refs';
		*$full_name = set_subname $full_name => $coderef;
	}
}

sub finalize_export_variables_for {
	my ( $me, $into, $setup ) = @_;
	
	my ( $into_ISA, $into_EXPORT, $into_EXPORT_OK, $into_EXPORT_TAGS ) =
		$me->standard_package_variables( $into );
	
	my %all_exports;
	for my $list ( $into_EXPORT, $into_EXPORT_OK, values %{ $into_EXPORT_TAGS // {} } ) {
		is_ArrayRef $list or next;
		$all_exports{$_}++ for @$list;
	}
	@{ $into_EXPORT_OK } = sort keys %all_exports;
	
	my %default_exports;
	for my $list ( $into_EXPORT, $into_EXPORT_TAGS->{default} ) {
		is_ArrayRef $list or next;
		$default_exports{$_}++ for @$list;
	}
	@{ $into_EXPORT } = sort keys %default_exports;
	
	return;
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Exporter::Almighty - combining Exporter::Tiny with some other stuff for added power

=head1 SYNOPSIS

  package Your::Package;
  
  use v5.12;
  use Exporter::Almighty -setup => {
    tag => {
      foo => [ 'foo1', 'foo2' ],
      bar => [ 'bar1' ],
    },
    const => {
      colours => { RED => 'red', BLUE => 'blue', GREEN => 'green' },
    },
    enum => {
      Status => [ 'dead', 'alive' ],
    },
    also => [
      'strict',
      'Scalar::Util' => [ 'refaddr' ],
      'warnings',
    ],
  };
  
  sub foo1 { ... }
  sub foo2 { ... }
  sub bar1 { ... }
  
  1;

=head1 DESCRIPTION

This module aims to make building exporters easier. It is based on
L<Exporter::Tiny>, but helps you avoid manually setting C<< @EXPORT_OK >>,
C<< %EXPORT_TAGS >>, etc.

Exporter::Almighty supports lexical exports, even on Perl versions as old
as 5.12.

Exporter::Almighty indeed requires Perl 5.12, so it's strongly recommended
you add C<< use v5.12 >> (or higher) before C<< use Exporter::Almighty >>
so that your package can benefit from features which don't exist in legacy
versions of Perl.

=head2 Setup Options

Exporter::Almighty's own setup happens through its import. A setup hashref
is passed as per the example in the L</SYNOPSIS>. Each key in this hash is
a setup option.

The names are all short, singular names, in case you forget whether to use
C<tag> or C<tags>!

=head3 C<< tag >>

This is a hashref where the keys are tag names and the values are arrayrefs
of function names.

  use Exporter::Almighty -setup => {
    tag => {
      foo => [ 'foo1', 'foo2' ],
      bar => [ 'bar1' ],
    }
  };

A user of the package defined in the L</SYNOPSIS> could import:

  use Your::Package qw( foo1 foo2 bar1 );   # import functions by name
  use Your::Package qw( :foo );             # import 'foo1' and 'foo2'
  use Your::Package qw( -foo );             # same!

If you have a tag called C<default>, that is special. It will be
automatically exported if your caller doesn't provide an explicit
list of things they want to import.

The following other tags also have special meanings: C<constants>,
C<types>, C<assert>, C<is>, C<to>, and C<all>.

By convention, tags names should be snake_case.

=head3 C<< const >>

Similar to C<< tag >> this is a hashref where keys are tag names, but instead
of the values being arrayrefs of function names, they are hashrefs which
define constants.

  use Exporter::Almighty -setup => {
    const => {
      colours => { RED => 'red', BLUE => 'blue', GREEN => 'green' },
    },
  };

A user of the package defined in the L</SYNOPSIS> could import:

  use Your::Package qw( RED GREEN BLUE );   # import constants by name
  use Your::Package qw( :colours );         # import 'colours' constants
  use Your::Package qw( :constants );       # import ALL constants

By convention, the tag names should be snake_case, but constant names
should be SHOUTING_SNAKE_CASE.

=head3 C<< type >>

This is an arrayref of type libraries. Each library listed will be I<imported>
into your exporter, and then the types in it will be I<re-exported> to the
people who use your package. Each type library can optionally be followed by an
arrayref of type names if you don't want to just import all types.

  package Your::Package;
  
  use Exporter::Almighty -setup => {
    tags => {
      foo => [ 'foo1', 'foo2' ],
    },
    type => [
      'Types::Standard',
      'Types::Common::String'  => [ 'NonEmptyStr' ],
      'Types::Common::Numeric' => [ 'PositiveInt', 'PositiveOrZeroInt' ],
    ],
  };
  
  sub foo1 { ... }
  sub foo2 { ... }
  
  ...;
  
  package main;
  
  use Your::Package qw( -foo is_NonEmptyStr );
  
  my $got = foo1();
  if ( is_NonEmptyStr( $got ) ) {
    foo2();
  }

If you re-export types like this, then your module will be "promoted" to being
a subclass of L<Type::Library> instead of L<Exporter::Tiny>. (Type::Library is
itself a subclass of Exporter::Tiny, so you don't miss out on any features.)

=head3 C<< enum >>

This is a hashref where keys are enumerated type names, and the values are
arrayrefs of strings.

  use Exporter::Almighty -setup => {
    enum => {
      Status => [ 'dead', 'alive' ],
    },
  };

A user of the package defined in the L</SYNOPSIS> could import:

  use Your::Package qw(
    Status
    is_Status
    assert_Status
    to_Status
    STATUS_ALIVE
    STATUS_DEAD
  );
  use Your::Package qw( +Status );  # shortcut for the above

The C<Status> function exported by the above will return a L<Type::Tiny::Enum>
object.

The C<< :types >>, C<< :is >>, C<< :assert >>, C<< :to >>, and C<< :constants >>
tags will also automatically include the relevent exports.

If you export any enums then your module will be "promoted" from being an
L<Exporter::Tiny> to being a L<Type::Library>.

By convention, enum types should be UpperCamelCase.

=head3 C<< class >>

This is an arrayref of class names.

  use Exporter::Almighty -setup => {
    class => [
      'HTTP::Tiny',
      'LWP::UserAgent',
    ],
  };

People can import:

  use Your::Package qw( +HTTPTiny +LWPUserAgent );
  
  unless ( is_HTTPTiny($x) or is_LWPUserAgent($x) ) {
    $x = HTTPTiny->new();
  }

These create L<Type::Tiny::Class> type constraints similar to how C<enum>
works. It will similarly promote your exporter to a L<Type::Library>.

Notice that the C<new> method will be proxied through to the underlying
class, so these can also work as useful aliases for long class names.

  use Exporter::Almighty -setup => {
    class => [
      'ShortName' => { class => 'Very::Long::Class::Name' },
      'TinyName'  => { class => 'An::Even::Longer::Class::Name' },
    ],
  };

Exporter::Almighty will attempt to pre-emptively load modules mentioned here,
so you don't need to do it yourself. However if the modules don't exist, it
won't complain.

=head3 C<< role >>

This works the same as C<class>, except for roles.

=head3 C<< duck >>

This is a hashref where keys are "duck type" type names, and the values are
arrayrefs of method names.

  use Exporter::Almighty -setup => {
    duck => [
      'UserAgent' => [ 'head', 'get', 'post' ],
    ],
  };

These create L<Type::Tiny::Duck> type constraints similar to how C<enum>
works. It will similarly promote your exporter to be a L<Type::Library>.

=head3 C<< also >>

A list of other packages to also export to your caller. Each package name
can optionally be followed by an arrayref of import arguments.

  use Exporter::Almighty -setup => {
    also => [
      'strict',
      'Scalar::Util' => [ 'refaddr' ],
      'warnings',
    ],
  };

Your caller isn't given any options allowing them to opt in or out of this,
so it is recommended that this be used sparingly. L<strict>, L<warnings>,
L<feature>, L<experimental>, and L<namespace::autoclean> are good packages to
consider listing here. Packages that export named functions are less good.

=head2 API

Instead of:

  package Your::Package;
  use Exporter::Almighty -setup => \%setup;

It is possible to do this at run-time:

  Exporter::Almighty->setup_for( 'Your::Package', %setup );

This may allow slightly more flexibility in some cases.

Exporter::Almighty is also designed to be easily subclassable.

=head2 Exporter::Tiny features you get for free

=head3 Features for you

Exporter::Almighty will import L<strict> and L<warnings> into your package.

You can export package variables, though it's rarely a good idea:

  package Your::Package;
  
  use Exporter::Almighty -setup => {
    tag => { default => [ 'xxx', '$YYY' ] },
  };
  
  our $YYY = 42;

You can use generators:

  package Your::Package;
  
  use Exporter::Almighty -setup => {
    tag => { default => [ 'xxx' ] },
  };
  
  sub _generate_xxx {
    my ( $me, $name, $vals, $opts ) = @_;
    my $caller = $opts->{into};
    
    # Return the sub which will be installed into caller as 'xxx'.
    return sub {
    };
  }
  
  ...;
  
  package main;
  use Your::Package 'xxx' => \%vals;
  
  xxx( ... );

=head3 Features for your caller

Your caller can do lexical imports:

  use Your::Package -lexical, qw( ... );

Your caller can rename imported functions:

  use Your::Package foo => { -as => 'foofoo' };

And everything else described in L<Exporter::Tiny::Manual::Importing>.

=head1 BUGS

Please report any bugs to
L<https://github.com/tobyink/p5-exporter-almighty/issues>.

=head1 SEE ALSO

L<Exporter::Tiny>, L<Exporter::Shiny>.

L<CXC::Exporter::Util> was an inspiration for this module and the features
overlap a bit.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2023 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

