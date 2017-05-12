package Gapp::Window;
{
  $Gapp::Window::VERSION = '0.60';
}

use Moose;
use MooseX::SemiAffordanceAccessor;
use MooseX::Types::Moose qw( HashRef );

extends 'Gapp::Container';
with 'Gapp::Meta::Widget::Native::Role::HasIcon';

has '+gclass' => (
    default => 'Gtk2::Window',
);

has 'transient_for' => (
    is => 'rw',
    isa => 'Maybe[Gapp::Window]',
);

#has 'default_widget' => (
#    is => 'rw',
#    isa => 'Maybe[Gapp::Widget]',
#);


sub BUILDARGS {
    my $class = shift;
    my %args = @_ == 1 && is_HashRef( $_[0] ) ? %{$_[0]} : @_;
    
    
    if ( exists $args{default_size} ) {
        $args{properties}{'default-width'} = $args{default_size}[0];
        $args{properties}{'default-height'} = $args{default_size}[1];
        delete $args{default_size};
    }
    if ( exists $args{type} ) {
        $args{args} = [ delete $args{type} ];
    }
    if ( exists $args{position} ) {
        $args{properties}{window_position} = delete $args{position};
    }
    for my $att ( qw(default_height default_width modal opacity resizable window_position title  ) ) {
        $args{properties}{$att} = delete $args{$att} if exists $args{$att};
    }
    
    __PACKAGE__->SUPER::BUILDARGS( %args );
}

#
#after _build_gobject => sub {
#    my ( $self ) = @_;
#    if ( $self->default_widget ) {
#        $self->default_widget->gobject->set_can_default( 1 );
#        $self->default_widget->gobject->grab_default;
#    }
#};



1;



__END__

=pod

=head1 NAME

Gapp::Window - Window Widget

=head1 OBJECT HIERARCHY

=over 4

=item L<Gapp::Object>

=item +-- L<Gapp::Widget>

=item ....+-- L<Gapp::Container>

=item ........+-- L<Gapp::Window>

=back

=head2 Roles

=over 4

=item L<Gapp::Meta::Widget::Native::Trait::Role::HasIcon>

=back

=head1 PROVIDED ATTRIBUTES

=over 4

=item B<transient_for>

=over 4

=item is rw

=item isa L<Gapp::Window>|Undef

=back

=back

=head1 DELEGATED PROPERTIES

=over 4

=item B<title>

=item B<default_height>

=item B<default_width>

=item B<default_size => [$width, $height]>

Takes an ArrayRef and delegates the contents to the C<default_width> and
C<default_height> properties.

=item B<modal>

=item B<opacity>

=item B<resizable>

=item B<title>

=item B<window_position>

=back 

=head1 AUTHORS

Jeffrey Ray Hallock E<lt>jeffrey.hallock at gmail dot comE<gt>

=head1 COPYRIGHT & LICENSE

    Copyright (c) 2011-2012 Jeffrey Ray Hallock.

    This program is free software; you can redistribute it and/or
    modify it under the same terms as Perl itself.

=cut