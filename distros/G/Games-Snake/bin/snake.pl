#!perl

# ABSTRACT: Play the game
# PODNAME: snake.pl

use strict;
use warnings;

BEGIN {
    if ( $^O eq 'darwin' && $^X !~ /SDLPerl$/ ) {
        exec 'SDLPerl', $0, @ARGV or die "Failed to exec SDLPerl: $!";
    }
}

use Games::Snake;

Games::Snake->new()->run();

exit;



=pod

=head1 NAME

snake.pl - Play the game

=head1 VERSION

version 0.000001

=head1 SYNOPSIS

Start the game from the command line:

    snake.pl

=head1 DESCRIPTION

This script starts the game.  It will open a 800x600 window (plus the
size of the window frame).  Use the arrow keys to control the snake.
Close the window to end the game.

=head1 SEE ALSO

=over 4

=item * L<Games::Snake>

=back

=head1 AUTHOR

Jeffrey T. Palmer <jtpalmer@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Jeffrey T. Palmer.

This is free software, licensed under:

  The MIT (X11) License

=cut


__END__


