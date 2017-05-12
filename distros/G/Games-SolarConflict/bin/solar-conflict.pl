#!perl

# ABSTRACT: Play the game
# PODNAME: solar-conflict.pl

use strict;
use warnings;

BEGIN {
    if ( $^O eq 'darwin' && $^X !~ /SDLPerl$/ ) {
        exec 'SDLPerl', $0, @ARGV or die "Failed to exec SDLPerl: $!";
    }
}

use Games::SolarConflict;

Games::SolarConflict->new->run();

exit;



=pod

=head1 NAME

solar-conflict.pl - Play the game

=head1 VERSION

version 0.000001

=head1 SYNOPSIS

Start the game from the command line:

    solar-conflict.pl

=head1 DESCRIPTION

This script starts the game.  It will open a 1024x768 window (plus the
size of the window frame).  Game controls are displayed on the menu
screen.  Close the window to end the game.

=head1 SEE ALSO

=over 4

=item * L<Games::SolarConflict>

=back

=head1 AUTHOR

Jeffrey T. Palmer <jtpalmer@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Jeffrey T. Palmer.

This is free software, licensed under:

  The MIT (X11) License

=cut


__END__


