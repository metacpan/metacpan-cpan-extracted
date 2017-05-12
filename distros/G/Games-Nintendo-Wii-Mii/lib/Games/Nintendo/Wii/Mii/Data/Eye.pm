package Games::Nintendo::Wii::Mii::Data::Eye;

use strict;
use warnings;

use base qw(Class::Accessor::Fast);

use Readonly;

Readonly our @ACCESSORS => qw/
                                 eye_type
                                 eye_rotation
                                 eye_vertical_position
                                 eye_color
                                 eye_size
                                 eye_horizon_spacing
                             /;

__PACKAGE__->mk_accessors(@ACCESSORS);

=head1 NAME

Games::Nintendo::Wii::Mii::Data::Eye - Mii's eye data

=head1 VERSION

version 0.01

=cut

our $VERSION = '0.01';

=head1 METHODS

=head2 new

=cut

sub new {
    my ($class, $args) = @_;

    $args ||= {};

    $args->{eye_type} ||= 6;
    $args->{eye_rotation} ||= 3;
    $args->{eye_vertical_position} ||= 5;
    $args->{eye_color} ||= 3;
    $args->{eye_size} ||= 3;
    $args->{eye_horizon_spacing} ||= 4;

    my $self = $class->SUPER::new($args);

    return $self;
}

=head2 eye_type

=head2 eye_rotation

=head2 eye_vertical_position

=head2 eye_color

=head2 eye_size

=head2 eye_horizon_spacing

=head1 AUTHOR

Toru Yamaguchi, C<< <zigorou@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-games-nintendo-wii-mii-data-eye@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically be
notified of progress on your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2007 Toru Yamaguchi, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Games::Nintendo::Wii::Mii::Data::Eye
