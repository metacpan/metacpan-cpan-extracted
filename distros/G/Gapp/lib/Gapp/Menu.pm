package Gapp::Menu;
{
  $Gapp::Menu::VERSION = '0.60';
}

use Moose;
use MooseX::SemiAffordanceAccessor;
extends 'Gapp::MenuShell';

has '+gclass' => (
    default => 'Gtk2::Menu',
);



1;


sub run_visible_funcs {
    my ( $self ) = @_;
   
    for my $i ( $self->children ) {
        if ( $i->visible_func ) {
            $i->visible_func->( $i ) ? $i->show_all : $i->hide
        }
        
    }
}

sub popup {
    my ( $self, @args ) = @_;
    
    $self->run_visible_funcs;
    $self->gobject->popup( @args );
}


__END__

=pod

=head1 NAME

Gapp::Menu - Menu Widget

=head1 OBJECT HIERARCHY

=over 4

=item L<Gapp::Object>

=item +-- L<Gapp::Widget>

=item ....+-- L<Gapp::Container>

=item ........+-- L<Gapp::MenuShell>

=item ............+-- L<Gapp::Menu>

=back

=head1 AUTHORS

Jeffrey Ray Hallock E<lt>jeffrey.hallock at gmail dot comE<gt>

=head1 COPYRIGHT & LICENSE

    Copyright (c) 2011-2012 Jeffrey Ray Hallock.

    This program is free software; you can redistribute it and/or
    modify it under the same terms as Perl itself.

=cut
