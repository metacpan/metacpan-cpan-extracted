package Gapp::FileChooserButton;
{
  $Gapp::FileChooserButton::VERSION = '0.60';
}

use Moose;

extends 'Gapp::Widget';
with 'Gapp::Meta::Widget::Native::Role::FormField';
with 'Gapp::Meta::Widget::Native::Role::FileChooser';

has '+gclass' => (
    default => 'Gtk2::FileChooserButton',
);


before '_build_gobject' => sub {
    my $self = shift;
    $self->set_args( [ $self->properties->{title} ? $self->properties->{title} : '' , $self->action ] );
};


# returns the value of the widget
sub get_field_value {
    $_[0]->gobject->get_filename;
}

sub set_field_value {
    my ( $self, $value ) = @_;
    $self->gobject->set_filename( defined $value ? $value : '' );
}

sub widget_to_stash {
    my ( $self, $stash ) = @_;
    $stash->store( $self->field, $self->get_field_value );
}

sub stash_to_widget {
    my ( $self, $stash ) = @_;
    $self->set_field_value( $stash->fetch( $self->field ) );
}

sub _connect_changed_handler {
    my ( $self ) = @_;

    $self->gobject->signal_connect (
      file_set => sub { $self->_widget_value_changed },
    );
}


1;

__END__

=pod

=head1 NAME

Gapp::FileChooserButton - FileChooserButton Widget

=head1 OBJECT HIERARCHY

=over 4

=item L<Gapp::Object>

=item +-- L<Gapp::Widget>

=item ....+-- L<Gapp::Container>

=item ........+-- L<Gapp::Box>

=item ............+-- L<Gapp::HBox>

=item ................+-- Gapp::FileChooserButton

=back

=head1 AUTHORS

Jeffrey Ray Hallock E<lt>jeffrey.hallock at gmail dot comE<gt>

=head1 COPYRIGHT & LICENSE

    Copyright (c) 2011-2012 Jeffrey Ray Hallock.

    This program is free software; you can redistribute it and/or
    modify it under the same terms as Perl itself.

=cut

