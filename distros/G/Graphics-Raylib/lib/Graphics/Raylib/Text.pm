use strict;
use warnings;
package Graphics::Raylib::Text;

# ABSTRACT: Output text to window
our $VERSION = '0.003'; # VERSION

use Graphics::Raylib::XS qw(:all);

=pod

=encoding utf8

=head1 NAME

Graphics::Raylib::Text - Output text to window


=head1 VERSION

version 0.003

=head1 SYNOPSIS

    use strict;
    use warnings;

    use Graphics::Raylib;
    use Graphics::Raylib::Color;
    use Graphics::Raylib::Text;


    my $i = 0;
    my $text = Graphics::Raylib::Text->new(
        color => Graphics::Raylib::Color::DARKGRAY,
        size => 20,
    );

    while (!$g->exiting)
    {
        Graphics::Raylib::draw {
            $g->clear(Graphics::Raylib::Color::BLACK);

            $text->text = "Generation " . ($i++);
            $text->draw;
        };
    }

=head1 METHODS AND ARGUMENTS

=over 4

=item new( text => $text, color => $color, pos => [$x, $y], size => [$width, $height] )

Constructs a new Graphics::Raylib::Text instance. Position defaults to C<[0,0]> and size to C<10>.

=cut

sub new {
    my $class = shift;

    my $self = {
        pos => [0,0],
        size => 10,
        @_
    };

    bless $self, $class;
    return $self;
}

=item new( text => $text, color => $color, pos => [$x, $y], size => [$width, $height], font => $font, spacing => $spacing )

Constructs a new Graphics::Raylib::Text instance. Position defaults to C<[0,0]> and size to C<10>.

=cut

sub draw {
    my $self = shift;
    return $self->{func}() if defined $self->{func};

    if (defined $self->{font}) {
        DrawTextEx(
            $self->{font}, $self->{text},
            $self->{pos}, $self->{size},
            $self->{spacing}, $self->{color}
        );
    } else {
        DrawText($self->{text}, @{$self->{pos}}, $self->{size}, $self->{color});
    }
}

=item new( text => $text, color => $color, pos => [$x, $y], size => [$width, $height], font => $font, spacing => $spacing )

Constructs a new Graphics::Raylib::Text instance. Position defaults to C<[0,0]> and size to C<10>.

=cut

sub text : lvalue {
    my $self = shift;

    $self->{text};
}

=back

=head1 PREDEFINED OBJECTS

=over 4

=item FPS

An already constructed C<Graphics::Raylib::Text>, that draws FPS to the top left corner.

=cut

use constant FPS => Graphics::Raylib::Text->new(func => sub { DrawFPS(0, 0) });


1;

=back

=head1 GIT REPOSITORY

L<http://github.com/athreef/Graphics-Raylib>

=head1 SEE ALSO

L<Graphics::Raylib>  L<Graphics::Raylib::Color>

=head1 AUTHOR

Ahmad Fatoum C<< <athreef@cpan.org> >>, L<http://a3f.at>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017 Ahmad Fatoum

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
