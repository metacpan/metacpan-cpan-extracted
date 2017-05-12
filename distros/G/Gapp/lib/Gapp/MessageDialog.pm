package Gapp::MessageDialog;
{
  $Gapp::MessageDialog::VERSION = '0.60';
}

use Moose;
use MooseX::SemiAffordanceAccessor;

extends 'Gapp::Dialog';

has 'buttons' => (
    is => 'rw',
    isa => 'Maybe[ArrayRef]',
);

has 'action_widgets' => (
    is => 'rw',
    isa => 'Maybe[ArrayRef]',
);

has '+gclass' => (
    default => 'Gtk2::Dialog',
);

has '+gobject' => (
    handles => [qw( run destroy )],
);

after '_build_gobject' => sub {
    shift->gobject->vbox->show_all;
};


1;

__END__

=pod

=head1 NAME

Gapp::Dialog - Dialog Widget

=head1 OBJECT HIERARCHY

=over 4

=item L<Gapp::Object>

=item +-- L<Gapp::Widget>

=item ....+-- L<Gapp::Container>

=item ........+-- L<Gapp::Window>

=item ............+-- L<Gapp::Dialog>

=back

=head1 PROVIDED ATTRIBUTES

=over 4

=item B<action_widgets>

=over 4

=item is rw

=item isa Maybe[ArrayRef]

=back

Additional widgets to pack into the action area.  

=item B<buttons>

=over 4

=item is rw

=item isa Maybe[ArrayRef]

=back

Buttons to pack into the dialog. Can use C<GappAction> items here as well.

=back

=head1 DELEGATED METHODS

=over 4

=item max_run

=back

=head1 AUTHORS

Jeffrey Ray Hallock E<lt>jeffrey.hallock at gmail dot comE<gt>

=head1 COPYRIGHT & LICENSE

    Copyright (c) 2011-2012 Jeffrey Ray Hallock.

    This program is free software; you can redistribute it and/or
    modify it under the same terms as Perl itself.

=cut