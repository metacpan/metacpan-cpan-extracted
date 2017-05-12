package Games::Nintendo::Wii::Mii::Data::Hair;

use strict;
use warnings;

use base qw(Class::Accessor::Fast);

use Readonly;

Readonly our @ACCESSORS => qw/
                                 hair_type
                                 hair_color
                                 hair_part
                             /;

__PACKAGE__->mk_accessors(@ACCESSORS);

=head1 NAME

Games::Nintendo::Wii::Mii::Data::Hair - mii's hair data

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

    $args->{hair_type} ||= 7;
    $args->{hair_color} ||= 3;
    $args->{hair_part} ||= 1;

    my $self = $class->SUPER::new($args);

    return $self;
}

=head2 hair_type

=head2 hair_color

=head2 hair_part

=head1 AUTHOR

Toru Yamaguchi, C<< <zigorou@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-games-nintendo-wii-mii-data-hair@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically be
notified of progress on your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2007 Toru Yamaguchi, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Games::Nintendo::Wii::Mii::Data::Hair
