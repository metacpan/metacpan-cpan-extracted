package Geo::Coordinates::Converter::Point;
use strict;
use warnings;
use Class::Accessor::Lite (
    rw => [qw/ lat lng datum format height /],
);

use Geo::Coordinates::Converter;

# back compatibility
sub mk_accessors {
    my($class, @args) = @_;
    Class::Accessor::Lite->mk_accessors(@_);
}
sub mk_ro_accessors {
    my($class, @args) = @_;
    Class::Accessor::Lite->mk_ro_accessors(@_);
}
sub mk_wo_accessors {
    my($class, @args) = @_;
    Class::Accessor::Lite->mk_wo_accessors(@_);
}

use Storable ();

*latitude  = \&lat;
*longitude = \&lng;

sub new {
    my($class, $args) = @_;
    $args = +{} unless defined $args;
    my $self = bless { %{ $args } }, $class;
    $self->{lat} ||= $self->{latitude} || '0.000000';
    $self->{lng} ||= $self->{longitude} || '0.000000';
    $self->{height} ||= 0;
    $self->{datum} ||= 'wgs84';
    $self;
}

sub clone {
    my $self = shift;
    my $clone = Storable::dclone($self);
    $clone;
}

sub converter {
    my $self = shift;
    Geo::Coordinates::Converter->new(
        point => $self,
    )->convert( @_ );
}

1;

__END__

=head1 NAME

Geo::Coordinates::Converter::Point - the coordinates object

=head1 SYNOPSIS

    use strict;
    use warnings;

    use Geo::Coordinates::Converter::Point;

    my $point = Geo::Coordinates::Converter::Point->new({
        lat    => '35.65580',
        lng    => '139.65580',
        datum  => 'wgs84',
        format => 'degree',
    });

    my $point = Geo::Coordinates::Converter::Point->new({
        lat    => '35.39.24.00',
        lng    => '139.40.15.05',
        datum  => 'wgs84',
        format => 'dms',
    });

    my $clone = $point->clone;

    my $new_point = $point->converter( degree => 'wgs84' );


=head1 DESCRIPTION

accessor of data concerning coordinates.
data is not processed at all.

=head1 METHODS

=over 4

=item new

constructor

=item lat

accessor of latitude

=item latitude

alias of lat

=item lng

accessor of longitude

=item longitude

alias of lng

=item height

sea level (meters).

=item datum

accessor of datum. default is C<wgs84>.

=item format

accessor of coordinates format

=item clone

clone object

=item converter

wrapper of Geo::Coordinates::Converter->convert.

    my $new_point = $point->converter(degree => 'wgs84');

the method same code is under.

    my $new_point = Geo::Coordinates::Converter->new(
        point => $point,
    )->convert(degree => 'wgs84');

=back

=head1 AUTHOR

Kazuhiro Osawa E<lt>yappo {at} shibuya {dot} plE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

