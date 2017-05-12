package Fey::Object::Iterator::FromSelect;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.47';

use Fey::Exceptions qw( param_error );
use Fey::ORM::Types qw( ArrayRef HashRef Maybe Str );

use Devel::GlobalDestruction;
use Moose;
use MooseX::SemiAffordanceAccessor;
use MooseX::StrictConstructor;
use Try::Tiny;

with 'Fey::ORM::Role::Iterator';

has dbh => (
    is       => 'ro',
    isa      => 'DBI::db',
    required => 1,
);

has select => (
    is       => 'ro',
    does     => 'Fey::Role::SQL::ReturnsData',
    required => 1,
);

has bind_params => (
    is      => 'ro',
    isa     => ArrayRef,
    lazy    => 1,
    default => sub { [ $_[0]->select()->bind_params() ] },
);

has _sth => (
    is        => 'ro',
    isa       => 'DBI::st',
    writer    => '_set_sth',
    predicate => '_has_sth',
    clearer   => '_clear_sth',
    init_arg  => undef,
    lazy      => 1,
    builder   => '_build_sth',
);

has attribute_map => (
    is      => 'ro',
    isa     => HashRef [ HashRef [Str] ],
    default => sub { return {} },
);

has _class_attributes_by_position => (
    is       => 'ro',
    isa      => HashRef [ HashRef [Str] ],
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_class_attributes_by_position',
);

has raw_row => (
    is       => 'rw',
    isa      => Maybe [ArrayRef],
    init_arg => undef,
    writer   => '_set_raw_row',
);

sub BUILD {
    my $self = shift;

    $self->_validate_attribute_map();
}

sub _validate_attribute_map {
    my $self = shift;

    my $map = $self->attribute_map();

    return unless keys %{$map};

    my %valid_classes = map { $_ => 1 } @{ $self->classes() };

    for my $class ( map { $_->{class} } values %{$map} ) {
        die
            "Cannot include a class in attribute_map ($class) unless it also in classes"
            unless $valid_classes{$class};
    }
}

## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
sub _get_next_result {
    my $self = shift;

    my $sth = $self->_sth();

    my $row = $sth->fetchrow_arrayref();

    $self->_set_raw_row($row);

    return unless $row;

    my $map = $self->_class_attributes_by_position();

    my @result;
    for my $class ( @{ $self->classes() } ) {
        my %attr = map { $map->{$class}{$_} => $row->[$_] }
            keys %{ $map->{$class} };
        $attr{_from_query} = 1;

        push @result, $self->_new_object( $class, \%attr );
    }

    return \@result;
}

sub _new_object {
    my $self  = shift;
    my $class = shift;
    my $attr  = shift;

    # FIXME - This eval is kind of a band-aid. It is possible (especially with
    # DBD::Mock) for %attr to contain bogus data (wrong types). However, it's
    # also possible for %attr to contain undefs for non-NULLable columns when
    # iterating over the results of a select, especially outer joins.
    #
    # In the outer join case, we do want to ignore object construction errors,
    # but otherwise we don't.
    #
    # Fortunately, bogus data is unlikely, unless the caller explicitly
    # provides a bad attribute_map, or a valid attribute_map and a crazy
    # query. It also can happen pretty easily with DBD::Mock.
    try { $class->new($attr) } || undef;
}

sub _build_sth {
    my $self = shift;

    my $sth = $self->dbh()->prepare( $self->select()->sql( $self->dbh() ) );

    $sth->execute( @{ $self->bind_params() } );

    return $sth;
}

sub _has_explicit_attribute_map {
    my $self = shift;

    return keys %{ $self->attribute_map() };
}

sub _build_class_attributes_by_position {
    my $self = shift;

    return $self->_remap_explicit_attribute_map()
        if $self->_has_explicit_attribute_map;

    my $x = 0;
    my %map;

    for my $s ( $self->select()->select_clause_elements() ) {
        if ( $s->can('table') ) {
            my $class = Fey::Meta::Class::Table->ClassForTable( $s->table() );

            $map{$class}{$x}
                = $s->can('alias_name') ? $s->alias_name() : $s->name();
        }

        $x++;
    }

    return \%map;
}

sub _remap_explicit_attribute_map {
    my $self = shift;

    my $explicit_map = $self->attribute_map();

    my %map;
    for my $pos ( keys %{$explicit_map} ) {
        $map{ $explicit_map->{$pos}{class} }{$pos}
            = $explicit_map->{$pos}{attribute};
    }

    return \%map;
}

## no critic (Subroutines::ProhibitBuiltinHomonyms)
sub reset {
    my $self = shift;

    $self->_finish_handle();
    $self->_clear_sth();
    $self->_reset_index();

    return;
}
## use critic

sub DEMOLISH {
    my $self = shift;

    $self->_finish_handle();
}

sub _finish_handle {
    my $self = shift;

    # We really don't care about cleanly finishing statement handles
    # in this case, and this code just doesn't work so well in that
    # case anyway.
    return if in_global_destruction();

    return unless $self->_has_sth();

    $self->_sth()->finish() if $self->_sth()->{Active};
}

__PACKAGE__->meta()->make_immutable();

1;

# ABSTRACT: Wraps a DBI statement handle to construct objects from the results

__END__

=pod

=head1 NAME

Fey::Object::Iterator::FromSelect - Wraps a DBI statement handle to construct objects from the results

=head1 VERSION

version 0.47

=head1 SYNOPSIS

  use Fey::Object::Iterator::FromSelect;

  my $iter = Fey::Object::Iterator::FromSelect->new(
      classes     => 'MyApp::User',
      select      => $select,
      dbh         => $dbh,
      bind_params => \@bind,
  );

  print $iter->index();    # 0

  while ( my $user = $iter->next() ) {
      print $iter->index();    # 1, 2, 3, ...
      print $user->username();
  }

  $iter->reset();

=head1 DESCRIPTION

This class implements an iterator on top of a DBI statement
handle. Each call to C<next()> returns one or more objects based on
the data returned by the statement handle.

=head1 METHODS

This class provides the following methods:

=head2 Fey::Object::Iterator::FromSelect->new(...)

This method constructs a new iterator. It accepts the following
parameters:

=over 4

=item * classes

This can be a single class name, or an array reference of class
names. These should be classes associated with the tables from which
data is being C<SELECT>ed. The iterator will return an object of each
class in order when C<< $iterator->next() >> is called.

This can be any class, not just a class which uses
L<Fey::ORM::Table>. However, the iterator methods below which return hashes
only work when all the classes have a C<Table()> method.

=item * dbh

A connected DBI handle

=item * select

This can be any object which does the L<Fey::Role::SQL::ReturnsData>
role. Usually this will be a L<Fey::SQL::Select> object. This object should be
a query which returns the data that this iterator will iterate over.

=item * bind_params

This should be an array reference of one or more bind params for the
C<SELECT>.

This is an optional parameter. If it not passed, then the bind
parameters will be obtained by calling the C<bind_params()> method on
the "select" parameter.

=item * attribute_map

This lets you explicitly map an element of the C<SELECT> clause to a
specific class's attribute.

See L<ATTRIBUTE MAPPING> for more details.

=back

=head2 $iterator->index()

This returns the current index value of the iterator. When the object
is first constructed, this index is 0, and it is incremented once for
each row fetched by calling C<< $iterator->next() >>.

=head2 $iterator->next()

This returns the next set of objects, based on data retrieved by the
query. In list context this returns all the objects. In scalar context
it returns the first object.

It is possible that one or more of the objects it returns will be
undefined, though this should really only happen with an outer
join. The statement handle will be executed the first time this method
is called.

If the statement handle is exhausted, this method returns false.

=head2 $iterator->remaining()

This returns all of the I<remaining> sets of objects. If the iterator
is for a single class, it returns a list of objects of that class. If
it is for multiple objects, it returns a list of array references.

=head2 $iterator->all()

This returns all of the sets of objects. If necessary, it will call
C<< $iterator->reset() >> first. If the iterator is for a single
class, it returns a list of objects of that class. If it is for
multiple objects, it returns a list of array references.

=head2 $iterator->next_as_hash()

Returns the next set of objects as a hash. The keys are the names of
the object's associated table.

If the statement handle is exhausted, this method returns false.

This method will throw an exception unless all of the iterator's classes have
a C<Table()> method.

=head2 $iterator->remaining_as_hashes()

This returns all of the I<remaining> sets of objects as a list of hash
references. Each hash ref is keyed on the table name of the associated
object's class.

This method will throw an exception unless all of the iterator's classes have
a C<Table()> method.

=head2 $iterator->all_as_hashes()

This returns all of the sets of objects as a list of hash
references. If necessary, it will call C<< $iterator->reset() >>
first. Each hash ref is keyed on the table name of the associated
object's class.

This method will throw an exception unless all of the iterator's classes have
a C<Table()> method.

=head2 $iterator->reset()

Resets the iterator so that the next call to C<< $iterator->next() >>
returns the first objects. Internally this means that the statement
handle will be executed again. It's possible that data will have
changed in the DBMS since then, meaning that the iterator will return
different objects after a reset.

=head2 $iterator->raw_row()

Returns an array reference containing the I<raw> data returned by the query on
the most recent call to C<< $iterator->next() >>. Once the iterator is
exhausted, this method returns C<undef>.

=head2 $iterator->DEMOLISH()

This method will call C<< $sth->finish() >> on its C<DBI> statement
handle if necessary.

=head1 ATTRIBUTE MAPPING

This class tries to automatically map each element of the C<SELECT>
clause to a class's attribute. You can also provide your own explicit
mappings as needed.

In the absence of an explicit mapping, it checks to see if the element
has a C<table()> method. If it does, it calls C<<
Fey::Meta::Class::Table->ClassForTable >> in order to get a class name
for the table. Then it uses the value of C<name()> (for column
objects) or C<alias_name()> (for column alias objects) as the name of
the attribute to be passed to the class's constructor.

If the class is not listed in the iterator's "classes" attribute, then
it will simply be ignored.

If the element does not have a C<table()> method or an explicit
mapping, it is ignored.

This default works for most queries, where you're just selecting some
or all of the columns from one or more tables.

In more exotic cases, you can specify an explicit mapping. The mapping
maps a C<SELECT> clause element to a specify class's attribute. The
map would look something like this:

  Fey::Object::Iterator::FromSelect->new
      ( classes       => [ 'User', 'Message' ],
        dbh           => $dbh,
        select        => $select,
        attribute_map => { 0 => { class     => 'User',
                                  attribute => 'user_id',
                                },
                           1 => { class     => 'User',
                                  attribute => 'username',
                                },
                           3 => { class     => 'Message',
                                  attribute => 'message_id',
                                },
                         },
      );

The keys in the mapping are positions in the list of C<SELECT> clause
elements. The numbers start from zero (0) just like a Perl array. The values
are themselves a hash reference specifying a "class" and "attribute" of that
class.

This explicit mapping is useful for more "exotic" queries. For example:

  SELECT   Message.user_id, COUNT(message_id) AS message_count
    FROM   Message
  ORDER BY message_count DESC
  GROUP BY user_id
     LIMIT 10

This query selects to the top 10 most frequent message posters from a
C<Message> table. Assuming our C<User> class has a C<message_count>
attribute, we'd like to create a list of C<User> objects from this
query.

  Fey::Object::Iterator::FromSelect->new
      ( classes       => [ 'User', 'Message' ],
        dbh           => $dbh,
        select        => $select,
        attribute_map => { 0 => { class     => 'User',
                                  attribute => 'user_id',
                                },
                           1 => { class     => 'User',
                                  attribute => 'message_count',
                                },
      );

Explicit mappings to classes not listed in the "classes" attribute
cause an error at object construction time.

=head1 ROLES

This class does the L<Fey::ORM::Role::Iterator> role.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 - 2015 by Dave Rolsky.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
