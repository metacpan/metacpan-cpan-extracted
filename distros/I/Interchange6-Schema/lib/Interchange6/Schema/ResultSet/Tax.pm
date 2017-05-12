use utf8;

package Interchange6::Schema::ResultSet::Tax;

=head1 NAME

Interchange6::Schema::ResultSet::Tax

=cut

=head1 SYNOPSIS

Provides extra accessor methods for L<Interchange6::Schema::Result::Tax>

=cut

use strict;
use warnings;
use mro 'c3';

use DateTime;

use parent 'Interchange6::Schema::ResultSet';

=head1 METHODS

=head2 current_tax( $tax_name )

Given a valid tax_name will return the Tax row for the current date

=cut

sub current_tax {
    my ( $self, $tax_name ) = @_;

    my $schema = $self->result_source->schema;
    my $dtf    = $schema->storage->datetime_parser;
    my $dt     = DateTime->today;

    $schema->throw_exception("tax_name not supplied") unless defined $tax_name;

    my $rset = $self->search(
        {
            tax_name   => $tax_name,
            valid_from => { '<=', $dtf->format_datetime($dt) },
            valid_to   => [ undef, { '>=', $dtf->format_datetime($dt) } ],
        }
    );

    if ( $rset->count == 1 ) {
        return $rset->next;
    }
    else {
        $schema->throw_exception(
            "current_tax not found for tax_name: " . $tax_name );
    }
}

1;
