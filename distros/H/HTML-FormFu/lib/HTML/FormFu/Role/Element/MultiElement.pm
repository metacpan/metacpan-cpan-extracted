use strict;

package HTML::FormFu::Role::Element::MultiElement;
# ABSTRACT: multi-element role
$HTML::FormFu::Role::Element::MultiElement::VERSION = '2.07';
use Moose::Role;

use Carp qw( croak );

sub nested_names {
    my ($self) = @_;

    croak 'cannot set nested_names' if @_ > 1;

    if ( defined $self->name ) {
        my @names;

        # ignore immediate parent
        my $parent = $self->parent;

        while ( defined( $parent = $parent->parent ) ) {

            if ( $parent->can('is_field') && $parent->is_field ) {

                # handling Field
                push @names, $parent->name
                    if defined $parent->name;
            }
            elsif ( $parent->can('is_repeatable') && $parent->is_repeatable ) {

                # handling Repeatable
                # ignore Repeatables nested_name attribute as it is provided
                # by the childrens Block elements
            }
            else {

                # handling 'not Field' and 'not Repeatable'
                push @names, $parent->nested_name
                    if defined $parent->nested_name;
            }
        }

        if (@names) {
            return reverse(@names), $self->name;
        }
    }

    return ( $self->name );
}

sub nested_base {
    my ($self) = @_;

    croak 'cannot set nested_base' if @_ > 1;

    # ignore immediate parent
    my $parent = $self->parent;

    while ( defined( $parent = $parent->parent ) ) {

        return $parent->nested_name if defined $parent->nested_name;
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HTML::FormFu::Role::Element::MultiElement - multi-element role

=head1 VERSION

version 2.07

=head1 AUTHOR

Carl Franks <cpan@fireartist.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Carl Franks.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
