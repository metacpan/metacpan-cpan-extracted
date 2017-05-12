package Gapp::Statusbar;
{
  $Gapp::Statusbar::VERSION = '0.60';
}

use Moose;
extends 'Gapp::Box';

has '+gclass' => (
    default => 'Gtk2::Statusbar',
);

1;

__END__

=pod

=head1 NAME

Gapp::HBox - HBox Widget

=head1 OBJECT HIERARCHY

=over 4

=item L<Gapp::Object>

=item +-- L<Gapp::Widget>

=item ....+-- L<Gapp::Container>

=item ........+-- L<Gapp::Box>

=item ............+-- L<Gapp::HBox>

=item ................+-- L<Gapp::StatusBar>

=back

=head1 AUTHORS

Jeffrey Ray Hallock E<lt>jeffrey.hallock at gmail dot comE<gt>

=head1 COPYRIGHT & LICENSE

    Copyright (c) 2011-2012 Jeffrey Ray Hallock.

    This program is free software; you can redistribute it and/or
    modify it under the same terms as Perl itself.

=cut

