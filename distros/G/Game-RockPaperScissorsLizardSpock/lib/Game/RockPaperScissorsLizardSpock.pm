package Game::RockPaperScissorsLizardSpock;

use strict;
use warnings;

$Game::RockPaperScissorsLizardSpock::VERSION = '0.01';

my %choices = (
    'rock'     => 0,
    'Spock'    => 1,
    'paper'    => 2,
    'lizard'   => 3,
    'scissors' => 4,
);

sub import {
    my $caller = caller();
    no strict 'refs';    ## no critic
    *{ $caller . '::rpsls' } = \&rpsls;
}

sub rpsls {
    my ( $player1, $player2 ) = @_;
    return if !defined $player1 || !exists $choices{$player1};
    if ( defined $player2 ) {
        return if !exists $choices{$player2};
    }
    else {
        $player2 = ( keys %choices )[ rand keys %choices ];
    }

    return 3 if $choices{$player1} == $choices{$player2};

    my $difference = ( $choices{$player1} - $choices{$player2} ) % 5;

    if ( $difference == 1 || $difference == 2 ) {
        return 1;
    }
    else {
        return 2;
    }
}

1;

__END__

=encoding utf8

=head1 NAME

Game::RockPaperScissorsLizardSpock - and as it always has …

=head1 VERSION

This document describes Game::RockPaperScissorsLizardSpock version 0.01

=head1 SYNOPSIS

    use Game::RockPaperScissorsLizardSpock;

    if ( my $winner = rpsls($ARGV[0]) ) {
        if ( $winner == 3 ) {
            print "Its a tie!\n";
        }
        else {
            if ( $winner == 1 ) {
                print "Player 1 wins\n";
            }
            else {
                print "Computer wins\n";
            }
        }
    }
    else {
        print "Please specify rock, paper, scissors, lizard, or Spock\n";
    }

=head1 DESCRIPTION

L<https://www.youtube.com/watch?v=iapcKVn7DdY>

=head1 INTERFACE 

=head2 rpsls()

First argument is player one’s choice.

Second, optional, argument is player two’s choice. If left out player two is the computer.

It return()s if the arguments are not valid.

Otherwise it returns 1 is player 1 wins, 2 if player 2 wins, and 3 if it is a tie.

Valid choices are these five strings 'rock', 'paper', 'scissors', 'lizard', or 'Spock'.

=head1 DIAGNOSTICS

Throws not errors or warnings of its own.

=head1 CONFIGURATION AND ENVIRONMENT

Game::RockPaperScissorsLizardSpock requires no configuration files or environment variables.

=head1 DEPENDENCIES

None.

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-game-rockpaperscissorslizardspock@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head2 TODO

Stringify winning message to match pair. 

e.g. instead of needing to "$x beats $y", you can get 'rock crushes scissors'

=head1 AUTHOR

Daniel Muey  C<< <http://drmuey.com/cpan_contact.pl> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2014, Daniel Muey C<< <http://drmuey.com/cpan_contact.pl> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
