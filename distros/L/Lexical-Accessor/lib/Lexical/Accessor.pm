use 5.008003;
use strict;
use warnings;
no warnings qw( void once uninitialized );

package Lexical::Accessor;

use Carp qw(croak);
use Sub::Accessor::Small ();

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.009';
our @EXPORT    = qw/ lexical_has /;
our @ISA       = qw/ Sub::Accessor::Small /;

sub _generate_lexical_has : method
{
	my $me = shift;
	my $code = $me->_generate_has(@_);
	$code = Sub::Name::subname("$me\::lexical_has", $code)
		if Sub::Accessor::Small::HAS_SUB_NAME;
	return $code;
}

sub lexical_has : method
{
	my $has = $_[0]->can('has');
	goto $has;
}
	
sub inline_to_coderef : method
{
	my $me = shift;
	my ($method_type, $code) = @_;
	my $coderef = $me->SUPER::inline_to_coderef(@_);
	Sub::Accessor::Small::HAS_SUB_NAME && $me->{package} && defined($me->{slot})
		? Sub::Name::subname("$me->{package}\::__LEXICAL__[$me->{slot}]", $coderef)
		: $coderef
}

sub accessor_kind : method
{
	return 'lexical';
}

sub canonicalize_is : method
{
	my $me = shift;
	
	if ($me->{is} eq 'rw')
	{
		$me->{accessor} = \(my $tmp)
			if !exists($me->{accessor});
	}
	elsif ($me->{is} eq 'ro')
	{
		$me->{reader} = \(my $tmp)
			if !exists($me->{reader});
	}
	elsif ($me->{is} eq 'rwp')
	{
		$me->{reader} = \(my $tmp1)
			if !exists($me->{reader});
		$me->{writer} = \(my $tmp2)
			if !exists($me->{writer});
	}
	elsif ($me->{is} eq 'lazy')
	{
		$me->{reader} = \(my $tmp)
			if !exists($me->{reader});
		$me->{lazy} = 1
			if !exists($me->{lazy});
		$me->{builder} = 1
			unless $me->{builder} || $me->{default};
	}
}

sub canonicalize_opts : method
{
	my $me = shift;
	$me->SUPER::canonicalize_opts(@_);

	if (defined $me->{init_arg})
	{
		croak("Invalid init_arg=>defined; private attributes cannot be initialized in the constructor");
	}
	
	if ($me->{required})
	{
		croak("Invalid required=>1; private attributes cannot be initialized in the constructor");
	}
	
	if (defined $me->{lazy} and not $me->{lazy})
	{
		croak("Invalid lazy=>0; private attributes cannot be eager");
	}
	else
	{
		$me->{lazy} ||= 1 if $me->{default} || $me->{builder};
	}
	
	for my $type (qw/ reader writer accessor clearer predicate /)
	{
		if (defined($me->{$type}) and not ref($me->{$type}) eq q(SCALAR))
		{
			croak("Expected $type to be a scalar ref; not '$me->{$type}'");
		}
	}
}

sub expand_handles
{
	my $me = shift;
	
	if (ref($me->{handles}) eq q(ARRAY))
	{
		return @{$me->{handles}};
	}
	
	croak "Expected delegations to be a reference to an array; got $me->{handles}";
}

1;

__END__

=pod

=encoding utf-8

=for stopwords benchmarking

=head1 NAME

Lexical::Accessor - true private attributes for Moose/Moo/Mouse

=head1 SYNOPSIS

   my $accessor = lexical_has identifier => (
      is       => 'rw',
      isa      => Int,
      default  => sub { 0 },
   );
   
   # or...
   lexical_has identifier => (
      is       => 'rw',
      isa      => Int,
      default  => sub { 0 },
      accessor => \$accessor,
   );
   
   # later...
   say $self->$accessor;     # says 0
   $self->$accessor( 1 );    # setter
   say $self->$accessor;     # says 1

=head1 DESCRIPTION

Lexical::Accessor generates coderefs which can be used as methods to
access private attributes for objects.

The private attributes are stored inside-out, and do not add any
accessors to the class' namespace, so are completely invisible to any
outside code, including any subclasses. This gives your attribute
complete privacy: subclasses can define a private (or even public)
attribute with the same name as your private one and they will not
interfere with each other.

Private attributes can not be initialized by L<Moose>/L<Moo>/L<Mouse>
constructors, but you can safely initialize them inside a C<BUILD> sub.

=head2 Functions

=over

=item C<< lexical_has $name?, %options >>

This module exports a function L<lexical_has> which acts much like
Moose's C<has> function, but sets up a private (lexical) attribute
instead of a public one.

Because lexical attributes are stored inside-out, the C<$name> is
completely optional; however a name is recommended because it allows
better error messages to be generated.

The L<lexical_has> function supports the following options:

=over

=item C<< is >>

Moose/Mouse/Moo-style C<ro>, C<rw>, C<rwp> and C<lazy> values are
supported. These control what sort of coderef is returned by the
C<lexical_has> function itself.

   my $reader            = lexical_has "foo" => (is => "ro");
   my $accessor          = lexical_has "foo" => (is => "rw");
   my ($reader, $writer) = lexical_has "foo" => (is => "rwp");

If generating more than one method it is probably clearer to pass in
scalar references to the C<reader>, C<writer>, etc methods, rather than
relying on the return value of the C<lexical_has> function.

=item C<< reader >>, C<< writer >>, C<< accessor >>, C<< predicate >>,
C<< clearer >>

These accept scalar references. The relevant coderefs will be plonked
into them:

   my ($get_foo, $set_foo);
   
   lexical_has foo => (
      reader      => \$get_foo,
      writer      => \$set_foo,
   );

=item C<< default >>, C<< builder >>, C<< lazy >>

Lazy defaults and builders are allowed. Eager (non-lazy) defaults and
builders are currently disallowed. (Use a C<BUILD> sub to set private
attribute values at object construction time.)

The default may be either a non-reference value, or a coderef which
will be called as a method to return the value.

Builders probably make less sense than defaults because they require
a method in the class' namespace. The builder may be a method name, or
the special value C<< '1' >> which will be interpreted as meaning the
attribute name prefixed by "_build_". If a coderef is provided, this is
automatically installed into the class' namespace with the "_build_"
prefix. (This last feature requires L<Sub::Name>.)

=item C<< isa >>

A type constraint for the attribute. L<Moo>-style coderefs are
accepted (including those generated by L<MooX::Types::MooseLike>),
as are L<Moose::Meta::TypeConstraint>/L<MooseX::Types> objects,
and L<Mouse::Meta::TypeConstraint>/L<MouseX::Types> objects, and
of course L<Type::Tiny> type constraints.

String type constraints may also be accepted, but only if
L<Type::Utils> is installed. (String type constraints are reified
using C<dwim_type>.)

=item C<< does >>

As an alternative to C<isa>, you can provide a role name in the
C<does> option.

=item C<< coerce >>

A coderef or L<Type::Coercion> object is accepted.

If the special value C<< '1' >> is provided, the type constraint object
is consulted to find the coercion. (This doesn't work for coderef type
constraints.)

=item C<< trigger >>

A method name or coderef to trigger when a new value is set.

=item C<< auto_deref >>

Boolean indicating whether to automatically dereference array and hash
values if called in list context.

=item C<< init_arg >>

Must be C<undef> if provided at all.

=item C<< required >>

Must be false if provided at all.

=item C<< weak_ref >>

Boolean. Makes the setter weaken any references it is called with.

=item C<< handles >>

Delegates methods. Has slightly different syntax to Moose's option of
the same name - is required to be an arrayref of pairs such that each
pair is a scalar ref followed by a method name, a coderef, or an
arrayref (where the first element is a method name or coderef and
subsequent elements are curried arguments).
 
   my ($get, $post);
  
   lexical_has ua => (
      isa      => 'HTTP::Tiny',
      default  => sub { 'HTTP::Tiny'->new },
      handles  => [
         \$get   => 'get',
         \$post  => 'post',
      ],
   );
   
   # later...
   my $response = $self->$get('http://example.net/');

=item C<< initializer >>, C<< traits >>, C<< lazy_build >>

Not currently implemented. Providing any of these options throws an
error.

=item C<< documentation >>, C<< definition_context >>

Don't do anything, but are allowed; effectively inline comments.

=back

=back

=head2 Class Methods

=over

=item C<< lexical_has >>

This function may also be called as a class method.

=back

=head2 Comparison (benchmarking, etc)

Lexical::Accessor is almost three times faster than
L<MooX::PrivateAttributes>, and almost twenty time faster than
L<MooseX::Privacy>. I'd also argue that it's a more "correct"
implementation of private accessors as (short of performing impressive
L<PadWalker> manipulations), the accessors generated by this module
are completely invisible to subclasses, method dispatch, etc.

Compared to the usual Moose convention of using a leading underscore
to indicate a private method (which is a very loose convention; it is
quite common for subclasses to override such methods!),
L<Lexical::Accessor> clearly offers much better method privacy. There
should be little performance hit from using lexical accessors compared
to normal L<Moose> accessors. (However they are nowhere near the speed
of the XS-powered accessors that L<Moo> I<sometimes> uses and L<Mouse>
I<usually> uses.)

See also: C<< examples/benchmark.pl >> bundled with this release.

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Lexical-Accessor>.

=head1 SUPPORT

B<< IRC: >> support is available through in the I<< #moops >> channel
on L<irc.perl.org|http://www.irc.perl.org/channels.html>.

=head1 SEE ALSO

L<MooX::PrivateAttributes>,
L<MooX::ProtectedAttributes>,
L<MooseX::Privacy>,
L<Sub::Private>,
L<Method::Lexical>,
etc...

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

