use 5.014;
use strict;
use warnings;

use Kavorka::Signature ();
use Sub::Util ();

package Kavorka::Sub;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.039';

use Text::Balanced qw( extract_bracketed );
use Parse::Keyword {};
use Parse::KeywordX;
use Carp;

our @CARP_NOT = qw(Kavorka);

use Moo::Role;
use namespace::sweep;

use overload (
	q[&{}]   => sub { shift->body },
	q[bool]  => sub { 1 },
	q[""]    => sub { shift->qualified_name // '__ANON__' },
	q[0+]    => sub { 1 },
	fallback => 1,
);

has keyword         => (is => 'ro');
has signature_class => (is => 'lazy', default => sub { 'Kavorka::Signature' });
has package         => (is => 'ro');
has declared_name   => (is => 'rwp');
has signature       => (is => 'rwp');
has traits          => (is => 'lazy', default => sub { +{} });
has prototype       => (is => 'rwp');
has attributes      => (is => 'lazy', default => sub { [] });
has body            => (is => 'rwp');
has qualified_name  => (is => 'rwp');

has _unwrapped_body => (is => 'rwp');
has _pads_to_poke   => (is => 'lazy');
has _tmp_name       => (is => 'lazy');

sub allow_anonymous      { 1 }
sub allow_lexical        { 1 }
sub is_anonymous         { !defined( shift->declared_name ) }
sub is_lexical           { (shift->declared_name || '') =~ /\A\$/ }
sub invocation_style     { +undef }
sub default_attributes   { return; }
sub default_invocant     { return; }
sub forward_declare_sub  { return; }

sub bypass_custom_parsing
{
	my $class = shift;
	my ($keyword, $caller, $args) = @_;
	croak("Attempt to call keyword '$keyword' bypassing prototype not supported");
}

sub install_sub
{
	my $self = shift;
	my $code = $self->body;
	
	if ($self->is_anonymous)
	{
		# no installation
	}
	elsif ($self->is_lexical)
	{
		require PadWalker;
		PadWalker::peek_my(2)->{ $self->declared_name } = \$code;
	}
	else
	{
		my $name = $self->qualified_name;
		no strict 'refs';
		*{$name} = $code;
	}
	
	$code;
}

sub inject_attributes
{
	my $self = shift;
	no warnings; # Perl 5.21+ sprintf emits warnings for redundant arguments
	join(' ', map sprintf($_->[1] ? ':%s(%s)' : ':%s', @$_), @{ $self->attributes }),
}

sub inject_prelude
{
	my $self = shift;
	$self->signature->injection;
}

sub parse
{
	my $class = shift;
	my $self  = $class->new(@_, package => compiling_package);
	
	lex_read_space;
	
	# sub name
	$self->parse_subname;
	unless ($self->is_anonymous or $self->is_lexical)
	{
		my $qualified = Kavorka::_fqname($self->declared_name);
		$self->_set_qualified_name($qualified);
		$self->forward_declare_sub;
	}
	
	# Thanks to Perl 5.20 subs, we have to allow attributes before
	# the signature too.
	lex_read_space;
	$self->parse_attributes
		if lex_peek    eq ':'
		&& lex_peek(2) ne ':(';
	
	# signature
	$self->parse_signature;
	my $sig = $self->signature;
	unless ($sig->has_invocants)
	{
		my @defaults = $self->default_invocant;
		unshift @{$sig->params}, @defaults;
		$sig->_set_has_invocants(scalar @defaults);
	}
	
	# traits
	$self->parse_traits;
	my $traits = $self->traits;
	if (keys %$traits)
	{
		# traits handled natively (none so far)
		state $native_traits = {};
		
		my @custom_traits =
			map  "Kavorka::TraitFor::Sub::$_",
			grep !exists($native_traits->{$_}),
			keys %$traits;
		
		'Moo::Role'->apply_roles_to_object($self, @custom_traits) if @custom_traits;
	}
	
	# prototype and attributes
	$self->parse_prototype;
	$self->parse_attributes;
	push @{$self->attributes}, $self->default_attributes;
	
	# body
	$self->parse_body;
	
	$self;
}

sub parse_subname
{
	my $self = shift;
	my $peek = lex_peek(2);
	
	my $saw_my = 0;
	
	if ($peek =~ /\A(?:\w|::)/)     # normal sub
	{
		my $name = parse_name('subroutine', 1);
		
		if ($name eq 'my')
		{
			lex_read_space;
			$saw_my = 1 if lex_peek eq '$';
		}
		
		if ($saw_my)
		{
			$peek = lex_peek(2);
		}
		else
		{
			$self->_set_declared_name($name);
			return;
		}
	}
	
	if ($peek =~ /\A\$[^\W0-9]/) # lexical sub
	{
		carp("'${\ $self->keyword }' should be '${\ $self->keyword } my'")
			unless $saw_my;
		
		lex_read(1);
		$self->_set_declared_name('$' . parse_name('lexical subroutine', 0));
		
		croak("Keyword '${\ $self->keyword }' does not support defining lexical subs")
			unless $self->allow_lexical;
		
		return;
	}
	
	croak("Keyword '${\ $self->keyword }' does not support defining anonymous subs")
		unless $self->allow_anonymous;
	
	();
}

sub parse_signature
{
	my $self = shift;
	lex_read_space;
	
	# default signature
	my $dummy = 0;
	if (lex_peek ne '(')
	{
		$dummy = 1;
		lex_stuff('(...)');
	}
	
	lex_read(1);
	my $sig = $self->signature_class->parse(package => $self->package, _is_dummy => $dummy);
	lex_peek eq ')' or croak('Expected ")" after signature');
	lex_read(1);
	lex_read_space;
	
	$self->_set_signature($sig);
	
	();
}

sub parse_prototype
{
	my $self = shift;
	lex_read_space;
	
	my $peek = lex_peek(1000);
	if ($peek =~ / \A \: \s* \( /xsm )
	{
		lex_read(1);
		lex_read_space;
		$peek = lex_peek(1000);
		
		my $extracted = extract_bracketed($peek, '()');
		lex_read(length $extracted);
		$extracted =~ s/(?: \A\( | \)\z )//xgsm;
		
		$self->_set_prototype($extracted);
	}
	
	();
}

sub parse_traits
{
	my $self = shift;
	lex_read_space;
	
	while (lex_peek(5) =~ m{ \A (is|does|but) \s }xsm)
	{
		lex_read(length($1));
		lex_read_space;
		my ($name, undef, $args) = parse_trait;
		$self->traits->{$name} = $args;
		lex_read_space;
	}
	
	();
}

sub parse_attributes
{
	my $self = shift;
	lex_read_space;
	
	if (lex_peek eq ':')
	{
		lex_read(1);
		lex_read_space;
	}
	else
	{
		return;
	}
	
	while (lex_peek(4) =~ /\A([^\W0-9]\w+)/)
	{
		my $parsed = [parse_trait];
		lex_read_space;
		
		if ($parsed->[0] eq 'prototype')
		{
			$self->_set_prototype($parsed->[1]);
		}
		else
		{
			push @{$self->attributes}, $parsed;
		}
		
		if (lex_peek eq ':')
		{
			lex_read(1);
			lex_read_space;
		}
	}

	();
}

sub _build__tmp_name
{
	state $i = 0;
	"Kavorka::Temp::f" . ++$i;
}

sub parse_body
{
	my $self = shift;
	
	lex_read_space;
	lex_peek(1) eq '{' or croak("expected block!");
	lex_read(1);
	
	if ($self->is_anonymous)
	{
		lex_stuff(sprintf("{ %s", $self->inject_prelude));
		
		# Parse the actual code
		my $code = parse_block(0) or Carp::croak("cannot parse block!");
		
		# Set up prototype
		&Scalar::Util::set_prototype($code, $self->prototype);
		
		# Fix sub name
		$code = Sub::Util::set_subname(join('::', $self->package, '__ANON__'), $code);
		
		# Set up attributes - this doesn't much work
		my $attrs = $self->attributes;
		if (@$attrs)
		{
			require attributes;
			no warnings;
			attributes->import(
				$self->package,
				$code,
				map($_->[0], @$attrs),
			);
		}
		
		# And keep the coderef
		$self->_set_body($code);
	}
	else
	{
		state $i = 0;
		
		my $lex = '';
		if ($self->is_lexical)
		{
			$lex = sprintf(
				'&Internals::SvREADONLY(\\(my %s = \&%s), 1);',
				$self->declared_name,
				$self->_tmp_name,
			);
		}
		
		# Here instead of parsing the body we'll leave it to plain old
		# Perl. We'll pick it up later from this name in _post_parse
		lex_stuff(
			sprintf(
				"%s sub %s %s { no warnings 'closure'; %s",
				$lex,
				$self->_tmp_name,
				$self->inject_attributes,
				$self->inject_prelude,
			)
		);
		$self->{argh} = $self->_tmp_name;
	}
	
	();
}

sub _post_parse
{
	my $self = shift;
	
	if ($self->{argh})
	{
		no strict 'refs';
		my $code = $self->is_lexical ? \&{$self->{argh}} : \&{ delete $self->{argh} };
		Sub::Util::set_subname(
			$self->is_anonymous || $self->is_lexical
				? join('::', $self->package, '__ANON__')
				: $self->qualified_name,
			$code,
		);
		&Scalar::Util::set_prototype($code, $self->prototype);
		$self->_set_body($code);
	}
	
	$self->_apply_return_types;
	
	$self->_set_signature(undef)
		if $self->signature && $self->signature->_is_dummy;
	
	();
}

sub _apply_return_types
{
	my $self = shift;
	
	my @rt = @{ $self->signature ? $self->signature->return_types : [] };
	
	if (@rt)
	{
		my @scalar = grep !$_->list, @rt;
		my @list   = grep  $_->list, @rt;
		
		my $scalar =
			(@scalar == 0) ? undef :
			(@scalar == 1) ? $scalar[0] :
			croak("Multiple scalar context return types specified for function");
		
		my $list =
			(@list == 0) ? undef :
			(@list == 1) ? $list[0] :
			croak("Multiple list context return types specified for function");
		
		return if (!$scalar || $scalar->assumed) && (!$list || $list->assumed);
		
		require Return::Type;
		my $wrapped = Return::Type->wrap_sub(
			$self->body,
			scalar        => ($scalar ? $scalar->_effective_type   : undef),
			list          => ($list   ? $list->_effective_type     : undef),
			coerce_scalar => ($scalar ? $scalar->coerce            : 0),
			coerce_list   => ($list   ? $list->coerce              : $scalar ? $scalar->coerce : 0),
		);
		$self->_set__unwrapped_body($self->body);
		$self->_set_body($wrapped);
	}
	
	();
}

sub _build__pads_to_poke
{
	my $self = shift;
	
	my @pads = $self->_unwrapped_body // $self->body;
	
	for my $param (@{ $self->signature ? $self->signature->params : [] })
	{
		push @pads, $param->default if $param->default;
		push @pads, @{ $param->constraints };
	}
	
	\@pads;
}

sub _poke_pads
{
	my $self = shift;
	my ($vars) = @_;
	
	for my $code (@{$self->_pads_to_poke})
	{
		my $closed_over = PadWalker::closed_over($code);
		ref($vars->{$_}) && ($closed_over->{$_} = $vars->{$_})
			for keys %$closed_over;
		PadWalker::set_closed_over($code, $closed_over);
	}
	
	();
}

1;

__END__

=pod

=encoding utf-8

=for stopwords invocant invocants lexicals unintuitive

=head1 NAME

Kavorka::Sub - a function that has been declared

=head1 DESCRIPTION

Kavorka::Sub is a role which represents a function declared using
L<Kavorka>. Classes implementing this role are used to parse functions,
and also to inject Perl code into them.

Instances of classes implementing this role are also returned by
Kavorka's function introspection API.

=head2 Introspection API

A function instance has the following methods.

=over

=item C<keyword>

The keyword (e.g. C<method>) used to declare the function.

=item C<package>

Returns the package name the parameter was declared in. Not necessarily
the package it will be installed into...

   package Foo;
   fun UNIVERSAL::quux { ... }  # will be installed into UNIVERSAL

=item C<is_anonymous>

Returns a boolean indicating whether this is an anonymous coderef.

=item C<declared_name>

The declared name of the function (if any).

=item C<qualified_name>

The name the function will be installed as, based on the package and
declared name.

=item C<signature>

An instance of L<Kavorka::Signature>, or undef.

=item C<traits>

A hashref of traits.

=item C<prototype>

The function prototype as a string.

=item C<attributes>

The function attributes. The structure returned by this method is
subject to change.

=item C<body>

The function body as a coderef. Note that this coderef I<will> have had
the signature code injected into it.

=back

=head2 Other Methods

=over

=item C<parse>,
C<parse_subname>,
C<parse_signature>,
C<parse_traits>,
C<parse_prototype>,
C<parse_attributes>,
C<parse_body> 

Internal methods used to parse a subroutine. It only makes sense to call
these from a L<Parse::Keyword> parser, but may make sense to override
them in classes consuming the Kavorka::Sub role.

=item C<allow_anonymous>

Returns a boolean indicating whether this keyword allows functions to be
anonymous.

The implementation defined in this role returns true.

=item C<signature_class>

A class to use for signatures.

=item C<default_attributes>

Returns a list of attributes to add to the sub when it is parsed.
It would make sense to override this in classes implementing this role,
however attributes don't currently work properly anyway.

The implementation defined in this role returns the empty list.

=item C<default_invocant>

Returns a list invocant parameters to add to the signature if no
invocants are specified in the signature. It makes sense to override
this for keywords which have implicit invocants, such as C<method>.
(See L<Kavorka::Sub::Method> for an example.)

The implementation defined in this role returns the empty list.

=item C<forward_declare_sub>

Method called at compile time to forward-declare the sub, if that
behaviour is desired.

The implementation defined in this role does nothing, but
L<Kavorka::Sub::Fun> actually does some forward declaration.

=item C<install_sub>

Method called at run time to install the sub into the symbol table.

This makes sense to override if the sub shouldn't be installed in the
normal Perlish way. For example L<Kavorka::MethodModifier> overrides
it.

=item C<invocation_style>

Returns a string "fun" or "method" depending on whether subs are
expected to be invoked as functions or methods. May return undef if
neither is really the case (e.g. as with method modifiers).

=item C<inject_attributes>

Returns a string of Perl code along the lines of ":foo :bar(1)" which
is injected into the Perl token stream to be parsed as the sub's
attributes. (Only used for named subs.)

=item C<inject_prelude>

Returns a string of Perl code to inject into the body of the sub.

=item C<bypass_custom_parsing>

A I<class method> that is called when people attempt to use the
keyword while bypassing the Perl keyword API's custom parsing.
Examples of how they can do that are:

   use Kavorka 'method';
   
   &method(...);
   
   __PACKAGE__->can("method")->(...);

The default implementation of C<bypass_custom_parsing> is to croak,
but this can be overridden in cases where it may be possible to do
something useful. (L<Kavorka::MethodModifier> does this.)

It is passed the name of the keyword, the name of the package that
the keyword was installed into, and an arrayref representing C<< @_ >>.

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

