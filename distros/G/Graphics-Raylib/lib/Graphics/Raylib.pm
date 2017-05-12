use strict;
use warnings;
package Graphics::Raylib;

# ABSTRACT: Perlish wrapper for Raylib videogame library
our $VERSION = '0.002'; # VERSION

use Carp;
use Graphics::Raylib::XS qw(:all);
use Graphics::Raylib::Color;

=pod

=encoding utf8

=head1 NAME

Graphics::Raylib - Perlish wrapper for Raylib videogame library

=head1 SYNOPSIS

    use Graphics::Raylib;
    use Graphics::Raylib::Text;
    use Graphics::Raylib::Color;

    my $g = Graphics::Raylib->window(120,20);
    $g->fps(5);

    my $text = Graphics::Raylib::Text->new(
        text => 'Hello World!',
        color => Graphics::Raylib::Color::DARKGRAY,
        size => 20,
    );

    while (!$g->exiting) {
        Graphics::Raylib::draw {
            $g->clear;

            $text->draw;
        };
    }




=head1 raylib

raylib is highly inspired by Borland BGI graphics lib and by XNA framework. Allegro and SDL have also been analyzed for reference.

NOTE for ADVENTURERS: raylib is a programming library to learn videogames programming; no fancy interface, no visual helpers, no auto-debugging... just coding in the most pure spartan-programmers way. Are you ready to learn? Jump to code examples!.


=head1 IMPLEMENTATION

This is a Perlish wrapper around L<Graphics::Raylib::XS>, but not yet feature complete.

You can import L<Graphics::Raylib::XS> for any functions not yet exposed perlishly.

=head1 METHODS/SUBS AND ARGUMENTS

=over 4

=item window($width, $height, $title)

Constructs the Graphics::Raylib window. C<$title> is optional and defaults to C<$0>. Resources allocated for the window are freed when the handle returned by C<window> goes out of scope.

=cut

sub window {
	my $class = shift;
    
    my $self = {
        width => $_[0],
        height => $_[1],
    };
    InitWindow($self->{width}, $self->{height}, $_[2] // $0);

	bless $self, $class;
	return $self;
}

=item fps($fps)

If C<$fps> is supplied, sets the frame rate to that value. Returns the frame rate in both cases.

=cut

sub fps {
    shift if $_[0]->isa(__PACKAGE__);

    my $fps = shift;
    if (defined $fps) {
        SetTargetFPS($fps);
    } else {
        $fps = GetTargetFPS();
    }
    $fps
}

=item clear($color)

Clears the background to C<$color>. C<$color> defaults to C<Graphics::Raylib::Color::RAYWHITE>.

=cut

sub clear {
    shift if $_[0]->isa(__PACKAGE__);

    ClearBackground(shift // Graphics::Raylib::Color::RAYWHITE);
}

=item exiting()

Returns true if user attempted exit.

=cut


sub exiting {
    my $self = shift;

    WindowShouldClose();
}
=item draw($coderef)

Begins drawing, calls C<$coderef->()> and ends drawing. See examples.

=cut

sub draw(&) {
    my $block = shift;

    BeginDrawing();
    $block->();
    EndDrawing();
}

sub DESTROY {
    CloseWindow();
}

1;

1;

=back

=head1 EXAMPLES

=over 4

=item Conway's Game of Life

    my $HZ = 60;
    my $SIZE = 80;

    my $CELL_SIZE = 6;

    use Graphics::Raylib;
    use Graphics::Raylib::Shape;
    use Graphics::Raylib::Color;
    use Graphics::Raylib::Text;

    use PDL;
    use PDL::Matrix;

    sub rotations { ($_->rotate(-1), $_, $_->rotate(1)) }

    my @data;
    foreach (0..$SIZE) {
        my @row;
        push @row, !!int(rand(2)) foreach 0..$SIZE;
        push @data, \@row;
    }

    my $gen = mpdl \@data;

    my $g = Graphics::Raylib->window($CELL_SIZE*$SIZE, $CELL_SIZE*$SIZE);

    $g->fps($HZ);

    my $text = Graphics::Raylib::Text->new(
        color => Graphics::Raylib::Color::DARKGRAY,
        size => 20,
    );

    my $rainbow = Graphics::Raylib::Color::Rainbow->new(colors => 240);

    my $i = 0;
    while (!$g->exiting)
    {
        my $bitmap = Graphics::Raylib::Shape->bitmap(
            matrix => unpdl($gen),
            color  => $rainbow->cycle,
        );

        Graphics::Raylib::draw {
            $g->clear(Graphics::Raylib::Color::BLACK);

            $text->{text} = "Generation " . ($i++);
            $text->draw;

            $bitmap->draw;
        };


        # replace every cell with a count of neighbours
        my $neighbourhood = zeroes $gen->dims;
        $neighbourhood += $_ for map { rotations } map {$_->transpose}
                                 map { rotations }      $gen->transpose;

        #  next gen are live cells with three neighbours or any with two
        my $next = $gen & ($neighbourhood == 4) | ($neighbourhood == 3);

        # procreate
        $gen = $next;
    }

=back

=head1 GIT REPOSITORY

L<http://github.com/athreef/Graphics-Raylib>

=head1 SEE ALSO

L<Graphics::Raylib::XS>  L<Alien::raylib>

=head1 AUTHOR

Ahmad Fatoum C<< <athreef@cpan.org> >>, L<http://a3f.at>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017 Ahmad Fatoum

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
