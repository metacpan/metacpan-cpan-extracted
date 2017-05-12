package Gapp::ImageMenuItem;
{
  $Gapp::ImageMenuItem::VERSION = '0.60';
}

use Moose;
use MooseX::StrictConstructor;
use MooseX::SemiAffordanceAccessor;

extends 'Gapp::MenuItem';
with 'Gapp::Meta::Widget::Native::Role::HasIcon';
with 'Gapp::Meta::Widget::Native::Role::HasImage';

has '+gclass' => (
    default => 'Gtk2::ImageMenuItem',
);

1;


__END__

=pod

=head1 NAME

Gapp::ImageMenuItem - ImageMenuItem Widget

=head1 OBJECT HIERARCHY

=over 4

=item L<Gapp::Widget>

=item +-- L<Gapp::MenuItem>

=item ....+-- L<Gapp::ImageMenuItem>

=back

=head2 Roles

=over 4

=item L<Gapp::Meta::Widget::Native::Role::HasIcon>

=item L<Gapp::Meta::Widget::Native::Role::HasImage>

=back

=head1 AUTHORS

Jeffrey Ray Hallock E<lt>jeffrey.hallock at gmail dot comE<gt>

=head1 COPYRIGHT & LICENSE

    Copyright (c) 2011-2012 Jeffrey Ray Hallock.

    This program is free software; you can redistribute it and/or
    modify it under the same terms as Perl itself.

=cut