use strict;
use warnings;
package Graphics::Raylib::Color;
#
# ABSTRACT: Colors for use with Graphics::Raylib
our $VERSION = '0.002'; # VERSION

use Graphics::Raylib::XS qw(:all);

=pod

=encoding utf8

=head1 NAME

Graphics::Raylib::Color - Use predefined Raylib colors or define your own


=head1 SYNOPSIS

    use Graphics::Raylib::Color;

    my $color   = Graphics::Raylib::Color::BLACK;
    my $gray    = Graphics::Raylib::Color::rgb(127,127,127);
    my $rainbow = Graphics::Raylib::Color::rainbow(colors => 100);
    push @colors, $rainbow->cycle for (1..100);


=head1 DESCRIPTION
    
Colors you can pass to raylib.

=head1 IMPLEMENTATION
    
As a color is basically a 32-bit integer (RGBA) in raylib, the constructors rgba and rgb do little more packing it into an integer and blessing it

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

=item rgb($red, $green, $blue)

Constructs a new Graphics::Raylib::Color instance out of an opaque color.
Calls C<rgba> with C<$alpha = 255>.

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

=item Rainbow->new(colors => $color_count)

Creates a new Graphics::Raylib::Color::Rainbow instance. C<$color_count> is the total number of colors before bouncing back. Default is C<7>.

=cut

{
    package Graphics::Raylib::Color::Rainbow;

    sub new {
        my $class = shift;
        
        my $self = {
            cycle  => 0,
            colors => 7,

            @_
        };
        $self->{freq} = 5 / $self->{colors};

        bless $self, $class;
        return $self;
    }

=item Rainbow->cycle()

Returns the next rainbow Graphics::Raylib::Color in sequence. When C<$color_count> is reached, It oscillates back to zero returning the same colors in reverse. At zero, it is back at normal.

=cut

    sub cycle {
        my $self = shift;

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
