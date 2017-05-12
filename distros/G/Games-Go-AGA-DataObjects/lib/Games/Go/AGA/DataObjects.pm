#===============================================================================
#
#         FILE:  Games::Go::AGA::DataObjects
#
#        USAGE:  well, not really
#
#      PODNAME:  Games::Go::AGA::DataObjects
#     ABSTRACT:  a library of DataObjects for American Go Association (AGA) files
#
#       AUTHOR:  Reid Augustin (REID), <reid@hellosix.com>
#      CREATED:  11/19/2010 03:13:05 PM PST
#===============================================================================

use 5.008;
use strict;
use warnings;

package Games::Go::AGA::DataObjects;

use Games::Go::AGA::DataObjects::Player;
use Games::Go::AGA::DataObjects::Round;

our $VERSION = '0.152'; # VERSION

sub import {
    my ($class, %opts) = @_;

    my $dep_level = $opts{deprecate};
    if ($dep_level) {
        $dep_level = 9999 if ($dep_level eq 'latest');
        $Games::Go::AGA::DataObjects::Player::deprecate = $dep_level;
        $Games::Go::AGA::DataObjects::Round::deprecate = $dep_level;
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Games::Go::AGA::DataObjects - a library of DataObjects for American Go Association (AGA) files

=head1 VERSION

version 0.152

=head1 SYNOPSIS

  use Games::Go::AGA::DataObjects::Types;
  use Games::Go::AGA::DataObjects::Player;
  use Games::Go::AGA::DataObjects::Game;
  use Games::Go::AGA::DataObjects::Round;
  use Games::Go::AGA::DataObjects::Directives;
  use Games::Go::AGA::DataObjects::Register;
  use Games::Go::AGA::DataObjects::Tournament;

=head1 DESCRIPTION

Games::Go::AGA::DataObjects is a collection of perl objects to model
various American Go Assocciation (AGA) data structures.  Objects
include:

    Types.pm        library of type-checking constraints
    Player.pm       a single player
    Game.pm         two players plus some game-specific information
    Round.pm        a list of games that make up a round of a tournament
    Register.pm     a list of players plus some tournament-specific information
    Directives.pm   a collection of register.tde directives
    Tournament.pm   a Register object and a list of Rounds

Types contains methods for validating various data types.

Player stores information about a player.

Game stores information about a game.

Round models a tournament round: a collection of Games.

Directives models a collection of tournament directives as found in a
register.tde file.

Register models a register.tde file: Directives and a collection of
Players.

Tournament models a tournament: Register and a collection of Rounds.

Player, Round and Register provide B<fprint> methods for printing
themselves to a filehandle (in AGA format).

=head1 DEPRECATION

As these modules have evolved, certain methods have been deprecated.  Old
code should be updated and new code should be written so as to not invoke
the deprecated methods.

The deprecated methods will croak with a deprecation message, but ONLY IF THE
$deprecate variable in the appropriate module has been set.  This allows old
code to still call the deprecated methods without penalty.

New/updated code can enforce a deprecation level with (e.g):

 use Games::Go::AGA::DataObjects deprecate => 2;

or with a version requirement:

 use Games::Go::AGA::DataObjects 0.148 deprecate => 2;

To enforce the latest level of deprecations, invoke like this:

 use Games::Go::AGA::DataObjects deprecate => 'latest';

Submodules can be deprecated to different levels with:

 use Games::Go::AGA::DataObjects deprecate => 2;
 $Games::Go::AGA::DataObjects::Player::deprecate = 1;   # override

Currently, the latest deprecation levels are:

 Games::Go::AGA::DataObjects::Player = 1
    Deprecates:
        games()
        opponents()
        defeated()
        defeated_by()
        no_result()
        wins()
        losses()
        no_result()
        bye()
    These are now handled at the Tournament level.

 Games::Go::AGA::DataObjects::Round = 1
    Deprecates:
        byes()
        add_bye()
        remove_bye()
        replace_bye()
        swap()
    These are now handled at the Tournament level.

=head1 SEE ALSO

=over

=item Games::Go::AGA::DataObjects::Types

=item Games::Go::AGA::DataObjects::Player

=item Games::Go::AGA::DataObjects::Game

=item Games::Go::AGA::DataObjects::Round

=item Games::Go::AGA::DataObjects::Directives

=item Games::Go::AGA::DataObjects::Register

=item Games::Go::AGA::DataObjects::Tournament

=back

=head1 AUTHOR

Reid Augustin <reid@hellosix.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Reid Augustin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
