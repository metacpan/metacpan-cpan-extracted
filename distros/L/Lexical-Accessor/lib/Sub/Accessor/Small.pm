use 5.008003;
use strict;
use warnings;
no warnings qw( void once uninitialized );

package Sub::Accessor::Small;

use Carp             qw( carp croak );
use Eval::TypeTiny   qw();
use Exporter::Tiny   qw();
use Hash::FieldHash  qw( fieldhash );
use Scalar::Util     qw( blessed reftype );

BEGIN {
	*HAS_SUB_UTIL = eval { require Sub::Util }
		? sub(){1}
		: sub(){0};
	*HAS_SUB_NAME = !HAS_SUB_UTIL() && eval { require Sub::Name }
		? sub(){1}
		: sub(){0};
};

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.009';
our @ISA       = qw/ Exporter::Tiny /;

fieldhash( our %FIELDS );

sub _generate_has : method
{
	my $me = shift;
	my (undef, undef, $export_opts) = @_;
	
	my $code = sub
	{
		my $attr = $me->new_from_has($export_opts, @_);
		$attr->install_accessors;
	};
	
	HAS_SUB_UTIL ? ($code = Sub::Util::set_subname("$me\::has", $code)) :
	HAS_SUB_NAME ? ($code = Sub::Name::subname("$me\::has", $code)) :
		();
	return $code;
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

sub install_accessors : method
{
	my $me = shift;
	
	for my $type (qw( accessor reader writer predicate clearer ))
	{
		next unless defined $me->{$type};
		$me->install_coderef($me->{$type}, $me->$type);
	}
	
	if (defined $me->{handles})
	{
		my @pairs = $me->expand_handles;
		while (@pairs)
		{
			my ($target, $method) = splice(@pairs, 0, 2);
			$me->install_coderef($target, $me->handles($method));
		}
	}
	
	my @return = map $$_,
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
	
	if (!ref $target and $target =~ /\A[^\W0-9]\w+\z/)
	{
		my $name = "$me->{package}\::$target";
		HAS_SUB_UTIL ? ($coderef = Sub::Util::set_subname($name, $coderef)) :
		HAS_SUB_NAME ? ($coderef = Sub::Name::subname($name, $coderef)) :
			();
		no strict qw(refs);
		*$name = $coderef;
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
	
	croak "Expected installation target to be a reference to an undefined scalar; got $target";
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
		builder    => [qw/ _builder_%s _builder_%s /],
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
			
		if (ref $me->{builder} eq 'CODE')
		{
			HAS_SUB_UTIL or
			HAS_SUB_NAME or
			do { require Sub::Util };
			
			my $code = $me->{builder};
			defined($name) && defined($me->{package})
				or croak("Invalid builder; expected method name as string");
			
			my $is_private = ($name =~ /\A_/) ? 1 : 0;
			
			my $subname    = sprintf($one{builder}[$is_private], $name);
			my $fq_subname = "$me->{package}\::$name";
			$me->_exporter_install_sub(
				$subname,
				{},
				$me->{_export},
				Sub::Name::subname($fq_subname, $code),
			);
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
			unless $me->{builder} || $me->{default};
	}
}

sub canonicalize_default : method
{
	my $me = shift;
	return unless exists $me->{default};
	
	unless (ref $me->{default})
	{
		my $value = $me->{default};
		$me->{default} = sub { $value };
	}
	
	croak("Invalid default; expected a CODE ref")
		unless ref $me->{default} eq 'CODE';
}

sub canonicalize_isa : method
{
	my $me = shift;
	
	if (my $does = $me->{does})
	{
		$me->{isa} ||= sub { blessed($_[0]) && $_[0]->DOES($does) };
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
}

sub canonicalize_trigger : method
{
	my $me = shift;
	
	if (defined $me->{trigger} and not ref $me->{trigger})
	{
		my $method_name = $me->{trigger};
		$me->{trigger} = sub { my $self = shift; $self->$method_name(@_) };
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
	
	return Eval::TypeTiny::eval_closure(
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
	
	sprintf(
		q[ delete(%s) ],
		$me->inline_access,
	);
}

sub inline_access : method
{
	my $me = shift;
	
	sprintf(
		q[ $Sub::Accessor::Small::FIELDS{$_[0]}{%d} ],
		$me->{id},
	);
}

sub inline_access_w : method
{
	my $me = shift;
	my ($expr) = @_;
	
	sprintf(
		q[ %s = %s ],
		$me->inline_access,
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
	
	sprintf(
		q[ exists(%s) ],
		$me->inline_access,
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
	my ($method) = @_;
	
	my $get = $me->inline_access;
	
	my $varname = sprintf('$handler_%d', ++$handler_uniq);
	$me->{inline_environment}{$varname} = \($method);
	
	my $death = 'Scalar::Util::blessed($h) or Carp::croak("Expected blessed object to delegate to; got $h")';
	
	if (ref $method eq 'ARRAY')
	{
		return sprintf(
			q[ %s; my $h = %s; %s; shift; my ($m, @a) = @%s; $h->$m(@a, @_) ],
			$me->inline_default,
			$get,
			$death,
			$varname,
		);
	}
	else
	{
		return sprintf(
			q[ %s; my $h = %s; %s; shift; $h->%s(@_) ],
			$me->inline_default,
			$get,
			$death,
			$varname,
		);
	}
}

sub inline_get : method
{
	my $me = shift;
	
	my $get = $me->inline_access;
	
	if ($me->{auto_deref})
	{
		$get = sprintf(
			q[ do { my $x = %s; wantarray ? (ref($x) eq 'ARRAY' ? @$x : ref($x) eq 'HASH' ? %$x : $x ) : $x } ],
			$get,
		);
	}
	
	return $get;
}

sub inline_default : method
{
	my $me = shift;
	
	if ($me->{lazy})
	{
		my $get = $me->inline_access;
		
		if ($me->{default})
		{
			$me->{inline_environment}{'$default'} = \($me->{default});
			
			return sprintf(
				q[ %s unless %s; ],
				$me->inline_access_w( q[$default->($_[0])] ),
				$me->inline_predicate,
			);
		}
		elsif (defined $me->{builder})
		{
			return sprintf(
				q[ %s unless %s; ],
				$me->inline_access_w( q($_[0]->) . $me->{builder} ),
				$me->inline_predicate,
			);
		}
	}
	
	return '';
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
	
	join('',
		$me->inline_default,
		$me->inline_get,
	);
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
	my $me = shift;
	
	my $get    = $me->inline_access;
	my $coerce = $me->inline_type_coercion('$_[1]');
	
	if ($coerce eq '$_[1]')  # i.e. no coercion
	{
		if (!$me->{trigger} and !$me->{weak_ref})
		{
			return $me->inline_access_w(
				$me->inline_type_assertion('$_[1]'),
			);
		}
		
		return sprintf(
			'%s; %s; %s; %s; %s',
			$me->inline_type_assertion('$_[1]'),
			$me->inline_trigger('$_[1]', $get),
			$me->inline_access_w('$_[1]'),
			$me->inline_weaken,
			$me->inline_get,
		);
	}
	
	sprintf(
		'my $val = %s; %s; %s; %s; %s; $val',
		$coerce,
		$me->inline_type_assertion('$val'),
		$me->inline_trigger('$val', $get),
		$me->inline_access_w('$val'),
		$me->inline_weaken,
	);
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

	my $get    = $me->inline_access;
	my $coerce = $me->inline_type_coercion('$_[1]');
	
	if ($coerce eq '$_[1]')  # i.e. no coercion
	{
		if (!$me->{lazy} and !$me->{trigger} and !$me->{weak_ref})
		{
			return sprintf(
				'(@_ > 1) ? (%s) : %s',
				$me->inline_access_w( $me->inline_type_assertion('$_[1]') ),
				$me->inline_get,
			);
		}
		
		return sprintf(
			'if (@_ > 1) { %s; %s; %s; %s }; %s',
			$me->inline_type_assertion('$_[1]'),
			$me->inline_trigger('$_[1]', $get),
			$me->inline_access_w('$_[1]'),
			$me->inline_weaken,
			$me->inline_reader,
		);
	}
	
	sprintf(
		'if (@_ > 1) { my $val = %s; %s; %s; %s; %s }; %s',
		$coerce,
		$me->inline_type_assertion('$val'),
		$me->inline_trigger('$val', $get),
		$me->inline_access_w('$val'),
		$me->inline_weaken,
		$me->inline_reader,
	);
}

sub inline_type_coercion : method
{
	my $me = shift;
	my ($var) = @_;
	
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
	$me->{inline_environment}{'$coercion'} = \$coercion;
	
	if ( blessed($coercion)
	and $coercion->can('coerce') )
	{
		return sprintf('$coercion->coerce(%s)', $var);
	}
	
	return sprintf('$coercion->(%s)', $var);
}

sub inline_type_assertion : method
{
	my $me = shift;
	my ($var) = @_;
	
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
	$me->{inline_environment}{'$type'} = \$type;
	
	# non-Type::Tiny but still supports inlining
	if ( blessed($type)
	and $type->can('can_be_inlined')
	and $type->can_be_inlined )
	{
		my $inliner = $type->can('inline_check') || $type->can('_inline_check');
		if ($inliner)
		{
			return sprintf('do { %s } ? %s : Carp::croak($type->get_message(%s))', $type->$inliner($var), $var, $var);
		}
	}
	
	if ( blessed($type)
	and $type->can('check')
	and $type->can('get_message') )
	{
		return sprintf('$type->check(%s) ? %s : Carp::croak($type->get_message(%s))', $var, $var, $var);
	}
	
	return sprintf('$type->(%s) ? %s : Carp::croak("Value %s failed type constraint check")', $var, $var, $var);
}

sub inline_weaken : method
{
	my $me = shift;
	
	return '' unless $me->{weak_ref};
	
	sprintf(
		q[ Scalar::Util::weaken(%s) if ref(%s) ],
		$me->inline_access,
		$me->inline_access,
	);
}

sub inline_trigger : method
{
	my $me = shift;
	my ($new, $old) = @_;
	
	my $trigger = $me->{trigger} or return '';
	
	$me->{inline_environment}{'$trigger'} = \$trigger;
	return sprintf('$trigger->($_[0], %s, %s)', $new, $old);
}

1;

__END__

=pod

=encoding utf-8

=for stopwords benchmarking

=head1 NAME

Sub::Accessor::Small - base class used by Lexical::Accessor

=head1 DESCRIPTION

Not documented yet.

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Lexical-Accessor>.

=head1 SUPPORT

Using this module directly is currently unsupported.

=head1 SEE ALSO

L<Lexical::Accessor>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013-2014, 2017 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

