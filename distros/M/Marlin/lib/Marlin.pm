use 5.008008;
use strict;
use warnings;
use utf8;

package Marlin;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.009000';

use constant _ATTRS => qw( caller this parents roles attributes strict constructor modifiers inhaled_from short_name is_struct plugins setup_steps_with_plugins );
use B::Hooks::AtRuntime   qw( at_runtime after_runtime );
use Class::XSAccessor     { getters => [ _ATTRS ] };
use Class::XSConstructor  [ undef, '_new' ], _ATTRS;
use Class::XSDestructor;
use Exporter::Tiny        qw( _croak );
use List::Util 1.45       qw( any uniqstr );
use Module::Runtime       qw( use_package_optimistically module_notional_filename require_module );
use Scalar::Util          qw( blessed weaken );
use Types::Common         qw( -is );

BEGIN {
	require MRO::Compat if $] < 5.010;
};

BEGIN {
	*_HAS_NATIVE_LEXICAL_SUB = ( "$]" >= 5.037002 )
		? sub () { !!1 }
		: sub () { !!0 };
	*_HAS_MODULE_LEXICAL_SUB = ( "$]" >= 5.011002 and eval('require Lexical::Sub; 1') )
		? sub () { !!1 }
		: sub () { !!0 };
};

{
	our %META;

	sub find_meta {
		my $me   = shift;
		my $for  = shift;
		if ( my $class = blessed $for ) {
			$for = $class;
		}
		if ( not exists $META{$for} ) {
			$me->try_inhale( $for );
		}
		$META{$for};
	}

	sub store_meta {
		my $me = shift;
		if ( blessed $me ) {
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
	
	# Native or already inhaled 
	{
		our %META;
		return !!1 if $META{$k};
	}
	
	# Inhale Class::XSAccessor
	if ( @{"$k\::__XSCON_HAS"} ) {
		my $has = \@{"$k\::__XSCON_HAS"};
		my $isa = \%{"$k\::__XSCON_ISA"};
		my $req = \@{"$k\::__XSCON_REQUIRED"};
		my $str =  ${"$k\::__XSCON_STRICT"};
		my $coe = \%{"$k\::__XSCON_COERCIONS"};
		my $def = \%{"$k\::__XSCON_DEFAULTS"};
		my $tt  = \%{"$k\::__XSCON_TYPETINY"};
		my $tri = \%{"$k\::__XSCON_TRIGGERS"};
		my $ia  = \%{"$k\::__XSCON_INIT_ARGS"};
		my $flg = \%{"$k\::__XSCON_FLAGS"};
		
		my @attrs = map {
			my $slot = $_;
			{
				is       => 'bare',
				package  => $k,
				slot     => $slot,
				$tt->{$slot} ? ( isa => $tt->{$slot} ) : $isa->{$slot} ? ( isa => $isa->{$slot} ): (),
				$coe->{$slot} ? ( coerce => $coe->{$slot} ) : (),
				$tri->{$slot} ? ( trigger => $tri->{$slot} ) : (),
				exists( $ia->{$slot} ) ? ( init_arg => $ia->{$slot} ) : (),
				isScalarRef( $def->{$slot} ) ? ( builder => ${$def->{$slot}} ) : exists($def->{$slot}) ? ( default => $def->{$slot} ) : (),
				required => !!( grep $_ eq $slot, @{ $req || [] }),
				( $flg->{$slot} & Class::XSConstructor::XSCON_FLAG_WEAKEN ) ? ( weak_ref => 1 ) : (),
			};
		} @{ $has || [] };
		
		__PACKAGE__->_new(
			this         => $k,
			attributes   => \@attrs,
			parents      => [ @{"$k\::ISA"} ],
			roles        => [],
			strict       => $str,
			constructor  => "__Marlin_${k_short}_new", # ???
			inhaled_from => 'Class::XSConstructor',
			short_name   => $k_short,
		)->store_meta;
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
				require Carp;
				Carp::carp("Marlin inhaled a mutable Moose class: $k");
			}
			
			my @attrs = map {
				my $attr = $_;
				{
					is       => $attr->{is} || 'bare',
					package  => $attr->definition_context->{package} || $k,
					slot     => $attr->name,
					$attr->has_type_constraint ? ( isa => Types::Common::to_TypeTiny($attr->type_constraint) ) : (),
					$attr->should_coerce ? ( coerce => 1 ) : (),
					$attr->has_trigger ? ( trigger => $attr->trigger ) : (),
					init_arg => $attr->init_arg,
					$attr->has_builder ? ( builder => $attr->builder ) : $attr->has_default ? ( default => $attr->default ) : (),
					$attr->is_required ? ( required => 1 ) : (),
					$attr->is_weak_ref ? ( weak_ref => 1 ) : (),
					$attr->is_lazy ? ( lazy => 1 ) : (),
				};
			} $moose_meta->get_all_attributes;
			
			__PACKAGE__->_new(
				this         => $k,
				attributes   => \@attrs,
				parents      => [ @{"$k\::ISA"} ],
				roles        => [ uniqstr( map { $_->name } @{ $moose_meta->roles } ) ],
				strict       => !!Moose::Util::does_role($moose_meta, 'MooseX::StrictConstructor::Trait::Class'),
				constructor  => $moose_meta->constructor_name,
				inhaled_from => 'Moose',
				short_name   => $k_short,
			)->store_meta;
			
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
					defined $attr->{isa} ? ( isa => Types::Common::to_TypeTiny($attr->{isa}) ) : (),
				};
			} $moose_meta->get_attribute_list;
			
			use Marlin::Role;
			'Marlin::Role'->_new(
				this         => $k,
				attributes   => \@attrs,
				roles        => [ uniqstr( map { $_->name } @{ $moose_meta->get_roles } ) ],
				inhaled_from => 'Moose::Role',
			)->store_meta;
			
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
		
		__PACKAGE__->_new(
			this         => $k,
			attributes   => \@attr,
			parents      => [ @{"$k\::ISA"} ],
			roles        => [ keys %{ $Role::Tiny::APPLIED_TO{$k} } ],
			strict       => Moo::Role::does_role($maker, 'MooX::StrictConstructor::Role::Constructor::Base'),
			constructor  => 'new',
			inhaled_from => 'Moo',
			short_name   => $k_short,
		)->store_meta;
		
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
		'Marlin::Role'->_new(
			this         => $k,
			attributes   => \@attr,
			roles        => [ keys %{ $Role::Tiny::APPLIED_TO{$k} } ],
			inhaled_from => 'Moo::Role',
		)->store_meta;
		
		return 'Moo::Role';
	}
	
	return !!0;
}

sub can_lexical {
	_HAS_NATIVE_LEXICAL_SUB || _HAS_MODULE_LEXICAL_SUB;
}

sub _croaker {
	return __PACKAGE__ . "::_croak";
}

sub import {
	my $class = shift;
	my $me = $class->new( -caller => [ scalar(CORE::caller) ], @_ );
	$me->store_meta;
	$me->do_setup;
}

my $_parse_package_list = sub {
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
	
	return @r;
};

my $_parse_attribute = sub {
	my ( $class, $name, $ref ) = @_;
	$ref ||= {};
	
	if ( blessed($ref) and $ref->DOES('Type::API::Constraint') ) {
		my $tc = $ref;
		$ref = {
			isa      => $tc,
			coerce   => !!( $tc->DOES('Type::API::Constraint::Coercible') and $tc->has_coercion ),
		};
	}
	elsif ( is_CodeRef $ref ) {
		my $builder = $ref;
		$ref = {
			lazy     => !!1,
			builder  => $builder,
		};
	}
	
	if ( $name =~ /^(.+)\!(\W*)$/ ) {
		$ref->{required} = !!1;
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
		$ref->{predicate} = !!1;
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
	
	_croak("Bad attribute name: $name") unless $name =~ /\A[^\W0-9]\w*\z/;
	
	my $default_init_arg = exists( $ref->{constant} ) ? undef : $name;
	return { is => 'ro', init_arg => $default_init_arg, %$ref, slot => $name };
};

sub new {
	my $class   = shift;
	
	my %arg = (
		parents      => [],
		roles        => [],
		attributes   => [],
		strict       => !!1,
		modifiers    => !!0,
		constructor  => 'new',
		plugins      => [],
	);
	
	while ( @_ ) {
		my ( $k, $v, $has_v ) = ( shift );
		if ( ref $_[0] or not defined $_[0] ) {
			( $v, $has_v ) = ( shift, !!1 );
		}
		
		if ( $k =~ /^-(?:base|isa|parent|parents|extends)$/ ) {
			( $v, $has_v ) = ( shift, !!1 ) unless $has_v;
			_croak("Expected arrayref or hashref of parent classes") unless $v;
			push @{ $arg{parents} }, $class->$_parse_package_list( $v );
		}
		elsif ( $k =~ /^-(?:with|does|role|roles)$/ ) {
			( $v, $has_v ) = ( shift, !!1 ) unless $has_v;
			_croak("Expected arrayref or hashref of roles") unless $v;
			push @{ $arg{roles} }, $class->$_parse_package_list( $v );
		}
		elsif ( $k =~ /^-(?:class|self|this)$/ ) {
			( $v, $has_v ) = ( shift, !!1 ) unless $has_v;
			_croak("Expected scalarref to this class name") unless $v;
			my @got = $class->$_parse_package_list( $v );
			_croak("This class must have exactly one name") if @got != 1 || exists $arg{this};
			$arg{this} = $got[0][0];
		}
		elsif ( $k =~ /^-(?:caller)$/ ) {
			( $v, $has_v ) = ( shift, !!1 ) unless $has_v;
			my @got = $class->$_parse_package_list( $v );
			_croak("Can be only one caller") if @got != 1 || exists $arg{caller};
			$arg{caller} = $got[0][0];
		}
		elsif ( $k =~ /^-(?:constructor)$/ ) {
			( $v, $has_v ) = ( shift, !!1 ) unless $has_v;
			my @got = $class->$_parse_package_list( $v );
			$arg{constructor} = $got[0][0];
		}
		elsif ( $k =~ /^-(?:(?:loose|sloppy)(?:_?constructor)?)$/ ) {
			$arg{strict} = !!0;
		}
		elsif ( $k =~ /^-(?:(?:strict)(?:_?constructor)?)$/ or $k eq '!!' ) {
			$arg{strict} = !!1;
		}
		elsif ( $k =~ /^-(?:modifiers?|mods?)$/ ) {
			$arg{modifiers} = !!1;
		}
		elsif ( $k =~ /^-(?:requires?)$/ ) {
			( $v, $has_v ) = ( shift, !!1 ) unless $has_v;
			_croak("Expected arrayref of required method names") unless is_ArrayRef $v;
			$arg{requires} = $v;
		}
		elsif ( $k =~ /^:(.+)$/ ) {
			my $plugin = "Marlin::X::$1";
			push @{ $arg{plugins} }, [ $plugin, $v ];
		}
		else {
			push @{ $arg{attributes} }, $class->$_parse_attribute( $k, $v );
		}
	}
	
	if ( my $caller = $arg{caller} ) {
		$arg{this} ||= $caller;
	}
	
	_croak "Not sure what class to create" unless $arg{this};
	
	( $arg{short_name} = $arg{this} ) =~ s/(::|')//g;
	
	return $class->_new( \%arg );
}

sub do_setup {
	my $me = shift;
	
	my $steps = [ $me->setup_steps ];
	my %handled;
	
	for my $pair ( @{ $me->plugins } ) {
		my ( $plugin, $opts ) = @$pair;
		$handled{$plugin} ? next : ( $handled{$plugin} = $pair );
		if ( is_HashRef $opts and $opts->{try} ) {
			use_package_optimistically( $plugin );
			$pair->[2] = undef;
			if ( $plugin->can('new') ) {
				$pair->[2] = $plugin->new( %$opts, marlin => $me );
				$pair->[2]->adjust_setup_steps( $steps );
			}
		}
		else {
			require_module( $plugin );
			$pair->[2] = $plugin->new(
				is_HashRef($opts) ? ( %$opts ) : (),
				marlin => $me,
			);
			$pair->[2]->adjust_setup_steps( $steps );
		}
	}
	
	for my $step ( @$steps ) {
		my @args;
		if ( $step =~ /^(.+)::(\w+)$/ ) {
			my $plugin = $1;
			push @args, $handled{$plugin}[2];
		}
		$me->$step( @args );
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
		setup_constructor
		setup_destructor
		setup_accessors
		setup_imports
		optimize_methods
	/;
}

sub mark_inc {
	my $me = shift;
	
	my $file = module_notional_filename($me->this);
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
		&use_package_optimistically( $pkg, defined($ver) ? $ver : () );
	} @{ $me->parents } or return $me;
	my $ISA = do {
		no strict 'refs';
		\@{sprintf("%s::ISA", $me->this)};
	};
	@$ISA = uniqstr( @$ISA, @parents );
	
	return $me;
}

sub setup_roles {
	my $me = shift;
	
	my @roles = uniqstr(
		map {
			my ( $pkg, $ver ) = @$_;
			&use_package_optimistically( $pkg, defined($ver) ? $ver : () );
		} @{ $me->roles }
	) or return $me;
	
	my ( @moose_roles, @tiny_roles );
	if ( $INC{'Moose/Role.pm'} ) {
		require Moose::Util;
		for my $r ( @roles ) {
			my $m = Moose::Util::find_meta( $r );
			if ( $m and $m->isa('Moose::Meta::Role') ) {
				push @moose_roles, $r;
			}
			else {
				push @tiny_roles, $r;
			}
		}
	}
	else {
		@tiny_roles = @roles;
	}
	
	at_runtime {
		require Role::Tiny;
		Role::Tiny->apply_roles_to_package( $me->this, @tiny_roles );
	} if @tiny_roles;
	
	at_runtime {
		Moose::Util::ensure_all_roles( $me->this, @moose_roles );
	} if @moose_roles;

	my $existing;
	for my $r ( @roles ) {
		my $r_meta = $me->find_meta( $r );
		if ( blessed $r_meta and $r_meta->isa('Marlin::Role') ) {
			$existing ||= do {
				my %e;
				for my $attr ( @{ $me->attributes } ) {
					undef $e{$attr->{slot}};
				}
				\%e;
			};
			for my $attr ( @{ $r_meta->attributes } ) {
				require Clone;
				my $copy = Clone::clone( $attr );
				$copy->{package} = $me->this;
				push @{ $me->attributes }, $copy;
			}
		}
	}
	
	return $me;
}

sub canonicalize_attributes {
	my $me = shift;
	
	require Marlin::Attribute;
	@{ $me->attributes } = map {
		blessed( $_ )
			? $_
			: Marlin::Attribute->new( %$_, package => $me->this, marlin => $me );
	} @{ $me->attributes };
	
	return $me;
}

sub setup_constructor {
	my $me = shift;
	
	my $attr = $me->attributes_with_inheritance;
	if ( any { $_->requires_pp_constructor } @$attr ) {
		my $code = $me->build_pp_constructor( $attr );
		$me->export( $me->constructor, $code->finalize->compile );
	}
	else {
		my @dfn = map {
			my $name = $_->{slot};
			my $req  = $_->{required} ? '!'           : '';
			my $opt  = {};
			$opt->{isa}      = $_->{isa}       if defined $_->{isa};
			$opt->{coerce}   = 1               if $_->{coerce} && blessed $_->{isa};
			$opt->{default}  = $_->{default}   if !$_->{lazy} && exists $_->{default};
			$opt->{builder}  = $_->{builder}   if !$_->{lazy} && defined $_->{builder};
			$opt->{init_arg} = $_->{init_arg}  if exists $_->{init_arg};
			$opt->{trigger}  = $_->{trigger}   if $_->{trigger};
			$opt->{weak_ref} = $_->{weak_ref}  if $_->{weak_ref};
			$_->{storage} eq 'HASH' ? ( $name.$req => $opt ) : ();
		} @$attr;
		push @dfn, '!!' if $me->strict;
		Class::XSConstructor->import( [ $me->this, $me->constructor ], @dfn );
	}
	
	return $me;
}

sub setup_destructor {
	my $me = shift;
	
	Class::XSDestructor->import( [ $me->this, 'DESTROY' ] );
	
	return $me;
}

sub setup_accessors {
	my $me = shift;
	
	for my $attr ( @{ $me->attributes } ) {
		$attr->install_accessors;
	}
	
	return $me;
}

sub setup_imports {
	my $me = shift;
	
	my @imports;
	if ( $me->modifiers ) {
		require Class::Method::Modifiers;
		push @imports, (
			before => \&Class::Method::Modifiers::before,
			after  => \&Class::Method::Modifiers::after,
			around => \&Class::Method::Modifiers::around,
			fresh  => \&Class::Method::Modifiers::fresh,
		);
	}
	
	$me->lexport( @imports );
	
	return $me;
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
		after_runtime {
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
		};
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
	}
	
	my %already;
	return [
		reverse
		grep { not $already{$_->{slot}}++ }
		map  { my $m = $me->find_meta($_); $m ? reverse( @{ $m->canonicalize_attributes->attributes } ) : () }
		@isa
	];
}

sub build_pp_constructor {
	my $me   = shift;
	my $attr = shift;
	
	require Eval::TypeTiny::CodeAccumulator;
	my $code = Eval::TypeTiny::CodeAccumulator->new;
	$code->add_line( 'sub {' );
	$code->increase_indent;
	$code->add_line( 'my $class    = ref( $_[0] ) ? ref( shift ) : shift;' );
	$code->add_line( 'my $self     = bless( {}, $class );' );
	$code->addf( 'my %%args     = ( @_ == 1 and %s ) ? %%{+shift} : @_;', Types::Common::HashRef->inline_check('$_[0]') );
	$code->add_line( 'my $no_build = delete $args{__no_BUILD__};' );
	$code->add_gap;
	for my $at ( @$attr ) {
		$at->{_locally_compiling_class} = $me->this;
		$at->_compile_init( $code );
		delete $at->{_locally_compiling_class};
	}
	$code->add_gap;
	$code->addf( '$%s::BUILD_CACHE{$class} ||= do {', __PACKAGE__ );
	$code->increase_indent;
	$code->add_line( 'no strict "refs";' );
	$code->add_line( 'my $linear_isa = mro::get_linear_isa($class);' );
	$code->add_line( '[ map { ( *{$_}{CODE} ) ? ( *{$_}{CODE} ) : () } map { "$_\::BUILD" } reverse @$linear_isa ];' );
	$code->decrease_indent;
	$code->add_line( '};' );
	$code->addf( '$_->( $self, \%%args ) for @{ $%s::BUILD_CACHE{$class} };', __PACKAGE__ );
	if ( $me->strict ) {
		$code->add_gap;
		my @allowed =
			grep { defined $_ }
			map { exists($_->{init_arg}) ? $_->{init_arg} : $_->{slot} }
			@$attr;
		my $check = do {
			my $enum = Types::Common::Enum->of( @allowed );
			$enum->can( '_regexp' )
				? sprintf( '/\\A%s\\z/', $enum->_regexp )
				: $enum->inline_check( '$_' );
		};
		$code->addf( 'my @unknown = grep not( %s ), keys %%args;', $check );
		$code->addf( '%s("Unexpected keys in constructor: " . join( q[, ], sort @unknown ) ) if @unknown;', $me->_croaker );
	}
	$code->add_gap;
	$code->add_line( 'return $self;' );
	$code->decrease_indent;
	$code->add_line( '}' );
	return $code;
}

sub make_type_constraint {
	my $me = shift;
	my $name = shift;
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
	
	my $isa = ( $attr and is_TypeTiny $attr->{isa} ) ? $attr->{isa} : Types::Common::Any;
	
	if ( $isa and $isa->is_a_type_of(Types::Common::Bool) and is_Bool $value ) {
		return $value ? 'true' : 'false';
	}
	
	if ( $isa and $isa->is_a_type_of(Types::Common::Num) and is_Num $value ) {
		return 0 + $value;
	}
	
	if ( $isa and $isa->is_a_type_of(Types::Common::Str) and is_Str $value ) {
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

1;

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
      say "Hi " . $arg->audience . "!" if $arg->has_audience;
      say "My name is " . $self->name . ".";
    }
  }
  
  package Employee {
    use Marlin
      -base =>  [ 'Person' ],
      'employee_id!';
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

It may not be as fast as classes built with the Perl builtin C<class> syntax
introduced in Perl v5.38.0, but has more features and supports Perl versions
as old as v5.8.8. (Some features require v5.12.0+.)

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
built, especially in the case of L<Marlin::Struct> classes.)

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
        is      => 'rw',
        isa     => Str,
        trigger => sub ($me) { $self->clear_full_name }
      },
      last_name => {
        is      => 'rw',
        isa     => Str,
        trigger => sub ($me) { $self->clear_full_name }
      },
      full_name => {
        is      => 'lazy',
        isa     => Str,
        clearer => true,
        builder => sub ($me) { join q[ ], $me->first_name, $me->last_name }
      };
  }

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
        is      => 'ro',
        isa     => Str,
        writer  => 'my set_first_name',
      },
      last_name => {
        is      => 'ro',
        isa     => Str,
        writer  => 'my set_last_name',
      },
      full_name => {
        is      => 'lazy',
        isa     => Str,
        clearer => true,
        builder => sub ($me) { join q[ ], $me->first_name, $me->last_name }
      };
    
    signature_for rename => (
      method  => true,
      named   => [ first_name => Optional[Str], last_name => Optional[Str] ],
    );
    
    sub rename ( $self, $arg ) {
      $self->&set_first_name($arg->first_name) if $arg->has_first_name;
      $self->&set_last_name($arg->last_name) if $arg->has_last_name;
      return $self;
    }
  }

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
  
  my $bob = Local::User->new( username => 'bd', password => 'zi1ch' );
  
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
from L<Class::XSConstructor>, L<Moo>, and L<Moose> classes. Other base classes
I<may> work, especially if they don't do anything much in their constructor.

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
L<Moo::Role>, or L<Moose::Role>.

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

=head3 Other Features

C<BUILD> and C<DEMOLISH> are supported.

=head3 Major Missing Features

Here are some features found in L<Moo> and L<Moose> which are missing from
L<Marlin>:

=over

=item *

Support for C<BUILDARGS>.

You can work around this by naming your constructor something other than
C<new>, then wrapping it.

=item *

The metaobject protocol.

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
in this list with Marlin::Attribute objects.

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

Usually undef, but may be "Moose", "Moose::Role", "Moo", or "Moo::Role" to
indicate that this metadata was imported from Moose or Moo.

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

L<Marlin::X::Clone>.

L<Class::XSAccessor>, L<Class::XSConstructor>, L<Types::Common>,
L<Type::Params>, and L<Sub::HandlesVia>.

L<Moose> and L<Moo>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2025 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

🐟
