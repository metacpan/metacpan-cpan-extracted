package Gapp::Entry;
{
  $Gapp::Entry::VERSION = '0.60';
}

use Moose;
use MooseX::SemiAffordanceAccessor;

extends 'Gapp::Widget';
with 'Gapp::Meta::Widget::Native::Role::FormField';

has '+gclass' => (
    default => 'Gtk2::Entry',
);

sub BUILDARGS {
    my $class = shift;
    my %args = @_ == 1 && is_HashRef( $_[0] ) ? %{$_[0]} : @_;
    
    for my $att ( qw( activates_default caps_lock_warning max_length invisible_char overwrite_mode text visibility width_chars xalign ) ) {
        $args{properties}{$att} = delete $args{$att} if exists $args{$att};
    }

    __PACKAGE__->SUPER::BUILDARGS( %args );
}

# returns the value of the widget
sub get_field_value {
    $_[0]->gobject->get_text;
}

sub set_field_value {
    my ( $self, $value ) = @_;
    $self->gobject->set_text( defined $value ? $value : '' );
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
      changed => sub { $self->_widget_value_changed },
    );
}

1;


__END__

=pod

=head1 NAME

Gapp::Entry - Entry Widget

=head1 OBJECT HIERARCHY

=over 4

=item L<Gapp::Object>

=item +-- L<Gapp::Widget>

=item ....+-- L<Gapp::Entry>

=back

=head2 Roles

=over 4

=item L<Gapp::Meta::Widget::Native::Role::FormField>

=back

=head1 DELEGATED PROPERTIES

=over 4

=item B<activates_default>

=item B<caps_lock_warning>

=item B<max_length>

=item B<invisible_char>

=item B<overwrite_mode>

=item B<text>

=item B<visibility>

=item B<width_chars>

=item B<xalign>

=back 

=head1 AUTHORS

Jeffrey Ray Hallock E<lt>jeffrey.hallock at gmail dot comE<gt>

=head1 COPYRIGHT & LICENSE

    Copyright (c) 2011-2012 Jeffrey Ray Hallock.

    This program is free software; you can redistribute it and/or
    modify it under the same terms as Perl itself.

=cut

