package Fey::Literal::Term;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.43';

use Fey::Types qw( Bool LiteralTermArg );

use Carp qw( croak );
use Moose 2.1200;
use MooseX::SemiAffordanceAccessor 0.03;
use MooseX::StrictConstructor 0.13;

with 'Fey::Role::Comparable', 'Fey::Role::Selectable',
    'Fey::Role::Orderable', 'Fey::Role::Groupable',
    'Fey::Role::IsLiteral';

has 'term' => (
    is       => 'ro',
    isa      => LiteralTermArg,
    required => 1,
    coerce   => 1,
);

has can_have_alias => (
    is      => 'rw',
    isa     => Bool,
    default => 1,
);

with 'Fey::Role::HasAliasName' => { generated_alias_prefix => 'TERM' };

sub BUILDARGS {
    my $class = shift;

    return { term => [@_] };
}

sub sql {
    my ( $self, $dbh ) = @_;

    return join(
        '',
        map {
            blessed($_) && $_->can('sql_or_alias')
                ? $_->sql_or_alias($dbh)
                : $_
        } @{ $self->term() }
    );
}

# XXX - this bit of wackness is necessary because MX::Role::Parameterized
# doesn't support -alias or -excludes, but we want to provide our own version
# of sql_with_alias.
{
    my $meta = __PACKAGE__->meta();

    my $method = $meta->remove_method('sql_with_alias');
    $meta->add_method( _han_sql_with_alias => $method );

    my $sql_with_alias = sub {
        my $self = shift;
        my $dbh  = shift;

        return $self->can_have_alias()
            ? $self->_han_sql_with_alias($dbh)
            : $self->sql($dbh);
    };

    $meta->add_method( sql_with_alias => $sql_with_alias );
}

before 'set_alias_name' => sub {
    my $self = shift;

    croak 'This term cannot have an alias'
        unless $self->can_have_alias();
};

__PACKAGE__->meta()->make_immutable();

1;

# ABSTRACT: Represents a literal term in a SQL statement

__END__

=pod

=head1 NAME

Fey::Literal::Term - Represents a literal term in a SQL statement

=head1 VERSION

version 0.43

=head1 SYNOPSIS

  my $term = Fey::Literal::Term->new(@anything)

=head1 DESCRIPTION

This class represents a literal term in a SQL statement. A "term" in this
module means a literal SQL snippet that will be used verbatim, without
quoting.

This allows you to create SQL for almost any expression, for example
C<EXTRACT( DOY FROM TIMESTAMP "User.creation_date" )>, which is a valid Postgres
expression. This would be created like this:

  my $term =
      Fey::Literal::Term->new
          ( 'DOY FROM TIMESTAMP ', $column );

  my $function = Fey::Literal::Function->new( 'EXTRACT', $term );

This ability to insert arbitrary strings into a SQL statement is meant
to be used as a back-door to support any sort of SQL snippet not
otherwise supported by the core Fey classes in a more direct manner.

=head1 INHERITANCE

This module is a subclass of C<Fey::Literal>.

=head1 METHODS

This class provides the following methods:

=head2 Fey::Literal::Term->new(@fragments)

This method creates a new C<Fey::Literal::Term> object representing
the term passed to the constructor.

More than one argument may be given; they will all be joined together
in the generated SQL.  For example:

  my $term = Fey::Literal::Term->new( $column, '::text' );

The arguments can be plain scalars, objects with a C<sql_or_alias()>
method (columns, tables, etc.) or any object which is overloaded (the
assumption being it that it overloads stringification).

=head2 $term->term()

Returns the array reference of fragments passed to the constructor.

=head2 $term->can_have_alias()

=head2 $term->set_can_have_alias()

If this attribute is explicitly set to a false value, then then the
SQL-generating methods below will never include an alias.

=head2 $term->id()

The id for a term is uniquely identifies the term.

=head2 $term->sql()

=head2 $term->sql_with_alias()

=head2 $term->sql_or_alias()

Returns the appropriate SQL snippet. If the term contains any Fey objects,
their C<sql_or_alias()> method is called to generate their part of the term.

=head1 DETAILS OF SQL GENERATION

A term generates SQL by taking each of the elements passed to its constructor
and concatenating them. If the element is an object with a C<sql_or_alias()>
method, that method will be called to generate SQL. Otherwise, the element is
just used as-is.

If C<< $term->can_have_alias() >> is false, then calling any of the three
SQL-generating methods is always equivalent to calling C<< $term->sql() >>.

=head1 ROLES

This class does the C<Fey::Role::Selectable>, C<Fey::Role::Comparable>,
C<Fey::Role::Groupable>, and C<Fey::Role::Orderable> roles.

Of course, the contents of a given term may not really allow for any
of these things, but having this class do these roles means you can
freely use a term object in any part of a SQL snippet.

=head1 BUGS

See L<Fey> for details on how to report bugs.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 - 2015 by Dave Rolsky.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
