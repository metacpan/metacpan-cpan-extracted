package Games::Tournament::Contestant::Swiss;
$Games::Tournament::Contestant::Swiss::VERSION = '0.21';
# Last Edit: 2011  2月 27, 21時32分54秒
# $Id: $

use warnings;
use strict;

use List::MoreUtils qw/any/;

use Games::Tournament::Swiss::Config;
use constant ROLES => @Games::Tournament::Swiss::Config::roles?
			@Games::Tournament::Swiss::Config::roles:
			Games::Tournament::Swiss::Config->roles;

use base qw/Games::Tournament::Contestant/;

# use overload qw/0+/ => 'pairingNumber', qw/""/ => 'name', fallback => 1;

=head1 NAME

Games::Tournament::Contestant::Swiss  A competitor in a FIDE-Swiss-Rules event

=cut

=head1 SYNOPSIS

    my $foo = Games::Tournament::Contestant::Swiss->new( rating => '15', name => 'Deep Blue', pairingNumber => 2 );
    ...

=head1 DESCRIPTION

Subclasses Games::Tournament::Contestant with Games::Tournament::Swiss-specific data and methods, like pairingNumber, floats.

Games::Tournament::Swiss will use this class when constructing a 'Bye' contestant.

=head1 METHODS

=head2 new

	Games::Tournament::Contestant::Swiss->new( rating => '15',
	    name => 'Red Chessman', pairingNumber => 2,
	    floats => [qw/Not Down Not Not],
	    roles => [qw/Black White Black White/] );

Actually, you don't want to assign pairing numbers this way. Let the assignPairingNumbers method in Games::Tournament::Swiss do it. The player gets a default mild preference for neither role.

=cut

sub new() {
    my $self = shift;
    my %args = @_;
    # $args{roles} = [] unless $args{roles};
    my $object = bless \%args, $self;
    $object->preference(
	Games::Tournament::Contestant::Swiss::Preference->new );
    return $object;
}


=head2 preference

	$member->preference

Gets (sets) $member's preference, or right (duty) to take a role, eg White or Black, in the next round, calculated as a function of the difference between the number of games previously played in the different roles, and accommodated according to its value, Mild, Strong, or Absolute. An Absolute preference of +2 for White is given when the contestant has played 2 (or a larger number) more of the previous rounds as Black than as White, or when the last 2 rounds were played as Black. A Strong preference of +1 for White represents having played one more round as Black than as White. A Mild preference of +0 occurs when the number of games played with both colors is the same, but the last game was played as Black. A Mild preference of -0 is the same, but with the last game being as White, the preference is for Black. Preferences of -1 and -2 represent the same situations as for +1 and +2, but with the roles reversed. Before the first round, the preference of the highest ranked player (+-0) is determined by lot.  A7

=cut

sub preference {
    my $self = shift;
    my $preference = shift() || $self->{preference};
    $self->{preference} = $preference;
    return $preference;
}


=head2 pairingNumber

	$member->pairingNumber(1)

Sets/gets the pairing number of the contestant, used to identify participants when pairing them with others. This index is assigned in order of a sorting of the participants by ranking, title and name. You know what you're doing with this number, don't you?

=cut

sub pairingNumber {
    my $self = shift;
    $self->{pairingNumber} = shift if @_;
    $self->{pairingNumber};
}


=head2 oldId

	$member->oldId

Sets/gets an original, possibly unreliable id of the contestant, supplied by the user.

=cut

sub oldId {
    my $self  = shift;
    my $oldId = shift;
    if ( defined $oldId ) { $self->{oldId} = $oldId; }
    elsif ( $self->{oldId} ) { return $self->{oldId}; }
}

=head2 opponents

	$member->opponents( 0, 5, 11 )
	$rolehistory = $member->opponents

If ids are passed, adds them to the end of the list representing the latest opponents that $member has had in this tournament. (Normally one and only one parameter, the id of the opponent in the latest round, will be passed.) If no parameter is passed, returns a reference to the list. If the member had no game or played no game, because of a bye, or no result, or was unpaired, pass 'Bye' or 'Forfeit' or 'Unpaired'.

=cut

sub opponents {
    my $self = shift;
    my @opponents = @_;
    if ( @opponents ) { push @{ $self->{opponents} }, @opponents; return }
    elsif ( $self->{opponents} ) { return $self->{opponents}; }
    else { return []; }
}


=head2 roles

	$member->roles( 1, 'Black' )
	$member->roles( 1 ) # 'Black'
	$rolehistory = $member->roles # { 1 => 'Black' }

If a round and role are passed, adds them to the roles that $member has had in this tournament. If the member had no game (or had a game but didn't play it), that is, if they had a bye, or no result, or were unpaired, pass 'Bye', or 'Forfeit', or 'Unpaired.' F2,3

=cut

sub roles {
    my $self = shift;
    my $round = shift;
    my $role = shift;
    if ( defined $role and defined $round ) {
	my $oldrole = $self->{roles}->{$round};
	warn "$oldrole role replaced by $role" if defined $oldrole and 
	    $oldrole ne $role;
	$self->{roles}->{$round} = $role;
    }
    elsif ( $self->{roles} and $round ) { return $self->{roles}->{$round}; }
    elsif ( $self->{roles} ) { return $self->{roles}; }
    else { return {}; }
}


=head2 rolesPlayedList

A list, in round order, of the roles played against other players. Byes and other non-partnership roles are not included.

=cut

sub rolesPlayedList {
    my $self = shift;
    my $roles = $self->roles;
    my @rounds = sort { $a <=> $b } keys %$roles;
    my $last = $rounds[-1];
    my @playrounds = grep { my $role = $roles->{$_};
			    any { $role eq $_ } ROLES } @rounds;
    my @playroles = map { $roles->{$_} } @playrounds;
    return \@playroles;
}


=head2 floating

        $member->floating
        $member->floating( 'Up'|'Down'|'' )

Sets/gets the direction in which the contestant is floating in the next round, "Up", "Down". If nothing is returned, the contestant is not floating. A4

=cut

sub floating {
    my $self      = shift;
    my $direction = shift;
    if ( defined $direction and $direction =~ m/^(?:Up|Down|)$/ ) {
        $self->{floater} = $direction;
    }
    elsif ( $self->{floater} ) { return $self->{floater}; }
}

=head2 floats

	$member->floats( $round, 'Down' )
	$rolehistory = $member->floats

If a round number and float is passed, inserts this in an anonymous array representing the old floats that $member has had in this tournament. If only a round is passed, returns the float for that round. If no parameter is passed,  returns a anonymous array of all the floats ordered by the round. If the player was not floated, pass 'Not'. For convenience, if -1 or -2 are passed for the last round before, or the round 2 rounds ago, and those rounds do not exist (perhaps the tournament only started one round before), 'Not' is returned.

=cut


sub floats {
    my $self  = shift;
    my $round = shift;
    my $float = shift;
    if ( defined $round and defined $float ) {
        $self->{floats}->[$round-1] = $float;
	return;
    }
    elsif ( defined $round ) {
	if ($round == -1 or $round == -2) {
	    if (not exists $self->{floats}->[$round-1] ) {return 'Not'}
	    else { return $self->{floats}->[$round]; }
	}
	else { return $self->{floats}->[$round-1]; }
    }
    elsif ( $self->{floats} ) { return $self->{floats}; }
    else { return; }
}

=head2 importPairtableRecord

    $member->importPairtableRecord(
	{ opponents => [ 6,4 ]
	  roles => [ 'Win', 'Loss' ],
	  floats => [ undef, 'Not', 'Down' ],
	  score => 1.5 } )

Populate $member with data about opponents met, roles played, and floats received in previous rounds, which together with the total score will allow it to be paired with an appropriate opponent in the next round. Set $member's preference. Delete any pre-existing opponents, roles, floats, scores, score, or preference data.

=cut


sub importPairtableRecord {
    my $self  = shift;
    my $record = shift;
    #die $self->name . ", " . $self->id . " pairtable record field lengths"
    #    unless @{$record->{opponents}} == @{$record->{roles}} and
    #    @{$record->{roles}} == @{$record->{floats}} - 1;
    my ($opponents, $roles, $floats) = @$record{qw/opponents roles floats/};
    delete @$self{qw/opponents roles floats scores score preference/};
    $self->opponents(@$opponents);
    $self->roles(@$roles);
    for my $i ( 0 .. $#$floats ) { $self->floats( $i, $floats->[$i] ); }
    use Games::Tournament::Contestant::Swiss::Preference;
    $self->preference(Games::Tournament::Contestant::Swiss::Preference->new);
    $self->preference->update( [ @$roles[0..$_] ] ) for 0.. $#$roles;
    $self->{score} = $record->{score};
    return;
}

=head2 unbyable

    $member->unbyable(1)
    return BYE unless $member->unbyable

A flag of convenience telling you whether to let this player have the bye. Am I doing the right thing here? This will be gettable and settable, but will it be reliable?

=cut

sub unbyable {
    my $self = shift;
    my $unbyable = shift;
    if ( $unbyable ) { $self->{unbyable} = 1; return }
    elsif ( defined $self->{unbyable} ) { return $self->{unbyable}; }
    else { return; }
}


=head1 AUTHOR

Dr Bean, C<< <drbean, followed by the at mark (@), cpan, then a dot, and finally, org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-games-tournament-contestant at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Games-Tournament-Contestant-Swiss>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Games::Tournament::Contestant::Swiss

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Games-Tournament-Contestant-Swiss>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Games-Tournament-Contestant-Swiss>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Games-Tournament-Contestant-Swiss>

=item * Search CPAN

L<http://search.cpan.org/dist/Games-Tournament-Contestant-Swiss>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2006 Dr Bean, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;    # End of Games::Tournament::Contestant::Swiss

# vim: set ts=8 sts=4 sw=4 noet:
