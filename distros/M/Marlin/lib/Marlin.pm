use 5.008008;
use strict;
use warnings;
use utf8;

package Marlin;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.022001';

use constant { true => !!1, false => !!0 };
use Types::Common qw( -is -types to_TypeTiny );

my $PackageTuple;
BEGIN { $PackageTuple = Tuple[NonEmptyStr,Optional[Str]] };

use constant _ATTRS => (
	this                      => { isa => NonEmptyStr,              required => true },
	attributes                => { isa => ArrayRef[HashRef|Object], default => [] },
	caller                    => { isa => Maybe[NonEmptyStr],       default => undef },
	cleanups                  => { isa => ArrayRef,                 default => [] },
	constructor               => { isa => NonEmptyStr,              default => 'new' },
	delayed                   => { isa => Maybe[ArrayRef[CodeRef]], default => [] },
	inhaled_from              => { isa => Maybe[NonEmptyStr],       default => undef },
	is_struct                 => { isa => Bool,                     default => false },
	modifiers                 => { isa => Bool,                     default => false },
	parents                   => { isa => ArrayRef[$PackageTuple],  default => [] },
	plugins                   => { isa => ArrayRef[Tuple[Str,Any]], default => [] },
	roles                     => { isa => ArrayRef[$PackageTuple],  default => [] },
	setup_steps_with_plugins  => { isa => ArrayRef[NonEmptyStr],    default => [] },
	strict                    => { isa => Bool,                     default => true },
	short_name                => { isa => NonEmptyStr,              builder => '_build_short_name' },
);

use Class::XSConstructor  _ATTRS, '!!';
use Class::XSReader       _ATTRS;
use Class::XSDestructor;

use B                     ();
use List::Util            ();
use Marlin::Util          ();
use Scalar::Util          ();
use Sub::Accessor::Small  ();

use constant {
	_HAS_NATIVE_LEXICAL_SUB  => !!( "$]" >= 5.037002 ),
	_HAS_MODULE_LEXICAL_SUB  => !!( "$]" >= 5.011002 and eval 'require Lexical::Sub; 1' ),
	_NEEDS_MRO_COMPAT        => !!( "$]" < 5.010 ),
};

require MRO::Compat if _NEEDS_MRO_COMPAT;
require namespace::clean unless _HAS_NATIVE_LEXICAL_SUB || _HAS_MODULE_LEXICAL_SUB;

{
	our %META;

	sub find_meta {
		my $me   = shift;
		my $for  = shift;
		if ( is_Object $for ) {
			$for = ref $for;
		}
		if ( not exists $META{$for} ) {
			$me->try_inhale( $for );
		}
		$META{$for} ? $META{$for}->setup_compat : undef;
	}

	sub store_meta {
		my $me = shift;
		if ( is_Object $me ) {
			$META{$me->this} = $me;
		}
		else {
			my $for  = shift;
			my $meta = shift;
			$META{$for} = $meta;
		}
	}
}

sub try_inhale {
	my $me = shift;
	my $k = shift;
	
	( my $k_short = $k ) =~ s/(::|')//g;
	
	no strict 'refs';
	no warnings 'once';
	
	# Native or already inhaled 
	{
		our %META;
		return true if $META{$k};
	}
	
	# If class or role uses Mite, force Moose to be loaded
	if ( my $mite = ${"${k}::USES_MITE"} ) {
		Marlin::Util::_carp "Marlin inhaled a non-MOP-enabled $mite: $k" unless $k->can('meta');
		my $meta = $k->meta;
		if ( $meta and $meta->isa('Moose::Meta::Class') ) {
			$meta->make_immutable(
				inline_constructor => 0,
				inline_destructor  => 0,
				inline_accessors   => 0,
			);
		}
	}
	
	# Inhale Class::XSConstructor
	if ( $INC{'Class/XSConstructor.pm'} and my $xscon_meta = do {
		my $m = Class::XSConstructor::get_metadata($k);
		$m && defined $m->{package} ? $m : undef;
	} ) {
		my @attrs = map {
			my %spec = (
				is       => 'bare',
				package  => $k,
				slot     => $_->{name},
				%{ $_->{spec} },
				isa      => $_->{type},
			);
			\%spec;
		} @{ $xscon_meta->{params} or [] };
		
		__PACKAGE__->new( {
			this         => $k,
			attributes   => \@attrs,
			parents      => [ map [ $_ ], @{"$k\::ISA"} ],
			strict       => $xscon_meta->{strict_params},
			constructor  => "__Marlin_${k_short}_new", # ???
			inhaled_from => 'Class::XSConstructor',
			short_name   => $k_short,
		} )->store_meta;
		return 'Class::XSConstructor';
	}
	
	# Inhale Moose
	if ( $INC{'Moose.pm'} and my $moose_meta = do {
		require Moose::Util;
		Moose::Util::find_meta($k);
	} ) {
		# Moose classes
		if ( $moose_meta->isa('Moose::Meta::Class') ) {
			if ( $moose_meta->is_mutable and $k ne 'Moose::Object' ) {
				Marlin::Util::_carp "Marlin inhaled a mutable Moose class: $k";
			}
			
			my @attrs = map {
				my $attr = $_;
				{
					is       => $attr->{is} || 'bare',
					package  => $attr->definition_context->{package} || $k,
					slot     => $attr->name,
					$attr->has_type_constraint ? ( isa => to_TypeTiny($attr->type_constraint) ) : (),
					$attr->should_coerce ? ( coerce => 1 ) : (),
					$attr->has_trigger ? ( trigger => $attr->trigger ) : (),
					init_arg => $attr->init_arg,
					$attr->has_builder ? ( builder => $attr->builder ) : $attr->has_default ? ( default => $attr->default ) : (),
					$attr->is_required ? ( required => 1 ) : (),
					$attr->is_weak_ref ? ( weak_ref => 1 ) : (),
					$attr->is_lazy ? ( lazy => 1 ) : (),
				};
			} $moose_meta->get_all_attributes;
			
			__PACKAGE__->new( {
				this         => $k,
				attributes   => \@attrs,
				parents      => [ map [ $_ ], @{"$k\::ISA"} ],
				roles        => [ map [ $_ ], List::Util::uniqstr( map { $_->name } @{ $moose_meta->roles } ) ],
				strict       => !!Moose::Util::does_role( $moose_meta, 'MooseX::StrictConstructor::Trait::Class' ),
				constructor  => $moose_meta->constructor_name,
				inhaled_from => 'Moose',
				short_name   => $k_short,
			} )->store_meta;
			
			return 'Moose';
		}
		# Moose roles
		elsif ( $moose_meta->isa('Moose::Meta::Role') ) {
			my @attrs = map {
				my $name = $_;
				my $attr = $moose_meta->get_attribute($_);
				{
					is       => $attr->{is} || 'bare',
					package  => $attr->{definition_context}{package} || $k,
					slot     => $name,
					%$attr,
					defined $attr->{isa} ? ( isa => to_TypeTiny $attr->{isa} ) : (),
				};
			} $moose_meta->get_attribute_list;
			
			require Marlin::Role;
			'Marlin::Role'->new( {
				this         => $k,
				attributes   => \@attrs,
				roles        => [ map [ $_ ], List::Util::uniqstr( map { $_->name } @{ $moose_meta->get_roles } ) ],
				inhaled_from => 'Moose::Role',
			} )->store_meta;
			
			return 'Moose::Role';
		}
	}
	
	# Inhale Moo
	if ( $INC{'Moo.pm'} and Moo->can('is_class') and Moo->is_class($k) ) {
		my $maker = Moo->_constructor_maker_for( $k );
		
		my $specs = $maker->all_attribute_specs;
		my @attr =
			sort { $a->{index} <=> $b->{index} }
			map  { +{ slot => $_, package => $k, %{ $specs->{$_} } }; }
			keys %$specs;
		
		require Moo::Role;
		__PACKAGE__->new( {
			this         => $k,
			attributes   => \@attr,
			parents      => [ map [ $_ ], @{"$k\::ISA"} ],
			roles        => [ map [ $_ ], keys %{ $Role::Tiny::APPLIED_TO{$k} } ],
			strict       => Moo::Role::does_role( $maker, 'MooX::StrictConstructor::Role::Constructor::Base' ),
			inhaled_from => 'Moo',
			short_name   => $k_short,
		} )->store_meta;
		
		return 'Moo';
	}

	# Inhale Moo::Role
	if ( $INC{'Moo/Role.pm'} and Moo::Role->can('is_role') and Moo::Role->is_role($k) ) {
		my @attr;
		my @specs = @{ $Moo::Role::INFO{$k}{attributes} };
		while ( my ( $name, $spec ) = splice @specs, 0, 2 ) {
			push @attr, +{ slot => $name, package => $k, %$spec };
		}
		
		require Marlin::Role;
		'Marlin::Role'->new( {
			this         => $k,
			attributes   => \@attr,
			roles        => [ map [ $_ ], keys %{ $Role::Tiny::APPLIED_TO{$k} } ],
			inhaled_from => 'Moo::Role',
		} )->store_meta;
		
		return 'Moo::Role';
	}

	# Inhale Mouse
	if ( $INC{'Mouse.pm'} and my $mouse_meta = do {
		require Mouse::Util;
		Mouse::Util::find_meta($k);
	} ) {
		# Moose classes
		if ( $mouse_meta->isa('Mouse::Meta::Class') ) {
			my @attrs = map {
				my $attr = $_;
				{
					is       => $attr->{is} || 'bare',
					package  => eval { $attr->associated_class->name } || $k,
					slot     => $attr->name,
					defined $attr->{does} ? ( isa => ConsumerOf[ $attr->{does} ] ) : (),
					defined $attr->{isa} ? ( isa => to_TypeTiny $attr->{isa} ) : (),
					$attr->{coerce} ? ( coerce => 1 ) : (),
					defined $attr->{trigger} ? ( trigger => $attr->{trigger} ) : (),
					exists $attr->{init_arg} ? ( init_arg => $attr->{init_arg} ) : (),
					defined $attr->{builder} ? ( builder => $attr->{builder} ) : exists $attr->{default} ? ( default => $attr->{default} ) : (),
					$attr->{required} ? ( required => 1 ) : (),
					$attr->{weak_ref} ? ( weak_ref => 1 ) : (),
					$attr->{lazy} || $attr->{lazy_build} ? ( lazy => 1 ) : (),
				};
			} $mouse_meta->get_all_attributes;
			
			__PACKAGE__->new( {
				this         => $k,
				attributes   => \@attrs,
				parents      => [ map [ $_ ], @{"$k\::ISA"} ],
				roles        => [ map [ $_ ], List::Util::uniqstr( map { $_->name } @{ $mouse_meta->roles } ) ],
				strict       => !!eval { $mouse_meta->strict_constructor },
				constructor  => $mouse_meta->{constructor_name} || 'new',
				inhaled_from => 'Mouse',
				short_name   => $k_short,
			} )->store_meta;
			
			return 'Mouse';
		}
		# Moose roles
		elsif ( $mouse_meta->isa('Mouse::Meta::Role') ) {
			my @attrs = map {
				my $name = $_;
				my $attr = $mouse_meta->get_attribute($_);
				{
					is       => $attr->{is} || 'bare',
					package  => $k,
					slot     => $name,
					%$attr,
					defined $attr->{does} ? ( isa => ConsumerOf[ $attr->{does} ] ) : (),
					defined $attr->{isa} ? ( isa => to_TypeTiny $attr->{isa} ) : (),
				};
			} $mouse_meta->get_attribute_list;
			
			require Marlin::Role;
			'Marlin::Role'->new( {
				this         => $k,
				attributes   => \@attrs,
				roles        => [ map [ $_ ], List::Util::uniqstr( map { $_->name } @{ $mouse_meta->get_roles } ) ],
				inhaled_from => 'Mouse::Role',
			} )->store_meta;
			
			return 'Mouse::Role';
		}
	}
	
	# Inhale Class::Tiny
	if ( $INC{'Class/Tiny.pm'} and $k->isa('Class::Tiny::Object') ) {
		my $defaults = Class::Tiny->get_all_attribute_defaults_for( $k );
		my @attrs = map {
			+{
				is       => 'rw',
				package  => $k,
				slot     => $_,
				exists $defaults->{$_} ? ( lazy => 1, default => $defaults->{$_} ) : (),
			};
		} Class::Tiny->get_all_attributes_for( $k );
		
		__PACKAGE__->new( {
			this         => $k,
			attributes   => \@attrs,
			parents      => [ map [ $_ ], @{"$k\::ISA"} ],
			inhaled_from => 'Class::Tiny',
			short_name   => $k_short,
			strict       => false,
		} )->store_meta;
		
		return 'Class::Tiny';
	}
	
	return false;
}

sub _build_short_name {
	( my $s = shift->this ) =~ s/(?:'|::)//g;
	return $s;
}

sub can_lexical {
	_HAS_NATIVE_LEXICAL_SUB || _HAS_MODULE_LEXICAL_SUB;
}

sub _croaker {
	return "Marlin::Util::_croak";
}

sub import {
	my $class = shift;
	my $me = $class->new( -caller => [ scalar(CORE::caller) ], @_ );
	$me->store_meta;
	$me->do_setup;
}

sub _parse_package_list {
	my ( $class, $v ) = @_;
	
	my @r;
	if ( is_HashRef $v ) {
		$v = [ $v ];
	}
	if ( is_ArrayRef $v ) {
		push @r, map {
			my $x = $_;
			is_HashRef($x)
				? ( map { [ $_ => $x->{$_} ] } sort keys %$x )
				: [ split /\s+/, $x ]
		} @$v;
	}
	elsif ( is_ScalarRef $v ) {
		push @r, [ split /\s+/, $$v ];
	}
	elsif ( is_Str $v ) {
		push @r, [ $v ];
	}
	
	return @r;
}

sub _parse_attribute {
	my ( $class, $name, $ref ) = @_;
	$ref ||= {};
	
	if ( is_Object $ref and $ref->DOES('Type::API::Constraint') ) {
		my $tc = $ref;
		$ref = {
			isa      => $tc,
			coerce   => !!( $tc->DOES('Type::API::Constraint::Coercible') and $tc->has_coercion ),
		};
	}
	elsif ( is_CodeRef $ref ) {
		my $builder = $ref;
		$ref = {
			lazy     => true,
			builder  => $builder,
		};
	}
	
	if ( $name =~ /^(.+)\!(\W*)$/ ) {
		$ref->{required} = true;
		$name = $1 . $2;
	}
	elsif ( $name =~ /^(.+)\.(\W*)$/ ) {
		$ref->{init_arg} = undef;
		$name = $1 . $2;
	}
	elsif ( $name =~ /^\.(.+)$/ ) {
		$ref->{init_arg} = undef;
		$name = $1;
	}
	
	if ( $name =~ /^(.+)\?(\W*)$/ ) {
		$ref->{predicate} = true;
		$name = $1 . $2;
	}

	if ( $name =~ /^(.+)==(\W*)$/ ) {
		$ref->{is} = 'rw';
		$name = $1 . $2;
	}
	elsif ( $name =~ /^(.+)=(\W*)$/ ) {
		$ref->{is} = 'rwp';
		$name = $1 . $2;
	}
	
	Marlin::Util::_croak("Bad attribute name: $name") unless $name =~ /\A\+?[^\W0-9]\w*\z/;
	
	my $default_init_arg = exists( $ref->{constant} ) ? undef : $name;
	
	return {
		( $name =~ /^\+/ or $ref->{extends} ) ? () : (
			is       => 'ro',
			init_arg => $default_init_arg,
		),
		%$ref,
		slot => $name,
	};
}

sub BUILDARGS {
	my $class = shift;
	return $_[0] if ( @_ == 1 and is_HashRef $_[0] );
	
	my %arg;
	
	while ( @_ ) {
		my ( $k, $v, $has_v ) = ( shift );
		if ( ref $_[0] or not defined $_[0] ) {
			( $v, $has_v ) = ( shift, true );
		}
		
		if ( $k =~ /^-(?:base|isa|parent|parents|extends)$/ ) {
			( $v, $has_v ) = ( shift, true ) unless $has_v;
			Marlin::Util::_croak("Expected arrayref or hashref of parent classes") unless $v;
			push @{ $arg{parents} ||= [] }, $class->_parse_package_list( $v );
		}
		elsif ( $k =~ /^-(?:with|does|role|roles)$/ ) {
			( $v, $has_v ) = ( shift, true ) unless $has_v;
			Marlin::Util::_croak("Expected arrayref or hashref of roles") unless $v;
			push @{ $arg{roles} ||= [] }, $class->_parse_package_list( $v );
		}
		elsif ( $k =~ /^-(?:class|self|this)$/ ) {
			( $v, $has_v ) = ( shift, true ) unless $has_v;
			Marlin::Util::_croak("Expected scalarref to this class name") unless $v;
			my @got = $class->_parse_package_list( $v );
			Marlin::Util::_croak("This class must have exactly one name") if @got != 1 || exists $arg{this};
			$arg{this} = $got[0][0];
		}
		elsif ( $k =~ /^-(?:caller)$/ ) {
			( $v, $has_v ) = ( shift, true ) unless $has_v;
			my @got = $class->_parse_package_list( $v );
			Marlin::Util::_croak("Can be only one caller") if @got != 1 || exists $arg{caller};
			$arg{caller} = $got[0][0];
		}
		elsif ( $k =~ /^-(?:constructor)$/ ) {
			( $v, $has_v ) = ( shift, true ) unless $has_v;
			my @got = $class->_parse_package_list( $v );
			$arg{constructor} = $got[0][0];
		}
		elsif ( $k =~ /^-(?:(?:loose|sloppy)(?:_?constructor)?)$/ ) {
			$arg{strict} = false;
		}
		elsif ( $k =~ /^-(?:(?:strict)(?:_?constructor)?)$/ or $k eq '!!' ) {
			$arg{strict} = true;
		}
		elsif ( $k =~ /^-(?:modifiers?|mods?)$/ ) {
			$arg{modifiers} = true;
		}
		elsif ( $k =~ /^-(?:requires?)$/ ) {
			( $v, $has_v ) = ( shift, true ) unless $has_v;
			Marlin::Util::_croak("Expected arrayref of required method names") unless is_ArrayRef $v;
			$arg{requires} = $v;
		}
		elsif ( $k =~ /^-/ ) {
			( $v, $has_v ) = ( shift, true ) unless $has_v;
			$arg{ substr( $k, 1 ) } = $v;
		}
		elsif ( $k =~ /^:(.+)$/ ) {
			my $plugin = "Marlin::X::$1";
			push @{ $arg{plugins} ||= [] }, [ $plugin, $v ];
		}
		else {
			push @{ $arg{attributes} ||= [] }, $class->_parse_attribute( $k, $v );
		}
	}
	
	if ( my $caller = $arg{caller} ) {
		$arg{this} ||= $caller;
	}
	
	Marlin::Util::_croak "Not sure what class to create" unless $arg{this};
	
	return \%arg;
}

sub do_setup {
	my $me = shift;
	
	my $steps = [ $me->setup_steps ];
	my %handled;
	
	for my $pair ( @{ $me->plugins } ) {
		my ( $plugin, $opts ) = @$pair;
		$handled{$plugin} ? next : ( $handled{$plugin} = $pair );
		if ( is_HashRef $opts and $opts->{try} ) {
			Marlin::Util::_maybe_load_module( $plugin );
			$pair->[2] = undef;
			if ( $plugin->can('new') ) {
				$pair->[2] = $plugin->new( %$opts, marlin => $me );
				$pair->[2]->adjust_setup_steps( $steps );
			}
		}
		else {
			Marlin::Util::_load_module( $plugin );
			$pair->[2] = $plugin->new(
				is_HashRef($opts) ? ( %$opts ) : (),
				marlin => $me,
			);
			$pair->[2]->adjust_setup_steps( $steps );
		}
	}
	
	for my $step ( @$steps ) {
		if ( $step =~ /^(.+)::(\w+)$/ ) {
			my $plugin = $1;
			my $invocant = $handled{$plugin}[2] || $plugin;
			$invocant->$step( $me );
		}
		else {
			$me->$step;
		}
	}
	
	return $me;
}

sub setup_steps {
	my $me = shift;
	
	return qw/
		mark_inc
		setup_mro
		setup_inheritance
		setup_roles
		canonicalize_attributes
		check_argument_conflicts
		check_accessor_conflicts
		setup_constructor
		setup_accessors
		setup_imports
		optimize_methods
		run_delayed
		setup_destructor
		setup_compat
		setup_cleanups
	/;
}

sub mark_inc {
	my $me = shift;
	
	my $file = Marlin::Util::_module_notional_filename( $me->this );
	$INC{$file} = __FILE__ unless defined $file;
	
	return $me;
}

sub setup_mro {
	my $me = shift;
	
	mro::set_mro( $me->this, 'c3' );
	
	return $me;
}

sub setup_inheritance {
	my $me = shift;
	
	my @parents = map {
		my ( $pkg, $ver ) = @$_;
		&Marlin::Util::_use_package_optimistically( $pkg, defined($ver) ? $ver : () );
	} @{ $me->parents } or return $me;
	my $ISA = do {
		no strict 'refs';
		\@{sprintf("%s::ISA", $me->this)};
	};
	@$ISA = List::Util::uniqstr( @$ISA, @parents );
	
	return $me;
}

sub setup_roles {
	my $me = shift;
	
	my @roles = List::Util::uniqstr(
		map {
			my ( $pkg, $ver ) = @$_;
			&Marlin::Util::_use_package_optimistically( $pkg, defined($ver) ? $ver : () );
		} @{ $me->roles }
	) or return $me;
	
	my ( $is_moose_role, $is_mouse_role );
	if ( $INC{'Moose/Role.pm'} ) {
		$is_moose_role = sub {
			require Moose::Util;
			my $m = Moose::Util::find_meta( $_[0] );
			$m and $m->isa('Moose::Meta::Role');
		};
	}
	if ( $INC{'Mouse/Role.pm'} ) {
		$is_mouse_role = sub {
			require Mouse::Util;
			my $m = Mouse::Util::find_meta( $_[0] );
			$m and $m->isa('Mouse::Meta::Role');
		};
	}

	my ( @moose_roles, @mouse_roles, @tiny_roles );
	for my $r ( @roles ) {
		if ( $is_moose_role and $is_moose_role->($r) ) {
			push @moose_roles, $r;
		}
		elsif ( $is_mouse_role and $is_mouse_role->($r) ) {
			push @mouse_roles, $r;
		}
		else {
			push @tiny_roles, $r;
		}
	}
	
	my $existing;
	for my $r ( @roles ) {
		my $r_meta = $me->find_meta( $r );
		if ( is_Object $r_meta and $r_meta->isa('Marlin::Role') ) {
			$existing ||= do {
				my %e;
				for my $attr ( @{ $me->attributes } ) {
					undef $e{$attr->{slot}};
				}
				\%e;
			};
			$r_meta->canonicalize_attributes;
			for my $attr ( @{ $r_meta->attributes } ) {
				my $copy = $attr->make_clone_for_consuming_class( $me );
				push @{ $me->attributes }, $copy;
			}
		}
	}
	
	$me->delay( sub {
		my $me = shift;
		do {
			require Role::Tiny;
			Role::Tiny->apply_roles_to_package( $me->this, @tiny_roles );
		} if @tiny_roles;
		do {
			Moose::Util::ensure_all_roles( $me->this, @moose_roles );
		} if @moose_roles;
		do {
			Mouse::Util::apply_all_roles( $me->this, @mouse_roles );
		} if @mouse_roles;
	} );
	
	return $me;
}

{
	my ( $at_runtime_sub, $after_runtime_sub, $find_hooks_sub );
	
	sub delay {
		my $me = shift;
		my $coderef = shift;
		my $after_runtime = shift;
		
		if ( not $find_hooks_sub ) {
			my @funcs = qw/ at_runtime after_runtime find_hooks /;
			no strict 'refs';
			( $at_runtime_sub, $after_runtime_sub, $find_hooks_sub ) = @{(
				eval {
					require B::Hooks::AtRuntime;
					B::Hooks::AtRuntime->VERSION( 8 );
					[ map \&{"B::Hooks::AtRuntime::$_"}, @funcs ]
				} or do {
					require B::Hooks::AtRuntime::OnlyCoreDependencies;
					[ map \&{"B::Hooks::AtRuntime::OnlyCoreDependencies::$_"}, @funcs ]
				}
			)};
		}
		
		if ( eval { $find_hooks_sub->(); 1 } ) {
			my $hook = $after_runtime ? $after_runtime_sub : $at_runtime_sub;
			$hook->( sub { $coderef->( $me ) } );
		}
		elsif ( $me->delayed ) {
			push @{ $me->delayed }, $coderef;
		}
		else {
			$coderef->( $me );
		}
	}
}

sub run_delayed {
	my $me = shift;
	for my $code ( @{ $me->delayed } ) {
		$code->( $me );
	}
	delete $me->{delayed};
	return $me;
}

sub canonicalize_attributes {
	my $me = shift;
	
	defined &Marlin::Attribute::new or require Marlin::Attribute;
	
	my ( @extensions, @attributes, %seen );
	for my $proto ( @{ $me->attributes } ) {
		
		if ( delete $proto->{extends} ) {
			$proto->{slot} = '+' . $proto->{slot}
				unless $proto->{slot} =~ /^\+/;
		}
		
		my $slot = $proto->{slot};
		if ( $slot =~ /^\+/ ) {
			push @extensions, $proto;
			next;
		}
		
		#Marlin::Util::_croak( "Attribute '%s' declared more than once in package '%s'", $slot, $me->this )
		#	if $seen{$slot}++;
		
		if ( is_Object $proto ) {
			push @attributes, $proto;
		}
		else {
			push @attributes, Marlin::Attribute->new(
				%$proto,
				package => $me->this,
				marlin  => $me,
			);
		}
	}
	
	@{ $me->attributes } = @attributes;
	
	if ( @extensions ) {
	
		my %lookup =
			map { $_->{slot} => $_ }
			@{ $me->attributes_with_inheritance };
		
		for my $extension ( @extensions ) {
			
			my ( $slot ) = ( $extension->{slot} =~ /^\+([^\W0-9]\w*)$/ )
				or Marlin::Util::_croak( "Cannot extend badly named attribute '%s' in package '%s'", $1, $me->this );
			
			my $old_attr = $lookup{$slot}
				or Marlin::Util::_croak( "Cannot extend non-existant attribute '%s' in package '%s'", $slot, $me->this );
			
			my $new_attr = $old_attr->make_extended( { %$extension, marlin => $me } );
			
			my $replaced = false;
			@{ $me->attributes } =
				map {
					( $_->{slot} eq $slot )
						? ( $replaced = $new_attr )
						: $_;
				}
				@{ $me->attributes };
			push @{ $me->attributes }, $new_attr unless $replaced;
			$lookup{$slot} = $new_attr;
		}
	}
	
	return $me;
}

sub check_accessor_conflicts {
	my $me = shift;
	
	my %method_names;
	for my $attr ( @{ $me->attributes_with_inheritance } ) {
		for my $accessor ( $attr->provides_accessors ) {
			push @{ $method_names{ $accessor->[0] } ||= [] }, $accessor;
		}
	}
	
	for my $name ( sort keys %method_names ) {
		my @got = @{ $method_names{$name} };
		Marlin::Util::_croak(
			"Method '%s' conflict: %s",
			$name,
			join( q[, ], map { sprintf q{%s for attribute '%s'}, $_->[1], $_->[2]{slot} } @got )
		) if @got > 1;
	}
}

sub check_argument_conflicts {
	my $me = shift;
	
	my %arg_names;
	for my $attr ( @{ $me->attributes_with_inheritance } ) {
		for my $arg ( $attr->allowed_constructor_parameters ) {
			push @{ $arg_names{$arg} ||= [] }, $attr;
		}
	}
	
	for my $name ( sort keys %arg_names ) {
		my @got = @{ $arg_names{$name} };
		Marlin::Util::_croak(
			"Initialization argument '%s' conflict: %s",
			$name,
			join( q[, ], map { sprintf q{attribute '%s'}, $_->{slot} } @got )
		) if @got > 1;
	}
}

sub setup_constructor {
	my $me = shift;
	
	Class::XSConstructor->import(
		[ $me->this, $me->constructor ],
		$me->strict ? '!!' : (),
		map( $_->xs_constructor_args, @{ $me->attributes_with_inheritance } ),
	);
	
	# XSConstructor's idea of "foreign" classes is more limited than ours,
	# so find the real foreign parent, if any. We accept Moo, Moose, Mouse,
	# etc (anything find_meta can find) as being friendly.
	no strict 'refs';
	$me->delay( sub {
		my $me = shift;
		my @isa = @{ mro::get_linear_isa($me->this) };
		shift @isa;  # discard $package itself
		return unless @isa;
		
		my $xscon_meta = Class::XSConstructor::get_metadata($me->this);
		return unless $xscon_meta->{foreignclass};
		
		delete $xscon_meta->{foreignclass};
		delete $xscon_meta->{foreignconstructor};
		delete $xscon_meta->{foreignbuildall};
		delete $xscon_meta->{foreignbuildargs};
		
		for my $parent ( @isa ) {
			next if $me->find_meta( $parent );
			next if !defined &{"${parent}::new"};
			$xscon_meta->{foreignclass}         = $parent;
			$xscon_meta->{foreignconstructor}   = \&{"${parent}::new"};
			$xscon_meta->{foreignbuildall}      = $parent->can('BUILDALL');
			$xscon_meta->{foreignbuildargs}     = $parent->can('BUILDARGS');
			last;
		}
		
		$me->this->XSCON_CLEAR_CONSTRUCTOR_CACHE;
	} );

	return $me;
}

sub setup_destructor {
	my $me = shift;
	
	$me->delay( sub {
		my $me = shift;
		local $Class::XSDestructor::REDEFINE = 1;
		Class::XSDestructor->import( [ $me->this, 'DESTROY' ] )
			if $me->this->can('DEMOLISH');
	} );
	
	return $me;
}

sub setup_accessors {
	my $me = shift;
	
	for my $attr ( @{ $me->attributes } ) {
		$attr->install_accessors;
	}
	for my $attr ( @{ $me->attributes_with_inheritance } ) {
		if ( $attr->{force_regenerate_accessors} && $attr->{package} ne $me->this ) {
			my $clone = bless { %$attr, package => $me->this }, ref($attr);
			$clone->install_accessors;
		}
	}
	
	return $me;
}

sub setup_imports {
	my $me = shift;
	
	my @imports;
	if ( $me->modifiers ) {
		push @imports, $me->_make_modifier_imports;
	}
	
	$me->lexport( @imports );
	
	return $me;
}

sub _make_modifier_imports {
	require Class::Method::Modifiers;
	return (
		before => \&Class::Method::Modifiers::before,
		after  => \&Class::Method::Modifiers::after,
		around => \&Class::Method::Modifiers::around,
		fresh  => \&Class::Method::Modifiers::fresh,
	);
}

sub export {
	my $me = shift;
	my $pkg = $me->this;
	
	require Eval::TypeTiny;
	no strict 'refs';
	no warnings 'redefine';
	while ( @_ ) {
		my ( $name, $coderef ) = splice( @_, 0, 2 );
		my $fqname = "$pkg\::$name";
		*$fqname = Eval::TypeTiny::set_subname( $fqname, $coderef );
	}
}

sub lexport {
	my $me = shift;
	my $caller;
	
	while ( @_ ) {
		my ( $lexname, $coderef ) = splice( @_, 0, 2 );
		if ( _HAS_NATIVE_LEXICAL_SUB ) {
			no warnings ( "$]" >= 5.037002 ? 'experimental::builtin' : () );
			builtin::export_lexically( $lexname, $coderef );
		}
		elsif ( _HAS_MODULE_LEXICAL_SUB ) {
			'Lexical::Sub'->import( $lexname, $coderef );
		}
		else {
			no strict 'refs';
			$caller ||= $me->caller;
			*{"$caller\::$lexname"} = $coderef;
			push @{ $me->{cleanups} }, $lexname;
		}
	}
	
	return $me;
}

# Stole much of this from MANWAR. The aim is to avoid perl ever
# needing to walk the inheritance tree to find methods. My
# benchmarking seems to suggest it doesn't make a lot of difference,
# but I can't see much harm in trying.
my %METHOD_COPY_CACHE;
my %SKIP_METHODS = map { $_ => 1 } qw(
	BUILD new does import AUTOLOAD DESTROY BEGIN END
	ISA VERSION EXPORT AUTHORITY INC DOES
);
sub optimize_methods {
	my $me = shift;
	if ( @{ $me->parents or [] } ) {
		$me->delay( sub {
			my $me = shift;
			no strict 'refs';
			for my $p ( @{ $me->parents or [] } ) {
				my $parent = $p->[0];
				my $child  = $me->this;
				next if $METHOD_COPY_CACHE{"$parent -> $child"}++;
				my $parent_symtab = \%{"${parent}::"};
				for (keys %$parent_symtab) {
					next if $SKIP_METHODS{$_} || /^_/ || /::$/;
					next if defined &{"${child}::${_}"} || !defined &{"${parent}::${_}"};
					*{"${child}::${_}"} = \&{"${parent}::${_}"};
				}
			}
		} );
	}
	return $me;
}

sub attributes_with_inheritance {
	my $me = shift;
	my @isa = @{ +mro::get_linear_isa($me->this) };
	no strict 'refs';
	
	# If anything in the inheritance tree appears to be a
	# Class::XSAccessor class, attempt to reconstruct it.
	#
	for my $k ( @isa ) {
		$me->try_inhale( $k );
		if ( my $meta = $me->find_meta( $k ) ) {
			$meta->setup_compat;
		}
	}
	
	my %already;
	return [
		reverse
		grep { not $already{$_->{slot}}++ }
		map  { my $m = $me->find_meta($_); $m ? reverse( @{ $m->canonicalize_attributes->attributes } ) : () }
		@isa
	];
}

sub make_type_constraint {
	my $me = shift;
	my $name = shift; $name =~ s{(::|')}{}g;
	require Marlin::TypeConstraint;
	my $tc = Marlin::TypeConstraint->new( name => $name, class => $me->this );
	$tc->{_marlin} = $me;
	Scalar::Util::weaken( $tc->{_marlin} );
	return $tc;
}

sub to_arrayref {
	my $me = shift;
	my $object = shift;
	
	my $is_struct = $me->is_struct;
	my @pos;
	my @named;
	
	for my $attr ( @{ $me->attributes_with_inheritance } ) {
		my $storage    = ( $attr->{storage} ||= 'HASH' ); next if $storage eq 'PRIVATE';
		my $has_value  = $storage eq 'HASH' ? exists($object->{$attr->{slot}}) : $attr->predicate->($object);
		my $value      = !$has_value ? undef : $storage eq 'HASH' ? $object->{$attr->{slot}} : $attr->reader->($object);
		
		if ( $is_struct and $attr->{required} ) {
			push @pos, $value;
		}
		elsif ( $has_value ) {
			push @named, $attr->{init_arg} || $attr->{slot}, $value;
		}
	}
	
	return [ @pos, @named ];
}

sub _stringify_value {
	my $me = shift;
	my $attr = shift;
	my $value = shift;
	
	if ( my $r = ref $value ) {
		if ( is_Object $value and my $meta = $me->find_meta( ref($value) ) ) {
			return $meta->to_string( $value ) if $meta->is_struct;
		}
		return '{...}' if $r eq 'HASH';
		return '[...]' if $r eq 'ARRAY';
		return 'sub{...}' if $r eq 'CODE';
		return q{\\} . $me->_stringify_value(undef, $$value) if $r eq 'SCALAR';
		return "${r}->new(...)" if is_Object $value;
		return '...';
	}
	
	my $isa = ( $attr and is_TypeTiny $attr->{isa} ) ? $attr->{isa} : Any;
	
	if ( $isa and $isa->is_a_type_of(Bool) and is_Bool $value ) {
		return $value ? 'true' : 'false';
	}
	
	if ( $isa and $isa->is_a_type_of(Num) and is_Num $value ) {
		return 0 + $value;
	}
	
	if ( $isa and $isa->is_a_type_of(Str) and is_Str $value ) {
		return is_SimpleStr( $value ) ? B::perlstring( $value ) : q{"..."};
	}
	
	if ( ! defined $value ) {
		return 'undef';
	}
	
	if ( Sub::Accessor::Small::_is_bool( $value ) ) {
		return $value ? 'true' : 'false';
	}
	
	if ( Sub::Accessor::Small::_created_as_number( $value ) ) {
		return 0 + $value;
	}
	
	if ( Sub::Accessor::Small::_created_as_string( $value ) ) {
		return is_SimpleStr( $value ) ? B::perlstring( $value ) : q{"..."};
	}
	
	return '...';
}

sub to_string {
	my $me = shift;
	my $object = shift;
	
	my $is_struct = $me->is_struct;
	my @pos;
	my @named;
	
	for my $attr ( @{ $me->attributes_with_inheritance } ) {
		my $storage    = ( $attr->{storage} ||= 'HASH' ); next if $storage eq 'PRIVATE';
		my $has_value  = $storage eq 'HASH' ? exists($object->{$attr->{slot}}) : $attr->predicate->($object);
		my $value      = !$has_value ? undef : $storage eq 'HASH' ? $object->{$attr->{slot}} : $attr->reader->($object);
		
		if ( $is_struct and $attr->{required} ) {
			push @pos, $me->_stringify_value($attr, $value);
		}
		elsif ( $has_value ) {
			push @named, [
				( $attr->{slot} =~ /\A[^\W0-9][\w]*\z/ ) ? $attr->{slot} : B::perlstring($attr->{slot}),
				$me->_stringify_value($attr, $value),
			];
		}
	}
	
	return sprintf(
		'%s[%s%s%s]',
		$me->short_name || 'Object',
		join( q{, }, @pos ),
		( @pos && @named ) ? q{, } : q{},
		join( q{, }, map { sprintf q{%s => %s}, @$_ } @named ),
	);
}

sub setup_compat {
	my $me = shift;
	if ( $me->can('inject_moose_metadata') ) {
		$me->inject_moose_metadata;
	}
	if ( $me->can('inject_moo_metadata') ) {
		$me->inject_moo_metadata;
	}
	return $me;
}

# This method does nothing, but is a hook for extensions.
# It is safer to wrap this (using CMM) than to wrap
# inject_moose_metadata or inject_moo_metadata which
# might not be loaded yet!
sub injected_metadata {
	my ( $me, $framework, $metadata ) = @_;
	return $metadata;
}

sub setup_cleanups {
	my $me = shift;
	if ( $INC{'namespace/clean.pm'} and my @subs = @{ $me->cleanups } ) {
		namespace::clean->import( -cleanee => $me->caller, @subs );
	}
}

no Types::Common;

__PACKAGE__
__END__

=pod

=encoding utf-8

=head1 NAME

Marlin - 🐟 pretty fast class builder with most Moo/Moose features 🐟

=head1 SYNOPSIS

  use v5.20.0;
  no warnings "experimental::signatures";
  
  package Person {
    use Types::Common -lexical, -all;
    use Marlin::Util -lexical, -all;
    use Marlin
      'name!' => Str,
      'age?'  => Int;
    
    signature_for introduction => (
      method   => true,
      named    => [ audience => Optional[InstanceOf['Person']] ],
    );
    
    sub introduction ( $self, $arg ) {
      say "Hi " . $arg->audience->name . "!" if $arg->has_audience;
      say "My name is " . $self->name . ".";
    }
  }
  
  package Employee {
    use Marlin -base => 'Person', 'employee_id!';
  }
  
  my $alice = Person->new( name => 'Alice Whotfia' );
  
  my $bob = Employee->new(
    name         => 'Bob Dobalina',
    employee_id  => '007',
  );
  
  $alice->introduction( audience => $bob );

=head1 DESCRIPTION

Marlin is a fast class builder, inspired by L<Moose> and L<Moo>. It supports
most of their features, but with a different syntax. Because it uses
L<Class::XSAccessor>, L<Class::XSConstructor>, and L<Type::Tiny::XS>, it
is usually I<slightly> faster though. Especially if you keep things simple
and don't use features that force Marlin to fall back to using Pure Perl.

It may not be as sleek as classes built with the Perl builtin C<class> syntax
introduced in Perl v5.38.0, but has more features, is often faster, and it
supports Perl versions as old as v5.8.8. (Some features require v5.12.0+.)

Marlin was created by the developer of L<Type::Tiny> and L<Sub::HandlesVia>
and integrates with them.

=head2 Using Marlin

Marlin does all of its work at compile time, so doesn't export keywords like
C<has> into your namespace.

=head3 Declaring Attributes

Any strings found in the C<< use Marlin >> line (except a few special ones
beginning with a dash, used to configure Marlin) will be assumed to be
attributes you want to declare for your class.

  package Address {
    use Marlin qw( street_address locality region country postal_code );
  }
  
  my $adr = Address->new( street_address => '123 Test Street' );
  say $adr->street_address;

Any attributes you declare will will be accepted by the constructor that
Marlin creates for your class, and reader/getter methods will be created
to access their values.

Attributes can be followed by a hashref to tailor their behaviour.

  package Address {
    use Marlin::Util qw( true false );
    
    use Marlin
      street_address  => { is => 'rw', required  => true },
      locality        => { is => 'rw' },
      region          => { is => 'rw' },
      country         => { is => 'rw', required => true },
      postal_code     => { is => 'rw', predicate => 'has_pc' },
      ;
  }
  
  my $adr = Address->new(
    street_address => '123 Test Street',
    country        => 'North Pole',
  );
  
  $adr->has_pc or die;  # will die as there is no postal_code

Some behaviours are so commonly useful that there are shortcuts for them.

  # Shortcut for: name => { required => true }
  use Marlin 'name!';
  
  # Shortcut for: name => { predicate => true }
  use Marlin 'name?';
  
  # Shortcut for: name => { is => "rwp" }
  use Marlin 'name=';
  
  # Shortcut for: name => { is => "rw" }
  use Marlin 'name==';
  
  # Shortcut for: name => { init_arg => undef }
  use Marlin 'name.';

Using these shortcuts, our previous Address example can be written as:

  package Address {
    use Marlin qw(
      street_address==!
      locality==
      region==
      country==!
      postal_code==?
    );
  }

The order of these trailing modifiers doesn't matter, so C<< 'foo=?' >>
means the same as C<< 'foo?=' >>, though in the double-equals
modifier for read-write attributes, the equals signs cannot have
a character between them.

There are also some useful alternatives to providing a full hashref:

  use Types::Common 'Str';
  
  # Shortcut for: name => { required => true, isa => Str }
  use Marlin 'name!' => Str;
  
  # Shortcut for: name => { lazy => true, builder => sub { ... } }
  use Marlin 'name' => sub { ... };

If we wanted to add type checks to our previous Address example, we might
use:

  package Address {
    use Types::Common 'Str';
    use Marlin
      'street_address==!'  => Str,
      'locality=='         => Str,
      'region=='           => Str,
      'country==!'         => Str,
      'postal_code==?'     => Str,
      ;
  }

Marlin can I<almost> be used as a drop-in replacement for L<Class::Tiny>.
Examples from the Class::Tiny SYNOPSIS:

  # Person.pm
  package Person;
  use Marlin qw( name );
  1;
  
  # Employee.pm
  package Employee;
  use parent 'Person';
  use Marlin qw( ssn ), timestamp => sub { time };
  1;

The only change was to remove the hashref which wrapped
C<< timestamp => sub { time } >>.

=head3 Supported Features for Attributes

The following Moose/Moo-like features are supported for attributes:

=over

=item C<< is >>

Supports: bare, ro, rw, rwp, lazy.

=item C<< required >>

If true, indicates that callers must provide a value for this attribute
to the constructor. If false, indicates that it is optional.

To indicate that the attribute is I<forbidden> in the constructor,
use a combination of C<< init_arg => undef >> and a strict constructor.

=item C<< init_arg >>

The name of the parameter passed to the constructor which will be used
to populate this attribute.

Setting to an explicit C<undef> prevents the constructor from initializing
the attribute from the arguments passed to it.

=item C<< undef_tolerant >>

If you set an attribute to C<< undef_tolerant => true >>, and then try to
initialized it to C<undef> in the constructor, it will be treated as if
you hadn't passed it to the constructor at all. See L<MooseX::UndefTolerant>.

This has no affect on writers/accessors.

To make all attributes in your class or role undef tolerant, see
L<Marlin::X::UndefTolerant>.

=item C<< reader >>

You can specify the name for a reader method:

  use Marlin name => { reader => "get_name" };

If you use C<< reader => 1 >> or C<< reader => true >>, Marlin will pick a
default name for your reader by adding "_get" to the front of attributes that
have a leading underscore and "get_" otherwise.

Marlin supports a number of options to keep your accessors truly private.
(More so than just a leading "_".)

You can specify a scalarref variable to install the reader into:

  use Marlin name => { reader => \( my $get_name ) };
  ...
  say $thingy->$get_name();

From Perl v5.12.0 onwards, the following is also supported:

  use Marlin name => { reader => 'my get_name' };
  ...
  say get_name( $thingy );

From Perl v5.42.0 onwards, the following is also supported:

  use Marlin name => { reader => 'my get_name' };
  ...
  say $thingy->&get_name();

If you use the C<< 'my get_name' >> syntax on Perl versions too old to support
lexical subs, they will be installed as a normal sub in the caller package.
(Note that the caller package might differ from the class currently being
built, especially in the case of L<Marlin::Struct> classes.) Marlin will
attempt to clean them later with L<namespace::clean>.

=item C<< writer >>

Like C<reader>, but a writer method.

If you use C<< writer => 1 >> or C<< writer => true >>, Marlin will pick a
default name for your writer by adding "_set" to the front of attributes that
have a leading underscore and "set_" otherwise.

Supports the same lexical method possibilities as C<reader>.

=item C<< accessor >>

A combination reader or writer, depending on whether it's called with a
parameter or not.

If you use C<< accessor => 1 >> or C<< accessor => true >>, Marlin will pick a
default name for your writer which is just the same as your attribute's name.

Supports the same lexical method possibilities as C<reader>.

=item C<< clearer >>

Like C<reader>, but a clearer method.

If you use C<< clearer => 1 >> or C<< clearer => true >>, Marlin will pick a
default name for your clearer by adding "_clear" to the front of attributes that
have a leading underscore and "clear_" otherwise.

Supports the same lexical method possibilities as C<reader>.

=item C<< predicate >>

Like C<reader>, but a predicate method, checking whether a value was supplied
for the attribute. (It checks C<exists>, not C<defined>!)

If you use C<< predicate => 1 >> or C<< predicate => true >>, Marlin will pick a
default name for your predicate by adding "_has" to the front of attributes that
have a leading underscore and "has_" otherwise.

Supports the same lexical method possibilities as C<reader>.

=item C<< alias >> and C<< alias_for >>

Allows you to establish aliases for an attribute.

  use Marlin
    name => {
      required   => true,
      isa        => Str,
      alias      => [ 'moniker', 'label' ],
    }, ...;

Aliases are accepted in the constructor and also additional reader methods
(or accessor methods for C<< is => 'rw' >> attributes) are installed for
each alias.

You can use C<< alias_for => 'reader' >> or C<< alias_for => 'accessor' >>
to override which type of method is installed (though not on a per-alias
basis). Technically it's possible to create writer/predicate/clearer aliases
but that would be weird.

=item C<< builder >>, C<< default >>, and C<< lazy >>

The C<default> can be set to a coderef or a non-reference value to set a
default value for the attribute.

As an extension to what Moose and Moo allow, you can also set the default
to a reference to a string of Perl code.

  default => \'[]'

Alternatively, C<builder> can be used to provide the name of a method to
call which will generate a default value.

If you use C<< builder => 1 >> or C<< builder => true >>, Marlin will assume
a builder name of "_build_" followed by your attribute name. If you use
C<< builder => sub {...} >> then the coderef will be installed with that
name.

If you choose C<lazy>, then the default or builder will be run when the
value of the attribute is first needed. Otherwise it will be run in the
constructor.

If you use lazy builders/defaults, readers/accessors for the affected
attributes will be implemented in Perl rather than XS. This is a good
reason to have separate methods for readers and writers, so that the
reader can remain fast!

=item C<< constant >>

Defines a constant attribute. For example:

  package Person {
    use Marlin
      ...,
      species => { constant => 'Homo sapiens' };
  }
  
  my $bob = Person->new( ... );
  say $bob->species;

Constants attributes cannot have writers, clearers, predicates, builders,
defaults, or triggers. They must be a simple non-reference value. They cannot
be passed to the constructor. They I<can> have a type constraint and coercion,
which will be used I<once> at compile time. They can have C<handles> and
C<handles_via>, provided the delegated methods do not attempt to alter the
constant.

These constant attributes are still intended to be called as object methods.
Calling them as functions is I<not supported> and even though it might
sometimes work, no guarantees are provided that it will continue to work.

  say $bob->species;      # GOOD
  say Person::species();  # BAD

If you want that type of constant, use the L<constant> pragma.

=item C<< trigger >>

A method name or coderef to call after an attribute has been set.

If you use C<< trigger => 1 >> or C<< trigger => true >>, Marlin will assume
a trigger name of "_trigger_" followed by your attribute name.

Marlin's triggers are a little more sophisticated than Moose's: within the
trigger, you can call the setter again without worrying about re-triggering
the trigger.

  use v5.42.0;
  
  package Person {
    use Types::Common -types, -lexical;
    use Marlin::Util -all, -lexical;
    
    use Marlin
      first_name => {
        is      => rw,
        isa     => Str,
        trigger => sub ($me) { $me->clear_full_name },
      },
      last_name => {
        is      => rw,
        isa     => Str,
        trigger => sub ($me) { $me->clear_full_name },
      },
      full_name => {
        is      => lazy,
        isa     => Str,
        clearer => true,
        builder => sub ($me) {
          join q[ ], $me->first_name, $me->last_name;
        },
      };
  }
  
  my $person = Person->new(
    first_name  => 'Alice',
    last_name   => 'Smith',
  );
  say $person->full_name;  # Alice Smith
  $person->last_name( 'Jones' );
  say $person->full_name;  # Alice Jones

Currently if your class has any triggers, this will force any writers/accessors
for the affected attributes to be implemented in Perl instead of XS. This is
a good reason to have separate methods for readers and writers, so that the
reader can remain fast!

It is usually possible to design your API in ways that don't require
triggers.

  use v5.42.0;
  
  package Person {
    use Types::Common -types, -lexical;
    use Marlin::Util -all, -lexical;
    
    use Marlin
      first_name => {
        is      => ro,
        isa     => Str,
        writer  => 'my set_first_name',
      },
      last_name => {
        is      => ro,
        isa     => Str,
        writer  => 'my set_last_name',
      },
      full_name => {
        is      => lazy,
        isa     => Str,
        clearer => 'my clear_full_name',
        builder => sub ($me) {
          join q[ ], $me->first_name, $me->last_name;
        },
      };
    
    signature_for rename => (
      method  => true,
      named   => [
        first_name => Optional[Str],
        last_name  => Optional[Str],
      ],
    );
    
    sub rename ( $self, $arg ) {
      $self->&set_first_name( $arg->first_name )
        if $arg->has_first_name;
      $self->&set_last_name( $arg->last_name )
        if $arg->has_last_name;
      $self->&clear_full_name;
      return $self;
    }
  }
  
  my $person = Person->new(
    first_name  => 'Alice',
    last_name   => 'Smith',
  );
  say $person->full_name;  # Alice Smith
  $person->rename( last_name => 'Jones' );
  say $person->full_name;  # Alice Jones

=item C<< handles >> and C<< handles_via >>.

Method delegation.

Supports C<handles_via> like with L<Sub::HandlesVia>.

Lexical methods are possible here too.

  use v5.42.0;
  
  package Person {
    use Types::Common -lexical, -types;
    
    use Marlin
      name   => Str,
      emails => {
        is           => 'ro',
        isa          => ArrayRef[Str]
        default      => sub { [] },
        handles_via  => 'Array',
        handles      => [
          'add_email'       => 'push',
          'my find_emails'  => 'grep',
        ],
      };
    
    sub has_hotmail ( $self ) {
      my @h = $self->&find_emails( sub { /\@hotmail\./ } );
      return( @h > 0 );
    }
  }
  
  my $bob = Person->new( name => 'Bob' );
  $bob->add_email( 'bob@hotmail.example' );
  die unless $bob->has_hotmail;
  
  die if $bob->can('find_emails');  # will not die

=item C<< isa >> and C<< coerce >>

A type constraint for an attribute.

Any type checks or coercions will force the accessors and writers for those
attributes to be implemented in Perl instead of XS.

You can use C<< isa => sub { ... } >> like Moo.

=item C<< enum >>

You can use C<< enum => ['foo','bar'] >> as a shortcut for
C<< isa => Enum['foo','bar'] >>

=item C<< auto_deref >>

Rarely used Moose option. If you call a reader or accessor in list context,
will automatically apply C<< @{} >> or C<< %{} >> to the value if it's an
arrayref or hashref.

=item C<< chain >>

By default, Marlin's writers, clearers, and (when used as writers) accessors
are chainable. That means, they return the object itself. So this works:

  my $result = $object->set_foo(1)->set_bar(2)->foobar;
  $object->clear_foo->clear_bar;

However, you can set them to be not chainable using C<< chain => false >>.
Non-chainable clearers return the old value (like C<delete> does).
Non-chainable writers and accessors used as writers return the new value.

Chainable versions are usually I<slightly> more useful, so that is the
default since Marlin 0.022000.

=item C<< storage >>

It is possible to give a hint to Marlin about how to store an attribute.

  use v5.12.0;
  use Marlin::Util -all, -lexical;
  use Types::Common -types, -lexical;
  
  package Local::User {
    use Marlin
      'username!',  => Str,
      'password!'   => {
        is            => bare,
        isa           => Str,
        writer        => 'change_password',
        required      => true,
        storage       => 'PRIVATE',
        handles_via   => 'String',
        handles       => { check_password => 'eq' },
      };
  }
  
  my $bob = Local::User->new(
    username => 'bd',
    password => 'zi1ch',
  );
  
  die if exists $bob->{password};   # will not die
  die if $bob->can('password');     # will not die
  
  if ( $bob->check_password( 'zi1ch' ) ) {
    ...;  # this code should execute
  }
  
  $bob->change_password( 'monk33' );

Note that in the above example, setting C<< is => bare >> prevents any reader
from being created, so you cannot call C<< $bob->password >> to discover his
password. This would normally suffer the issue that the password is still
stored in C<< $bob->{password} >> if you access the object as a hashref.

However, setting C<< storage => "PRIVATE" >> tells Marlin to store the value
privately so it no longer appears in the hashref, so won't be included in any
Data::Dumper dumps sent to your logger, etc. This does complicate things if
you ever need to serialize your object to a file or database though! (Note
that while the value is not stored in the hashref, it is still stored
I<somewhere>. A determined Perl hacker can easily figure out where. This
shouldn't be relied on in place of proper security.)

Marlin supports three storage methods for attributes: "HASH" (the default),
"PRIVATE" (as above), and "NONE" (only used for constants).

=item C<clone>, C<clone_on_read>, C<clone_on_write>, and C<clone_bypass>

References provide shortcuts to data structures I<inside> your object,
allowing code outside your class to tamper with your object's internals
in unpredictable ways.

  my @array  = ( 1, 2, 3 );
  my $object = Local::Thing->new( numbers => \@array );
  push @array, "Hello world";

Setting C<clone_on_write> signals to the constructor and any writer/accessor
methods that when they get passed a value, they should instead keep a I<clone>
of the value, breaking any references outside code might be keeping to it.
So in the previous example, C<< $object >> wouldn't have a reference to
C<< @array >>, but a reference to a clone of that array. Altering C<< @array >>
later wouldn't alter the copy that C<< $object >> had.

Setting C<clone_on_read> does the same thing for reader/accessor methods and
avoids this altering your object:

  push @{ $object->numbers }, "Hello world";

Because C<< $object->numbers >> would be returning a clone of the data the
object holds internally instead of returning a direct reference to its
internal data.

C<clone_on_write> and C<clone_on_read> can be set to true to enable deep
cloning of values. If you need more fine-grained control of cloning, you
can set them to a coderef or a method name.

  package Local::Thing {
    use Types::Common -types;
    use Marlin
      numbers => {
        is             => 'rw',
        isa            => ArrayRef[Int],
        clone_on_write => sub ( $self, $attrname, $value ) {
          ...;
          retun $cloned_value;
        },
        clone_on_read => '_clone',
        handles_via   => 'Array',
        handles       => { add_number => 'push' },
      };
    
    sub _clone ( $self, $attrname, $value ) {
      ...;
      return $cloned_value;
    }
  }

The C<clone> option is a shortcut for setting both C<clone_on_write> and
C<clone_on_read>. You should usually use that as it's rare to need
such fine-grained control.

Delegated methods (see C<handles> and C<handles_via>) operate on the
internal copy of the data, bypassing the clone options. This means
that in our example C<< $object->add_number( 4 ) >> will correctly
push a number onto the object's internal numbers arrayref instead of
pushing it onto an ephemeral copy of the numbers arrayref.

It is worth noting that your I<internal> use of the attributes will
also trigger cloning. So for example, this will not work how you
want it to:

  package Local::Thing {
    use Types::Common -types;
    use Marlin
      numbers => {
        is      => 'rw',
        isa     => ArrayRef[Int],
        clone   => 1,
      };
    
    sub push_numbers ( $self, @more_numbers ) {
      push @{ $self->numbers }, @more_numbers;
    }
  }

The C<clone_bypass> option creates a second, internal accessor:

  package Local::Thing {
    use Types::Common -types;
    use Marlin
      numbers => {
        is           => 'rw',
        isa          => ArrayRef[Int],
        clone        => 1,
        clone_bypass => '_numbers_ref',
      };
    
    sub push_numbers ( $self, @more_numbers ) {
      push @{ $self->_numbers_ref }, @more_numbers;
    }
  }

(Note that C<clone_bypass> methods are always accessors, allowing you
to get/set the attribute, even for read-only attributes! They are intended
for your class's internal use only. Lexical clone bypass methods are
supported and indeed recommended!)

Setting the cloning options makes most sense for attributes which you expect
to be arrayrefs, hashrefs, or annoyingly mutable objects (like L<DateTime>).
It makes little sense for other attributes. It will slow down accessors and
object construction.

This feature is inspired by L<MooseX::Extended::Manual::Cloning>.

=item C<< extends >>

Indicates that this attribute extends or modifies an attribute inherited
from a parent class or role.

  package Local::Person {
    use Types::Common -types;
    use Marlin
      name => NonEmptyStr,
      age  => PositiveOrZeroNum;
  }
  
  package Local::Employee {
    use Types::Common -types;
    use Marlin::Util qw( true false );
    
    use Marlin
      -base => 'Local::Person',
      # Require name for employees.
      name => {
        extends  => true,
        required => true,
      },
      # We only employ adults.
      age => {
        extends  => true,
        required => true,
        isa      => NumRange[ 18, undef ]
      };
  }

A shortcut for C<extends> is a leading plus sign.

  package Local::Employee {
    use Types::Common -types;
    use Marlin -base => 'Local::Person',
      '+name!',                          # Required
      '+age!' => NumRange[ 18, undef ];  # Adults only
  }

Marlin limits what changes child classes are allowed to make to the API they
inherited from their parents. Some of the limitations:

=over

=item *

Optional attributes can be made required, but required attributes cannot
be made optional unless you also provide a default/builder.

=item *

Type constraints can be made more strict, but not looser. Type coercions
can be enabled by child classes but not disabled if they're already enabled
in the parent class.

=item *

Accessor-like methods (reader, writer, accessor, clearer, predicate)
can be added, but accessors defined in parent classes cannot be replaced
or removed.

=item *

Attribute storage type cannot be changed.

=item *

The auto_deref status cannot be changed.

=back

In the rare case where an attribute has an option which you wish to
delete, you can use C<< $Marlin::Attribute::NONE >>.

  package Local::ChildClass {
  
    use Marlin::Attribute ();
    use Marlin::Util -all;
    
    use Marlin
      -base => "Local::ParentClass",
      # Parent class defined a default for this attribute
      someattr => {
        extends  => true,
        required => true,
        default  => $Marlin::Attribute::NONE,
      };
  }

=item C<< documentation >>

Does nothing, but you can put a string of documentation for an attribute
here.

=back

=head3 Marlin Options

Any strings passed to Marlin that have a leading dash are taken to be
options affecting how Marlin builds your class.

=over

=item C<< -base >> or C<< -parents >> or C<< -isa >> or C<< -extends >>

Sets the parent classes of your class.

  package Employee {
    use Marlin -base => ['Person'], qw( employee_id payroll_number );
  }

Marlin currently only supports inheriting from other Marlin classes, or
from L<Class::XSConstructor>, L<Class::Tiny>, L<Moo>, L<Moose>, and
L<Mouse> classes. Other base classes I<may> work, especially if they use
blessed hashref instances and don't do anything fancy in their constructor.

Marlin can inherit from classes built with L<Mite>, provided that the
MOP option was enabled (see L<Mite::Manual::MOP>) and Moose is available.
(Mite doesn't expose attribute metadata, so Marlin needs to force the
class to "upgrade itself" to a Moose class.)

You can include version numbers:

  package Employee {
    use Marlin -base => ['Person 2.000'], ...;
  }

If you've only got one parent class (fairly normal situation!) you can
use a string instead of an arrayref:

  package Employee {
    use Marlin -base => 'Person', qw( employee_id payroll_number );
  }

You can technically manually set your C<< @ISA >>, but must do it I<before>
Marlin creates your class; otherwise Marlin won't be able to see any
attribute definitions in parent classes.

  package Employee {
    use Person 1.0;
    BEGIN { @ISA = ( 'Person' ) };
    use Marlin qw( employee_id payroll_number );
  }

I don't know why you'd want to do that though.

=item C<< -with >> or C<< -roles >> or C<< -does >>

Composes roles into your class.

  package Payable {
    use Marlin::Role -requires => ['payroll_number'];
  }
  
  package Employee {
    use Marlin
      -extends => ['Person'],
      -with    => ['Payable'],
      qw( employee_id payroll_number );
  }

Marlin classes can accept roles built with L<Marlin::Role>, L<Role::Tiny>,
L<Moo::Role>, L<Moose::Role>, or L<Mouse::Role>.

Like C<< -base >>, you can include version numbers.

=item C<< -this >> or C<< -self >> or C<< -class >>

Specifies the name of your class. If you don't include this, it will
just use C<caller>, which is normally what you want.

The following are roughly equivalent:

  package Person {
    use Marlin 'name!';
  }
  
  use Marlin -this => 'Person', 'name!';

The main difference is what scope any lexical subs Marlin creates will end
up in. (And if your version of Perl is too old to support lexical subs,
the "scope" they will be installed in is actually the caller package!)

=item C<< -constructor >>

Tells Marlin to use a constructor name other than C<new>:

  package Person {
    use Marlin -constructor => 'create', 'name!';
  }
  
  my $bob = Person->create( name => 'Bob' );

It can sometimes be useful to name your constructor something like
C<< _new >> if you wish to create your own C<< new >> method wrapping
it.

=item C<< -strict >> or C<< -strict_constructor >>

Tells Marlin to build a constructor like L<MooX::StrictConstructor> or 
L<MooseX::StrictConstructor>, which will reject unknown arguments.

Since version 0.007000, this is the default.

=item C<< -sloppy >> or C<< -sloppy_constructor >> C<< -loose >> or C<< -loose_constructor >>

Switches off the strict constructor.

Option introduced in version 0.007000. This was previously the default.

=item C<< -mods >> or C<< -modifiers >>

Exports the C<before>, C<after>, C<around>, and C<fresh> method modifiers
from L<Class::Method::Modifiers>, but lexical versions of them.

=back

=head3 Marlin Extensions

Strings in the C<< use Marlin >> line which start with a colon are used to
load Marlin extensions.

For example:

  package Local::Foobar {
    use Marlin qw( foo bar :Clone );
  }

Will create a class called Local::Foobar with attributes "foo" and "bar",
but use the Marlin extension L<Marlin::X::Clone>. (This module is bundled
with Marlin as a demonstration of how to create extensions.)

Extensions can be followed by a hashref of arguments for the extension:

  package Local::Foobar {
    use Marlin qw( foo bar ), ':Clone' => { try => 1 };
  }

The C<try> argument is special. By setting it to true, it tells Marlin to
only I<try> to use that extension, but carry on if the extension cannot
be loaded.

It is also possible to write attribute-specific extensions.

  package Local::Foobar {
    use Marlin foo => { is => 'rw', ':Frobnicate' => {...} };
  }

This will apply a role "Marlin::XAttribute::Frobnicate" to the
L<Marlin::Attribute> object that is used to generate accessors, etc.

=head3 Other Features

C<BUILDARGS>, C<BUILD>, C<FOREIGNBUILDARGS>, and C<DEMOLISH> are supported.
These are methods you can define in your class to influence how the constructor
and destructor work.

If you define a C<BUILDARGS> method, then it will be passed the constructor's
C<< @_ >> and expected to return a hashref mapping attribute names to values.
The default is something like this:

  sub BUILDARGS {
    my $class = shift;
    if ( @_ == 1 and is_HashRef $_[0] ) {
      return $_[0];
    }
    my %args = @_;
    return \%args;
  }

It is usually a good idea to I<not> provide a C<BUILDARGS> method as the
default behaviour is coded in fast C. However, you may sometimes need this
flexibility/

If you define a C<BUILD> method, it will be called after your object has
been created but before the constructor returns it. It is passed a copy
of the hashref returned by C<BUILDARGS>. In an inheritance heirarchy,
the constructor will call C<BUILD> for B<all> the parent classes too,
starting at the very base class.

Because C<BUILD> is called before the strict constructor check, it has
an opportunity to remove particular keys from the args hashref if they
are likely to trigger the strict constructor to die.

You can also call C<< $object->BUILDALL( \%args ) >> at any time to
run all the C<BUILD> methods on an existing object, though quite why
you'd want to is beyond my comprehension. Maybe some kind of
inflate/deflate situation?

If you define a C<DEMOLISH> method, this is treated like C<BUILD>, but
for the constructor. The inheritance heirarchy is traversed in reverse.

When you are inheriting from a non-Marlin, non-Class::XSConstructor class
(a "foreign class"), Marlin will want to call the base class's constructor.
It has two different techniques, depending on whether it appears to be a
"friendly foreign class" (built by Class::Tiny, Moo, or Moose) or a
"difficult foreign class".

=over

=item *

Marlin decides a parent class is a B<< friendly foreign class >> if the
parent class has a C<BUILDALL> method. Marlin will never call that method,
but its presence indicates that it was built by a sensible OO framework.

It will do roughly this:

  my $foreign_constructor = $foreignclass->can( 'new' );
  my $foreign_buildargs   = $foreignclass->can( 'BUILDARGS' )
                           || $default_buildargs;
  
  my $args = $ourclass->$foreign_buildargs( @_ );
  my $object = do {
    local $args->{__no_BUILD__} = true;
    $ourclass->$foreign_constructor( $args );
  };
  
  # ... then initialize our attributes from $args
  # ... then call BUILD methods, passing them $args
  # ... then do the strict constructor check on $args
  # ... then return $object

The friendly foreign class is supposed to honour C<__no_BUILD__> and skip
calling C<BUILD> methods. Marlin is going to call them and they shouldn't
be called twice. Moose, Moo, and Class::Tiny all honour that parameter.

=item *

If it's a B<< difficult foreign class >>, Marlin will do this instead:

  my $foreign_constructor = $foreignclass->can( 'new' );
  
  my @foreign_args = $ourclass->can('FOREIGNBUILDARGS')
    ? $ourclass->FOREIGNBUILDARGS( @_ )
    : @_;
  my $args = $ourclass->can('BUILDARGS')
    ? $ourclass->BUILDARGS( @_ )
    : $outclass->$default_buildargs( @_ );
  
  my $object = $ourclass->$foreign_constructor( @foreign_args );
  
  # ... then initialize our attributes from $args
  # ... then call BUILD methods, passing them $args
  # ... then do the strict constructor check on $args
  # ... then return $object

We just hope that the foreign class does not try to call C<BUILD>.
(It probably won't.)

=back

=head2 API

Marlin provides an API of sorts.

=over

=item C<< my $meta = Marlin->new( @args ) >>

Creates an object representing a class, but doesn't build the class yet.

=item C<< my $meta = Marlin->find_meta( $class_name ) >>

Returns an object representing an existing class or role. Will automatically
import Moose and Moo classes and roles too.

=item C<< $meta->do_setup >>

Builds the class.

=item C<< $meta->caller >>

Returns the name of the package which called Marlin.

=item C<< $meta->this >>

Returns the name of the class being built.

=item C<< $meta->parents >>

Returns an arrayref of parents. Each parent is itself an arrayref with the
first element being the class name and the second element being a version
number.

=item C<< $meta->roles >>

Returns an arrayref of roles. Each role is itself an arrayref with the
first element being the class name and the second element being a version
number.

=item C<< $meta->attributes >>

Returns an arrayref of attributes defined in this class. Includes attributes
from composed roles, but not inherited attributes from parent classes.
Each attribute is either a hashref or a L<Marlin::Attribute> object.

Calling C<< $meta->canonicalize_attributes >> will replace any hashrefs
in this list with Marlin::Attribute objects. That method is chainable, so
the best way to get a list of L<Marlin::Attribute> objects is:
C<< @{ $meta->canonicalize_attributes->attributes } >>.

=item C<< $meta->attributes_with_inheritance >>

Like C<< $meta->attributes >>, but includes parent classes.

=item C<< $meta->strict >>

Boolean indicating if the constructor will be strict.

=item C<< $meta->constructor >>

Name of the constructor method. Usually "new".

=item C<< $meta->modifiers >>

Boolean indicating whether Marlin should export L<Class::Method::Modifiers>
keywords into the package.

=item C<< $meta->inhaled_from >>

Usually undef, but may be "Moose", "Moose::Role", "Moo", "Moo::Role",
"Mouse", "Mouse::Role", "Class::Tiny", or "Class::XSConstructor" to
indicate that this metadata was imported from another OO framework.

=item C<< $meta->short_name >>

The package name without any colons. This is used in the stringification
provided by C<to_string>.

=item C<< $meta->is_struct >>

Boolean indicating that the class was created by L<Marlin::Struct>.

=item C<< $meta->to_string( $object ) >>

Stringifies the object to a representation useful in debugging, etc.

=item C<< $meta->to_arrayref( $object ) >>

Creates an arrayref representation of the object which closely resembles
the string representation.

=item C<< Marlin->can_lexical >>

Returns true if Marlin is running in an environment that supports lexical subs.

=back

=head1 BUGS

Please report any bugs to
L<https://github.com/tobyink/p5-marlin/issues>.

=head1 SEE ALSO

L<Marlin::Role>,
L<Marlin::Struct>,
L<Marlin::Util>,
L<Marlin::Manual::Principles>,
L<Marlin::Manual::Comparison>.

Example extensions:
L<Marlin::X::Clone>,
L<Marlin::X::ToHash>,
L<Marlin::X::UndefTolerant>,
L<Marlin::XAttribute::LocalWriter>,
L<Marlin::XAttribute::Lvalue>.

Modules that Marlin exposes the functionality of:
L<Class::XSAccessor>, L<Class::XSConstructor>, L<Types::Common>,
L<Type::Params>, and L<Sub::HandlesVia>.

Inspirations:
L<Moose> and L<Moo>.

See also:
L<MooseX::Marlin>, L<MooX::Marlin>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2025-2026 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

🐟
