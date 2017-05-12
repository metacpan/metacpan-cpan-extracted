package Gapp::SpinButton;
{
  $Gapp::SpinButton::VERSION = '0.60';
}

use Moose;
use MooseX::SemiAffordanceAccessor;

extends 'Gapp::Entry';

has '+gclass' => (
    default => 'Gtk2::SpinButton',
);

has range => (
    is => 'rw',
    isa => 'ArrayRef',
    default => sub{ [0,999] },
);

has step => (
    is => 'rw',
    isa => 'Num',
    default => 1,
);

has page => (
    is => 'rw',
    isa => 'Maybe[Num]',
);

has '+constructor' => (
    default => 'new_with_range',
);

sub BUILDARGS {
    my $class = shift;
    my %args = @_ == 1 && is_HashRef( $_[0] ) ? %{$_[0]} : @_;
    
    for my $att ( qw(digits climb_rate) ) {
        $args{properties}{$att} = delete $args{$att} if exists $args{$att};
    }
    
    __PACKAGE__->SUPER::BUILDARGS( %args );
}

before '_construct_gobject' => sub {
    my ( $self ) = @_;
    $self->set_args( [ @{ $self->range }, $self->step ]);
};

# returns the value of the widget
sub get_field_value {
    $_[0]->gobject->get_value;
}

sub set_field_value {
    my ( $self, $value ) = @_;
    $self->gobject->set_value( defined $value ? $value : 0 );
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

Gapp::SpinButton - RadioButton Widget

=head1 OBJECT HIERARCHY

=over 4

=item L<Gapp::Object>

=item +-- L<Gapp::Widget>

=item ....+-- L<Gapp::Entry>

=item ........+-- L<Gapp::SpinButton>

=back

=head1 PROVIDED ATTRIBUTES

=over 4

=item B<range>

=over 4

=item is rw

=item isa ArrayRef

=item default [0,999]

=back

The minimum and maximum possible values.

=over 4

=item B<step>

=over 4

=item is rw

=item isa Num

=item default 1

=back

The amount the value will change when the user presses the up or down arrows.

=over 4

=item B<page>

=over 4

=item is rw

=item isa Maybe[Num]

=back

The amount the value will change when the user presses the page-up or page-down keys.

=back

=head1 AUTHORS

Jeffrey Ray Hallock E<lt>jeffrey.hallock at gmail dot comE<gt>

=head1 COPYRIGHT & LICENSE

    Copyright (c) 2011-2012 Jeffrey Ray Hallock.

    This program is free software; you can redistribute it and/or
    modify it under the same terms as Perl itself.

=cut


