#===============================================================================
#
#         FILE:  Games::Go::AGA::DataObjects::Player.pm
#      PODNAME:  Games::Go::AGA::DataObjects::Player
#     ABSTRACT:  model an AGA player
#
#       AUTHOR:  Reid Augustin (REID), <reid@com->full_name
#      CREATED:  11/19/2010 03:13:05 PM PST
#===============================================================================


use strict;
use warnings;

package Games::Go::AGA::DataObjects::Player;
use Moo;
use namespace::clean;

use Carp qw{ cluck carp croak };
use Scalar::Util qw( refaddr looks_like_number );
use Games::Go::AGA::Parse::Util qw( normalize_ID Rank_to_Rating );
use Games::Go::AGA::DataObjects::Types qw( is_ID is_Rating is_Rank_or_Rating isa_ArrayRef isa_Num isa_CodeRef);

our $VERSION = '0.152'; # VERSION

our $deprecate = 0;
has id => (
    is => 'rw',
    isa => sub {
        confess("$_[0] is not an ID\n") if (not is_ID($_[0]))
    },
    trigger => sub {
        # TODO: make this a coercion?
        my ($self, $new) = @_;
        $self->{id} = normalize_ID($new);
        $self->changed;
    },
);
has last_name  => (
    is => 'rw',
    trigger => sub { shift->changed; },
);
has first_name => (
    is => 'rw',
    trigger => sub { shift->changed; },
);
has rank       => (
    is => 'rw',
    isa => sub {
        confess("$_[0] is not a Rank or Rating\n") if (not is_Rank_or_Rating($_[0]))
    },
    trigger => sub {
        my ($self, $new) = @_;
        if (is_Rating($new)) {
            $self->{rank} += 0; # force numification
        }
        shift->changed;
    },
);
has date    => (
    is => 'rw',
    lazy => 1,
    default => '',
    trigger => sub { shift->changed; },
);
has membership    => (
    is => 'rw',
    lazy => 1,
    default => '',
    trigger => sub { shift->changed; },
);
has state    => (
    is => 'rw',
    lazy => 1,
    default => '',
    trigger => sub { shift->changed; },
);
has club    => (
    is => 'rw',
    lazy => 1,
    default => '',
    trigger => sub {
        my $self = shift;
        $self->{club} = uc $self->{club};
        $self->changed;
    },
);
has flags => (
    is  => 'rw',
    isa => \&isa_ArrayRef,
);
has comment  => (
    is => 'rw',
    lazy => 1,
    default => '',
    trigger => sub { shift->changed; },
);
has sigma      => (
    is => 'rw',
    isa => \&isa_Num,
    trigger => sub { shift->changed; },
);
has games      => (
    is => 'rw',
    isa     => \&isa_ArrayRef,
    lazy => 1,
    default => sub { [] },
    #  trigger => sub { shift->changed; },
);
has change_callback => (
    is => 'rw',
    isa => \&isa_CodeRef,
    lazy => 1,
    default => sub { sub { } }
);
has _adj_ratings => (   # array of adjusted ratings, one per round_num, but not 0
    is => 'lazy',
    isa => \&isa_ArrayRef,
    default => sub { [] }
);

sub BUILD {
    my ($self) = @_;
    $self->{flags} ||= [];    # empty array
}

sub changed {
    my ($self) = @_;

    &{$self->change_callback}(@_);
}

sub full_name  {
    my ($self) = @_;

    if (my $name = $self->first_name) {
        return join(', ', $self->last_name, $name),
    }
    # some players don't have first name
    return $self->last_name;
}


#   sub comment {
#       my $self = shift;
#       if (@_) {
#           if (defined $_[0]) {
#               $self->{comment} = join '', @_;
#           }
#           else {
#               delete $self->{comment};
#           }
#       }
#       return $self->{comment};
#   }

sub add_game {
    my ($self, $game, $idx) = @_;

croak("Player::add_game deprecated: Use tournament->round->games list instead\n") if ($deprecate > 0);
    my $add_refaddr = refaddr $game;    # ID of game to add
    if(not grep { (refaddr $_) == $add_refaddr } @{$self->{games}}) {
#print STDERR "add_game $game to " . $self->full_name . "\n";
        if (@_ < 3) {
            push @{$self->{games}}, $game;
        }
        else {
            splice @{$self->{games}}, $idx, 0, $game;
        }
        #$self->changed;
    }
}

sub delete_game {
    my ($self, $idx, $id1) = @_;

croak("Player::delete_game deprecated: Use tournament->round->games list instead\n") if ($deprecate > 0);
    my $games = $self->{games};
    if (not looks_like_number($idx)) {
        if (ref $idx) {
            # $idx is actually a Game object, find its idx in our games
            # list
            my $game = $idx;
            my $refaddr = refaddr($game);
            for my $ii (0 .. $#{$games}) {
                if (refaddr($games->[$ii]) == $refaddr) {
                    $idx = $ii;
                    last;
                }
            }
        }
        elsif ($id1) {
            my $id0 = $idx; # idx is actually ID_0
            for my $ii (0 .. $#{$games}) {
                if (($games->[$ii]->black->id eq $id0 and 
                     $games->[$ii]->white->id eq $id1) or
                    ($games->[$ii]->black->id eq $id1 and 
                     $games->[$ii]->white->id eq $id0)) {
                    $idx = $ii;
                    last;
                }
            }
        }
    }
    if (not looks_like_number($idx)) {
        if (ref $idx) {
            croak(sprintf "Can't find game %s vs %s in games list for %s\n",
                $idx->white->last_name,
                $idx->black->last_name,
                $self->id,
            );
        }
        else {
            $idx ||= '<>';
            $id1 ||= '<>';
            my $id = $self->id;
            croak("Can't find game $idx vs $id1 in games list for $id\n");
        }
    }
    splice(@{$games}, $idx, 1); # remove from list
    #$self->changed;            # not recorded in any file, so ignore
    return $idx;
}

sub adj_rating {
    my ($self, $round_num, $new) = @_;

    $round_num ||= -1;  # if no round number, use last round
    croak('adj_rating: round_num not valid') if ($round_num < -1);
    # there is no round_num 0, but -1 is allowed

    $self->{adj_rating} = [] if (not $self->{adj_rating});
    my $adj_rating = $self->{adj_rating};
    if (@_ > 2) {
        $self->_adj_ratings->[$round_num] = $new;
    }
    # rating if no adjusted rating has been set
    return $self->rating if (not $self->_adj_ratings->[$round_num]);
    return $self->_adj_ratings->[$round_num];
}

sub handicap_rating {
    my ($self, $new) = @_;

    if (@_ > 1) {
        $self->{handicap_rating} = $new;
    }
    return defined $self->{handicap_rating}
        ? $self->{handicap_rating}
        : $self->rating;
}

sub opponents {
    my ($self) = @_;

croak("Player::opponents deprecated: Use tournament->round->games list instead\n") if ($deprecate > 0);
    my @opps = map { $_->opponent($self) } @{$self->{games}};
    return wantarray ? @opps
                        : scalar @opps;
}

sub defeated {
    my ($self) = @_;

croak("Player::defeated deprecated: Use tournament->player_defeated instead\n") if ($deprecate > 0);
    my $me = refaddr $self;
    my @defeated = map { $_->loser }
                        grep { defined $_->winner and
                                (refaddr($_->winner) == $me) } @{$self->{games}};
    return wantarray ? @defeated
                        : scalar @defeated;
}

sub defeated_by {
    my ($self) = @_;

croak("Player::defeated_by deprecated: Use tournament->player_defeated_by instead\n") if ($deprecate > 0);
    my $me = refaddr $self;
    my @defeated_by = map { $_->winner }
                            grep { defined $_->loser and
                                    (refaddr($_->loser) == $me) } @{$self->{games}};
    return wantarray ? @defeated_by
                        : scalar @defeated_by;
}

# games with no result (usually means still playing)
sub no_result {
    my ($self) = @_;

croak("Player::defeated_by deprecated: Use tournament->player_no_result instead\n") if ($deprecate > 0);
    my $me = refaddr $self;
    my @no_result = map { (refaddr($_->black) == $me) ? $_->white : $_->black }
                            grep { not defined $_->loser and
                                    not defined $_->winner } @{$self->{games}};
    return wantarray ? @no_result
                        : scalar @no_result;
}

sub wins {
    my ($self) = @_;

croak("Player::wins deprecated: Use tournament->player_wins instead\n") if ($deprecate > 0);
    my $me = refaddr $self;
    my @wins = grep { (refaddr($_->winner) || -1) == $me} @{$self->{games}};
    return wantarray ? @wins
                        : scalar @wins;
}

sub losses {
    my ($self) = @_;

croak("Player::losses deprecated: Use tournament->player_losses instead\n") if ($deprecate > 0);
    my $me = refaddr $self;
    my @losses = grep {defined $_->winner and
                        refaddr $_->winner != $me} @{$self->{games}};
    return wantarray ? @losses
                        : scalar @losses;
}

sub completed_games {
    my ($self) = @_;

croak("Player::completed_games deprecated: Use tournament->round->games list instead\n") if ($deprecate > 0);
    my @games = grep { $_->winner } @{$self->{games}};
    return wantarray ? @games
                        : scalar @games;
}

sub drop {
    my ($self, $round_num) = @_;

croak("Player::drop deprecated: Use tournament->get_directive('DROP') instead\n") if ($deprecate > 0);
    return 1 if ($self->get_flag('drop'));
    if (defined $round_num) {
        return 1 if ($self->get_flag("drop$round_num"));
    }
    return 0;
}

sub bye {
    my ($self) = @_;

croak("Player::bye deprecated: Use tournament->get_directive('BYE_CANDIDATE') instead\n") if ($deprecate > 0);
    return $self->get_flag('bye');
}

sub get_flag {
    my ($self, $key) = @_;

    my $flags = $self->{flags};
    my $ii = 0;
    for (@{$flags}) {
        last if (uc $key eq uc $flags->[$ii]);
        $ii++;
    }
    return $flags->[$ii];
}

sub set_flag {
    my ($self, $key) = @_;

    my $flags = $self->{flags};
    my $ii = 0;
    for (@{$flags}) {
        last if (uc $key eq uc $flags->[$ii]);
        $ii++;
    }
    $flags->[$ii] = $key;       # add if not there, overwrite if it is
    $self->changed;
    return $flags->[$ii];
}

sub clear_flag {
    my ($self, $key) = @_;

    my $flags = $self->{flags};
    my $ii = 0;
    for (@{$flags}) {
        last if (uc $key eq uc $flags->[$ii]);
        $ii++;
    }
    if ($ii < @{$flags}) {      # if element was found
        splice @{$flags}, $ii, 1;   #   remove it
        $self->changed;
    }
}

sub rating {
    my ($self) = @_;

    return Rank_to_Rating($self->rank);
}

# in register.tde format
sub fprint_register {
    my ($self, $fh) = @_;

    my @flags = @{$self->{flags}};
    push(@flags, "Club=" . $self->club) if ($self->club);

    $fh->printf("%s %s, %s %s",
        $self->id,
        $self->last_name,
        $self->first_name,
        $self->rank,
    );
    $fh->printf(" %s", join(' ', @flags)) if (@flags);
    my $comment = $self->comment;
    if ($comment) {
        $comment =~ s/\n/\\n/g;             # prevent newlines which would mess things up
        $comment =~ s/^\s*(.*?)\s*$/$1/;    # remove preceding and trailing whitespace
        $fh->print(" # $comment");
    }
    $fh->print("\n");
}

# in tdlist format
sub fprint_tdlist {
    my ($self, $fh) = @_;

    $fh->printf("%s, %s %s %s %s %s %s %s\n",
        $self->last_name,
        $self->first_name,
        $self->id,
        $self->membership,
        $self->rank,
        $self->date,
        $self->club,
        $self->state,
    );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Games::Go::AGA::DataObjects::Player - model an AGA player

=head1 VERSION

version 0.152

=head1 SYNOPSIS

    use Games::Go::AGA::DataObjects::Player;

    my $player = Games::Go::AGA::DataObjects::Player->new(
        id         => 'USA2122',
        last_name  => 'Augustin',
        first_name => 'Reid',
        rank       => '5d',
        flags      => ['FOO', 'DROP']
        comment    => 'programs in perl',
    );

=head1 DESCRIPTION

Games::Go::AGA::DataObjects::Player models a single player.

=head1 METHODS

=over

=item $player = new ( options ... );

Creates a new object.  The options are in a hash describing any of the
attributes of the player (see below).

=item clone

Clones the player by copying all the attributes.  Note that the B<games>
list still points to the original's games.

=item add_game ($game, [ $idx ])

THIS METHOD IS DEPRECATED - modify tournament->round->games list instead.

Adds C<$game> to the list of games.  C<$game> must be a
B<Games::Go::AGA::DataObjects::Game>.  If B<$idx> is specified,
splices into that position in the games list, otherwise pushes onto
the end.

Note that this doesn't call the B<change_callback> function.

=item delete_game ($game, [ $idx, [ $id1 ] ])

THIS METHOD IS DEPRECATED - modify tournament->round->games list instead.

Finds and deletes C<$game> from the list of games.  C<$game> may be a
B<Games::Go::AGA::DataObjects::Game>, or an index into the games list, or
an ID of one of the players (in which case $id1 should be the ID of the
other player).  Croaks if C<$game> is not found the list of games.

Note that this doesn't call the B<change_callback> function.

=item opponents

THIS METHOD IS DEPRECATED - use tournament->round->games list instead.

=item defeated

THIS METHOD IS DEPRECATED - use tournament->player_defeated instead.

Returns the players this player defeated.  In scalar context, returns
the number of wins.

=item defeated_by

THIS METHOD IS DEPRECATED - use tournament->player_defeated_by instead.

Returns the players this player lost to.  In scalar context, returns
the number of loses.

=item wins

THIS METHOD IS DEPRECATED - use tournament->player_wins instead.

Returns the won games from the B<games> array.  In scalar context, returns
the number of wins.

=item losses

THIS METHOD IS DEPRECATED - use tournament->player_losses instead.

Returns the lost games from the B<games> array.  In scalar context, returns
the number of losses.

=item drop ( [ $round_num ] )

THIS METHOD IS DEPRECATED - use tournament->get_directive('DROP') instead.

Returns true if DROP flag is set, false if not.  If C<$round_num> is
defined, also checks for DROPn flag where n = C<$round_num>.

=item bye

THIS METHOD IS DEPRECATED - use tournament->get_directive('BYE_CANDIDATE') instead.

Returns true if BYE flag is set, false if not.

=item get_flag ( $name )

=item set_flag ( $name )

=item clear_flag ( $name )

These functions manipulate the AGA flags for a player as expected from the
names.

B<get_flag()> returns the flag if the C<$name> flag is set for this player,
false if it is not.

For string matching, C<$name> is always set to upper-case by this method.

Any C<$name> can be used, but 'BYE', 'DROP', 'DROPn' (where n is a round
number) are recognized by tournament software as significant.

Flags may also be key=value pairs.  The 'club' attribute is really an AGA
key=value pair.

'club', and 'drop*' attributes are actually AGA flags, but they are handled
specially by this object - don't use these functions to manage the 'club'.

=item rating

Returns player's rank/rating field in rating (numeric) format suitable
for direct comparison (eg C<if ($p1->rating > $p2->rating) {...}>).

Note that B<rating> is not settable.  Instead, set the rank/rating to
B<rank>.

=item fprint_register( $file_handle )

Prints the player to $file_handle in register.tde format.

=item fprint_tdlist( $file_handle )

Prints the player to $file_handle in tdlist format.

=back

=head1 ATTRIBUTES

Accessor methods are defined for the following attributes:

=over 4

=item id          Games::Go::AGA::DataObjects::ID

=item last_name   String

=item first_name  String

=item rank        Games::Go::AGA::DataObjects::Rank or ::Rating

=item date        Date of membership (see TDList)

=item membership  Type of membership (see TDList)

=item state       State of residence

=item club        Club affiliation (converted to uppercase)

=item flags       Flags as defined by the AGA

=item comment     Arbitrary information for this player

=item sigma       Num, rates the trustworthiness of the rank

=item games       Array (ref) of games recorded for this player

=item change_callback   A code ref to a subroutine called whenever the object changes

=item adj_rating  Rating    # rank/rating may change as a tournament progresses

=item handicap_rating

Handicap rating is used during pairing.  For normal handicap tournaments,
this should be left uninitialized in which case it returns the normal
C<rating>.  For B<HANDICAP MIN> tournaments, initialize all players to the
same C<handicap_rating> value before pairing the first round (doesn't
really matter what the value is).

=item comment     String

=item flags       reference to an Array of Strings

When setting flags, pass an array of new flags.  To add flags, do a read/modify/write:

    my $flags = $player->flags;
    push @{$flags}, 'new_flag';
    $player->flags($flags);

Returns a reference to the array of the current flags.

Note that the B<club> field is not added to the B<flags> even though it
is part of the AGA flags field in a register.tde file.  B<club> should
be handled by the caller as necessary.

=back

Accessors are used like this to retrieve an attribute:

    my $id = $player->id;

and like this to set an attribute:

    $player->id("new_id");

All attributes are read/write, and are type-checked on setting.

B<rank> can be either a Games::Go::AGA::DataObjects::Rank (like '4d' or
'15K'), or a Games::Go::AGA::DataObjects::Rating (like 4.5 or -15.5).

=head1 SEE ALSO

=over 4

=item Games::Go::AGA

=item Games::Go::AGA::DataObjects

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
