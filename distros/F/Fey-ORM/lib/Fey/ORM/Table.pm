## no critic (Moose::RequireMakeImmutable)
package Fey::ORM::Table;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.47';

use Class::Load qw( load_class );
use Fey::Meta::Class::Table;
use Fey::Object::Table;

use Moose 1.15                     ();
use MooseX::StrictConstructor 0.13 ();
use Moose::Exporter;
use Moose::Util::MetaRole;
use MooseX::Params::Validate qw( pos_validated_list );

Moose::Exporter->setup_import_methods(
    with_meta =>
        [qw( has_table has_policy has_one has_many transform query )],
    as_is => [qw( inflate deflate handles )],
    also  => [ 'Moose', 'MooseX::StrictConstructor' ],
);

## no critic (Subroutines::ProhibitSubroutinePrototypes)

sub init_meta {
    shift;
    my %p = @_;

    return Moose->init_meta(
        %p,
        base_class => 'Fey::Object::Table',
        metaclass  => 'Fey::Meta::Class::Table',
    );
}

sub has_table {
    my $meta = shift;

    my ($table) = pos_validated_list( \@_, { isa => 'Fey::Table' } );

    $meta->_associate_table(
        $table,
        _context(),
    );
}

sub has_policy {
    my $meta   = shift;
    my $policy = shift;

    unless ( ref $policy ) {
        load_class($policy);

        $policy = $policy->Policy();
    }

    $meta->set_policy($policy);
}

sub transform {
    my $meta = shift;

    my @p;

    push @p, pop @_ while ref $_[-1];

    my %p = _combine_hashes(@p);

    for my $name (@_) {
        $meta->_add_transform(
            $name,
            _context(),
            %p,
        );
    }
}

sub _combine_hashes {
    return map { %{$_} } @_;
}

sub inflate (&) {
    return { inflate => $_[0] };
}

sub deflate (&) {
    return { deflate => $_[0] };
}

sub handles ($) {
    return { handles => $_[0] };
}

sub has_one {
    my $meta = shift;

    my %p;
    if ( @_ == 1 ) {
        ( $p{table} ) = shift;
    }
    else {
        $p{name} = shift;

        %p = ( %p, @_ );
    }

    $meta->add_has_one(%p);
}

sub has_many {
    my $meta = shift;

    my %p;
    if ( @_ == 1 ) {
        ( $p{table} ) = shift;
    }
    else {
        $p{name} = shift;

        %p = ( %p, @_ );

    }

    $meta->add_has_many(%p);
}

sub query {
    my $meta = shift;
    my $name = shift;

    $meta->add_query_method( name => $name, @_ );
}

sub _context {
    my %context;
    @context{qw(package file line)} = caller(2);

    return \%context;
}

1;

# ABSTRACT: Provides sugar for table-based classes

__END__

=pod

=head1 NAME

Fey::ORM::Table - Provides sugar for table-based classes

=head1 VERSION

version 0.47

=head1 SYNOPSIS

  package MyApp::User;

  use Fey::ORM::Table;

  has_table ...;

  no Fey::ORM::Table;

=head1 DESCRIPTION

Use this class to associate your class with a table. It exports a
number of sugar functions to allow you to define things in a
declarative manner.

=head1 EXPORTED FUNCTIONS

This package exports the following functions:

=head2 has_table($table)

Given a L<Fey::Table> object, this method associates that table with
the calling class.

Calling C<has_table()> will make your class a subclass of
L<Fey::Object::Table>, which provides basic CRUD operations for
L<Fey::ORM>. You should make sure to review the docs for
L<Fey::Object::Table>.

Calling this function also generates a number of methods and
attributes in the calling class.

First, it generates one attribute for each column in the associated
table. Of course, this assumes that your columns are named in such a
way as to be usable as Perl methods.

It also generates a predicate for each attribute, where the predicate
is the column named prefixed with "has_". So for a column named
"user_id", you get a C<user_id()> attribute and a C<has_user_id()>
predicate.

These column-named attributes do not have a public setter method. If
you want to change the value of these attributes, you need to use the
C<update()> method.

=head2 has_policy($policy_class)

=head2 has_policy($policy_object)

This allows you to associate a policy with your class. See
L<Fey::ORM::Policy> for details on how policies work.

=head2 has_one($table)

=head2 has_one 'name' => ( table => $table, fk => $fk, cache => $bool, undef => $bool, handles => ... )

The C<has_one()> function declares a relationship between the calling
class's table and another table. The method it creates returns an
object of the foreign table's class, or undef or none exists.

With the single-argument form, you can simply pass a single
L<Fey::Table> object. This works when there is a single foreign key
between the calling class's table and the table passed to
C<has_one()>.

With a single argument, the generated attribute will be named as C<<
lc $has_one_table->name() >>, and caching will be turned on.

If you want to change any of the defaults, you can use the
multi-argument form. In this case, the first argument is the name of
the attribute or method to add. Then you can specify various
parameters by name. You must specify a C<table>, of course.

The C<fk> parameter is required when there is more than one foreign
key between the two tables. Finally, you can turn off caching by
setting C<cache> to a false value.

When caching is enabled, the object for the foreign table is only
fetched once, and is cached afterwards. This is independent of the
object caching for a particular class. If you turn off caching, then
the object is fetched every time the method is called.

Also, a private clearer method is created when caching is enabled, of
the form C<< $object->_clear_$name() >>.

The C<undef> parameter allows you to explicitly say whether the
attribute can be undefined. Normally this is calculated by looking at
the foreign key and seeing if any of the source columns are nullable.

The C<handles> parameter works exactly like it does for any Moose
attribute, but it only works if C<cache> is true, since otherwise the
relationship is implemented via a simple method, not a Moose
attribute.

=head2 has_one 'name' => ( table => $table, select => $select, bind_params => $sub, cache => $bool, undef => $bool, handles => ... )

This is an alternative form of C<has_one()> that lets you declare a
relationship to another table via an arbitrary SELECT statement.

In this form, you provide a query object to define the SQL used to fetch the
foreign row. You can provide a C<bind_params> parameter as a code reference,
which will be called as a method on your object. It is expected to return one
or more bind parameters. The C<cache> parameter works exactly the same as in
the first form of C<has_one()>.

In this form the C<undef> parameter defaults to true, but you can set
it to a false value.

Note that if you want to provide bind_params for the SQL you provide,
you need to make sure it has placeholders.

=head2 has_many($table)

=head2 has_many 'name' => ( table => $table, fk => $fk, cache => $bool, order_by => [ ... ] )

The C<has_many()> function declares a relationship between the calling
class's table and another table, just like C<has_one()>. The method it
creates returns a L<Fey::Object::Iterator::FromSelect> of the foreign
table's objects.

With the single-argument form, you can simply pass a single
L<Fey::Table> object. This works when there is a single foreign key
between the calling class's table and the table passed to
C<has_many()>.

With a single argument, the generated attribute will be named as C<<
lc $has_one_table->name() >>, and caching will be turned off. There
will be no specific order to the results returned.

If you want to change any of the defaults, you can use the
multi-argument form. In this case, the first argument is the name of
the attribute or method to add. Then you can specify various
parameters by name. You must specify a C<table>, of course.

The C<fk> parameter is required when there is more than one foreign
key between the two tables. Finally, you can turn on caching by
setting C<cache> to a true value.

When caching is enabled, the iterator returned is of the
L<Fey::Object::Iterator::FromSelect::Caching> class.

Also, a private clearer method is created when caching is enabled, of
the form C<< $object->_clear_$name() >>.

Note that you will always get an iterator object back from your
has_many methods and attributes, even if there are no matching rows in
the foreign table.

You can also specify an C<order_by> parameter as an array
reference. This should be an array like you would pass to C<<
Fey::SQL::Select->order_by() >>.

=head2 query $name => select => $select, bind_params => sub { ... }

The C<query()> function declares a method based on the given query. This works
much like declaring an attribute with the C<FromSelect> metaclass, but the
value returned from the query is not stored in the object.

=head2 transform $column1, $column2 => inflate { ... } => deflate { ... }

The C<transform()> function declares an inflator, deflator, or both
for the specified column. The inflator will be used to wrap the normal
accessor for the column. You'd generally use this to turn a raw value
from the DBMS into an object, for example:

  transform 'creation_date' =>
      inflate { DateTime::Format::Pg->parse_date( $_[1] ) };

The inflator (and deflator) coderef you specify will be called as a
I<method> on the object (or class). This lets you get at other
attributes for the object if needed.

When a column is inflated, a new attribute is created to allow you to
get at the raw data by suffixing the column name with "_raw". Given
the above inflator, a C<creation_date_raw()> attribute would be
created.

If the column in question is nullable your inflator should be prepared
to handle an undef value for the column.

Deflators are used to transform objects passed to C<update()> or
C<insert()> into values suitable for passing to the DBMS:

  transform 'creation_date' =>
      deflate { defined $_[1] && ref $_[1]
                  ? DateTime::Format::Pg->format_date( $_[1] )
                  : $_[1] };

Just as with an inflator, your deflator should be prepared to accept
an undef if the column is nullable.

You can only declare one inflator and one deflator for each column.

You can use the same inflator and deflator for more than one column at
once:

  transform 'creation_date', 'modification_date'
      => inflate { ... }
      => deflate { ... };

=head2 inflate { .. }

=head2 deflate { .. }

These are sugar functions that accept a single coderef. They mostly
exist to prevent you from having to write this:

  # this is not valid code!
  transform 'creation_date' =>
      ( inflator => sub { ... },
        deflator => sub { ... },
      );

=head2 handles ...

This sugar function lets you add delegation to an inflated
attribute. It accepts anything that Moose accepts for an attribute's
C<handles> parameter.

  transform 'creation_date'
      => inflate { ... }
      => handles { creation_ymd     => 'ymd',
                   creation_iso8601 => 'iso8601',
                 }
      => deflate { ... };

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 - 2015 by Dave Rolsky.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
