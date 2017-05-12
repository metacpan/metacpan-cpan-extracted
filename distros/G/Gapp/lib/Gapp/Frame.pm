package Gapp::Frame;
{
  $Gapp::Frame::VERSION = '0.60';
}

use Moose;
use MooseX::SemiAffordanceAccessor;

extends 'Gapp::Bin';

has '+gclass' => (
    default => 'Gtk2::Frame',
);

has 'label_widget' => (
    is => 'rw',
    isa => 'Maybe[Gapp::Widget]',
);


sub BUILDARGS {
    my $class = shift;
    my %args = @_ == 1 && is_HashRef( $_[0] ) ? %{$_[0]} : @_;
    
    for my $att ( qw(label shadow_type) ) {
        $args{properties}{$att} = delete $args{$att} if exists $args{$att};
    }
    
    if ( exists $args{label_align} ) {
        $args{properties}{label_xalign} = $args{label_align}[0];
        $args{properties}{label_yalign} = $args{label_align}[1];
        delete $args{label_align};
    }
    
    __PACKAGE__->SUPER::BUILDARGS( %args );
}


1;



__END__

=pod

=head1 NAME

Gapp::Frame - Frame widget

=head1 OBJECT HIERARCHY

=over 4

=item L<Gapp::Object>

=item +-- L<Gapp::Widget>

=item ....+-- L<Gapp::Container>

=item ........+-- L<Gapp::Bin>

=item ............+-- L<Gapp::Frame>

=back

=head1 PROVIDED ATTRIBUTES

=over 4

=item B<label_widget>

=over 4

=item is rw

=item isa Maybe[L<Gapp::Widget>]

=back

The widget to use as the label for the frame.

=back

=head1 DELEGATED PROPERTIES

=over 4

=item B<label>

=item B<label_align>

=item B<shadow_type>

=back 

=head1 AUTHORS

Jeffrey Ray Hallock E<lt>jeffrey.hallock at gmail dot comE<gt>

=head1 COPYRIGHT & LICENSE

    Copyright (c) 2011-2012 Jeffrey Ray Hallock.

    This program is free software; you can redistribute it and/or
    modify it under the same terms as Perl itself.

=cut