use 5.014;
use strict;
use warnings;

package Kavorka::Parameter;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.039';
our @CARP_NOT  = qw( Kavorka::Signature Kavorka::Sub Kavorka );

use Carp qw( croak );
use Text::Balanced qw( extract_codeblock extract_bracketed );
use Parse::Keyword {};
use Parse::KeywordX;

use Moo;
use namespace::sweep;

has package         => (is => 'ro');
has type            => (is => 'ro');
has name            => (is => 'ro');
has constraints     => (is => 'ro', default => sub { +[] });
has named           => (is => 'ro', default => sub { 0 });
has named_names     => (is => 'ro', default => sub { +[] });

has position        => (is => 'rwp');
has default         => (is => 'ro');
has default_when    => (is => 'ro');
has ID              => (is => 'rwp');
has traits          => (is => 'ro', default => sub { +{} });

has sigil           => (is => 'lazy', builder => sub { substr(shift->name, 0, 1) });
has kind            => (is => 'lazy', builder => 1);

sub readonly  { !!shift->traits->{ro} }
sub ro        { !!shift->traits->{ro} }
sub rw        {  !shift->traits->{ro} }
sub alias     { !!shift->traits->{alias} }
sub copy      {  !shift->traits->{alias} }
sub slurpy    { !!shift->traits->{slurpy} }
sub optional  { !!shift->traits->{optional} }
sub invocant  { !!shift->traits->{invocant} }
sub coerce    { !!shift->traits->{coerce} }
sub locked    { !!shift->traits->{locked} }

our @PARAMS;
sub BUILD
{
	my $self = shift;
	my $id = scalar(@PARAMS);
	$self->_set_ID($id);
	$PARAMS[$id] = $self;
	
	my $traits = $self->traits;
	
	exists($traits->{rw})
		and !exists($traits->{ro})
		and ($traits->{ro} = !$traits->{rw});
	
	exists($traits->{ro})
		and !exists($traits->{rw})
		and ($traits->{rw} = !$traits->{ro});
	
	exists($traits->{copy})
		and !exists($traits->{alias})
		and ($traits->{alias} = !$traits->{copy});
	
	exists($traits->{alias})
		and !exists($traits->{copy})
		and ($traits->{copy} = !$traits->{alias});
	
	$traits->{$_} || delete($traits->{$_}) for keys %$traits;
	
	# traits handled natively
	state $native_traits = {
		coerce    => 1,
		copy      => 1,
		invocant  => 1,
		rw        => 1,
		slurpy    => 1,
	};
	
	my @custom_traits =
		map  "Kavorka::TraitFor::Parameter::$_",
		grep !exists($native_traits->{$_}),
		keys %$traits;
	
	'Moo::Role'->apply_roles_to_object($self, @custom_traits) if @custom_traits;
}

sub _build_kind
{
	my $self = shift;
	local $_ = $self->name;
	/::/ ? 'global' : /\A[\$\@\%](?:\W|_\z)/ ? 'magic' : 'my';
}

my $variable_re = qr{ [\$\%\@] (?: \{\^[A-Z]+\} | \w* ) }x;

sub parse
{
	state $deparse = do { require B::Deparse; 'B::Deparse'->new };
	
	my $class = shift;
	my %args = @_;
	
	lex_read_space;
	
	my %traits = (
		invocant  => 0,
		_optional => 1,
	);
	
	if (lex_peek(6) eq 'slurpy')
	{
		lex_read(6);
		lex_read_space;
		$traits{slurpy} = 1;
	}
	
	my $type;
	my $peek = lex_peek(1000);
	if ($peek =~ /\A[^\W0-9]/ and not $peek =~ /\A(my|our)\b/)
	{
		my $reg = do {
			require Type::Registry;
			require Type::Utils;
			my $tmp = 'Type::Registry::DWIM'->new;
			$tmp->{'~~chained'} = $args{package};
			$tmp->{'~~assume'}  = 'make_class_type';
			$tmp;
		};
		
		require Type::Parser;
		($type, my($remaining)) = Type::Parser::extract_type($peek, $reg);
		my $len = length($peek) - length($remaining);
		lex_read($len);
		lex_read_space;
	}
	elsif ($peek =~ /\A\(/)
	{
		lex_read(1);
		lex_read_space;
		my $expr = parse_listexpr
			or croak('Could not parse type constraint expression as listexpr');
		lex_read_space;
		lex_peek eq ')'
			or croak("Expected ')' after type constraint expression");
		lex_read(1);
		lex_read_space;
		
		require Types::TypeTiny;
		$type = Types::TypeTiny::to_TypeTiny( scalar $expr->() );
		$type->isa('Type::Tiny')
			or croak("Type constraint expression did not return a blessed type constraint object");
	}
	
	my ($named, $parens, $varname, $varkind, @paramname) = (0, 0);
	
	# :foo( ... )
	if (lex_peek(2) =~ /\A\:\w/)
	{
		$named = 2;
		$traits{_optional} = 1;
		while (lex_peek(2) =~ /\A\:\w/)
		{
			lex_read(1);
			push @paramname, parse_name('named parameter name', 0);
			if (lex_peek eq '(')
			{
				lex_read(1);
				$parens++;
			}
			lex_read_space;
		}
	}
	
	# Allow colon before "my"/"our" - just shift it to the correct position
	my $saw_colon;
	if (lex_peek eq ':')
	{
		$saw_colon++;
		lex_read(1);
		lex_read_space;
	}
	
	if (lex_peek eq '\\')
	{
		$traits{ref_alias} = 1;
		lex_read(1);
		lex_read_space;
	}
	
	if (lex_peek(3) =~ /\A(my|our)/)
	{
		$varkind = $1;
		lex_read(length $varkind);
		lex_read_space;
	}
	
	if (lex_peek eq '\\')
	{
		croak("cannot be a double-ref-alias") if $traits{ref_alias}++;
		lex_read(1);
		lex_read_space;
	}
	
	lex_stuff(':') if $saw_colon; # re-insert colon
	$peek = lex_peek;
	
	# :$foo
	if ($peek eq ':')
	{
		lex_read(1);
		lex_read_space;
		$varname = parse_variable;
		$named   = 1;
		$traits{_optional} = 1;
		push @paramname, substr($varname, 1);
		lex_read_space;
	}
	# $foo
	elsif ($peek eq '$' or $peek eq '@' or $peek eq '%')
	{
		$varname = parse_variable(1);
		$traits{_optional} = 0 unless @paramname;
		lex_read_space;
	}
	
	undef($peek);
	
	for (1 .. $parens)
	{
		lex_peek(1) eq ')'
			? lex_read(1)
			: croak("Expected close parentheses after named parameter name");
		lex_read_space;
	}
	
	if (lex_peek eq '!')
	{
		$traits{optional} = 0;
		lex_read(1);
		lex_read_space;
	}
	elsif (lex_peek eq '?')
	{
		$traits{optional} = 1;
		lex_read(1);
		lex_read_space;
	}
	
	my (@constraints, $default, $default_when);
	
	while (lex_peek(5) eq 'where')
	{
		lex_read(5);
		lex_read_space;
		push @constraints, parse_block_or_match;
		lex_read_space;
	}
	
	while (lex_peek(5) =~ m{ \A (is|does|but) \s }xsm)
	{
		lex_read(length($1));
		lex_read_space;
		my ($name, undef, $args) = parse_trait;
		$traits{$name} = $args;
		lex_read_space;
	}
	
	if (lex_peek(5) =~ m{ \A ( (?: [/]{2} | [|]{2} )?= ) }x)
	{
		$default_when = $1;
		lex_read(length($1));
		lex_read_space;
		$default = lex_peek(5) =~ m{ \A (?: when\b | [,)] ) }x
			? sub { (); }
			: parse_arithexpr;
		lex_read_space;
		$traits{_optional} = 1;
	}
	
	$traits{optional} //= $traits{_optional};
	delete($traits{_optional});
	
	$traits{slurpy} = 1
		if defined($varname)
		&& !$traits{ref_alias}
		&& $varname =~ /\A[\@\%]/;
	
	return $class->new(
		%args,
		type           => $type,
		name           => $varname,
		constraints    => \@constraints,
		named          => !!$named,
		named_names    => \@paramname,
		default        => $default,
		default_when   => $default_when,
		traits         => \%traits,
		((kind         => $varkind) x!!(defined $varkind)),
	);
}

sub sanity_check
{
	my $self = shift;
	
	my $traits = $self->traits;
	my $name   = $self->name;
	
	if ($self->named)
	{
		length($_) || croak("Bad name for parameter $name")
			for @{ $self->named_names or die };
		
		croak("Bad parameter $name") if $self->invocant;
		croak("Bad parameter $name") if $self->slurpy;
	}
	
	if ($self->kind eq 'my')
	{
		croak("Bad name for lexical variable: $name") if $name =~ /(::|\^)/;
	}
	else
	{
		croak("Bad name for package variable: $name") if length($name) < 2;
	}
	
	croak("Bad parameter $name") if $self->invocant && $self->slurpy;
}

sub injection
{
	my $self = shift;
	my ($sig) = @_;
	
	my $var = $self->name;
	my $is_dummy = 0;
	if (length($var) == 1)
	{
		$var .= 'tmp';
		$is_dummy = 1;
	}
	
	my ($val, $condition) = $self->_injection_extract_and_coerce_value($sig);
	
	my $code = $self->_injection_assignment($sig, $var, $val)
		. $self->_injection_conditional_type_check($sig, $condition, $var);
	
	$is_dummy ? "{ $code }" : $code;
}

sub _injection_assignment
{
	my $self = shift;
	my ($sig, $var, $val) = @_;
	my $kind = $self->kind;
	
	sprintf(
		'%s %s = %s;',
		(
			$kind eq 'our' ? "our $var; local" :
			$kind eq 'my'  ? 'my' :
			'local'
		),
		$var,
		$val,
	);
}

sub _injection_conditional_type_check
{
	my $self = shift;
	my ($sig, $condition, $var) = @_;
	
	my $sigil = $self->sigil;
	my $type =
		($sigil eq '@') ? sprintf('for (%s) { %s }', $var, $self->_injection_type_check('$_')) :
		($sigil eq '%') ? sprintf('for (values %s) { %s }', $var, $self->_injection_type_check('$_')) :
		($condition eq '1')    ? sprintf('%s;', $self->_injection_type_check($var)) :
		sprintf('if (%s) { %s }', $condition, $self->_injection_type_check($var));
	
	return '' if $type =~ /\{  \}\z/;
	
	return sprintf(
		'unless ($____nobble_checks) { %s };',
		$type,
	) if $sig->nobble_checks;
	
	return $type;
}

sub _injection_extract_and_coerce_value
{
	my $self = shift;
	my ($sig) = @_;
	
	$self->coerce
		or return $self->_injection_extract_value(@_);
	
	my $type = $self->type
		or croak("Parameter ${\ $self->name } cannot coerce without a type constraint");
	$type->has_coercion
		or croak("Parameter ${\ $self->name } cannot coerce because type constraint has no coercions defined");
	
	my ($val, $condition) = $self->_injection_extract_value(@_);
	
	my $coerce_variable = sub {
		my $variable = shift;
		if ($type->coercion->can_be_inlined)
		{
			$type->coercion->inline_coercion($variable),
		}
		else
		{
			sprintf(
				'$%s::PARAMS[%d]->{type}->coerce(%s)',
				__PACKAGE__,
				$self->ID,
				$variable,
			);
		}
	};
	
	my $sigil = $self->sigil;
	
	if ($sigil eq '@')
	{
		$val = sprintf(
			'(map { %s } %s)',
			$coerce_variable->('$_'),
			$val,
		);
	}
	
	elsif ($sigil eq '%')
	{
		$val = sprintf(
			'do { my %%tmp = %s; for (values %%tmp) { %s }; %%tmp }',
			$val,
			$coerce_variable->('$_'),
		);
	}
	
	elsif ($sigil eq '$' and $type->coercion->can_be_inlined)
	{
		$val = sprintf(
			'do { my $tmp = %s; %s}',
			$val,
			$coerce_variable->('$tmp'),
		);
	}
	
	elsif ($sigil eq '$')
	{
		$val = $coerce_variable->($val);
	}
	
	wantarray ? ($val, $condition) : $val;
}

sub _injection_default_value
{
	my $self = shift;
	my ($fallback) = @_;
	
	return sprintf('$%s::PARAMS[%d]{default}->()', __PACKAGE__, $self->ID) if $self->default;
	return $fallback if defined $fallback;
	
	return sprintf(
		'Carp::croak(sprintf q/Named parameter `%%s` is required/, %s)',
		B::perlstring($self->named_names->[0]),
	) if $self->named;
	
	return sprintf(
		'Carp::croak(q/Invocant %s is required/)',
		$self->name,
	) if $self->invocant;
	
	return sprintf(
		'Carp::croak(q/Positional parameter %d is required/)',
		$self->position,
	);
}

sub _injection_extract_value
{
	my $self = shift;
	my ($sig) = @_;
	
	my $condition;
	my $val;
	my $slurpy_style = '';
	
	if ($self->slurpy)
	{
		if ($self->sigil eq '%'
		or ($self->sigil eq '$'
			and $self->type
			and do { require Types::Standard; $self->type->is_a_type_of(Types::Standard::HashRef()) }))
		{
			my @names = map(@{$_->named ? $_->named_names : []}, @{$sig->params});
			if (@names)
			{
				croak("Cannot alias slurpy hash for a function with named parameters")
					if $self->alias;
				
				my $delete = $_->name eq '%_' ? '' : sprintf(
					'delete $tmp{$_} for (%s);',
					join(q[,], map B::perlstring($_), @names),
				);
				my $ix  = 1 + $sig->last_position;
				$val = sprintf(
					'do { use warnings FATAL => qw(all); my %%tmp = ($#_==%d && ref($_[%d]) eq q(HASH)) ? %%{$_[%d]} : @_[ %d .. $#_ ]; %s %%tmp ? %%tmp : (%s) }',
					($ix) x 4,
					$delete,
					$self->_injection_default_value('()'),
				);
			}
			else
			{
				$val = sprintf(
					'do { use warnings FATAL => qw(all); my %%tmp = @_[ %d .. $#_ ]; %%tmp ? @_[ %d .. $#_ ] : (%s) }',
					$sig->last_position + 1,
					$sig->last_position + 1,
					$self->_injection_default_value('()'),
				);
			}
			$condition = 1;
			$slurpy_style = '%';
		}
		else
		{
			croak("Cannot have a slurpy array for a function with named parameters")
				if $sig->has_named;
			$val = sprintf(
				'($#_ >= %d) ? @_[ %d .. $#_ ] : (%s)',
				$sig->last_position + 1,
				$sig->last_position + 1,
				$self->_injection_default_value('()'),
			);
			$condition = 1;
			$slurpy_style = '@';
		}
		
		if ($self->sigil eq '$')
		{
			$val = $slurpy_style eq '%' ? "+{ $val }" : "[ $val ]";
			$slurpy_style = '$';
		}
	}
	elsif ($self->named)
	{
		no warnings 'uninitialized';
		my $when = +{
			'//='   => 'defined',
			'||='   => '!!',
			'='     => 'exists',
		}->{ $self->default_when } || 'exists';
		
		$val = join '', map(
			sprintf('%s($_{%s}) ? $_{%s} : ', $when, $_, $_),
			map B::perlstring($_), @{$self->named_names}
		), $self->_injection_default_value();
		
		$condition = join ' or ', map(
			sprintf('%s($_{%s})', $when, $_),
			map B::perlstring($_), @{$self->named_names}
		);
	}
	elsif ($self->invocant)
	{
		$val = sprintf('@_ ? shift(@_) : %s', $self->_injection_default_value());
		$condition = 1;
	}
	else
	{
		no warnings 'uninitialized';
		my $when = +{
			'//='   => 'defined($_[%d])',
			'||='   => '!!($_[%d])',
			'='     => '($#_ >= %d)',
		}->{ $self->default_when } || '($#_ >= %d)';
		
		my $pos = $self->position;
		$val       = sprintf($when.' ? $_[%d] : %s', $pos, $pos, $self->_injection_default_value());
		$condition = sprintf($when, $self->position);
	}
	
	$condition = 1 if $self->_injection_default_value('@@') ne '@@';
	
	wantarray ? ($val, $condition) : $val;
}

sub _injection_type_check
{
	my $self = shift;
	my ($var) = @_;
	
	my $check = '';
	if ( my $type = $self->type )
	{
		my $can_xs =
			$INC{'Mouse/Util.pm'}
			&& Mouse::Util::MOUSE_XS()
			&& ($type->{_is_core} or $type->is_parameterized && $type->parent->{_is_core});
		
		if (!$can_xs and $type->can_be_inlined)
		{
			$check .= sprintf(
				'%s;',
				$type->inline_assert($var),
			);
		}
		else
		{
			$check .= sprintf(
				'$%s::PARAMS[%d]->{type}->assert_valid(%s);',
				__PACKAGE__,
				$self->ID,
				$var,
			);
		}
	}
	
	for my $i (0 .. $#{$self->constraints})
	{
		$check .= sprintf(
			'do { local $_ = %s; $%s::PARAMS[%d]->{constraints}[%d]->() } or Carp::croak(sprintf("%%s failed value constraint", %s));',
			$var,
			__PACKAGE__,
			$self->ID,
			$i,
			B::perlstring($var),
		);
	}
	
	return $check;
}

1;


__END__

=pod

=encoding utf-8

=for stopwords invocant invocants lexicals unintuitive booleans globals

=head1 NAME

Kavorka::Parameter - a single parameter in a function signature

=head1 DESCRIPTION

Kavorka::Parameter is a class where each instance represents a
parameter in a function signature. This class is used to help parse
the function signature, and also to inject Perl code into the final
function.

Instances of this class are also returned by Kavorka's function
introspection API.

=head2 Introspection API

A parameter instance has the following methods:

=over

=item C<ID>

An opaque numeric identifier for this parameter.

=item C<package>

Returns the package name the parameter was declared in.

=item C<type>

A L<Type::Tiny> object representing the type constraint for the
parameter, or undef.

=item C<name>

The name of the variable associated with this parameter, including
its sigil.

=item C<constraints>

An arrayref of additional constraints upon the value. These are given
as coderefs.

=item C<named>

A boolean indicating whether this is a named parameter.

=item C<named_names>

An arrayref of names for this named parameter.

=item C<position>

The position for a positional parameter.

=item C<default>

A coderef supplying the default value for this parameter.

=item C<default_when>

The string "=", "//=" or "||=".

=item C<traits>

A hashref, where the keys represent names of parameter traits, and
the values are booleans.

=item C<sigil>

The sigil of the variable for this parameter.

=item C<kind>

Returns "our" for package variables; "global" for namespace-qualified
package variables (i.e. containing "::"); "magic" for C<< $_ >> and
escape char variables like C<< ${^HELLO} >>; "my" otherwise.

=item C<readonly>, C<ro>

A boolean indicating whether this variable will be read-only.

=item C<rw>

A boolean indicating whether this variable will be read-write.

=item C<locked>

A boolean indicating whether this variable is a locked hash(ref).

=item C<alias>

A boolean indicating whether this variable will be an alias.

=item C<copy>

A boolean indicating whether this variable will be a copy (non-alias).

=item C<slurpy>

A boolean indicating whether this variable is slurpy.

=item C<optional>

A boolean indicating whether this variable is optional.

=item C<invocant>

A boolean indicating whether this variable is an invocant.

=item C<coerce>

A boolean indicating whether this variable should coerce.

=back

=head2 Other Methods

=over

=item C<parse>

An internal method used to parse a parameter. Only makes sense to use
within a L<Parse::Keyword> parser.

=item C<injection>

The string of Perl code to inject for this parameter.

=item C<sanity_check>

Tests that the parameter is sane. (For example it would not be sane to
have an invocant that is an optional parameter.)

=back

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Kavorka>.

=head1 SEE ALSO

L<Kavorka::Manual::API>,
L<Kavorka::Signature>.

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

