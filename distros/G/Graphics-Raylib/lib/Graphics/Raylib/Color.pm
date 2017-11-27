use strict;
use warnings;
package Graphics::Raylib::Color;

# ABSTRACT: Colors for use with Graphics::Raylib
our $VERSION = '0.007'; # VERSION

use Graphics::Raylib::XS qw(:all);
require Exporter;
our @ISA = qw(Exporter);
our %EXPORT_TAGS = (colors => [qw( LIGHTGRAY GRAY DARKGRAY LIGHTGREY GREY DARKGREY YELLOW GOLD
                                   ORANGE PINK RED MAROON GREEN LIME DARKGREEN SKYBLUE BLUE
                                   DARKBLUE PURPLE VIOLET DARKPURPL BEIGE BROWN DARKBROWN WHITE
                                   BLACK BLANK MAGENTA RAYWHITE)]
                   );
Exporter::export_ok_tags('colors');
{
    my %seen;
    push @{$EXPORT_TAGS{all}}, grep {!$seen{$_}++} @{$EXPORT_TAGS{$_}} foreach keys %EXPORT_TAGS;
}

=pod

=encoding utf8

=head1 NAME

Graphics::Raylib::Color - Use predefined Raylib colors or define your own


=head1 VERSION

version 0.007

=head1 SYNOPSIS

    use Graphics::Raylib::Color;
    my $color   = Graphics::Raylib::Color::BLACK;
    # alternatively:
    use Graphics::Raylib::Color qw(:all);
    my $color2  = MAROON;

    my $gray    = Graphics::Raylib::Color::rgb(127,127,127);
    my $rainbow = Graphics::Raylib::Color::rainbow(colors => 100);
    push @colors, $rainbow->cycle for (1..100);


=head1 DESCRIPTION

Colors you can pass to raylib.

=head1 IMPLEMENTATION

As a color is basically a 32-bit integer (RGBA) in raylib, the constructors rgba and rgb do little more packing it into an integer and blessing it. Interpolating a color into a string results in a tuple of the form C<< "(r: %u, g: %u, b: %u, a: %u)" >>.

=head1 METHODS AND ARGUMENTS

=over 4

=item rgba($red, $green, $blue, $alpha)

Constructs a new Graphics::Raylib::Color instance.

=cut

sub rgba {
    my $self = \pack("C4", @_);

    bless $self, 'Color';
    return $self;
}

=item rgb($red, $green, $blue)

Constructs a new Graphics::Raylib::Color instance out of an opaque color.
Calls C<rgba> with C<$alpha = 255>.

=cut

sub rgb {
    rgba(@_, 255);
}

=item ($r, $g, $b, $a) = colors

Returns a list with the red, green, blue and alpha components of the color.

=cut
{
    package Color;

    sub r { return unpack("C",    ${$_[0]}) }
    sub g { return unpack("xC",   ${$_[0]}) }
    sub b { return unpack("xxC",  ${$_[0]}) }
    sub a { return unpack("xxxC", ${$_[0]}) }
    sub colors {
        my ($self) = @_;

        return unpack("C4", ${$self});
    }

    sub stringify {
        my ($self) = @_;
        return sprintf '(r: %u, g: %u, b: %u, a: %u)', $self->colors;
    }

    use overload fallback => 1, '""' => 'stringify';
}

=item rgb($red, $green, $blue)

Constructs a new Graphics::Raylib::Color instance out of an opaque color.
Calls C<rgba> with C<$alpha = 255>.


=item color($color_32bit)

Constructs a C<Color> out of a 32 bit integer.

=cut

sub color {
    return bless \pack("N", shift), 'Color'
}

{
    package Color;
    sub color { return unpack("N", ${$_[0]}); }
}

=back

=head1 PREDEFINED COLORS

    use constant LIGHTGRAY => rgb( 200, 200, 200 );
    use constant GRAY      => rgb( 130, 130, 130 );
    use constant DARKGRAY  => rgb( 80,  80,  80  );
    use constant LIGHTGREY => rgb( 200, 200, 200 );
    use constant GREY      => rgb( 130, 130, 130 );
    use constant DARKGREY  => rgb( 80,  80,  80  );
    use constant YELLOW    => rgb( 253, 249, 0   );
    use constant GOLD      => rgb( 255, 203, 0   );
    use constant ORANGE    => rgb( 255, 161, 0   );
    use constant PINK      => rgb( 255, 109, 194 );
    use constant RED       => rgb( 230, 41,  55  );
    use constant MAROON    => rgb( 190, 33,  55  );
    use constant GREEN     => rgb( 0,   228, 48  );
    use constant LIME      => rgb( 0,   158, 47  );
    use constant DARKGREEN => rgb( 0,   117, 44  );
    use constant SKYBLUE   => rgb( 102, 191, 255 );
    use constant BLUE      => rgb( 0,   121, 241 );
    use constant DARKBLUE  => rgb( 0,   82,  172 );
    use constant PURPLE    => rgb( 200, 122, 255 );
    use constant VIOLET    => rgb( 135, 60,  190 );
    use constant DARKPURPL => rgb( 112, 31,  126 );
    use constant BEIGE     => rgb( 211, 176, 131 );
    use constant BROWN     => rgb( 127, 106, 79  );
    use constant DARKBROWN => rgb( 76,  63,  47  );

    use constant WHITE     => rgb( 255, 255, 255 );
    use constant BLACK     => rgb( 0,   0,   0   );
    use constant BLANK     => rgba(  0, 0, 0, 0  );
    use constant MAGENTA   => rgb( 255, 0,   255 );
    use constant RAYWHITE  => rgb( 245, 245, 245 );

=cut

use constant LIGHTGRAY => rgb( 200, 200, 200 );
use constant GRAY      => rgb( 130, 130, 130 );
use constant DARKGRAY  => rgb( 80,  80,  80  );
use constant LIGHTGREY => rgb( 200, 200, 200 );
use constant GREY      => rgb( 130, 130, 130 );
use constant DARKGREY  => rgb( 80,  80,  80  );
use constant YELLOW    => rgb( 253, 249, 0   );
use constant GOLD      => rgb( 255, 203, 0   );
use constant ORANGE    => rgb( 255, 161, 0   );
use constant PINK      => rgb( 255, 109, 194 );
use constant RED       => rgb( 230, 41,  55  );
use constant MAROON    => rgb( 190, 33,  55  );
use constant GREEN     => rgb( 0,   228, 48  );
use constant LIME      => rgb( 0,   158, 47  );
use constant DARKGREEN => rgb( 0,   117, 44  );
use constant SKYBLUE   => rgb( 102, 191, 255 );
use constant BLUE      => rgb( 0,   121, 241 );
use constant DARKBLUE  => rgb( 0,   82,  172 );
use constant PURPLE    => rgb( 200, 122, 255 );
use constant VIOLET    => rgb( 135, 60,  190 );
use constant DARKPURPL => rgb( 112, 31,  126 );
use constant BEIGE     => rgb( 211, 176, 131 );
use constant BROWN     => rgb( 127, 106, 79  );
use constant DARKBROWN => rgb( 76,  63,  47  );

use constant WHITE     => rgb( 255, 255, 255 );
use constant BLACK     => rgb( 0,   0,   0   );
use constant BLANK     => rgba(  0, 0, 0, 0  );
use constant MAGENTA   => rgb( 255, 0,   255 );
use constant RAYWHITE  => rgb( 245, 245, 245 );

=over 4

=item rainbow(colors => $color_count)

Returns a code reference that cycles through the rainbow colors on each evaluation. C<$color_count> is the total number of colors before bouncing back. Default is C<7>.

=cut

sub rainbow {
    my $self = {
        cycle  => 0,
        colors => 7,

        @_
    };
    $self->{freq} = 5 / $self->{colors};
    $self->{last} = 0;

    return sub {
        my $r = int(sin($self->{freq} * abs($self->{cycle}) + 0) * (127) + 128);
        my $g = int(sin($self->{freq} * abs($self->{cycle}) + 1) * (127) + 128);
        my $b = int(sin($self->{freq} * abs($self->{cycle}) + 3) * (127) + 128);

        $self->{cycle} *= -1 if ++$self->{cycle} == $self->{colors};

        return Graphics::Raylib::Color::rgb($r, $g, $b);
    }
}

1;

=back

=head1 GIT REPOSITORY

L<http://github.com/athreef/Graphics-Raylib>

=head1 SEE ALSO

L<Graphics-Raylib>

L<Graphics-Raylib-XS>

=head1 AUTHOR

Ahmad Fatoum C<< <athreef@cpan.org> >>, L<http://a3f.at>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017 Ahmad Fatoum

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
