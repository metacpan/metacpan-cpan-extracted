package Gapp::Meta::Widget::Native::Role::CanDefault;
{
  $Gapp::Meta::Widget::Native::Role::CanDefault::VERSION = '0.60';
}

use Moose::Role;
use MooseX::SemiAffordanceAccessor;

has 'default' => (
    is => 'rw',
    isa => 'Bool',
    default => 0,
);

after _build_gobject => sub {
    my ( $self ) = @_;
    if ( $self->toplevel && $self->toplevel->isa('Gapp::Window') ) {
        $self->gobject->set_can_default( 1 );
        $self->toplevel->gobject->set_default( $self->gobject );
    }
};


1;


__END__

=pod

=head1 NAME

Gapp::Meta::Widget::Native::Role::CanDefault - Role for widgets that can be the default

=head1 SYNOPSIS

    Gapp::Button->new( label => 'Exit', default => 1 );
    
=head1 PROVIDED ATTRIBUTES

=over 4

=item B<default>

=over 4

=item is rw

=item isa Bool

=item default 0

=back

If true the button will set istelf as the default widget for the window.

=back

=head1 AUTHORS

Jeffrey Ray Hallock E<lt>jeffrey.hallock at gmail dot comE<gt>

=head1 COPYRIGHT & LICENSE

    Copyright (c) 2011-2012 Jeffrey Ray Hallock.

    This program is free software; you can redistribute it and/or
    modify it under the same terms as Perl itself.

=cut