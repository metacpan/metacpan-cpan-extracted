package Gapp::RadioToolButton;
{
  $Gapp::RadioToolButton::VERSION = '0.60';
}

use Moose;
use MooseX::SemiAffordanceAccessor;
extends 'Gapp::ToggleToolButton';

has '+gclass' => (
    default => 'Gtk2::RadioToolButton',
);

has 'value' => (
    is => 'rw',
    isa => 'Str',
    default => '1',
);



# create and set the actual gobject
sub _construct_gobject {
    my ( $self ) = @_;
    
    my $gtk_class = $self->gclass;
    my $gtk_constructor = $self->constructor;
    
    # determine the radio group
    my $group = $self->field && $self->parent ?
    $self->parent->{_rdo_groups}{ $self->field } :
    undef;
    
    # use any build-arguments if they exist
    my $w = $gtk_class->$gtk_constructor( $group );
    $self->set_gobject( $w );
    
    # save the radio group in the parent
    if ( $self->parent ) {
        $self->parent->{_rdo_groups}{ $self->field } ||= $w->get_group;
    }
    
    return $w;
}

sub get_field_value {
    my $self = shift;
    my $state = $self->gobject->get_active;
    if ( $state ) {
        return $self->value;
    }
}

sub widget_to_stash {
    my ( $self, $stash ) = @_;
    my $state = $self->gobject->get_active;
    if ( $state ) {
        $stash->store( $self->field, $self->get_field_value );
    }
}

sub stash_to_widget {
    my ( $self, $stash ) = @_;
    $self->set_field_value( $stash->fetch( $self->field ) );
}

#sub _connect_changed_handler {
#    my ( $self ) = @_;
#    
#    $self->gobject->signal_connect (
#      released => sub { $self->_widget_value_changed; }
#    );
#}



1;



__END__

=pod

=head1 NAME

Gapp::ToggleToolButton - ToggleToolButton Widget

=head1 OBJECT HIERARCHY

=over 4

=item L<Gapp::Object>

=item +-- L<Gapp::Widget>

=item ....+-- L<Gapp::ToolItem>

=item ........+-- L<Gapp::ToolButton>

=item ............+-- L<Gapp::ToggleToolButton>

=item ................+-- Gapp::RadioToolButton

=back

=head1 AUTHORS

Jeffrey Ray Hallock E<lt>jeffrey.hallock at gmail dot comE<gt>

=head1 COPYRIGHT & LICENSE

    Copyright (c) 2011-2012 Jeffrey Ray Hallock.

    This program is free software; you can redistribute it and/or
    modify it under the same terms as Perl itself.

=cut

