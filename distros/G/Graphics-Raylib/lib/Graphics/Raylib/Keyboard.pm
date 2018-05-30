use strict;
use warnings;
package Graphics::Raylib::Keyboard;
use Graphics::Raylib::Key;

# ABSTRACT: Deal with Keyboard Input
our $VERSION = '0.019'; # VERSION

use Import::Into;
sub import {
    Graphics::Raylib::Key->import::into(scalar caller);
}
our @ISA = qw(Exporter);
our %EXPORT_TAGS = (subs => [qw( key_pressed key_down key_released key_up exit_key)]);
Exporter::export_ok_tags('subs');
{
    my %seen;
    push @{$EXPORT_TAGS{all}}, grep {!$seen{$_}++} @{$EXPORT_TAGS{$_}} foreach keys %EXPORT_TAGS;
}


=pod

=encoding utf8

=head1 NAME

Graphics::Raylib::Keyboard - Deal with Keyboard Input


=head1 VERSION

version 0.019

=head1 SYNOPSIS

    use Graphics::Raylib::Keyboard ':all';

    print "A is pressed down\n" if key_down 'a';
    print "B is not being pressed down\n" if key_up 'a';
    print "last key pressed is ", key_pressed, "\n";

=head1 DESCRIPTION

Keys are specified in Vi-like notation. Keys returned are instances of L<Graphics::Raylib::Key> which has the C<eq> operator overloaded, so you don't have to care about letter case and synonyms (e.g. C<< <CR> >>, C<< <Return> >> and C<< <Enter> >>

=head1 METHODS AND ARGUMENTS

=cut

sub from_vinotation { Graphics::Raylib::Key->new(map => shift) }
sub from_keycode { Graphics::Raylib::Key->new(keycode => shift) }

=over 4

=item key_pressed([$key])

Returns last pressed key. if a $key argument is supplied, detects if that given key has been pressed once.

=cut


sub key_pressed {
    if (@_) {
        Graphics::Raylib::XS::IsKeyPressed(from_vinotation $_[0])
    } else {
        from_keycode Graphics::Raylib::XS::GetKeyPressed()
    }
}

=item key_down($key)

Detects if key is being pressed down

=cut

sub key_down { Graphics::Raylib::XS::IsKeyDown(from_vinotation $_[0]) }

=item key_released($key)

Detects if a key has been released once

=cut

sub key_released { Graphics::Raylib::XS::IsKeyReleased(from_vinotation $_[0]) }

=item key_up($key)

Detects if a key is NOT being pressed

=cut

sub key_up { Graphics::Raylib::XS::IsKeyUp(from_vinotation $_[0]) }

=item $exit = exit_key() or exit_key("<Esc>")

getter/setter for the key used to exit the program

    print "Exit key is ",  Graphics::Raylib::Keyboard::exit_key, "\n";
    Graphics::Raylib::Keyboard::exit_key("<Enter>"); # Instead of the default "<Esc>"

=cut

my $EXIT_KEY = from_vinotation "<ESC>";
sub exit_key {
    if (@_) {
        $EXIT_KEY = from_vinotation $_[0];
        Graphics::Raylib::XS::SetExitKey($EXIT_KEY);
    } else {
        $EXIT_KEY
    }
}

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
