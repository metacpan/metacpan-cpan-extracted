package Geo::Coordinates::Converter::Point::ISO6709;
use strict;
use warnings;
use parent 'Geo::Coordinates::Converter::Point';
use Class::Accessor::Lite (
    rw => [qw/ iso6709 /],
);

sub new {
    my($class, $args) = @_;
    my $iso6709 = delete $args->{iso6709};

    my $self = $class->SUPER::new($args);

    delete $self->{lat};
    delete $self->{lng};
    $self->{iso6709} = $iso6709;

    $self;
}

1;
__END__

=head1 NAME

Geo::Coordinates::Converter::Point::ISO6709 - location point class for ISO6709

=head1 SYNOPSIS

  use Geo::Coordinates::Converter::Point::ISO6709;

  my $point = Geo::Coordinates::Converter::Point::ISO6709->new({
      iso6709 => '+35.36083+138.72750+3776CRSWGS_84/',
  }),

=head1 METHOD

=head2 iso6709

can you set the ISO6709 string.

=head1 AUTHOR

Kazuhiro Osawa E<lt>yappo {at} shibuya {dot} plE<gt>

=head1 SEE ALSO

L<Geo::Coordinates::Converter::Format::ISO6709>,
L<Geo::Coordinates::Converter::Point>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
