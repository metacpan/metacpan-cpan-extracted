package Devel::TypeCheck::Type;

use strict;
use Carp;

require Exporter;

our @ISA = qw(Exporter);
our @EXPORT = ();
our @EXPORT_OK = qw(n2s s2n);

use Devel::TypeCheck::Util;

=head1 NAME

Devel::TypeCheck::Type - base type for the type language representation of Devel::TypeCheck

=head1 SYNOPSIS

Devel::TypeCheck::Type is an abstract class and should not be
instantiated directly.  However, all types used in the type system are
inheritors of this class and rely on methods defined here.

=head1 DESCRIPTION

The data structure is essentially a linked list from Mu at the head of
the list to terminal or variable types at the end.  Thus, most of the
functions defined here support that by relaying the request to the
subtype member (the next link in the linked list) instead of actually
doing anything themselves.

=over 4

=cut

# This is the base class for the object system used to store the types
# when computing the run-time type inference.

# **** CLASS ****

our $AUTOLOAD; # Package global used in &AUTOLOAD

our %name2number; # Mapping type names to numbers from @EXPORTS for &AUTOLOAD
our @number2name; # Mapping numbers to names for printing purposes

our @SUBTYPES;
our @subtypes;

=item B<VAR, M, H, K, P, N, O, X, Y, Z, IO, PV, IV, DV>

Class methods implemented through C<< AUTOLOAD >> to return a unique
number for each different function.  This is used to represent type
for certain queries.

=cut

# Set up the tables for AUTOLOAD, n2s, and s2n operation.
BEGIN {
    my $count = 0;
    @EXPORT = qw(VAR M H K P N O X Y Z IO PV IV DV);

    for my $i (@EXPORT) {
	$number2name[$count] = $i;
	$name2number{$i} = $count++;
    }
}

# For the Devel::TypeCheck::Type::{VAR,M,H,etc...}() methods
sub AUTOLOAD {
    my $name = $AUTOLOAD;
    $name =~ s/.*://;   # strip fully-qualified portion

    # Die if the name this was called by isn't exported
    if (!exists($name2number{$name})) {
	confess("Method &$name not implemented");
    }
    
    return $name2number{$name};
}

# Number to string lookup on Type subclasses
sub n2s ($) {
    my ($n) = @_;
    return $number2name[$n];
}

# String to number lookup on Type subclasses
sub s2n ($) {
    my ($s) = @_;
    return $name2number{$s};
}

# Required, since AUTOLOAD will suck this up if not defined
sub DESTROY {}

# **** INSTANCE ****

=item B<new>($subtype)

Create a new Type instance with the given item as the next link in the
list data structure.  This will control the subtypes allowed, so that
illegal types cannot be created when using this constructor.  This
method is abstract for this class, but works with subtypes.  Types are
never constructed by the user -- they should always be generated with
the fresh* and gen* methods of the type environment,
Devel::TypeCheck::Environment.

=cut

# Constructor
sub new {
    my ($name, $subtype) = @_;

    if ($name eq "Devel::TypeCheck::Type") {
	abstract("new", $name);
    }

    if (! $subtype->isa("Devel::TypeCheck::Type")) {
	croak("Subtype is not a member of class Devel::TypeCheck::Type");
    }

    my $this = {};

    bless($this, $name);

    if (! $this->hasSubtype($subtype->type)) {
	croak("Invalid subtype ", n2s($subtype->type), " for class $name");
    }

    $this->{'subtype'} = $subtype;

    return $this;
}

=item B<type>

Return the numerical type of the instance.

=cut

# Returns the type of an instance
sub type {
    my ($this) = @_;
    abstract("type", ref($this));
}

=item B<subtype>

Returns the next link in the list.

=cut

# Returns the subtype
sub subtype {
    my ($this) = @_;
    return $this->{'subtype'};
}

=item B<hasSubtype>($type)

Returns true if the given instance has the given type.

=cut

# Determines if a given class has a given type as an allowed subtype
sub hasSubtype {
    abstract("hasSubtype", "Devel::TypeCheck::Type");
}

# Shouldn't ever be called except by a T::Environment or an inheritor of T.
sub unify {
    my ($this, $that, $env) = @_;

    $this = $env->find($this);
    $that = $env->find($that);

    # Make sure that types match and that subtypes are valid.
    if ($this->type == $that->type &&
        $this->hasSubtype($this->subtype->type) &&
        $that->hasSubtype($that->subtype->type)) {
	return $this->subtype->unify($that->subtype, $env);
    } else {
	return undef;
    }
}

# Do the occurs check against $that with the given environment $env.
sub occurs {
    my ($this, $that, $env) = @_;
    
    if ($that->type != Devel::TypeCheck::Type::VAR()) {
	die("Invalid type ", $that->str, " for occurs check");
    }

    return $this->subtype->occurs($that, $env);
}

=item B<str>($env)

Return a string constructed from this type and subtypes.  This is the
"ugly" string as output by the B::TypeCheck backend module.

=cut

# Return a readable string
sub str {
    my ($this, $env) = @_;
    return (n2s($this->type) . $this->subtype->str($env));
}

=item B<pretty>

The human readable description of this type.

=cut

sub pretty {
    my ($this, $env) = @_;
    return $this->subtype->pretty($env);
}

=item B<is>($type)

Indicate whether some instance in the list of types is the same as the
numerical type passed to this method.

=cut

sub is {
    my ($this, $type) = @_;
    if ($this->type == $type) {
       	return TRUE;
    } else {
	if (defined($this->subtype)) {
	    return $this->subtype->is($type);
	} else {
	    return FALSE();
	}
    }
}

=item B<getParent>

Return the parent type of the instance.  This always returns undef for
internal and most terminal types, but returns the variable's parent in
the union-find data structure (if it has one).

=cut

# If the return is undefined, then the type has no parent in the type
# classes.  Incomplete and terminal types act this way.  Type
# variables return the current type class that they belong to, if any.
sub getParent {
    return undef;
}

=item B<complete>

True if the type is completely specified and has no unbound type variables.

=cut

# Returns a boolean value.  If TRUE, then the type is complete and has
# no type variables.
sub complete {
    my ($this) = @_;
    return $this->subtype->complete;
}

=item B<deref>

Dereference this type.

=cut

sub deref {
    my ($this) = @_;
    return $this->subtype->deref;
}

=item B<homogeneous>

Whether the underlying array or hash is homogeneous.

=cut

sub homogeneous {
    my ($this) = @_;
    return $this->subtype->homogeneous();
}

=item B<arity>

The size of the tuple, if the type at the end of the linked list is a
tuple type for an array.  This fails otherwise.

=cut

sub arity {
    my ($this) = @_;
    return $this->subtype->arity;
}

=item B<append>

Append a given type to an array type.  Promotes to homogeneous list as necessary.

=cut

sub append {
    my ($this, $that, $env) = @_;
    return $this->subtype->append($that, $env, $this);
}

=item B<ary>

Get the underlying tuple from a tuple type.

=cut

sub ary {
    my ($this) = @_;
    return $this->subtype->ary();
}

=item B<derefIndex>($index, $env)

Dereference the type from the array or hash at the given index.

=cut

sub derefIndex {
    my ($this, $index, $env) = @_;
    return $this->subtype->derefIndex($index, $env);
}

=item B<derefHomogeneous>

Dereference the homogeneous type for lists and associative arrays.

=cut

sub derefHomogeneous {
    my ($this) = @_;
    return $this->subtype->derefHomogeneous();
}

=item B<referize>

Generate a list of references from the underlying array.  Exists solely to support the srefgen operator on items of array type.

=cut

sub referize {
    my ($this, $env) = @_;
    return $this->subtype->referize($env);
}

=item B<derefKappa>

Get the scalar type out of a glob type.  This is roughly equivalent to C<<*foo{SCALAR}>>.

=cut
sub derefKappa {
    my ($this) = @_;
    return $this->subtype->derefKappa();
}

=item B<derefOmicron>

Get the array type out of a glob type.  This is roughly equivalent to C<<*foo{ARRAY}>>.

=cut
sub derefOmicron {
    my ($this) = @_;
    return $this->subtype->derefOmicron();
}

=item B<derefChi>

Get the hash type out of a glob type.  This is roughly equivalent to C<<*foo{HASH}>>.

=cut
sub derefChi {
    my ($this) = @_;
    return $this->subtype->derefChi();
}

=item B<derefZeta>

Get the CV type out of a glob type.  This is roughly equivalent to C<<*foo{CODE}>>.

=cut
sub derefZeta {
    my ($this) = @_;
    return $this->subtype->derefZeta();
}

=item B<listCoerce>

Coerce a hash in to an array.

=cut
sub listCoerce {
    my ($this, $env) = @_;
    return $this->subtype->listCoerce($env);
}

=item B<derefParam>

Dereference the parameter list type from a CV.

=cut
sub derefParam {
    my ($this, $env) = @_;
    return $this->subtype->derefParam();
}

=item B<derefReturn>

Dereference the return value type from a CV.

=cut
sub derefReturn {
    my ($this, $env) = @_;
    return $this->subtype->derefReturn();
}

=back

=cut

TRUE;

=head1 AUTHOR

Gary Jackson, C<< <bargle at umiacs.umd.edu> >>

=head1 BUGS

This version is specific to Perl 5.8.1.  It may work with other
versions that have the same opcode list and structure, but this is
entirely untested.  It definitely will not work if those parameters
change.

Please report any bugs or feature requests to
C<bug-devel-typecheck at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Devel-TypeCheck>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2005 Gary Jackson, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
