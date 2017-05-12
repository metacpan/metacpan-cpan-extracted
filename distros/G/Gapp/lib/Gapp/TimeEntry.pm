package Gapp::TimeEntry;
{
  $Gapp::TimeEntry::VERSION = '0.60';
}

use Moose;
use MooseX::SemiAffordanceAccessor;

use Gapp::Gtk2::DateEntry;

extends 'Gapp::Entry';
with 'Gapp::Meta::Widget::Native::Role::FormField';

has '+gclass' => (
    default => 'Gapp::Gtk2::TimeEntry',
);


sub BUILDARGS {
    my $class = shift;
    my %args = @_ == 1 && is_HashRef( $_[0] ) ? %{$_[0]} : @_;
    
    
    for my $att ( qw(value) ) {
        $args{properties}{$att} = delete $args{$att} if exists $args{$att};
    }

    __PACKAGE__->SUPER::BUILDARGS( %args );
}

# returns the value of the widget
sub get_field_value {
    $_[0]->gobject->get_value;
}

sub set_field_value {
    my ( $self, $value ) = @_;
    $self->gobject->set_value( $value );
}

sub _connect_changed_handler {
    my ( $self ) = @_;

    $self->gobject->signal_connect (
      'value-changed' => sub { $self->_widget_value_changed },
    );
}


1;


__END__

=pod

=head1 NAME

Gapp::TimeEntry - TimeEntry Widget

=head1 OBJECT HIERARCHY

=over 4

=item L<Gapp::Widget>

=item +-- L<Gapp::Entry>

=item ....+-- L<Gapp::TimeEntry>

=back

=head1 DELEGATED PROPERTIES

=over 4

=item B<value>

=back 

=head1 AUTHORS

Jeffrey Ray Hallock E<lt>jeffrey.hallock at gmail dot comE<gt>

=head1 COPYRIGHT & LICENSE

    Copyright (c) 2011-2012 Jeffrey Ray Hallock.

    This program is free software; you can redistribute it and/or
    modify it under the same terms as Perl itself.

=cut

