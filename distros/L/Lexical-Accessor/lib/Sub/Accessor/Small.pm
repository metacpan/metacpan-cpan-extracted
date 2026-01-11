use 5.008003;
use strict;
use warnings;
no warnings qw( void once uninitialized );

package Sub::Accessor::Small;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '1.000003';
our @ISA       = qw/ Exporter::Tiny /;
our @EXPORT_OK = qw/ has /;

use Carp             qw( carp croak );
use Eval::TypeTiny   qw();
use Exporter::Tiny   qw();
use Scalar::Util     qw( blessed reftype );

BEGIN {
	*fieldhash =
		eval { require Hash::FieldHash;               \&Hash::FieldHash::fieldhash               } ||
		eval { require Hash::Util::FieldHash;         \&Hash::Util::FieldHash::fieldhash         } ||
		do   { require Hash::Util::FieldHash::Compat; \&Hash::Util::FieldHash::Compat::fieldhash } ;;
};

fieldhash( our %FIELDS );

my $set_subname_is_fake = 0;
*set_subname =
	eval { require Sub::Util } ? \&Sub::Util::set_subname :
	eval { require Sub::Name } ? \&Sub::Name::subname :
	do { $set_subname_is_fake++; sub { pop; } };

sub _generate_has : method
{
	my $me = shift;
	my (undef, undef, $export_opts) = @_;
	
	my $code = sub
	{
		my $attr = $me->new_from_has($export_opts, @_);
		$attr->install_accessors;
	};
	
	return set_subname( "$me\::has", $code );
}

{
	my $uniq = 0;
	sub new_from_has : method
	{
		my $me = shift;
		my $export_opts = ref($_[0]) eq 'HASH' ? shift(@_) : {};
		my ($name, %opts) = (@_%2) ? @_ : (undef, @_);
		
		my $package;
		$package = $export_opts->{into}
			if defined($export_opts->{into}) && !ref($export_opts->{into});
		
		$me->new(
			slot    => $name,
			id      => $uniq++,
			_export => $export_opts,
			($package ? (package => $package) : ()),
			%opts,
		);
	}
}

sub _create_child : method
{
	my $me = shift;
	my $name = shift;
	
	return ref($me)->new_from_has(
		$name,
		$me->{package} ? (package => $me->{package}) : (),
		$me->{_export} ? (_export => $me->{_export}) : (),
		@_,
	);
}

sub has : method
{
	my $me = shift;
	my $attr = $me->new_from_has(@_);
	$attr->install_accessors;
}

sub new : method
{
	my $me = shift;
	my (%opts) = @_;
	my $self = bless(\%opts, $me);
	$self->canonicalize_opts;
	return $self;
}

sub make_var_name : method
{
	my $me = shift;
	my $stem = shift;
	my $sigil = shift || '$';
	
	my $varname = sprintf '%s_for_%s', $stem, $me->{slot};
	$varname =~ s{([\WX])}{sprintf q{X%04XX}, ord($1)}eg;
	
	return $sigil . $varname;
}

sub install_accessors : method
{
	my $me = shift;
	
	for my $type (qw( accessor reader writer predicate clearer ))
	{
		next unless defined $me->{$type};
		$me->install_coderef($me->{$type}, $me->$type);
	}
	
	if (defined $me->{handles}) {
		
		my $shv_data;
		if ($me->{traits} or $me->{handles_via}) {
			
			my @pairs = $me->expand_handles;
			my %handles_map;
			while ( @pairs ) {
				my ( $name ) = splice( @pairs, 0, 2 );
				$handles_map{"$name"} = $name;
			}
			
			require Sub::HandlesVia::Toolkit::SubAccessorSmall;
			my $SHV = 'Sub::HandlesVia::Toolkit::SubAccessorSmall'->new(
				attr => $me,
				handles_map => \%handles_map,
			);
			$shv_data = $SHV->clean_spec(
				$me->{package},
				$me->{slot},
				+{%$me},
			);
			$shv_data and $SHV->install_delegations( $shv_data );
		}
		
		if (!$shv_data) {
			my @pairs = $me->expand_handles;
			while (@pairs) {
				my ($target, $method) = splice(@pairs, 0, 2);
				$me->install_coderef($target, $me->handles($method));
			}
		}
	}
	
	my @return = map { ( ref($_) eq 'REF' or ref($_) eq 'SCALAR' ) ? ${$_} : $_ }
		$me->{is} eq 'ro'   ? ($me->{reader}) :
		$me->{is} eq 'rw'   ? ($me->{accessor}) :
		$me->{is} eq 'rwp'  ? ($me->{reader}, $me->{writer}) :
		$me->{is} eq 'lazy' ? ($me->{reader}) :
		();
	wantarray ? @return : $return[0];
}

sub install_coderef
{
	my $me = shift;
	my ($target, $coderef) = @_;
	
	return unless defined $target;
	
	if (!ref $target and $target =~ /\A[^\W0-9]\w*\z/)
	{
		my $name = "$me->{package}\::$target";
		no strict qw(refs);
		*$name = set_subname( $name, $coderef );
		return;
	}
		
	if (ref($target) eq q(SCALAR) and not defined $$target)
	{
		$$target = $coderef;
		return;
	}
	
	if (!ref($target) and $target eq 1)
	{
		return;
	}
	
	croak "Expected installation target to be a method name or a reference to an undefined scalar; got $target";
}

sub expand_handles
{
	my $me = shift;
	
	if (ref($me->{handles}) eq q(ARRAY))
	{
		return map ($_=>$_), @{$me->{handles}};
	}
	elsif (ref($me->{handles}) eq q(HASH))
	{
		return %{$me->{handles}};
	}
	
	croak "Expected delegations to be a reference to an array or hash; got $me->{handles}";
}

{
	my %one = (
		accessor   => [qw/ %s %s /],
		reader     => [qw/ get_%s _get%s /],
		writer     => [qw/ set_%s _set%s /],
		predicate  => [qw/ has_%s _has%s /],
		clearer    => [qw/ clear_%s _clear%s /],
		trigger    => [qw/ _trigger_%s _trigger_%s /],
		builder    => [qw/ _build_%s _build_%s /],
	);
	
	sub canonicalize_1 : method
	{
		my $me = shift;
		
		my $is_private = ($me->{slot} =~ /\A_/) ? 1 : 0;
		
		for my $type (keys %one)
		{
			next if !exists($me->{$type});
			next if ref($me->{$type});
			next if $me->{$type} ne 1;
			
			croak("Cannot interpret $type=>1 because attribute has no name defined")
				if !defined $me->{slot};
			
			$me->{$type} = sprintf($one{$type}[$is_private], $me->{slot});
		}
	}
	
	sub canonicalize_builder : method
	{
		my $me = shift;
		my $name = $me->{slot};
		
		if ( ref $me->{builder} eq 'CODE' ) {
			
			croak "builder => CODE requires Sub::Util or Sub::Name to be installed"
				if $set_subname_is_fake;
			
			defined($name) && defined($me->{package})
				or croak("Invalid builder; expected method name as string");
			
			my $code = delete $me->{builder};
			my $is_private = ($name =~ /\A_/) ? 1 : 0;
			my $subname = sprintf $one{builder}[$is_private], $name;
			$me->install_coderef( $subname, $code );
			$me->{builder} = $subname;
		}
	}
}

sub canonicalize_is : method
{
	my $me = shift;
	my $name = $me->{slot};
	
	if ($me->{is} eq 'rw')
	{
		$me->{accessor} = $name
			if !exists($me->{accessor}) and defined $name;
	}
	elsif ($me->{is} eq 'ro')
	{
		$me->{reader} = $name
			if !exists($me->{reader}) and defined $name;
	}
	elsif ($me->{is} eq 'rwp')
	{
		$me->{reader} = $name
			if !exists($me->{reader}) and defined $name;
		$me->{writer} = "_set_$name"
			if !exists($me->{writer}) and defined $name;
	}
	elsif ($me->{is} eq 'lazy')
	{
		$me->{reader} = $name
			if !exists($me->{reader}) and defined $name;
		$me->{lazy} = 1
			if !exists($me->{lazy});
		$me->{builder} = 1
			unless $me->{builder} || exists $me->{default};
	}
}

sub canonicalize_default : method
{
	my $me = shift;
	return unless exists $me->{default};
	
	my $ref = ref $me->{default};
	
	if ( $ref eq 'ARRAY' and not @{$me->{default}} ) {
		$ref = 'SCALAR';
		$me->{default} = \'[]';
	}
	elsif ( $ref eq 'HASH' and not %{$me->{default}} ) {
		$ref = 'SCALAR';
		$me->{default} = \'{}';
	}
	
	!$ref or $ref =~ /^(CODE|SCALAR)$/ or croak("Invalid default; expected a non-reference, CODE ref, or SCALAR ref");
}

sub canonicalize_isa : method
{
	my $me = shift;
	
	if (my $does = $me->{does})
	{
		$me->{isa} ||= sub { blessed($_[0]) && $_[0]->DOES($does) };
	}
	
	if ( $me->{enum} )
	{
		require Types::Standard;
		$me->{isa} = Types::Standard::Enum()->of( $me->{coerce} ? \1: (), @{$me->{enum}} );
	}
	
	if (defined $me->{isa} and not ref $me->{isa})
	{
		my $type_name = $me->{isa};
		eval { require Type::Utils }
			or croak("Missing requirement; type constraint strings require Type::Utils");
		
		$me->{isa} = $me->{package}
			? Type::Utils::dwim_type($type_name, for => $me->{package})
			: Type::Utils::dwim_type($type_name);
	}
	
	if ( 'CODE' eq ref $me->{isa} )
	{
		require Type::Tiny;
		$me->{isa} = Type::Tiny->new( constraint => $me->{isa} );
	}
}

sub canonicalize_trigger : method
{
	my $me = shift;
	if ( defined $me->{trigger} ) {
		# Create an additional slot to hold a mutex, preventing the trigger
		# from triggering itself. This slot won't have any accessors, etc
		# so the slot name doesn't need to consist of wordlike characters.
		# Indeed, it's better to include a non-wordlike character to avoid
		# collisions.
		my $slot = sprintf( '%s:trigger_mutex', $me->{slot} );
		$me->{trigger_mutex} = $me->_create_child( $slot );
	}
}

sub canonicalize_opts : method
{
	my $me = shift;
	
	croak("Initializers are not supported") if $me->{initializer};
	croak("Traits are not supported") if $me->{traits};
	croak("The lazy_build option is not supported") if $me->{lazy_build};
	
	$me->canonicalize_1;
	$me->canonicalize_is;
	$me->canonicalize_isa;
	$me->canonicalize_default;
	$me->canonicalize_builder;
	$me->canonicalize_trigger;
}

sub has_simple_accessor : method
{
	my $me = shift;
	return !!0 if !$me->has_simple_reader;
	return !!0 if !$me->has_simple_writer;
	return !!1;
}

sub has_simple_reader : method
{
	my $me = shift;
	return !!0 if $me->{lazy};
	return !!1;
}

sub has_simple_writer : method
{
	my $me = shift;
	return !!0 if exists $me->{trigger};
	return !!0 if exists $me->{isa};
	return !!0 if $me->{weak_ref};
	return !!1;
}

sub has_simple_predicate : method
{
	my $me = shift;
	return !!1;
}

sub has_simple_clearer : method
{
	my $me = shift;
	return !!1;
}

sub accessor_kind : method
{
	return 'small';
}

sub inline_to_coderef : method
{
	my $me = shift;
	my ($method_type, $code) = @_;

	my $kind = $me->accessor_kind;
	my $src  = sprintf(q[sub { %s }], $code);
	my $desc = defined($me->{slot})
		? sprintf('%s %s for %s', $kind, $method_type, $me->{slot})
		: sprintf('%s %s', $kind, $method_type);
	# warn "#### $desc\n$src\n";
	
	Eval::TypeTiny::eval_closure(
		source      => $src,
		environment => $me->{inline_environment},
		description => $desc,
	);
}

sub clearer : method
{
	my $me = shift;
	
	$me->inline_to_coderef(
		clearer => $me->inline_clearer,
	);
}

sub inline_clearer : method
{
	my $me = shift;
	my $selfvar = shift || '$_[0]';
	
	sprintf(
		q[ delete(%s) ],
		$me->inline_access( $selfvar ),
	);
}

sub inline_access : method
{
	my $me = shift;
	my $selfvar = shift || '$_[0]';

	sprintf(
		q[ $Sub::Accessor::Small::FIELDS{%s}{%d} ],
		$selfvar,
		$me->{id},
	);
}

sub inline_access_w : method
{
	my $me = shift;
	my $selfvar = shift || '$_[0]';
	my $expr    = shift || die;
	
	sprintf(
		q[ %s = %s ],
		$me->inline_access( $selfvar ),
		$expr,
	);
}

sub predicate : method
{
	my $me = shift;
	
	$me->inline_to_coderef(
		predicate => $me->inline_predicate,
	);
}

sub inline_predicate : method
{
	my $me = shift;
	my $selfvar = shift || '$_[0]';
	
	sprintf(
		q[ exists(%s) ],
		$me->inline_access( $selfvar ),
	);
}

sub handles : method
{
	my $me = shift;
	my ($method) = @_;
	
	$me->inline_to_coderef(
		'delegated method' => $me->inline_handles,
	);
}

my $handler_uniq = 0;
sub inline_handles : method
{
	my $me = shift;
	my $selfvar  = shift || '$_[0]';
	my $method   = shift || die;
	
	my $get = $me->inline_access( $selfvar );
	
	my $varname = $me->make_var_name( sprintf 'handler_%d', ++$handler_uniq );
	$me->{inline_environment}{$varname} = \($method);
	
	my $death = 'Scalar::Util::blessed($h) or Carp::croak("Expected blessed object to delegate to; got $h")';
	
	if (ref $method eq 'ARRAY')
	{
		return sprintf(
			q[ %s; my $h = %s; %s; shift; my ($m, @a) = @%s; $h->$m(@a, @_) ],
			$me->inline_maybe_write_default( $selfvar ),
			$get,
			$death,
			$varname,
		);
	}
	else
	{
		return sprintf(
			q[ %s; my $h = %s; %s; shift; $h->%s(@_) ],
			$me->inline_maybe_write_default( $selfvar ),
			$get,
			$death,
			$varname,
		);
	}
}

sub inline_get : method
{
	my $me = shift;
	my $selfvar = shift || '$_[0]';
	
	my $get = $me->inline_access( $selfvar );
	
	if ($me->{auto_deref})
	{
		$get = sprintf(
			q[ do { my $x = %s; wantarray ? (ref($x) eq 'ARRAY' ? @$x : ref($x) eq 'HASH' ? %$x : $x ) : $x } ],
			$get,
		);
	}
	
	return $get;
}

sub inline_maybe_write_default : method
{
	my $me = shift;
	my $selfvar = shift || '$_[0]';
	
	if ($me->{lazy})
	{
		return sprintf(
			q[ %s unless %s; ],
			$me->inline_access_w( $selfvar, $me->inline_default( $selfvar ) ),
			$me->inline_predicate( $selfvar ),
		);
	}
	
	return '';
}

sub _is_bool ($)
{
	my $value = shift;
	return !!0 unless defined $value;
	return !!0 if ref $value;
	return !!0 unless Scalar::Util::isdual( $value );
	return !!1 if  $value && "$value" eq '1' && $value+0 == 1;
	return !!1 if !$value && "$value" eq q'' && $value+0 == 0;
	return !!0;
}

sub _created_as_number ($)
{
	my $value = shift;
	return !!0 if utf8::is_utf8($value);
	return !!0 unless defined $value;
	return !!0 if ref $value;
	require B;
	my $b_obj = B::svref_2object(\$value);
	my $flags = $b_obj->FLAGS;
	return !!1 if $flags & ( B::SVp_IOK() | B::SVp_NOK() ) and !( $flags & B::SVp_POK() );
	return !!0;
}

sub _created_as_string ($)
{
	my $value = shift;
	defined($value)
		&& !ref($value)
		&& !_is_bool($value)
		&& !_created_as_number($value);
}

sub inline_default : method
{
	my $me = shift;
	my $selfvar = shift || '$_[0]';
	my $preferred_closeover_var = shift || $me->make_var_name('default');
	
	if (exists $me->{default})
	{
		my $ref = ref $me->{default};
		if ( $ref eq 'CODE' )
		{
			$me->{inline_environment}{$preferred_closeover_var} = \($me->{default});
			return qq[$preferred_closeover_var\->($selfvar)];
		}
		elsif ( $ref eq 'SCALAR' )
		{
			return ${$me->{default}};
		}
		elsif ( !defined $me->{default} )
		{
			return 'undef';
		}
		elsif ( _is_bool $me->{default} )
		{
			return $me->{default} ? '!!1' : '!!0';
		}
		elsif ( _created_as_number $me->{default} )
		{
			return $me->{default} + 0;
		}
		elsif ( _created_as_string $me->{default} )
		{
			require B;
			return B::perlstring( $me->{default} );
		}
	}
	elsif (defined $me->{builder})
	{
		return $selfvar . '->' . $me->{builder};
	}
	
	return undef;
}

sub reader : method
{
	my $me = shift;
	
	$me->inline_to_coderef(
		reader => $me->inline_reader,
	);
}

sub inline_reader : method
{
	my $me = shift;
	my $selfvar = shift || '$_[0]';
	
	if ( $me->{lazy} )
	{
		my $flag;
		delete local $me->{trigger};
		my $w = $me->inline_writer( $selfvar, $me->inline_default( $selfvar ), \$flag );
		
		if ( $flag )
		{
			return sprintf(
				'( (%s) ? (%s) : (%s) )',
				$me->inline_predicate( $selfvar ),
				$me->inline_get( $selfvar ),
				$w,
			);
		}
		else
		{
			return sprintf(
				'( (%s) ? (%s) : do { %s } )',
				$me->inline_predicate( $selfvar ),
				$me->inline_get( $selfvar ),
				$w,
			);
		}
	}
	
	return $me->inline_get( $selfvar );
}

sub writer : method
{
	my $me = shift;
	
	$me->inline_to_coderef(
		writer => $me->inline_writer,
	);
}

sub inline_writer : method
{
	my $me      = shift;
	my $selfvar = shift || '$_[0]';
	my $expr    = shift || '$_[1]';
	my $flag    = shift || undef;
	
	my $get    = $me->inline_access( $selfvar );
	my $coerce = $me->inline_type_coercion( $selfvar, $expr );
	
	# no coercion and simple variable
	if ($coerce eq $expr and $expr =~ /^\$\w+(?:[-][>])?(?:\[\d+\]|\{[^}]\})*$/)
	{
		if (!$me->{trigger} and !$me->{weak_ref})
		{
			$$flag = 1 if $flag;
			return $me->inline_access_w(
				$selfvar,
				$me->inline_type_assertion( $selfvar, $expr ),
			);
		}
		elsif ( !$me->{weak_ref} )
		{
			return sprintf(
				'%s; my @old = (%s) ? (%s) : (); %s; %s; %s',
				$me->inline_type_assertion( $selfvar, $expr ),
				$me->inline_predicate( $selfvar ),
				$me->inline_access( $selfvar ),
				$me->inline_access_w( $selfvar, $expr ),
				$me->inline_trigger( $selfvar, undef, '@old' ),
				$me->inline_get( $selfvar ),
			);
		}
		else
		{
			return sprintf(
				'%s; my @old = (%s) ? (%s) : (); %s; %s; %s; %s',
				$me->inline_type_assertion( $selfvar, $expr ),
				$me->inline_predicate( $selfvar ),
				$me->inline_access( $selfvar ),
				$me->inline_access_w( $selfvar, $expr ),
				$me->inline_trigger( $selfvar, undef, '@old' ),
				$me->inline_weaken( $selfvar ),
				$me->inline_get( $selfvar ),
			);
		}
	}
	
	
	# Use intermediate variable to store result of coercion and/or default
	if ( !$me->{trigger} and !$me->{weak_ref} )
	{
		my $ass = $me->inline_type_assertion( $selfvar, '$val' );
		sprintf(
			'my $val = %s; %s',
			$coerce,
			$me->inline_access_w( $selfvar, $ass =~ /^do/ ? $ass : "do { $ass }" ),
		);
	}
	elsif ( !$me->{weak_ref} )
	{
		sprintf(
			'my $val = %s; %s; my @old = (%s) ? (%s) : (); %s; %s; %s',
			$coerce,
			$me->inline_type_assertion( $selfvar, '$val' ),
			$me->inline_predicate( $selfvar ),
			$me->inline_access( $selfvar ),
			$me->inline_access_w( $selfvar, '$val' ),
			$me->inline_trigger( $selfvar, undef, '@old' ),
			$me->inline_access( $selfvar ),
		);
	}
	else
	{
		sprintf(
			'my $val = %s; %s; my @old = (%s) ? (%s) : (); %s; %s; %s; $val',
			$coerce,
			$me->inline_type_assertion( $selfvar, '$val' ),
			$me->inline_predicate( $selfvar ),
			$me->inline_access( $selfvar ),
			$me->inline_access_w( $selfvar, '$val' ),
			$me->inline_trigger( $selfvar, undef, '@old' ),
			$me->inline_weaken( $selfvar ),
		);
	}
}

sub accessor : method
{
	my $me = shift;
	
	$me->inline_to_coderef(
		accessor => $me->inline_accessor,
	);
}

sub inline_accessor : method
{
	my $me = shift;
	my $selfvar = shift || '$_[0]';
	my $expr    = shift || '$_[1]';
	my $toggle  = shift || '@_ > 1';

	my $get    = $me->inline_access( $selfvar );
	my $coerce = $me->inline_type_coercion( $selfvar, $expr );
	
	if ($coerce eq $expr)  # i.e. no coercion
	{
		if (!$me->{lazy} and !$me->{trigger} and !$me->{weak_ref})
		{
			return sprintf(
				'(%s) ? (%s) : %s',
				$toggle,
				$me->inline_access_w( $selfvar, $me->inline_type_assertion( $selfvar, $expr ) ),
				$me->inline_get( $selfvar ),
			);
		}
		
		return sprintf(
			'if (%s) { %s; my @old = (%s) ? (%s) : (); %s; %s; %s }; %s',
			$toggle,
			$me->inline_type_assertion( $selfvar, $expr ),
			$me->inline_predicate( $selfvar ),
			$me->inline_access( $selfvar ),
			$me->inline_access_w( $selfvar, $expr ),
			$me->inline_trigger( $selfvar, undef, '@old' ),
			$me->inline_weaken( $selfvar ),
			$me->inline_reader( $selfvar ),
		);
	}
	
	sprintf(
		'if (%s) { my $val = %s; %s; my @old = (%s) ? (%s) : (); %s; %s; %s }; %s',
		$toggle,
		$coerce,
		$me->inline_type_assertion( $selfvar, '$val' ),
		$me->inline_predicate( $selfvar ),
		$me->inline_access( $selfvar ),
		$me->inline_access_w( $selfvar, '$val' ),
		$me->inline_trigger( $selfvar, undef, '@old' ),
		$me->inline_weaken( $selfvar ),
		$me->inline_reader( $selfvar ),
	);
}

sub inline_type_coercion : method
{
	my $me = shift;
	my $selfvar = shift || '$_[0]';  # usually ignored
	my $var     = shift || die;
	
	my $coercion = $me->{coerce} or return $var;
	
	unless (ref $coercion)
	{
		my $type = $me->{isa};
		
		if (blessed($type) and $type->can('coercion'))
		{
			$coercion = $type->coercion;
		}
		elsif (blessed($type) and $type->can('coerce'))
		{
			$coercion = sub { $type->coerce(@_) };
		}
		else
		{
			croak("Invalid coerce; type constraint cannot be probed for coercion");
		}
		
		unless (ref $coercion)
		{
			carp("Invalid coerce; type constraint has no coercion");
			return $var;
		}
	}
	
	if ( blessed($coercion)
	and $coercion->can('can_be_inlined')
	and $coercion->can_be_inlined
	and $coercion->can('inline_coercion') )
	{
		return $coercion->inline_coercion($var);
	}
	
	# Otherwise need to close over $coerce
	my $coercion_varname = $me->make_var_name('coercion');
	$me->{inline_environment}{$coercion_varname} = \$coercion;
	
	if ( blessed($coercion)
	and $coercion->can('coerce') )
	{
		return sprintf('%s->coerce(%s)', $coercion_varname, $var);
	}
	
	return sprintf('%s->(%s)', $coercion_varname, $var);
}

sub inline_type_assertion : method
{
	my $me = shift;
	my $selfvar = shift || '$_[0]';  # usually ignored
	my $var     = shift || die;
	
	my $type = $me->{isa} or return $var;
	
	if ( blessed($type)
	and $type->isa('Type::Tiny')
	and $type->can_be_inlined )
	{
		my $ass = $type->inline_assert($var);
		if ($ass =~ /\Ado \{(.+)\};\z/sm)
		{
			return "do { $1 }";  # i.e. drop trailing ";"
		}
		# otherwise protect expression from trailing ";"
		return "do { $ass }"
	}
	
	# Otherwise need to close over $type
	my $type_varname = $me->make_var_name('type');
	$me->{inline_environment}{$type_varname} = \$type;
	
	# non-Type::Tiny but still supports inlining
	if ( blessed($type)
	and $type->can('can_be_inlined')
	and $type->can_be_inlined )
	{
		my $inliner = $type->can('inline_check') || $type->can('_inline_check');
		if ($inliner)
		{
			return sprintf('do { %s } ? %s : Carp::croak(%s->get_message(%s))', $type->$inliner($var), $var, $type_varname, $var);
		}
	}
	
	if ( blessed($type)
	and $type->can('check')
	and $type->can('get_message') )
	{
		return sprintf('%s->check(%s) ? %s : Carp::croak(%s->get_message(%s))', $type_varname, $var, $var, $type_varname, $var);
	}
	
	return sprintf('%s->(%s) ? %s : Carp::croak("Value %s failed type constraint check")', $type_varname, $var, $var, $var);
}

sub inline_weaken : method
{
	my $me = shift;
	my $selfvar = shift || '$_[0]';
	
	return '' unless $me->{weak_ref};
	
	sprintf(
		q[ Scalar::Util::weaken(%s) if ref(%s) ],
		$me->inline_access( $selfvar ),
		$me->inline_access( $selfvar ),
	);
}

sub inline_trigger : method
{
	my $me = shift;
	my $selfvar = shift || '$_[0]';
	my $new     = shift || $me->inline_access( $selfvar );
	my $old     = shift || '';
	
	my $trigger = $me->{trigger} or return '';
	my $run_trigger_code;
	
	if ( ref($trigger) ) {
		my $trigger_varname = $me->make_var_name('trigger');
		$me->{inline_environment}{$trigger_varname} = \$trigger;
		$run_trigger_code = sprintf('%s->(%s, %s, %s)', $trigger_varname, $selfvar, $new, $old);
	}
	else {
		$run_trigger_code = sprintf('%s->%s(%s, %s)', $selfvar, $trigger, $new, $old);
	}
	
	my $mutex = $me->{trigger_mutex};
	return sprintf(
		'%s || do { my $tmp = %s; my $g = %s->new(sub { %s }); %s; %s }',
		$mutex->inline_access($selfvar),
		$selfvar,
		$mutex->_guard_class,
		$mutex->inline_clearer('$tmp'),
		$mutex->inline_access_w($selfvar, '!!1'),
		$run_trigger_code,
	);
}

sub _guard_class : method
{
	return __PACKAGE__ . "::_Guard";
}

{
	package #hide
		Sub::Accessor::Small::_Guard;
	sub new     { bless( [ $_[1], $_[2] ], $_[0] ) }
	sub defang  { $_[0][1] = ( @_==2 ? $_[1] : 1 ) }
	sub DESTROY { $_[0][0]->() unless $_[0][1] }
}

1;

__END__

=pod

=encoding utf-8

=for stopwords benchmarking

=head1 NAME

Sub::Accessor::Small - small toolkit for generating getter/setter methods

=head1 SYNOPSIS

  package MyClass;
  use Sub::Accessor::Small;
  use Types::Standard qw( Int );
  
  sub new {
    my $class = shift;
    my $self  = bless \$class, $class;
    my %args  = @_ == 1 ? %{ $_[0] } : @_;
    
    # Simple way to initialize each attribute
    for my $key ( sort keys %args ) {
      $self->$key( $args{$key} );
    }
    
    return $self;
  }
  
  'Sub::Accessor::Small'->new(
    package  => __PACKAGE__,
    name     => "foo",
    is       => "rw",
    isa      => Int,
  )->install_accessors();
  
  package main;
  
  my $obj = MyClass->new( foo => 42 );

=head1 DESCRIPTION

This is a small toolkit for generating Moose-like attribute accessors.
B<< It does not generate a constructor. >>

It stores attribute values inside-out, but it is designed for 
Sub::Accessor::Small to be subclassed, making it easy to store attributes
in other ways.

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Lexical-Accessor>.

=head1 SEE ALSO

L<Lexical::Accessor>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013-2014, 2017, 2020, 2025 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

