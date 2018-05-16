use strict;
use warnings;
package Graphics::Raylib::Mouse;

use Graphics::Raylib::XS;

# ABSTRACT: Deal with Mouse Input
our $VERSION = '0.018'; # VERSION

=pod

=encoding utf8

=head1 NAME

Graphics::Raylib::Mouse - Deal with Mouse Input


=head1 VERSION

version 0.018

=head1 SYNOPSIS

    use Graphics::Raylib::Mouse;

    $mouse = Graphics::Raylib::Mouse->new; # More concise this way
    if ($mouse->pressed_left) {
        printf "(%d, %d)\n", $mouse->x, $mouse->y;
    }


=head1 METHODS AND ARGUMENTS

=over 4

=item new()

Optional. Returns a C<Graphics::Raylib::Mouse> object that saves you typing that prefix all the time.

=cut

sub new { return bless {}, shift }
my %button = (left => MOUSE_LEFT_BUTTON, middle => MOUSE_MIDDLE_BUTTON, right => MOUSE_RIGHT_BUTTON);

=item pressed_left(), pressed_middle(), pressed_right()

Detects if mouse button has been pressed once

=cut

sub pressed { shift if ref $_[0]; Graphics::Raylib::XS::IsMouseButtonPressed($button{$_[0]}) }
sub left_pressed { pressed 'left' }
sub middle_pressed { pressed 'middle' }
sub right_pressed { pressed 'right' }

=item down_left(), down_middle(), down_right()

Detects if mouse button is down

=cut

sub down { shift if ref $_[0]; Graphics::Raylib::XS::IsMouseButtonDown($button{$_[0]}) }
sub left_down { down 'left' }
sub middle_down { down 'middle' }
sub right_down { down 'right' }

=item released_left(), released_middle(), released_right()

Detects if mouse button has been released

=cut

sub released { shift if ref $_[0]; Graphics::Raylib::XS::IsMouseButtonReleased($button{$_[0]}) }
sub left_released { released 'left' }
sub middle_released { released 'middle' }
sub right_released { released 'right' }

=item up_left(), up_middle(), up_right()

Detects if mouse button is up

=cut

sub up { shift if ref $_[0]; Graphics::Raylib::XS::IsMouseButtonUp($button{$_[0]}) }
sub left_up { up 'left' }
sub middle_up { up 'middle' }
sub right_up { up 'right' }

=item my ($x, $y) = position; or position($x, $y)

Retrieves cursor position if not in void context. Moves cursor to position if coordinate argument supplied.

=cut

sub position { shift if defined $_[0] && ref $_[0];

    my @args = @_;
    if (@args) {
        @args = @{$args[0]} if @args == 1;

        my $vector = bless \pack('f2', @args), 'Vector2';
        Graphics::Raylib::XS::SetMousePosition($vector);
    }

    if (defined wantarray) {
        if (wantarray) {
            return (Graphics::Raylib::XS::GetMouseX(), Graphics::Raylib::XS::GetMouseY());
        } else {
            return [Graphics::Raylib::XS::GetMouseX(), Graphics::Raylib::XS::GetMouseY()];
        }
   }
}

=item wheelmove

Wheel Y-axis movement

=cut

sub wheelmove { shift if defined $_[0] && ref $_[0];
    return Graphics::Raylib::XS::GetMouseWheelMove();
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
