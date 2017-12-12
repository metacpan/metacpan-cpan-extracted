use strict;
use warnings;
package Graphics::Raylib;

# ABSTRACT: Perlish wrapper for Raylib videogame library
our $VERSION = '0.008'; # VERSION

use Carp;
use Graphics::Raylib::XS qw(:all);
use Graphics::Raylib::Color;

use Import::Into;

=pod

=encoding utf8

=head1 NAME

Graphics::Raylib - Perlish wrapper for Raylib videogame library

=head1 VERSION

version 0.008

=head1 SYNOPSIS

    use Graphics::Raylib;
    use Graphics::Raylib::Text;
    use Graphics::Raylib::Color ':all';

    my $g = Graphics::Raylib->window(120,20);
    $g->fps(5);

    my $text = Graphics::Raylib::Text->new(
        text => 'Hello World!',
        color => DARKGRAY,
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

You can import L<Graphics::Raylib::XS> for any functions not yet exposed perlishly. Scroll down for an example.

=head1 AUTOMATIC IMPORT

C<use Graphics::Raylib '+family';> can be used as a shorthand for

    use Graphics::Raylib::Color ':all';
    use Graphics::Raylib::Shape;
    use Graphics::Raylib::Text;
    use Graphics::Raylib::Mouse;
    use Graphics::Raylib::Keyboard ':all';

=cut

sub import {
    for (@_) {
        if ($_ eq '+family') {
            Graphics::Raylib::Color   ->import::into(scalar caller, ':all');
            Graphics::Raylib::Shape   ->import::into(scalar caller);
            Graphics::Raylib::Text    ->import::into(scalar caller);
            Graphics::Raylib::Mouse   ->import::into(scalar caller);
            Graphics::Raylib::Keyboard->import::into(scalar caller, ':all');
        }
    }
}

=head1 METHODS/SUBS AND ARGUMENTS

=over 4

=item window($width, $height, [$title = $0])

Constructs the Graphics::Raylib window. C<$title> is optional and defaults to C<$0>. Resources allocated for the window are freed when the handle returned by C<window> goes out of scope.

=cut

sub window {
    my $class = shift;

    my $self = { width => shift, height => shift, title => shift // $0, @_ };
    InitWindow($self->{width}, $self->{height}, $self->{title});
    SetTargetFPS($self->{fps}) if defined $self->{fps};
    ClearBackground($self->{background}) if defined $self->{background};

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

sub draws(@) {
    BeginDrawing();
    for (@_) { $_->draw }
    EndDrawing();
}

sub DESTROY {
    CloseWindow();
}

1;

=back

=head1 EXAMPLES

=over 4

=item Conway's Game of Life

    my $HZ = 120;
    my $SIZE = 160;
    my $MUTATION_CHANCE = 0.000;

    ###########

    my $CELL_SIZE = 3;

    use Graphics::Raylib '+family'; # one use to rule them all
    # Alternatively
    use Graphics::Raylib::Color ':all';
    use Graphics::Raylib::Shape;
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

    my $text = Graphics::Raylib::Text->new(color => RED, size => 20);

    my $bitmap = Graphics::Raylib::Shape->bitmap(
        matrix => unpdl($gen),
        # color => GOLD # commented-out, we are doing it fancy
    );

    my $rainbow = Graphics::Raylib::Color::rainbow(colors => 240);

    $g->clear(BLACK);

    while (!$g->exiting) {
        $bitmap->matrix = unpdl($gen);
        $bitmap->color = $rainbow->();
        $text->text = "Generation " . ($i++);

        Graphics::Raylib::draw {
            $bitmap->draw;
            $text->draw;
        };


        # replace every cell with a count of neighbours
        my $neighbourhood = zeroes $gen->dims;
        $neighbourhood += $_ for map { rotations } map {$_->transpose}
                                 map { rotations }      $gen->transpose;

        #  next gen are live cells with three neighbours or any with two
        my $next = $gen & ($neighbourhood == 4) | ($neighbourhood == 3);

        # mutation
        $next |= $neighbourhood == 2 if rand(1) < $MUTATION_CHANCE;

        # procreate
        $gen = $next;
    }

=back

=head2 Result

=for html <iframe src="https://giphy.com/embed/3ov9jGoKzwnt4l4UQo" width="458" height="480" frameBorder="0" class="giphy-embed" allowFullScreen></iframe><p><a href="https://giphy.com/gifs/graphicsraylib-3ov9jGoKzwnt4l4UQo">via GIPHY</a></p>

=head1 GIT REPOSITORY

L<http://github.com/athreef/Graphics-Raylib>

=head1 SEE ALSO

L<Graphics::Raylib::Shape>

L<Graphics::Raylib::XS>
L<Alien::raylib>

=head1 AUTHOR

Ahmad Fatoum C<< <athreef@cpan.org> >>, L<http://a3f.at>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017 Ahmad Fatoum

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
