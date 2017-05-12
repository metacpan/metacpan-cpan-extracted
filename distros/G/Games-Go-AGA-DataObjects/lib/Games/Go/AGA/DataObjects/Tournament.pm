#===============================================================================
#
#         FILE:  Games::Go::AGA::DataObjects::Tournament.pm
#
#        USAGE:  use Games::Go::AGA::DataObjects::Tournament;
#
#      PODNAME:  Games::Go::AGA::DataObjects::Tournament
#     ABSTRACT:  models AGA register.tde file information
#
#       AUTHOR:  Reid Augustin (REID), <reid@hellosix.com>
#      CREATED:  11/19/2010 03:13:05 PM PST
#===============================================================================


use strict;
use warnings;

package Games::Go::AGA::DataObjects::Tournament;
use Moo;
use namespace::clean;

use parent 'Games::Go::AGA::DataObjects::Register';
use Games::Go::AGA::DataObjects::Round;
use Games::Go::AGA::DataObjects::Types qw( isa_CodeRef);
use Games::Go::AGA::Parse::Util qw( normalize_ID );

use Carp;
use IO::File;
use IO::String;
use Scalar::Util qw( refaddr );

our $VERSION = '0.152'; # VERSION

# public attributes
#   has 'rounds'   => (
#       isa => 'ArrayRef[Games::Go::AGA::DataObjects::Round]',
#       is => 'ro',
#       default => sub { [] }
#   );

# Note: the change callback shouldn't really be necessary since
# Directives are changed by the Directives object and player data is
# changed by the Player object.  But it might be convenient...
has change_callback => (
    isa => \&isa_CodeRef,
    is => 'rw',
    lazy => 1,
    default => sub { sub { } }
);
has suppress_changes => (   # don't call change_callback if set
    is => 'rw',
    lazy => 1,
    default => sub { 0 }
);
has fprint_pending => (   # set when changed called, cleared after fprint done
    is => 'rw',
    lazy => 1,
    default => sub { 0 }
);

sub clear_rounds { $_[0]->{rounds} = [ undef ]; }    # rounds start at 1

sub BUILD {
    my ($self) = @_;
    $self->clear_rounds;
}

sub changed {
    my ($self) = @_;

    $self->fprint_pending(1);
    &{$self->change_callback}(@_) if (not $self->suppress_changes);
}

sub add_round {
    my ($self, $round_num, $round, $replace) = @_;

    if ($round_num <= 0) {
        croak "Round number must be >= 1\n";
    }
    elsif ($round_num > 1 and       # allow round 1
            not defined $self->{rounds}[$round_num - 1]) {
        croak "Can't add round $round_num, previous round doesn't exist yet\n";
    }
    my $rm_round = $self->{rounds}[$round_num];
    if (    defined $rm_round
        and not $replace) {
        croak "$round_num already exists\n";
    }
    my $prev_callback = $round->change_callback;
    $round->change_callback(
        sub {
            delete $self->{player_stats};   # force re-count
            $prev_callback->(@_);
            $self->changed;
        }
    );
    $self->{rounds}[$round_num] = $round;
    # $self->changed; # rounds are recorded in N.tde files, not in register.tde
}

# NOTE: returns games for ALL ROUNDS up to and including $round_num
sub games  {
    my ($self, $round_num) = @_;

    $round_num = $#{$self->{rounds}} if (not defined $round_num);
    my @games;
    foreach my $r_num (1 .. $round_num) {
        my $round = $self->{rounds}[$r_num];
        next if (not $round);
        push @games, $round->games;
    }
    return wantarray
        ?  @games
        : \@games;
}

sub rounds  {
    my ($self) = @_;

    return $#{$self->{rounds}};  # we don't count 0
}

sub round {
    my ($self, $round_num) = @_;

    if (not defined $self->{rounds}[$round_num]) {
        croak "Round $round_num doesn't exist\n";
    }
    return $self->{rounds}[$round_num];
}

#return unpaired players for a round, sorted by rank
sub unpaired_in_round_num {
    my ($self, $round_num) = @_;

    my %un_paired = map { $_->id => $_ } @{$self->players}; # players by ID
    my $round = $self->round($round_num);
    for my $game (@{$round->games}) {
        delete $un_paired{$game->white->id};
        delete $un_paired{$game->black->id};
    }
    my @unpaired = sort { $b->rating <=> $a->rating } values %un_paired;
    return wantarray
      ?  @unpaired
      : \@unpaired;
}

sub swap_players_in_round_num {
    my ($self, $p0, $p1, $round_num) = @_;

    $p0 = $self->get_player($p0);     # ensure both players are valid
    $p1 = $self->get_player($p1);
    my $round = $self->round($round_num)
        || die("No round number $round_num in this tournament");
    my $id0 = $p0->id;
    my $id1 = $p1->id;
    my @games;
    for my $game (@{$round->games}) {
        push @games, $game if ($game->white->id eq $id0 or $game->black->id eq $id0);
        push @games, $game if ($game->white->id eq $id1 or $game->black->id eq $id1);
    }
    return if not @games;   # both in unpaired list?
    if (@games > 2) {   # if a player is in more than one game
        die "Too many games.  Please un-pair and re-pair games instead";
    }
    # two games if both are playing, one if there is a bye
    if    ($games[0]->white->id eq $id0) { $games[0]->white($p1) }
    elsif ($games[0]->white->id eq $id1) { $games[0]->white($p0) }
    if    ($games[0]->black->id eq $id0) { $games[0]->black($p1) }
    elsif ($games[0]->black->id eq $id1) { $games[0]->black($p0) }
    $games[0]->handicap;
    if (@games == 2 and refaddr($games[0]) != refaddr($games[1])) {
        if    ($games[1]->white->id eq $id0) { $games[1]->white($p1) }
        elsif ($games[1]->white->id eq $id1) { $games[1]->white($p0) }
        if    ($games[1]->black->id eq $id0) { $games[1]->black($p1) }
        elsif ($games[1]->black->id eq $id1) { $games[1]->black($p0) }
        $games[1]->handicap;
    }
}

sub clear_stats {
    my ($self) = @_;

    delete $self->{player_stats};
}

sub player_stats {
    my ($self, $id, $stat) = @_;

    if (not defined $self->{player_stats}) {
        my %players;
        for my $round_num (1 .. $self->rounds) {
            my $round = $self->round($round_num);
            for my $game (@{$round->games}) {
                my $white = $game->white;
                my $black = $game->black;
                my $wid = $white->id;
                my $bid = $black->id;
                push @{$players{$wid}{games}}, $game;
                push @{$players{$bid}{games}}, $game;
                if (not defined $game->winner) {
                    push @{$players{$wid}{no_result}}, $black;
                    push @{$players{$bid}{no_result}}, $white;
                    next;
                }
                my $win_id = $game->winner->id;
                my $los_id = $game->loser->id;
                push @{$players{$win_id}{wins}}, $game;
                push @{$players{$win_id}{defeated}}, $game->loser;
                push @{$players{$los_id}{losses}}, $game;
                push @{$players{$los_id}{defeated_by}}, $game->winner;
            }
        }
        $self->{player_stats} = \%players;
    }
    $id = normalize_ID($id);
    $self->{player_stats}{$id}{$stat} ||= [];
    return wantarray
      ? @{$self->{player_stats}{$id}{$stat}}
      :   $self->{player_stats}{$id}{$stat};
}

sub player_games       { shift->player_stats(@_, 'games'); }
sub player_wins        { shift->player_stats(@_, 'wins'); }
sub player_losses      { shift->player_stats(@_, 'losses'); }
sub player_no_result   { shift->player_stats(@_, 'no_result'); }
sub player_defeated    { shift->player_stats(@_, 'defeated'); }
sub player_defeated_by { shift->player_stats(@_, 'defeated_by'); }

sub send_to_AGA {
    my ($self, $fd) = @_;

    if (not $fd) {
        $fd = IO::String->new() or die "Failed to create IO::String\n";
    }

    $fd->printf("TOURNEY %s\n",
        $self->get_directive_value('TOURNEY'));

    my $date = $self->get_directive_value('DATE');
    my ($start, $finish) = $date =~ m/^(\S+)[\-\s]+(\S+)$/;
    $start  ||= $date;
    $finish ||= $start;
    $start  =~ s/\D/\//g;     # use slash date notation
    $finish =~ s/\D/\//g;
    $fd->print("     start=$start\n"),
    $fd->print("    finish=$finish\n"),

    $fd->printf("     rules=%s\n",
        $self->get_directive_value('RULES'));
    $fd->print("\nPLAYERS\n");

    # print player info
    my $name_width = 5;
    for my $player ($self->players) {
        $name_width = length($player->full_name)
            if (length($player->full_name) > $name_width);
    }

    for my $player ($self->players) {
        $fd->printf("%9.9s %*.*s %s\n",
            $player->id,
            $name_width,
            $name_width,
            $player->full_name,
            $player->rating,
        );
    }

    # print games with results
    $fd->print("\nGAMES\n");
    for my $round (@{$self->{rounds}}) {
        next if (not defined $round);
        for my $game ($round->games) {
            if ($game->winner) {
                my $result = ($game->winner->id eq $game->white->id) ? 'W' : 'B';
                $fd->printf("%9.9s %9.9s $result %s %s\n",
                    $game->white->id,
                    $game->black->id,
                    $game->handi,
                    $game->komi,
                );
            }
        }
    }
    $fd->print("\n");

    return $fd
}

# this really shouldn't be necessary.  Register and Directives will
#    fprint the register.tde files, and Round will fprint the N.tde files.
sub fprint {
    my ($self, $fh) = @_;

    $self->SUPER::fprint($fh);         # print the register.tde file
    $self->fprint_pending(0);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Games::Go::AGA::DataObjects::Tournament - models AGA register.tde file information

=head1 VERSION

version 0.152

=head1 SYNOPSIS

    use Games::Go::AGA::DataObjects::Tournament;
    my $tournament = Games::Go::AGA::DataObjects::Tournament->new();

    my $rounds = $tournament->rounds;  # ref to the array of rounds

=head1 DESCRIPTION

Games::Go::AGA::DataObjects::Tournament models the information about a
American Go Association (AGA) go tournament.

Games::Go::AGA::DataObjects::Tournament isa Games::Go::AGA::DataObjects::Register
object with additional methods:

=over

=item $tournament->add_round($round_num, $round, [ 'replace' ] )

Adds a Games::Go::AGA::DataObjects::Round to the tournament as number B<$round_num>.
Throws an exception if B<$round_num> - 1 doesn't exist yet.  If B<'replace'> is
defined, all existing games from this B<$round_num> are removed from the
Games::Go::AGA::DataObjects::Players.

=item $tournament->rounds

Returns the number of rounds (round 0 never exists and is not counted).

=item $tournament->round($round_num)

Returns the Games::Go::AGA::DataObjects::Round object for round B<$round_num>.

=item $tournament->send_to_AGA( [ $fd ] )

Format the tournament data for sending to the AGA (ratings@usgo.org).

If B<$fd> is defined, it is printed to.  If not, it is created as a new
C<IO::String> object.  $<fd> is returned, so if B<$fd> is an C<IO::String>
object, the caller can acquire the string using B<$fd->string_ref> (see
C<perldoc IO::String>).

=back

=head1 SEE ALSO

=over

=item Games::Go::AGA

=item Games::Go::AGA::DataObjects

=item Games::Go::AGA::DataObjects::Register

=item Games::Go::AGA::DataObjects::Game

=item Games::Go::AGA::DataObjects::Player

=item Games::Go::AGA::Parse

=item Games::Go::AGA::Gtd

=back

=head1 AUTHOR

Reid Augustin <reid@hellosix.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Reid Augustin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
