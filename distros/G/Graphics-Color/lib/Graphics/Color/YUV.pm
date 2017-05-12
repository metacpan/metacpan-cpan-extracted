package Graphics::Color::YUV;
$Graphics::Color::YUV::VERSION = '0.31';
use Moose;
use MooseX::Aliases;

extends qw(Graphics::Color);

# ABSTRACT: YUV color space

use Graphics::Color::Types qw(NumberOneOrLess);


has 'luma' => (
    is => 'rw',
    isa => NumberOneOrLess,
    default => 0,
    alias => 'y'
);


has 'blue_luminance' => (
    is => 'rw',
    isa => NumberOneOrLess,
    default => 0,
    alias => 'u'
);


has 'red_luminance' => (
    is => 'rw',
    isa => NumberOneOrLess,
    default => 0,
    alias => 'v'
);


has 'name' => ( is => 'rw', isa => 'Str' );


sub as_string {
    my ($self) = @_;

    return sprintf('%s,%s,%s',
        $self->luma, $self->blue_luminance, $self->red_luminance
    );
}


sub as_array {
    my ($self) = @_;

    return ($self->luma, $self->blue_luminance, $self->red_luminance);
}


sub equal_to {
    my ($self, $other) = @_;

    return 0 unless defined($other);

    unless($self->luma == $other->luma) {
        return 0;
    }
    unless($self->blue_luminance == $other->blue_luminance) {
        return 0;
    }
    unless($self->red_luminance == $other->red_luminance) {
        return 0;
    }

    return 1;
}


# TODO RGB Conversion
# OLD STYLE : Y' = 0.299R + 0.587G + 0.114B
# NEW STYLE: Y' = 0.2125R + 0.7154G + 0.0721B
# U = B - Y'
# V = R - Y'
#
# http://www.fourcc.org/fccyvrgb.php

__PACKAGE__->meta->make_immutable;

no Moose;
1;

__END__

=pod

=head1 NAME

Graphics::Color::YUV - YUV color space

=head1 VERSION

version 0.31

=head1 SYNOPSIS

    use Graphics::Color::YUV;

    my $color = Graphics::Color::YUV->new({
        luma            => .5,
        blue_luminance  => .5,
        red_luminance   => .25,
    });

=head1 DESCRIPTION

Graphics::Color::YUV represents a Color in an Y'UV color space.

=head1 ATTRIBUTES

=head2 luma

=head2 y

Set/Get the luma (Y') component of this Color.  Aliased to y.

=head2 blue_luminance

=head2 u

Set/Get the blue_luminance component of this Color. Aliased to u.

=head2 red_luminance

=head2 v

Set/Get the red_luminance component of this Color. Aliased to v.

=head1 METHODS

=head2 name

Get the name of this color.  Only valid if the color was created by name.

=head2 as_string

Get a string version of this Color in the form of:
LUMA,BLUE_LUMINENCE,RED_LUMINANCE

=head2 as_array

Get the YUV values as an array

=head2 equal_to

Compares this color to the provided one.  Returns 1 if true, else 0;

=head2 not_equal_to

The opposite of equal_to.

=head1 AUTHOR

Cory G Watson <gphat@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Cold Hard Code, LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
