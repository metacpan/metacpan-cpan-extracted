#===============================================================================
#
#         FILE:  Games::Go::AGA::DataObjects::Register.pm
#
#        USAGE:  use Games::Go::AGA::DataObjects::Register;
#
#      PODNAME:  Games::Go::AGA::DataObjects::Register
#     ABSTRACT:  models AGA register.tde file information
#
#       AUTHOR:  Reid Augustin (REID), <reid@hellosix.com>
#      CREATED:  11/19/2010 03:13:05 PM PST
#===============================================================================


use strict;
use warnings;

package Games::Go::AGA::DataObjects::Register;
use Moo;
use namespace::clean;
use parent 'Games::Go::AGA::DataObjects::Directives';

use Carp;
use Readonly;
use Scalar::Util qw( refaddr looks_like_number );
use IO::File;
use Games::Go::AGA::Parse::Util qw( normalize_ID );
use Games::Go::AGA::Parse::Util qw( Rank_to_Rating );
use Games::Go::AGA::DataObjects::Player;
use Games::Go::AGA::DataObjects::Directives;
use Games::Go::AGA::DataObjects::Types qw( isa_CodeRef isa_ArrayRef isa_HashRef );

our $VERSION = '0.152'; # VERSION

#   has 'directives' => (
#       isa => 'Games::Go::AGA::DataObjects::Directives',
#       is => 'rw',
#       default => sub {
#           Games::Go::AGA::DataObjects::Directives->new();
#       },
#   );
#   has 'comments'   => (
#       isa => 'ArrayRef',
#       is => 'ro',
#       default => sub { [] }
#   );
#   has 'players'    => (
#       isa => 'ArrayRef',
#       is => 'ro',
#       default => sub { [] }
#   );
has change_callback => (
    isa => \&isa_CodeRef,
    is => 'rw',
    lazy => 1,
    default => sub { sub { } }
);
has _bye_candidates => (
    is => 'rw',
);
has _drops => (
    is => 'rw',
);
sub BUILD {
    my ($self) = @_;
    $self->{comments} = [];
    $self->{players} = [];
}

sub directive_is_boolean { return $_[0]->is_boolean($_[1]) }    # proxy to Directives

# hashref of player IDs, each value true or false
sub bye_candidates {
    my ($self) = @_;

    if (not $self->_bye_candidates) {
        my %bye_candidates = map { $_ => $self->get_player($_) }
            split /\s+/, $self->get_directive_value('BYE_CANDIDATES') || '';
        $self->_bye_candidates(\%bye_candidates);
    }
    return $self->_bye_candidates;
}

sub add_bye_candidates {
    my ($self, @candidates) = @_;

    my $bye_candidates_hash = $self->bye_candidates;

    for my $candidate (@candidates) {
        if (not $bye_candidates_hash->{$candidate}) {
            $self->_find_player_idx($candidate);   # croaks if not found
            $self->_bye_candidates(undef);  # force refresh on next ->bye_candidates
            $bye_candidates_hash->{$candidate} = 1;
        }
    }
    if (not $self->_bye_candidates) {
        $self->set_directive_value('BYE_CANDIDATES', join(' ', keys %{$bye_candidates_hash}));
    }
}

sub delete_bye_candidates {
    my ($self, @candidates) = @_;

    my $bye_candidates_hash = $self->bye_candidates;

    my @deleted;
    for my $candidate (@candidates) {
        if ($bye_candidates_hash->{$candidate}) {
            $self->_bye_candidates(undef);  # force refresh on next ->bye_candidates
            push @deleted, $candidate if (delete $bye_candidates_hash->{$candidate});
        }
    }
    if (not $self->_bye_candidates) {
        $self->set_directive_value('BYE_CANDIDATES', join(' ', keys %{$bye_candidates_hash}));
    }
    return @deleted;
}

# arrayref of rounds, each entry a hashref of player IDs, true or false
sub drops {
    my ($self, $round_num) = @_;

    if (not $self->_drops) {
        my @drops;
        for my $ii (0 .. ($self->get_directive_value('ROUNDS') || 7)) {
            my $key = $ii ? "DROP_$ii" : 'DROP_ALL';
            my %round_drops = map { $_ => $self->get_player($_) }
                split /\s+/, $self->get_directive_value($key) || '';
            push @drops, \%round_drops;
        }
        $self->_drops(\@drops);
    }
    return $self->_drops->[$round_num] if (@_ > 1);
    return $self->_drops;
}

sub add_drops {
    my ($self, $round_num, @ids) = @_;

    my $drops_hash = $self->drops($round_num);

    for my $id (@ids) {
        if (not $drops_hash->{$id}) {
            $self->_find_player_idx($id);   # croaks if not found
            $self->_drops(undef);   # force refresh on next ->drops
            $drops_hash->{$id} = 1;
        }
    }
    if (not $self->_drops) {
        $round_num ||= 'All';   # round 0 means All
        $self->set_directive_value("DROP_$round_num", join(' ', keys %{$drops_hash}));
    }
}

sub delete_drops {
    my ($self, $round_num, @ids) = @_;

    if (not defined $round_num) {   # all rounds
        my @dropped_ary;
        my $ii = 0;
        for my $drop_round (@{$self->drops}) {
            $dropped_ary[$ii] = { map { $_ => 1 } $self->delete_drops($ii, @ids) } || {};
            $ii++;
        }
        return @dropped_ary;
    }

    my $drops_hash = $self->drops($round_num);

    my @deleted;
    for my $id (@ids) {
        if ($drops_hash->{$id}) {
            $self->_drops(undef);   # force refresh on next ->drops
            push @deleted, $id if (delete $drops_hash->{$id});
        }
    }
    if (not $self->_drops) {
        $round_num ||= 'All';   # round 0 means All
        $self->set_directive_value("DROP_$round_num", join(' ', keys %{$drops_hash}));
    }
    return @deleted
}

sub changed {
    my ($self) = @_;

    &{$self->change_callback}(@_);
}

sub comments {
    my ($self) = @_;

    return wantarray ? @{$self->{comments}} : $self->{comments};
}

sub add_comment {
    my ($self, $comment) = @_;

    push @{$self->{comments}}, $comment;
}

sub players {
    my ($self) = @_;

    return wantarray ? @{$self->{players}} : $self->{players};
}

sub id_is_duplicate {
    my ($self, $id, $player) = @_;

    # normalize the ID first.  IDs in Players are already normalised.
    $id = normalize_ID($id);
    my @matched = grep { $id eq $_->id } @{$self->{players}};
    my $my_refaddr = refaddr $player || 0;
    foreach my $p (@matched) {
        if (refaddr $p != $my_refaddr) {
            return 1
        }
    }
    return 0;
}

sub add_player { shift->insert_player_at_idx(-1, @_) }

sub insert_player_at_idx {
    my ($self, $idx, $player) = @_;

    my $id = $player->id;
    if (not $id) {
        $id = 1;
        $id++ while ($self->id_is_duplicate("TMP$id", undef));
        $id = "TMP$id";
        $player->id($id);
    }
    if ($self->id_is_duplicate($id, undef)) {
        croak "duplicate ID: $id\n";
    }
#print "insert_player ", $player->id, " at $idx\n";
    if ($idx < 0 or
        $idx > $#{$self->{players}}) {
        push (@{$self->{players}}, $player);
    }
    else {
        splice (@{$self->{players}}, $idx, 0, $player);
    }
    $self->changed;
}

sub get_player_idx {
    my ($self, $idx) = @_;

    return $self->_find_player_idx($idx);
}

sub get_player {
    my ($self, $idx) = @_;

    $idx = $self->_find_player_idx($idx);
    return $self->{players}[$idx];
}

sub delete_player {
    my ($self, $idx) = @_;

    $idx = $self->_find_player_idx($idx);

    my $players = $self->{players};
    if (@{$players->[$idx]->games}) {
        my $id = $players->[$idx]->id;
        croak "Games recorded for $id, can't delete\n";
    }
    my $player = splice(@{$players}, $idx, 1);   # delete and return it
    $self->delete_bye_candidates($player->id);
    $self->delete_drops(undef, $player->id);
#print "delete ", $player->id, "\n";
    $self->changed;
    return $player;
}

sub _find_player_idx {
    my ($self, $idx) = @_;

    my $players = $self->{players};
    if (looks_like_number($idx)) {
        # already what we need
    }
    elsif (ref $idx) {      # must be a Player dataobject
        # find Player object with matching refaddr
        FIND_REFADDR : {
            my $player = $idx;
            my $my_refaddr = refaddr($player);
            for my $ii (0 .. $#{$players}) {
                if (refaddr($players->[$ii]) == $my_refaddr) {
                    $idx = $ii;
                    last FIND_REFADDR;
                }
            }
            my $id = $player->id;
            croak "can't find player at refaddr = $my_refaddr (ID=$id)\n";
        }
    }
    else {
        # find Player with matching ID
        FIND_ID : {
            my $id = normalize_ID($idx);
            for my $ii (0 .. $#{$players}) {
                if ($players->[$ii]->id eq $id) {
                    $idx = $ii;
                    last FIND_ID;
                }
            }
            croak "can't find player matching ID $id\n";
        }
    }
    if ($idx < 0 or
        $idx > $#{$players}) {
        croak "index=$idx is out of bounds\n";
    }
    return $idx;
}

# override some Directives methods so we can intercept
# setting/getting of certain directives (which requires player info)
sub set_directive_value {
    my $self = shift;
    my ($key, $val) = @_;

    if (uc $key eq 'BYE_CANDIDATES') {
        $self->_bye_candidates(undef);  # force refresh on next ->bye_candidates
        if (not $val) {
            return $self->SUPER::delete_directive(@_);
        }
    }
    elsif ($key =~ m/^DROP_(\d+|ALL)$/i) {
        $self->_drops(undef);  # force refresh on next ->drops
        if (not $val) {
            return $self->SUPER::delete_directive(@_);
        }
    }
    return $self->SUPER::set_directive_value(@_);
}

sub get_directive_value {
    my $self = shift;
    my ($key) = $_[0];

    if (uc $key eq 'BAND_BREAKS') {
        return $self->break_bands;
    }
    return $self->SUPER::get_directive_value(@_);
}

# break players into number of bands in BANDS directives
sub break_bands {
    my ($self) = @_;

    my $band_breaks = $self->SUPER::get_directive_value('BAND_BREAKS');
    return $band_breaks if ($band_breaks);

    my $num_bands = $self->get_directive_value('BANDS');
    return if (not $num_bands       # no BANDS directive and not BAND_BREAKS
                or $num_bands == 1); # everyone is in same band

    my @players = $self->players;
    my %entrants_per_rating;
    for my $player (@players) {
        $entrants_per_rating{int $player->rating}++;     # count entrants of each rating
    }
    my @sorted_ranks = sort {$b <=> $a} keys %entrants_per_rating;
    my $running_total = 0;
    my $ii = 0;
    my @band_breaks;
    for my $band (1 .. $num_bands - 1) {
        last if ($ii >= @sorted_ranks);
        my $next_break = $band * (@players / $num_bands);
        while ($running_total + $entrants_per_rating{$sorted_ranks[$ii]} < $next_break) {
            $running_total += $entrants_per_rating{$sorted_ranks[$ii++]};
        }
        if (($running_total + ($entrants_per_rating{$sorted_ranks[$ii]} / 2) < $next_break)) {
            $running_total += $entrants_per_rating{$sorted_ranks[$ii++]};
        }
#print "$running_total to band $band=$sorted_ranks[$ii - 1]\n";
        push(@band_breaks, $sorted_ranks[$ii - 1]);
    }
    $band_breaks = join ' ', @band_breaks;
    $self->set_directive_value('BAND_BREAKS', $band_breaks);
    return $band_breaks;
}

sub bands {
    my ($self) = @_;

    my @breaks = split /[^\d\.\-]+/, ($self->get_directive_value('BAND_BREAKS') || '');
    return wantarray
        ? @breaks
        : \@breaks;
}

sub which_band_is {
    my ($self, $rating) = @_;

    my $bands = $self->bands;
    return 0 if (@{$bands} < 1);        # one or no bands defined, all players are in band 0

    $rating = Rank_to_Rating($rating);  # make sure it's numeric
    my $idx;
    for ($idx = 0; $idx < @{$bands}; $idx++) {  # go past the end
        my $limit = $bands->[$idx];
        if ($limit < 0 and
            $limit == int $limit) { # -2.0 means entire 2K range down to -2.9999,
            $limit = $limit - 1;    #   but -2.5 really means -2.5.
            last if ($rating > $limit);     # dan: -3.0 is a 3 kyu
        }
        else {
            last if ($rating >= $limit);    # dan: 3.0 is a 3 dan
        }
    }
    return $idx;
}

sub fprint {
    my ($self, $fh) = @_;

    $self->SUPER::fprint($fh);        # print the directives
    foreach my $comment ($self->comments) {
        $fh->print("#$comment\n");
    }
    foreach my $player ($self->players) {
        $player->fprint_register($fh);
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Games::Go::AGA::DataObjects::Register - models AGA register.tde file information

=head1 VERSION

version 0.152

=head1 SYNOPSIS

  use Games::Go::AGA::DataObjects::Register;

  my $reg = Games::Go::AGA::DataObjects::Register->new();

  $reg->insert_player_at_idx($idx, $player);

  my $player_list = $reg->players;  # get ref to list of players

=head1 DESCRIPTION

A Games::Go::AGA::DataObjects::Register represents the information in a
B<register.tde> file.  B<register.tde> contains tournemant registration
information for an American Go Association (AGA) go tournament.  The format
is like this:

  ## directive
  # comment
  id last name, first name  rank  CLUB=club DROP # COMMENT

These three types of line are stored in this object in the corresponding
attributes:

=over 8

=item comments    ref to Array (full line comments, in order)

=item players     ref to Array of Games::Go::AGA::DataObjects::Player

=item directives  a Games::Go::AGA::DataObjects::Directives object

=back

Directives are global configuration for the tournament, and include such
things as TOURNEY (the tournament name), RULES (e.g. Ing or AGA), etc.

B<id> is single token, unique per player (usually the AGA ID).

Following B<id> to the first comma (',') is the player's B<last_name>.

Following the comma to the B<rank> is the B<first_name>.

B<rank> is either an integer followed by D, d, K, or k (for dan or kyu), or
it is a decimal number less than 20 and greater than -100 but excluding the
range from .9999 to -.9999 where positive numbers represent dan and
negative represent kyu.  The convention is that a decimal number (rating)
represents a more reliable estimate than a D/K representation (rank).
Note: the TDListN.txt file from the AGA includes ratings of 0.0 to indicate
unknown rank.  Converting these to (i.e.) 30k is reasonable.

B<CLUB=...> is optional.  A tournament pairing system may choose to
avoid pairing players who belong to the same club.

B<DROP> is optional and indicates the players who will not participate in
any future rounds.  An enhancement is to allow B<DROPn> where 'n' indicates
specific round numbers to drop.

B<COMMENT> is optional and may contain any information.

=head1 METHODS

=over

=item comments

Returns a reference to a copy of the comments list.  Since this is a copy,
you cannot add or remove comments by altering this list.

=item players

In array context, returns a copy of the players list.  Since this is a
copy, you cannot add or remove players by altering this list.

In scalar context, returns a reference to the player list.

=item id_is_duplicate ($id, $player | undef )

B<$id> is normalized and checked for validity.  If valid, it is checked for
duplicatation in the existing list of players.  If B<$player> is defined
and in the list, matching B<$player>'s ID is not considered a duplication.
To check against all existing players, pass explicit an 'undef' parameter:

    $register->id_is_duplicate($id, undef);

=item insert_player_at_idx ($idx, $player)

B<$player> is a Games::Go::AGA::DataObjects::Player to be added to the
players array.  B<$idx> is the index of the player to insert before.  If
B<$idx> is out of bounds (-1 for example), adds B<$player> to the end of
the list.

Throws an error if B<$player>'s B<id > duplicates an existing ID.

=item get_player_idx ($player)     # index of player in list

=item get_player ($player)         # actual player object

These methods find and return a player index (in the B<players> list), or
the Games::Go::AGA::DataObjects::Player.  B<$player> can be any of:

=over 8

=item the ID of the player to retrieve

=item the index of the player

=item a Games::Go::AGA::DataObjects::Player object

=back

Throws an exception if B<$player> is not found or is out of bounds.

=item delete_player ($player)

Removes and returns a Games::Go::AGA::DataObjects::Player.  B<$player> may
be any of the items listed for B<get_player>, and throws an exception in
the same circumstances.

=item @band_breaks = bands()

Bands are used to divide a tournament into groups for the purpose of
allocating awards.  For example, all Dan players might be in one band while
the kyu players are divided into two bands: 10k and stronger, and 11K and
below.  Standings are then divided into these three groups.

Bands are defined with the BAND_BREAKS directive which is a sequence of
ranks where the listed rank is always included in the group above that
rank.  For the example above with three bands:

    ## BAND_BREAKS 1D 10K

indicates the two band breaking points, and includes 9D to 1D players in
the top group, 1K to 10K players in the middle group, and all others in
the bottom group.

BAND_BREAKS may be entered in any order, but they will always be sorted in
top down order (stronger breaks first).  Ranks (2K, 3D) will be converted
to Ratings (numerical) and integerizedd. A rank of 2D, for example,
converts to a rating of 2.5.  For bands, we want to include all 2Ds, from
2.0 to just below 3.0 in the same group.  Converting to integers
accomplishes this. Break points entered as Ratings (numeric) should also be
integers (or like 2.0), but they will not be integerized, so you can split
a in the middle of rank groups if you wish.

There is also a BANDS directive which declares how many bands to break the
tournament into.  If there is a BANDS directive but no BAND_BREAKS
directive, then as soon as any band-related fetch occurs, this module
attempts to find the best breaking points so as to place aproximately equal
numbers of players in each band.  This process creates a BAND_BREAKS
directive.

For backwards compatibility, BAND (singular) directives are supported on
entry, but will be converted to a BAND_BREAKS directive for read back.

The B<bands()> method returns an array (or in scalar context, a reference
to an array) whose elements are the band breaking points (as numerical
ratings, not ranks).  If there is no BAND_BREAKS directives, a single,
all-inclusive band is assumed and this function returns an array consisting
of -99 (99K).

The first element of the array is the rating above which a player falls
into the top band (between 9D and the first element).  A rating that is less
than the first element and greater than the second element falls into the
second strongest band, and so on.

=item $band_idx = which_band_is($rank_or_rating);

Returns the index of the band that B<$rank_or_rating> falls into.  If there
is no BAND_BREAKS directive, a single, all-inclusive band is assumed and
this function returns 0 for all B<$rank_or_rating>s.

B<$band_idx> 0 is the strongest band with higher B<$band_idx>s being lower in rank.

=back

=head1 ATTRIBUTES

Accessor methods are defined for the following attributes:

=over 8

=item comments          ref to Array (full line comments, in order)

=item directives        a Games::Go::AGA::DataObjects::Directives object

=item change_callback   reference to a function to call after a change

=back

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
