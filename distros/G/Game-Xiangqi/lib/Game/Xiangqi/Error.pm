package Game::Xiangqi::Error;

use 5.010;
use strict;
use warnings;

use Object::Proto::Sugar -types;

our $VERSION = '0.01';

our @FLAGS;
BEGIN {
    @FLAGS = qw(
        bad_move
        game_over
        not_your_turn
        no_piece
        own_piece
        not_legal

        in_check
        generals_face

        general_leaves_palace
        advisor_leaves_palace
        elephant_crosses_river
        elephant_eye_blocked
        horse_leg_blocked
        cannon_needs_one_screen
        soldier_no_retreat
        soldier_no_sideways
    );
}

our %MESSAGE;
BEGIN {
    %MESSAGE = (
        bad_move                => 'that is not a move',
        game_over               => 'the game is already over',
        not_your_turn           => 'it is not your turn',
        no_piece                => 'there is no piece there',
        own_piece               => 'one of your own pieces is already there',
        not_legal               => 'that piece cannot move there',

        in_check                => 'that would leave your general in check',
        generals_face           => 'that would leave the two generals facing each other',

        general_leaves_palace   => 'the general never leaves its palace',
        advisor_leaves_palace   => 'the advisor never leaves its palace',
        elephant_crosses_river  => 'the elephant never crosses the river',
        elephant_eye_blocked    => 'the elephant is blocked at its eye',
        horse_leg_blocked       => 'the horse is hobbled at its leg',
        cannon_needs_one_screen => 'a cannon captures only by jumping exactly one piece',
        soldier_no_retreat      => 'a soldier never moves backward',
        soldier_no_sideways     => 'a soldier moves sideways only once it has crossed the river',
    );
}

has [@FLAGS] => (is => 'ro');

has error => (is => 'ro', default => 1);

has message => (is => 'ro', isa => Str, default => '');

has legal => (is => 'ro', isa => ArrayRef, default => []);

sub throw {
    my ($class, $flag, %extra) = @_;
    die "Game::Xiangqi::Error: no such flag '$flag'" unless exists $MESSAGE{$flag};
    return $class->new(
        $flag   => 1,
        error   => 1,
        message => $MESSAGE{$flag},
        %extra,
    );
}

sub code {
    my ($self) = @_;
    for my $flag (@FLAGS) {
        return $flag if $self->$flag;
    }
    return undef;
}

sub stringify { $_[0]->message }

sub flags { @FLAGS }

sub message_for { $MESSAGE{ $_[1] } }

sub known { exists $MESSAGE{ $_[1] } ? 1 : 0 }

1;

__END__

=head1 NAME

Game::Xiangqi::Error - a flagged refusal, returned and never thrown

=head1 SYNOPSIS

    my $refusal = $game->play('c4e6');

    if ($refusal) {
        say $refusal->code;         # 'elephant_crosses_river'
        say $refusal->message;      # 'the elephant never crosses the river'
        say 1 if $refusal->elephant_crosses_river;
    }

=head1 DESCRIPTION

A refused move comes back as one of these. It is B<not> thrown, and that is a
decision rather than an oversight: a refused move is an ordinary thing for a
player to do, and unwinding the stack for it would make every caller wrap every
move in an C<eval>. C<die> is kept for programmer error: a flag that does not
exist.

Sixteen flags, one of them set. Six are structural (C<bad_move>, C<game_over>,
C<not_your_turn>, C<no_piece>, C<own_piece>, C<not_legal>), two are about the
general (C<in_check>, C<generals_face>), and nine name one rule of the game each.
The nine exist so a refusal tells a player B<which rule they broke> rather than
"no": somebody told their elephant cannot cross the river does not come back and
argue.

C<Game::Xiangqi::Engine> is the layer underneath and does not use this class: its
own C<play> returns the flag as a plain string, because the engine is a skin over
the C ABI and knows nothing about the Perl layers above it.

=head1 ATTRIBUTES

=head2 bad_move

=head2 game_over

=head2 not_your_turn

=head2 no_piece

=head2 own_piece

=head2 not_legal

=head2 in_check

=head2 generals_face

=head2 general_leaves_palace

=head2 advisor_leaves_palace

=head2 elephant_crosses_river

=head2 elephant_eye_blocked

=head2 horse_leg_blocked

=head2 cannon_needs_one_screen

=head2 soldier_no_retreat

=head2 soldier_no_sideways

One accessor per reason, true on the one that applies and false on the rest.

C<not_legal> is the answer of last resort and the nine rule flags exist to keep it
rare: it means the move is not in the legal list and no rule of the piece explains
why. C<in_check> and C<generals_face> are told apart because they are different
mistakes, one of them the flying general, and a player told the wrong one learns
the wrong rule.

=head2 error

Always 1. It is there so that a caller holding something which may be a move or
may be a refusal can ask one question of either.

=head2 message

The sentence for the flag, as a player should be shown it.

=head2 legal

The legal alternatives where offering them helps. B<An arrayref even when empty>,
because the normal case is a caller dereferencing it without checking.

=head1 METHODS

=head2 throw

    Game::Xiangqi::Error->throw('in_check');
    Game::Xiangqi::Error->throw('not_legal', legal => \@iccs);

B<Returns> the refusal. It does not die. The name is the house's.

Dies only if the flag does not exist, which is programmer error.

=head2 code

The flag that is set, as a string, or C<undef>. This is what an adapter maps to
its own vocabulary.

=head2 stringify

The message. There is deliberately no C<""> overload: a refusal that quietly
turned into a sentence when it was used as a hash key would be a worse bug than
one that looks like a reference.

=head2 flags

    my @names = Game::Xiangqi::Error->flags;

A class method: the list of every refusal name, in C<@FLAGS> order. An adapter
mapping these to its own codes should assert against B<this list> rather than
against a copy of it.

=head2 message_for

    Game::Xiangqi::Error->message_for('in_check');
    # 'that would leave your general in check'

A class method: the sentence for one flag without building a refusal, or C<undef>
for a name that is not one. The instance's own sentence is C<message>.

=head2 known

    Game::Xiangqi::Error->known($flag);      # 1 or 0

A class method: whether that name is a refusal this distribution can return.

=head1 SEE ALSO

L<Game::Xiangqi>, which returns these; L<Game::Xiangqi::Engine>, which does not.

=cut
