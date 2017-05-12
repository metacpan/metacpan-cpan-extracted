package Games::Nintendo::Wii::Mii::Data::Profile;

use strict;
use warnings;

use base qw(Class::Accessor::Fast);

use Readonly;

Readonly our @ACCESSORS => qw/
                                 gender
                                 birth_date
                                 birth_month
                                 favorite_color
                                 name
                                 mii_id
                                 system_id
                                 system_id_checksum8
                                 mingle
                                 creator_name
                                 invalid
                             /;

__PACKAGE__->mk_accessors(@ACCESSORS);

=head1 NAME

Games::Nintendo::Wii::Mii::Data::Profile - Mii's profile data

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
    $args->{gender} ||= 1;
    $args->{birth_date} ||= 5;
    $args->{birth_month} ||= 4;
    $args->{favorite_color} ||= 4;
    $args->{mingle} ||= 1;
    $args->{valid} ||= 1;

    my $self = $class->SUPER::new($args);

    return $self;
}

=head2 gender

=head2 birth_date

=head2 birth_month

=head2 favorite_color

=head2 name

=head2 mii_id

=head2 system_id

=head2 systemd_id_checksum8

=head2 mingle

=head2 creator_name

=head1 AUTHOR

Toru Yamaguchi, C<< <zigorou@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-games-nintendo-wii-mii-data-profile@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically be
notified of progress on your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2007 Toru Yamaguchi, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Games::Nintendo::Wii::Mii::Data::Profile
