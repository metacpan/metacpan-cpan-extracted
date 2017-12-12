use strict;
use warnings;
package Graphics::Raylib::Keyboard;

# ABSTRACT: Deal with Keyboard Input
our $VERSION = '0.008'; # VERSION

use Graphics::Raylib::XS qw(:all);
require Exporter;
our @ISA = qw(Exporter);
our %EXPORT_TAGS = (keys => [ grep /^KEY_/, @Graphics::Raylib::XS::EXPORT_OK ]);
Exporter::export_ok_tags('keys');
{
    my %seen;
    push @{$EXPORT_TAGS{all}}, grep {!$seen{$_}++} @{$EXPORT_TAGS{$_}} foreach keys %EXPORT_TAGS;
}


=pod

=encoding utf8

=head1 NAME

Graphics::Raylib::Keyboard - Deal with Keyboard Input


=head1 VERSION

version 0.008

=head1 SYNOPSIS

    use Graphics::Raylib::Keyboard;

    $key = Graphics::Raylib::Keyboard->new; # More concise this way
    print "a is pressed down\n" if $key->down('a');
    print "b is not being pressed down\n" if $key->up('a');
    print "last key pressed is ", $key->latest, "\n";

=head1 KEY CODES in Graphics::Raylib::Keyboard namespace

    KEY_SPACE KEY_ESCAPE KEY_ENTER KEY_BACKSPACE KEY_RIGHT KEY_LEFT KEY_DOWN KEY_UP KEY_F1
    KEY_F2 KEY_F3 KEY_F4 KEY_F5 KEY_F6 KEY_F7 KEY_F8 KEY_F9 KEY_F10 KEY_F11 KEY_F12
    KEY_LEFT_SHIFT KEY_LEFT_CONTROL KEY_LEFT_ALT KEY_RIGHT_SHIFT KEY_RIGHT_CONTROL
    KEY_RIGHT_ALT KEY_ZERO KEY_ONE KEY_TWO KEY_THREE KEY_FOUR KEY_FIVE KEY_SIX KEY_SEVEN
    KEY_EIGHT KEY_NINE KEY_A KEY_B KEY_C KEY_D KEY_E KEY_F KEY_G KEY_H KEY_I KEY_J KEY_K
    KEY_L KEY_M KEY_N KEY_O KEY_P KEY_Q KEY_R KEY_S KEY_T KEY_U KEY_V KEY_W KEY_X KEY_Y KEY_Z

Sample usage:

    use Graphics::Raylib::Keyboard ':keys'; # imports keys
    use Graphics::Raylib::Keyboard ':all';  # imports keys and possibly more
    use Graphics::Raylib '+family';         # implies use Graphics::Raylib::Keyboard ':all';
    # alternatively write the namespace in front, e.g.:
    Graphics::Raylib::Keyboard::KEY_NINE

=head1 METHODS AND ARGUMENTS

=over 4

=item new()

Optional. Returns a C<Graphics::Raylib::Keyboard> object that saves you typing that prefix all the time.

=cut

sub new { return bless {}, shift }
sub encode_key { shift }
sub decode_key { shift }


=item pressed([$key])

Returns last pressed key. if a $key argument is supplied, detects if that given key has been pressed once.

=cut


sub pressed {
    shift if ref $_[0];
    if (@_) {
        Graphics::Raylib::XS::IsKeyPressed(encode_key $_[0])
    } else {
        decode_key Graphics::Raylib::XS::GetKeyPressed()
    }
}

=item down($key)

Detects if key is being pressed down

=cut

sub down { shift if ref $_[0]; Graphics::Raylib::XS::IsKeyDown(encode_key $_[0]) }

=item released($key)

Detects if a key has been released once

=cut

sub released { shift if ref $_[0]; Graphics::Raylib::XS::IsKeyReleased(encode_key $_[0]) }

=item up($key)

Detects if a key is NOT being pressed

=cut

sub up { shift if ref $_[0]; Graphics::Raylib::XS::IsKeyUp(encode_key $_[0]) }

=item $exit = exit() or $exit(KEY_ESCAPE)

L-value subroutine to access the key used to exit the program

    $keyboard = Graphics::Raylib::Keyboard->new; # More concise this way
    print "Exit key is ",  $key->exit, "\n";
    $key->exit(Graphics::Raylib::Keyboard::KEY_ENTER); # Lets use the Enter key instead of Escape

=cut

my $EXIT_KEY = "<Esc>";
sub exit {
    shift if ref $_[0];

    if (@_) {
        Graphics::Raylib::XS::SetExitKey(encode_key $_[0]);
        $EXIT_KEY = $_[0];
    } else {
        $EXIT_KEY
    }
}

=begin comment

=item encode_key($vim_like_key_string)

Encode Vim-like key (e.g. C<< "<Return>" >>) as Graphics::Raylib::XS compatible key code.
Normally, you shouldn't need to use this.

#=cut

my %SPECIAL_KEYSTRS = (
    SPACE  => KEY_SPACE,
    ESC    => KEY_ESCAPE,
    ENTER  => KEY_ENTER,
    RETURN => KEY_ENTER,
    CR     => KEY_ENTER,
    BS     => KEY_BACKSPACE,
    RIGHT  => KEY_RIGHT,
    LEFT   => KEY_LEFT,
    DOWN   => KEY_DOWN,
    UP     => KEY_UP,
    F1     => KEY_F1,
    F2     => KEY_F2,
    F3     => KEY_F3,
    F4     => KEY_F4,
    F5     => KEY_F5,
    F6     => KEY_F6,
    F7     => KEY_F7,
    F8     => KEY_F8,
    F9     => KEY_F9,
    F10    => KEY_F10,
    F11    => KEY_F11,
    F12    => KEY_F12,
    SLEFT  => KEY_LEFT_SHIFT,
    CLEFT  => KEY_LEFT_CONTROL,
    ALEFT  => KEY_LEFT_ALT,
    MLEFT  => KEY_LEFT_ALT,
    SRIGHT => KEY_RIGHT_SHIFT,
    CRIGHT => KEY_RIGHT_CONTROL,
    ARIGHT => KEY_RIGHT_ALT,
    MRIGHT => KEY_RIGHT_ALT,
);

=item decode_key($vim_like_key_string)

Decode Graphics::Raylib::XS compatible key code into a Vim-like key (e.g. C<< "<Return>" >>).
Normally, you shouldn't need to use this.

#=cut

my %SPECIAL_KEYCODES = reverse %SPECIAL_KEYSTRS;

sub decode_key($) {
    my $keycode = shift;
}

=end comment

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
