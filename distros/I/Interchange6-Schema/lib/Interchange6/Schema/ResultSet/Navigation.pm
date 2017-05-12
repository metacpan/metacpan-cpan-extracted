use utf8;

package Interchange6::Schema::ResultSet::Navigation;

=head1 NAME

Interchange6::Schema::ResultSet::Navigation

=cut

=head1 SYNOPSIS

Provides extra accessor methods for L<Interchange6::Schema::Result::Navigation>

=cut

use strict;
use warnings;
use mro 'c3';

use parent 'Interchange6::Schema::ResultSet';

=head1 METHODS

=head2 active

Returns all rows where L<Interchange6::Schema::Result::Navigation/active> is
true.

=cut

sub active {
    return $_[0]->search( { $_[0]->me('active') => 1 } );
}

=head2 with_active_child_count

Create slot C<active_child_count> in the resultset containing the count of
active child navs.

=cut

sub with_active_child_count {
    my $self = shift;

    return $self->search(
        undef,
        {
            '+columns' => {
                active_child_count =>
                  $self->correlate('active_children')->count_rs->as_query
            },
        }
    );
}

=head2 with_active_product_count

Create slot C<active_product_count> in the resultset containing the count of
active products associated with each navigation row.

=cut

sub with_active_product_count {
    my $self = shift;

    return $self->search(
        undef,
        {
            '+columns' => {
                active_product_count =>
                  $self->correlate('navigation_products')
                  ->related_resultset('product')->active->count_rs->as_query
            },
        }
    );
}

1;
