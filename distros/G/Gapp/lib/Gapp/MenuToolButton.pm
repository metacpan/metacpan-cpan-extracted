package Gapp::MenuToolButton;
{
  $Gapp::MenuToolButton::VERSION = '0.60';
}

use Moose;
use MooseX::SemiAffordanceAccessor;
extends 'Gapp::ToolButton';
with 'Gapp::Meta::Widget::Native::Role::HasMenu';

has '+gclass' => (
    default => 'Gtk2::MenuToolButton',
);

#after '_construct_gobject' => sub {
#    my ( $self ) = @_;
#    $self->gobject->set_menu( $self->menu->gobject ) if $self->menu;
#};

1;



__END__

=pod

=head1 NAME

Gapp::MenuToolButton - MenuToolButton Widget

=head1 OBJECT HIERARCHY

=over 4

=item L<Gapp::Object>

=item +-- L<Gapp::Widget>

=item ....+-- L<Gapp::ToolItem>

=item ........+-- L<Gapp::ToolButton>

=item ............+-- L<Gapp::MenuToolButton>

=back

=head2 Roles

=over 4

=item L<Gapp::Meta::Widget::Native::Role::HasMenu>

=back

=head1 AUTHORS

Jeffrey Ray Hallock E<lt>jeffrey.hallock at gmail dot comE<gt>

=head1 COPYRIGHT & LICENSE

    Copyright (c) 2011-2012 Jeffrey Ray Hallock.

    This program is free software; you can redistribute it and/or
    modify it under the same terms as Perl itself.

=cut

