use strict;

package HTML::FormFu::Element::Fieldset;
$HTML::FormFu::Element::Fieldset::VERSION = '2.07';
# ABSTRACT: Fieldset element

use Moose;
extends 'HTML::FormFu::Element::Block';

use HTML::FormFu::Util qw( xml_escape );

__PACKAGE__->mk_output_accessors(qw( legend ));

__PACKAGE__->mk_attrs(qw( legend_attributes ));

after BUILD => sub {
    my $self = shift;

    $self->tag('fieldset');

    return;
};

sub render_data_non_recursive {
    my ( $self, $args ) = @_;

    my $render = $self->SUPER::render_data_non_recursive(
        {   legend            => $self->legend,
            legend_attributes => xml_escape( $self->legend_attributes ),
            $args ? %$args : (),
        } );

    return $render;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HTML::FormFu::Element::Fieldset - Fieldset element

=head1 VERSION

version 2.07

=head1 SYNOPSIS

    my $fs = $form->element( Fieldset => 'address' );

=head1 DESCRIPTION

Fieldset element.

=head1 METHODS

=head2 legend

If L</legend> is set, it is used as the fieldset's legend

=head2 legend_loc

Arguments: $localization_key

To set the legend to a localized string, set L</legend_loc> to a key in
your L10N file instead of using L</legend>.

=head1 SEE ALSO

Is a sub-class of, and inherits methods from
L<HTML::FormFu::Element::Block>,
L<HTML::FormFu::Element>

L<HTML::FormFu>

=head1 AUTHOR

Carl Franks, C<cfranks@cpan.org>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 AUTHOR

Carl Franks <cpan@fireartist.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Carl Franks.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
