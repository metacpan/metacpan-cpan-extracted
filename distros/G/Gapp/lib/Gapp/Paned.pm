package Gapp::Paned;
{
  $Gapp::Paned::VERSION = '0.60';
}

use Moose;
use MooseX::SemiAffordanceAccessor;

extends 'Gapp::Container';

has '+gclass' => (
    default => 'Gtk2::Paned',
);

has 'resize1' => (
    is => 'rw',
    isa => 'Bool',
    default =>  0,
);

has 'shrink1' => (
    is => 'rw',
    isa => 'Bool',
    default => 1,
);

has 'resize2' => (
    is => 'rw',
    isa => 'Bool',
    default =>  1,
);

has 'shrink2' => (
    is => 'rw',
    isa => 'Bool',
    default => 1,
);


sub BUILDARGS {
    my $class = shift;
    my %args = @_ == 1 && is_HashRef( $_[0] ) ? %{$_[0]} : @_;
    
    for my $att ( qw(max_position min_position position position_set) ) {
        $args{properties}{$att} = delete $args{$att} if exists $args{$att};
    }
    
    __PACKAGE__->SUPER::BUILDARGS( %args );
}

1;


__END__

=pod

=head1 NAME

Gapp::Paned - Box widget

=head1 OBJECT HIERARCHY

=over 4

=item l<Gapp::Object>

=item +--L<Gapp::Widget>

=item ....+-- L<Gapp::Container>

=item ........+-- L<Gapp::Paned>

=back

=head1 DELEGATED PROPERTIES

=over 4

=item max_position

=item min_position

=item position

=item position_set

=back

=head1 PROVIDED ATTRIBUTES

=over 4

=item resize1

=over 4

=item is rw

=item isa Bool

=item default 0

=back

Determines if the widget in the left/top pane will expand when the pane is resized.

=item resize2

=over 4

=item is rw

=item isa Bool

=item default 1

=back

Determines if the widget in the right/bottom pane will expand when the pane is resized.

=item shrink1

=over 4

=item is rw

=item isa Bool

=item default 1

=back

Determines if the widget in the left/top cpane an be resized smaller than it's requested dimensions.

=item shrink2

=over 4

=item is rw

=item isa Bool

=item default 1

=back

Determines if the widget in the right/bottom pane can be resized smaller than it's requested dimensions.

=back

=head1 AUTHORS

Jeffrey Ray Hallock E<lt>jeffrey.hallock at gmail dot comE<gt>

=head1 COPYRIGHT & LICENSE

    Copyright (c) 2011-2012 Jeffrey Ray Hallock.

    This program is free software; you can redistribute it and/or
    modify it under the same terms as Perl itself.

=cut