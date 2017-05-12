package Gapp::ToolItem;
{
  $Gapp::ToolItem::VERSION = '0.60';
}

use Moose;
use MooseX::SemiAffordanceAccessor;
extends 'Gapp::Widget';
with 'Gapp::Meta::Widget::Native::Role::HasAction';

has '+gclass' => (
    default => 'Gtk2::ToolItem',
);

1;



__END__

=pod

=head1 NAME

Gapp::ToolItem - ToolItem Widget

=head1 OBJECT HIERARCHY

=over 4

=item L<Gapp::Object>

=item +-- L<Gapp::Widget>

=item ....+-- L<Gapp::ToolItem>

=back

=head2 Roles

=over 4

=item L<Gapp::Meta::Widget::Native::Role::HasAction>

=back

=head1 AUTHORS

Jeffrey Ray Hallock E<lt>jeffrey.hallock at gmail dot comE<gt>

=head1 COPYRIGHT & LICENSE

    Copyright (c) 2011-2012 Jeffrey Ray Hallock.

    This program is free software; you can redistribute it and/or
    modify it under the same terms as Perl itself.

=cut