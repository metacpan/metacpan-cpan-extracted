package Gapp::CheckButton;
{
  $Gapp::CheckButton::VERSION = '0.60';
}

use Moose;
use MooseX::SemiAffordanceAccessor;

extends 'Gapp::ToggleButton';

has '+gclass' => (
    default => 'Gtk2::CheckButton',
);

sub get_field_value {
    my $self = shift;
    my $state = $self->gobject->get_active;
    if ( $state ) {
        return $self->value;
    }
}

1;

__END__

=pod

=head1 NAME

Gapp::CheckButton - CheckButton Widget

=head1 OBJECT HIERARCHY

=over 4

=item L<Gapp::Object>

=item +-- L<Gapp::Widget>

=item ....+-- L<Gapp::Button>

=item ........+-- L<Gapp::ToggleButton>

=item ............+-- L<Gapp::CheckButton>

=back

=head1 AUTHORS

Jeffrey Ray Hallock E<lt>jeffrey.hallock at gmail dot comE<gt>

=head1 COPYRIGHT & LICENSE

    Copyright (c) 2011-2012 Jeffrey Ray Hallock.

    This program is free software; you can redistribute it and/or
    modify it under the same terms as Perl itself.

=cut