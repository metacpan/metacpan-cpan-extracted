package Geo::Coordinates::Converter;
use strict;
use warnings;
use Class::Accessor::Lite (
    rw => [qw/ source current /],
);

use 5.008001;

our $VERSION = '0.13';

use Carp;
use String::CamelCase qw( camelize );
use Module::Load ();

use Geo::Coordinates::Converter::Point;

our $DEFAULT_CONVERTER = 'Geo::Coordinates::Converter::Datum';
our $DEFAULT_FORMAT = [qw/ Degree Dms Milliseconds ISO6709 /];
our $DEFAULT_INETRNAL_FORMAT = 'degree';

sub add_default_formats {
    my($class, @formats) = @_;
    my %default_formats = map { $_ => 1 } @{ $DEFAULT_FORMAT }, @formats;
    $DEFAULT_FORMAT = [ keys %default_formats ];
}

sub new {
    my($class, %opt) = @_;

    my $converter = delete $opt{converter} || $DEFAULT_CONVERTER;
    unless (ref $converter) {
        Module::Load::load($converter);
        $converter = $converter->new unless ref $converter;
    }

    my $internal_format = delete $opt{internal_format} || $DEFAULT_INETRNAL_FORMAT;
    my $formats = delete $opt{formats};
    my $source = delete $opt{point} || Geo::Coordinates::Converter::Point->new(\%opt);

    my $self = bless {
        source => $source,
        formats => {},
        converter => $converter,
        internal_format => $internal_format,
    }, $class;

    my @plugins = @{ $DEFAULT_FORMAT };
    push @plugins, @{ $formats } if ref $formats eq 'ARRAY';
    for my $plugin (@plugins) {
        $self->load_format($plugin);
    }

    $self->format_detect($self->source) unless $source->format;
    $self->normalize($self->source);
    $self->reset;

    $self;
}

sub load_format {
    my($self, $format) = @_;

    unless (ref $format) {
        if ($format =~ s/^\+//) {
            Module::Load::load($format);
        } else {
            my $name = $format;
            $format = sprintf '%s::Format::%s', ref $self, camelize($name);
            Module::Load::load($format);
        }
        $format = $format->new;
    }
    $self->formats($format->name, $format);
}

sub formats {
    my($self, $format, $plugin) = @_;
    $self->{formats}->{$format} = $plugin if $plugin;
    wantarray ? keys %{ $self->{formats} } : $self->{formats}->{$format};
}

sub format_detect {
    my($self, $point) = @_;

    for my $format ($self->formats) {
        my $name = $self->formats($format)->detect($point);
        next unless $name;
        $point->format($name);
        last;
    }
    $point->format;
}

sub normaraiz { goto &normalize; } # alias for backward compatibility.
sub normalize {
    my($self, $point) = @_;
    $self->formats($point->format)->normalize($point);
    $point;
}

sub convert {
    my($self, @opt) = @_;
    return $self->point unless @opt;

    my $point = $self->source->clone;
    my $format = $point->format;
    $self->format($self->{internal_format}, $point);
    for my $type (@opt) {
        if ($self->formats($type)) {
            $format = $type unless $format eq $type;
        } else {
            eval { $self->datum($type, $point) };
            croak "It dosen't correspond to the $type format/datum: $@" if $@;
        }
    }
    $self->format($format, $point);

    $point->$_( $self->$_($point) ) for qw/ lat lng /;
    $self->current($point->clone);
}

for my $meth (qw/ lat lng /) {
    no strict 'refs';
    *{__PACKAGE__ . "::$meth"} = sub {
        my $self = shift;
        my $point = shift || $self->current;
        $self->formats($point->format)->round($point->$meth);
    };
}
sub height {
    my $self = shift;
    my $point = shift || $self->current;
    $point->height;
}

sub datum {
    my $self = shift;

    if (my $datum = shift) {
        my $point = shift || $self->current;
        return $self if $point->datum eq $datum;

        my $format = $point->format;
        $self->format($self->{internal_format}, $point);
        $self->{converter}->convert($point => $datum);
        $self->format($format, $point);

        return $self;
    } else {
        return $self->current->datum;
    }
}

sub format {
    my $self = shift;

    if (my $fmt = shift) {
        croak "It dosen't correspond to the $fmt format" unless $self->formats($fmt);
        my $point = shift || $self->current;
        return $self if $point->format eq $fmt;

        $self->formats($point->format)->to($point);
        $self->formats($fmt)->from($point);
        $point->format($fmt);

        return $self;
    } else {
        return $self->current->format;
    }
}

sub round {
    my($self, $point) = @_;
    my $fmt = $self->formats($point->format);
    $point->$_($fmt->round($point->$_)) for (qw/ lat lng /);
    $point;
}

sub point {
    my($self, $point) = @_;
    $point ||= $self->current;
    $self->round($point->clone);
}

sub reset {
    my $self = shift;
    $self->current($self->source->clone);
    $self;
}

1;

__END__

=head1 NAME

Geo::Coordinates::Converter - simple converter of geo coordinates

=head1 SYNOPSIS

    use strict;
    use warnings;

    use Geo::Coordinates::Converter;

    my $geo = Geo::Coordinates::Converter->new( lat => '35.65580', lng => '139.65580', datum => 'wgs84' );
    my $point = $geo->convert( dms => 'tokyo' );
    print $point->lat;
    print $point->lng;
    print $point->datum;
    print $point->format;

    my $clone = $point->clone;
    my $geo2 = Geo::Coordinates::Converter->new( point => $clone );
    my $point2 = $geo->convert( degree => 'wgs84' );
    print $point2->lat;
    print $point2->lng;
    print $point2->datum;
    print $point2->format;

can you use milliseconds format

    my $geo = Geo::Coordinates::Converter->new( lat => -128064218, lng => 502629380 );
    $geo->format('degree');
    is($geo->lat, -35.573394);
    is($geo->lng, 139.619272);

=head1 DESCRIPTION

the format and datum of geo coordinates are simply converted.
when it is insufficient in the coordinate system and the format of the standard, it is possible to add it easily.

=head1 CONSTRUCTOR

=over 4

=item new

    my $geo = Geo::Coordinates::Converter->new( lat => '35.65580', lng => '139.65580', datum => 'wgs84' );
    my $geo = Geo::Coordinates::Converter->new( point => $point );

=back

=head2 Options

=over 8

=item lat

set to latitude

=item lng

set to longitude

=item point

set to L<Geo::Coordinates::Converter::Point> object.

when this is set, neither 'lat' and 'lng' and 'datum' and 'format' options are necessary having.

=item datum

set to datum

=item format

set to format.
it is detected automatically.

=item converter

set to converter object.
L<Geo::Coordinates::Converter::Datum> can be used by default, and other conversion classes also use it.

=item formats

the object of the format is set by the ARRAY reference when using it excluding the formatter of default.

=item internal_format

the specification format is set internally. default is degree.
when it dose not like on internal format when datum is customized, it use it.

=back

=head1 METHODS

=over 4

=item convert

the geometric transformation is done.
after it converts it, L<Geo::Coordinates::Converter::Point> object it returned.

    # Examples:
    my $point = $geo->convert( grs80 => 'degree' );
    my $point = $geo->convert( tokyo => 'dms' );
    my $point = $geo->convert( dms => 'wgs84' );
    my $point = $geo->convert('wgs84');
    my $point = $geo->convert('degree');

=back

=head1 AUTHOR

Kazuhiro Osawa E<lt>yappo {at} shibuya {dot} plE<gt>

=head1 SEE ALSO

L<Geo::Coordinates::Converter::Point>, L<Geo::Coordinates::Converter::Format>, L<Geo::Coordinates::Converter::Datum>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

