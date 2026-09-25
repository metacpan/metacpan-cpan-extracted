use strict;

package HTML::FormFu::Role::Filter::Compound;
$HTML::FormFu::Role::Filter::Compound::VERSION = '2.09';
# ABSTRACT: Role for Compound filters

use Moose::Role;

has field_order => ( is => 'rw', traits => ['Chained'] );

sub _get_values {
    my ( $self, $value ) = @_;

    my ( $multi, @fields ) = @{ $self->parent->get_fields };

    if ( my $order = $self->field_order ) {
        my @new_order;

    FIELD:
        for my $i (@$order) {
            for my $field (@fields) {
                if ( $field->name eq $i ) {
                    push @new_order, $field;
                    next FIELD;
                }
            }
        }

        @fields = @new_order;
    }

    my @names = map { $_->name } @fields;

    return map { defined $_ ? $_ : '' } @{$value}{@names};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HTML::FormFu::Role::Filter::Compound - Role for Compound filters

=head1 VERSION

version 2.09

=head1 METHODS

=head2 field_order

Arguments: \@order

If the submitted parts should be joined in an order different than that of the
order of the fields, you must provide an arrayref containing the names, in the
order they should be joined.

    ---
    element:
      - type: Multi
        name: address

        elements:
          - name: street
          - name: number

        filter:
          - type: CompoundJoin
            field_order:
              - number
              - street

=head1 AUTHOR

Carl Franks, C<cfranks@cpan.org>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 AUTHOR

Carl Franks <cpan@fireartist.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026, 2018, 2016, 2015, 2012, 2011 by Carl Franks.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
