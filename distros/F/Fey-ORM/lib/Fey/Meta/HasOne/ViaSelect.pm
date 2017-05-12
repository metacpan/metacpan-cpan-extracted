package Fey::Meta::HasOne::ViaSelect;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.47';

use Fey::ORM::Types qw( CodeRef );

use Moose;
use MooseX::StrictConstructor;

with 'Fey::Meta::Role::Relationship::HasOne';

has 'select' => (
    is       => 'ro',
    does     => 'Fey::Role::SQL::ReturnsData',
    required => 1,
);

has 'bind_params' => (
    is  => 'ro',
    isa => CodeRef,
);

# Since we don't know the content of the SQL, we just assume it can
# undef
sub _build_allows_undef {
    return 1;
}

## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
sub _make_subref {
    my $self = shift;

    my $foreign_table = $self->foreign_table();
    my $select        = $self->select();
    my $bind          = $self->bind_params();

    # XXX - this is really similar to
    # Fey::Object::Table->_get_column_values() and needs some serious
    # cleanup.
    return sub {
        my $self = shift;

        my $dbh = $self->_dbh($select);

        my $sth = $dbh->prepare( $select->sql($dbh) );

        $sth->execute( $bind ? $self->$bind() : () );

        my %col_values;
        $sth->bind_columns( \( @col_values{ @{ $sth->{NAME} } } ) );

        my $fetched = $sth->fetch();

        $sth->finish();

        return unless $fetched;

        $self->meta()->ClassForTable($foreign_table)
            ->new( %col_values, _from_query => 1 );
    };

}
## use critic

__PACKAGE__->meta()->make_immutable();

1;

# ABSTRACT: A parent for has-one metaclasses based on a query object

__END__

=pod

=head1 NAME

Fey::Meta::HasOne::ViaSelect - A parent for has-one metaclasses based on a query object

=head1 VERSION

version 0.47

=head1 DESCRIPTION

This class implements a has-one relationship for a class, based on a
provided (or deduced) query object.

=head1 CONSTRUCTOR OPTIONS

This class accepts the following constructor options:

=over 4

=item * select

An object which does the L<Fey::Role::SQL::ReturnsData> role. This query
defines the relationship between the tables.

=item * bind_params

An optional subroutine reference which will be called when the SQL is
executed. It is called as a method on the object of this object's
associated class.

=item * allows_undef

This defaults to true.

=back

=head1 METHODS

Besides the methods provided by L<Fey::Meta::Role::Relationship::HasOne>, this
class also provides the following methods:

=head2 $ho->select()

Corresponds to the value passed to the constructor.

=head2 $ho->bind_params()

Corresponds to the value passed to the constructor.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 - 2015 by Dave Rolsky.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
