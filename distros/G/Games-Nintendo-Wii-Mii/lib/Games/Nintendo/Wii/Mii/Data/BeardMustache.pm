package Games::Nintendo::Wii::Mii::Data::BeardMustache;

use strict;
use warnings;

use base qw(Class::Accessor::Fast);

use Readonly;

Readonly our @ACCESSORS => qw/
                                 mustache_type
                                 beard_type
                                 facial_hair_color
                                 mustache_size
                                 mustache_vertical_position
                             /;

__PACKAGE__->mk_accessors(@ACCESSORS);

=head1 NAME

Games::Nintendo::Wii::Mii::Data::BeardMustache - Mii's beard and mustache data

=head1 VERSION

version 0.02

=cut

our $VERSION = '0.02';

=head1 METHODS

=head2 new

=cut

sub new {
    my ($class, $args) = @_;

    $args ||= {};
    $args->{mustache_type} ||= 2;
    $args->{beard_type} ||= 2;
    $args->{facial_hair_color} ||= 3;
    $args->{mustache_size} ||= 4;
    $args->{mustache_vertical_position} ||= 4;

    my $self = $class->SUPER::new($args);

    return $self;
}

=head2 mustache_type

=head2 beard_type

=head2 facial_hair_color

=head2 mustache_size

=head2 mustache_vertical_position

=head1 AUTHOR

Toru Yamaguchi, C<< <zigorou@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-games-nintendo-wii-mii-data-mustache@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically be
notified of progress on your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2007 Toru Yamaguchi, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Games::Nintendo::Wii::Mii::Data::BeardMustache
