package Gapp::CheckMenuItem;
{
  $Gapp::CheckMenuItem::VERSION = '0.60';
}

use Moose;
use MooseX::StrictConstructor;
use MooseX::SemiAffordanceAccessor;

extends 'Gapp::MenuItem';
with 'Gapp::Meta::Widget::Native::Role::FormField';

has '+gclass' => (
    default => 'Gtk2::CheckMenuItem',
);

has 'value' => (
    is => 'rw',
    isa => 'Str',
    default => '1',
);




sub BUILDARGS {
    my $class = shift;
    my %args = @_ == 1 && is_HashRef( $_[0] ) ? %{$_[0]} : @_;
    
    if ( exists $args{active} ) {
        $args{properties}{active} = delete $args{active};
    }
    
    __PACKAGE__->SUPER::BUILDARGS( %args );
}

sub get_field_value {
    my $self = shift;
    my $state = $self->gobject->get_active;
    if ( $state ) {
        return $self->value;
    }
    else {
        return undef;
    }
}

sub set_field_value {
    my ( $self, $value ) = @_;
    if ( defined $value && $value eq $self->value ) {
        $self->gobject->set_active( 1 )
    }
    else {
        $self->gobject->set_active( 0 )
    }
}

sub widget_to_stash {
    my ( $self, $stash ) = @_;
    $stash->store( $self->field, $self->get_field_value );
}

sub stash_to_widget {
    my ( $self, $stash ) = @_;
    $self->set_field_value( $stash->fetch( $self->field ) );
}







1;


__END__

=pod

=head1 NAME

Gapp::ImageMenuItem - ImageMenuItem Widget

=head1 OBJECT HIERARCHY

=over 4

=item L<Gapp::Widget>

=item +-- L<Gapp::MenuItem>

=item ....+-- L<Gapp::CheckMenuItem>

=back

=head2 Roles

=over 4

=item L<Gapp::Meta::Widget::Native::Role::FormField>

=back

=head1 AUTHORS

Jeffrey Ray Hallock E<lt>jeffrey.hallock at gmail dot comE<gt>

=head1 COPYRIGHT & LICENSE

    Copyright (c) 2011-2012 Jeffrey Ray Hallock.

    This program is free software; you can redistribute it and/or
    modify it under the same terms as Perl itself.

=cut