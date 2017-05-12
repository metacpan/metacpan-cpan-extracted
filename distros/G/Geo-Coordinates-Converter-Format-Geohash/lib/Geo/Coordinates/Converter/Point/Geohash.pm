package Geo::Coordinates::Converter::Point::Geohash;
use strict;
use warnings;
use parent 'Geo::Coordinates::Converter::Point';
use Class::Accessor::Lite (
    rw => [qw/ geohash /],
);

sub new {
    my($class, $args) = @_;
    my $geohash = delete $args->{geohash};

    my $self = $class->SUPER::new($args);

    delete $self->{lat};
    delete $self->{lng};
    $self->{geohash} = $geohash;

    $self;
}

1;
__END__

=head1 NAME

Geo::Coordinates::Converter::Point::Geohash - location point class for Geohash

=head1 SYNOPSIS

  use Geo::Coordinates::Converter::Point::Geohash;

  my $point = Geo::Coordinates::Converter::Point::Geohash->new({
      geohash => 'xn76gg',
  });

=head1 METHOD

=head2 geohash

can you set the Geohash string.

=head1 AUTHOR

Kazuhiro Osawa E<lt>yappo {at} shibuya {dot} plE<gt>

=head1 SEE ALSO

L<Geo::Coordinates::Converter::Format::Geohash>,
L<Geo::Coordinates::Converter::Point>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
