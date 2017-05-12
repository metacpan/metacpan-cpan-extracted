#
# This file is part of HTML-FormFu-ExtJS
#
# This software is Copyright (c) 2011 by Moritz Onken.
#
# This is free software, licensed under:
#
#   The (three-clause) BSD License
#
package HTML::FormFu::Element::ExtJS::Panel;
BEGIN {
  $HTML::FormFu::Element::ExtJS::Panel::VERSION = '0.090';
}
use Moose;
extends 'HTML::FormFu::Element::Block';

__PACKAGE__->mk_output_accessors( qw( title label ) );

has xtype => ( is => 'ro', default => 'panel' );

sub render_data_non_recursive {
    my ( $self, $args ) = @_;

    my $render = $self->next::method( {
        title => $self->title,
        label => $self->label,
        xtype => $self->xtype,
        $args ? %$args : (),
    } );

    return $render;
}


# A special ExtJS Element, so no output in HTML forms

sub string {
    my ( $self, $args ) = @_;
    warn "Stringification is not supported for " . __PACKAGE__;

    return '';
}

sub tt {
    my ( $self, $args ) = @_;
    warn "Stringification is not supported for " . __PACKAGE__;

    return '';
}

1;



=pod

=head1 NAME

HTML::FormFu::Element::ExtJS::Panel

=head1 VERSION

version 0.090

=head1 DESCRIPTION

FormFu class for ExtJS panels.

=head1 NAME

HTML::FormFu::Element::ExtJS::Panel - FormFu class for ExtJS panels

=head1 METHODS

=head2 xtype
Defaults to 'panel'

=head2 title, label
Sets the title attribute of a panel.
If both are given title has the higher priority.

=head1 SEE ALSO

The ExtJS specific stuff is in L<HTML::FormFu::ExtJS::Element::ExtJS::Panel>

=head1 AUTHOR

Mario Minati, C<mario.minati@googlemail.com>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 AUTHOR

Moritz Onken <onken@netcubed.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Moritz Onken.

This is free software, licensed under:

  The (three-clause) BSD License

=cut


__END__

