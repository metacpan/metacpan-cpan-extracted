package Gapp::ToolButton;
{
  $Gapp::ToolButton::VERSION = '0.60';
}

use Moose;
use MooseX::Types::Moose qw( ArrayRef );
use MooseX::SemiAffordanceAccessor;

extends 'Gapp::ToolItem';
with 'Gapp::Meta::Widget::Native::Role::HasIcon';
with 'Gapp::Meta::Widget::Native::Role::HasIconSize';
with 'Gapp::Meta::Widget::Native::Role::HasImage';
with 'Gapp::Meta::Widget::Native::Role::HasLabel';
with 'Gapp::Meta::Widget::Native::Role::HasStockId';

has '+gclass' => (
    default => 'Gtk2::ToolButton',
);





1;



__END__

=pod

=head1 NAME

Gapp::ToolButton - ToolButton Widget

=head1 OBJECT HIERARCHY

=over 4

=item L<Gapp::Object>

=item +-- L<Gapp::Widget>

=item ....+-- L<Gapp::ToolItem>

=item ........+-- L<Gapp::ToolButton>

=back

=head2 Roles

=over 4

=item L<Gapp::Meta::Widget::Native::Role::HasIcon>

=item L<Gapp::Meta::Widget::Native::Role::HasIconSize>

=item L<Gapp::Meta::Widget::Native::Role::HasLabel>

=item L<Gapp::Meta::Widget::Native::Role::HasStockId>

=back


=head1 AUTHORS

Jeffrey Ray Hallock E<lt>jeffrey.hallock at gmail dot comE<gt>

=head1 COPYRIGHT & LICENSE

    Copyright (c) 2011-2012 Jeffrey Ray Hallock.

    This program is free software; you can redistribute it and/or
    modify it under the same terms as Perl itself.

=cut
