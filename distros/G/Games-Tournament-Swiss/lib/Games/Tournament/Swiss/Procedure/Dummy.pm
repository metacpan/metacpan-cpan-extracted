package Games::Tournament::Swiss::Procedure::Dummy;
$Games::Tournament::Swiss::Procedure::Dummy::VERSION = '0.21';
# Last Edit: 2016 Jan 01, 13:44:45
# $Id: $

use warnings;
use strict;

use constant ROLES      => @Games::Tournament::Swiss::Config::roles;
use constant FIRSTROUND => $Games::Tournament::Swiss::Config::firstround;

use base qw/Games::Tournament::Swiss/;
use Games::Tournament::Contestant::Swiss;

=head1 NAME

Games::Tournament::Swiss::Procedure::Dummy - A brain-dead pairing algorithm

=cut

=head1 SYNOPSIS

 $tourney = Games::Tournament::Swiss->new( rounds => 2, entrants => [ $a, $b, $c ] );
 %groups = $tourney->formBrackets;
 $pairing = $tourney->pairing( \%groups );
 @pairs = $pairing->matchPlayers;

=head1 DESCRIPTION

A test module swappable in to allow testing the non-Games::Tournament::Procedure parts of Games::Tournament::Swiss

=head1 METHODS

=head2 new

 $pairing = Games::Tournament::Swiss::Procedure::Dummy->new(TODO \@groups );

Creates a stupid algorithm object that on matchPlayers will just pair the nth player with the n+1th in each score group, downfloating the last player if the number in the bracket is odd, ignoring the FIDE Swiss Rules. You can swap in this module in your configuration file, instead of your real algorithm to test the non-algorithm parts of your program are working.

=cut 

sub new {
    my $self     = shift;
    my $index    = 0;
    my %args     = @_;
    my $round    = $args{round};
    my $brackets = $args{brackets};
    my $banner   = "Round $round:  ";
    for my $bracket ( reverse sort keys %$brackets ) {
        my $members = $brackets->{$bracket}->members;
        my $score   = $brackets->{$bracket}->score;
        $banner .= "@{[map { $_->pairingNumber } @$members]} ($score), ";
    }
    print $banner . "\n";
    return bless {
        round    => $round,
        brackets => $brackets,
        matches  => []
      },
      "Games::Tournament::Swiss::Procedure";
}


=head2 matchPlayers

 @pairs = $pairing->matchPlayers;

Run a brain-dead algorithm that instead of pairing the players according to the rules creates matches between the nth and n+1th player of a bracket, downfloating the last player of the group if the number of players is odd. If there is an odd number of total players, the last gets a Bye.

=cut 

sub matchPlayers {
    my $self     = shift;
    my $brackets = $self->brackets;
    my $downfloater;
    # my @allMatches = @{ $self->matches };
    my %allMatches;
    my $number = 1;
    for my $score ( reverse sort keys %$brackets ) {
        my @bracketMatches;
        my $players = $brackets->{$score}->members;
        if ($downfloater) {
            unshift @$players, $downfloater;
            undef $downfloater;
        }
        $downfloater = pop @$players if @$players % 2;
        for my $table ( 0 .. @$players / 2 - 1 ) {
            push @bracketMatches, Games::Tournament::Card->new(
                round       => $self->round,
                result      => undef,
		score => $score,
                contestants => {
                    (ROLES)[0] => $players->[ 2 * $table ],
                    (ROLES)[1] => $players->[ 2 * $table + 1 ]
                },

                # floats => \%floats
            );
        }
        if ( $number == keys %$brackets and $downfloater ) {
            push @bracketMatches, Games::Tournament::Card->new(
                round       => $self->round,
                result      => undef,
                contestants => { Bye => $downfloater },

                # floats => \%floats
            );
        }
        $allMatches{$score} = \@bracketMatches;
	$number++;
    }
    $self->matches( \%allMatches );
}


=head2 brackets

	$pairing->brackets

Gets/sets all the brackets which we are pairing, as an anonymous array of score group (bracket) objects. The order of this array is important. The brackets are paired in order.

=cut

sub brackets {
    my $self     = shift;
    my $brackets = shift;
    if ( defined $brackets ) { $self->{brackets} = $brackets; }
    elsif ( $self->{brackets} ) { return $self->{brackets}; }
}


=head2 round

	$pairing->round

What round is this round's results we're pairing on the basis of?

=cut

sub round {
    my $self  = shift;
    my $round = shift;
    if ( defined $round ) { $self->{round} = $round; }
    elsif ( $self->{round} ) { return $self->{round}; }
}


=head2 matches

	$group->matches

Gets/sets the matches which we have made.

=cut

sub matches {
    my $self    = shift;
    my $matches = shift;
    if ( defined $matches ) { $self->{matches} = $matches; }
    elsif ( $self->{matches} ) { return $self->{matches}; }
}

=head1 AUTHOR

Dr Bean, C<< <drbean, followed by the at mark (@), cpan, then a dot, and finally, org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-games-tournament-swiss at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Games-Tournament-Swiss>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Games::Tournament::Swiss

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Games-Tournament-Swiss>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Games-Tournament-Swiss>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Games-Tournament-Swiss>

=item * Search CPAN

L<http://search.cpan.org/dist/Games-Tournament-Swiss>

=back

=head1 ACKNOWLEDGEMENTS

See L<http://www.fide.com/official/handbook.asp?level=C04> for the FIDE's Swiss rules.

=head1 COPYRIGHT & LICENSE

Copyright 2006 Dr Bean, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;    # End of Games::Tournament::Swiss::Procedure

# vim: set ts=8 sts=4 sw=4 noet:
