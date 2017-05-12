package Fey::Meta::HasMany::ViaFK;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.47';

use Fey::ORM::Types qw( ArrayRef );
use List::AllUtils qw( any );

use Moose;
use MooseX::StrictConstructor;

with 'Fey::Meta::Role::Relationship::HasMany',
    'Fey::Meta::Role::Relationship::ViaFK';

has 'order_by' => (
    is  => 'ro',
    isa => ArrayRef,
);

## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
sub _make_iterator_maker {
    my $self = shift;

    my $target_table = $self->foreign_table();

    my $select = $self->associated_class()->schema_class()->SQLFactoryClass()
        ->new_select();
    $select->select( $target_table->columns() )->from($target_table);

    my @ph_names;

    my $ph = Fey::Placeholder->new();
    for my $pair ( @{ $self->fk()->column_pairs() } ) {
        my ( $from, $to ) = @{$pair};

        $select->where( $to, '=', $ph );

        push @ph_names, $from->name();
    }

    $select->order_by( @{ $self->order_by() } )
        if $self->order_by();

    my $bind_params_sub = sub {
        return map { $_[0]->$_() } @ph_names;
    };

    return $self->_make_subref_for_sql(
        $select,
        $bind_params_sub,
    );
}
## use critic

__PACKAGE__->meta()->make_immutable();

1;

# ABSTRACT: A parent for has-one metaclasses based on a L<Fey::FK> object

__END__

=pod

=head1 NAME

Fey::Meta::HasMany::ViaFK - A parent for has-one metaclasses based on a L<Fey::FK> object

=head1 VERSION

version 0.47

=head1 DESCRIPTION

This class implements a has-one relationship for a class, based on a
provided (or deduced) L<Fey::FK> object.

=head1 CONSTRUCTOR OPTIONS

This class accepts the following constructor options:

=over 4

=item * fk

If you don't provide this, the class looks for foreign keys between
C<< $self->table() >> and and C<< $self->foreign_table() >>. If it
finds exactly one, it uses that one.

=item * order_by

This will be appended to the SQL which is generated to select the
foreign rows. It should be an arrayref which can be passed to C<<
Fey::SQL::Select->order_by() >>.

=item * allows_undef

This defaults to true if any of the columns in the local table are
NULLable, otherwise it defaults to false.

=back

=head1 METHODS

Besides the methods provided by L<Fey::Meta::Role::Relationship::HasMany> and
L<Fey::Meta::Role::Relationship::ViaFK>, this class also provides the
following methods:

=head2 $ho->fk()

Corresponds to the value passed to the constructor, or the calculated
default.

=head2 $ho->order_by()

Corresponds to the value passed to the constructor.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 - 2015 by Dave Rolsky.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
