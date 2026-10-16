package Game::Shogi::Engine;

use 5.014;
use strict;
use warnings;

use Carp ();
use Exporter 'import';
use Object::Proto::Sugar;

our $VERSION = '0.01';

require XSLoader;
XSLoader::load('Game::Shogi', $VERSION);

use constant {
    SQUARES    => 81,
    FILES      => 9,
    RANKS      => 9,
    BLACK      => 0,
    WHITE      => 1,
    EMPTY      => 0,
    OFF        => 64,
    SET_PIECES => 40,
    SFEN_MAX   => 256,
    MOVE_MAX   => 999999,
    MOVES_MAX  => 1024,
};

use constant {
    PAWN       => 1,
    LANCE      => 2,
    KNIGHT     => 3,
    SILVER     => 4,
    GOLD       => 5,
    BISHOP     => 6,
    ROOK       => 7,
    KING       => 8,
    TOKIN      => 9,
    PRO_LANCE  => 10,
    PRO_KNIGHT => 11,
    PRO_SILVER => 12,
    HORSE      => 13,
    DRAGON     => 14,
};

use constant {
    POS_OK      => 0,
    POS_NULL    => 1,
    POS_LONG    => 2,
    POS_FIELDS  => 3,
    POS_RANKS   => 4,
    POS_LETTER  => 5,
    POS_WIDTH   => 6,
    POS_PROMOTE => 7,
    POS_SIDE    => 8,
    POS_HAND    => 9,
    POS_MOVE    => 10,
    POS_KINGS   => 11,
    POS_COUNT   => 12,
};

use constant {
    DROP_OK        => 0,
    DROP_BAD       => 1,
    DROP_NOT_HELD  => 2,
    DROP_OCCUPIED  => 3,
    DROP_DEAD      => 4,
    DROP_TWO_PAWNS => 5,
    DROP_IN_CHECK  => 6,
    DROP_PAWN_MATE => 7,
};

use constant {
    FAULT_OK                  => 0,
    FAULT_BAD                 => 1,
    FAULT_NOT_YOURS           => 2,
    FAULT_NOT_HELD            => 3,
    FAULT_CANNOT_REACH        => 4,
    FAULT_OCCUPIED            => 5,
    FAULT_PROMOTE_NOT_ALLOWED => 6,
    FAULT_PROMOTE_REQUIRED    => 7,
    FAULT_DEAD                => 8,
    FAULT_TWO_PAWNS           => 9,
    FAULT_IN_CHECK            => 10,
    FAULT_PAWN_MATE           => 11,
};

use constant {
    DECLARE_OK          => 0,
    DECLARE_NO_KING     => 1,
    DECLARE_FEW_PIECES  => 2,
    DECLARE_IN_CHECK    => 3,
    DECLARE_FEW_POINTS  => 4,
    DECLARE_PIECES      => 10,
    DECLARE_POINTS_BLACK => 28,
    DECLARE_POINTS_WHITE => 27,
    PACKED              => 96,
    REP_TIMES           => 4,
};

use constant {
    MATE_SCORE          => 30000,
    MATE_BOUND          => 29000,
    EVAL_NO_HAND_BONUS  => 1,
    EVAL_NO_KING_SAFETY => 2,
    EVAL_NO_ENTERING    => 4,
    SEARCH_NO_MATE      => 8,
};

our @EXPORT_OK = qw(
    SQUARES FILES RANKS BLACK WHITE EMPTY OFF SET_PIECES SFEN_MAX MOVE_MAX MOVES_MAX
    PAWN LANCE KNIGHT SILVER GOLD BISHOP ROOK KING
    TOKIN PRO_LANCE PRO_KNIGHT PRO_SILVER HORSE DRAGON
    POS_OK POS_NULL POS_LONG POS_FIELDS POS_RANKS POS_LETTER POS_WIDTH POS_PROMOTE
    POS_SIDE POS_HAND POS_MOVE POS_KINGS POS_COUNT
    DROP_OK DROP_BAD DROP_NOT_HELD DROP_OCCUPIED DROP_DEAD DROP_TWO_PAWNS DROP_IN_CHECK DROP_PAWN_MATE
    FAULT_OK FAULT_BAD FAULT_NOT_YOURS FAULT_NOT_HELD FAULT_CANNOT_REACH FAULT_OCCUPIED
    FAULT_PROMOTE_NOT_ALLOWED FAULT_PROMOTE_REQUIRED FAULT_DEAD FAULT_TWO_PAWNS FAULT_IN_CHECK
    FAULT_PAWN_MATE
    DECLARE_OK DECLARE_NO_KING DECLARE_FEW_PIECES DECLARE_IN_CHECK DECLARE_FEW_POINTS
    DECLARE_PIECES DECLARE_POINTS_BLACK DECLARE_POINTS_WHITE PACKED REP_TIMES
    MATE_SCORE MATE_BOUND EVAL_NO_HAND_BONUS EVAL_NO_KING_SAFETY EVAL_NO_ENTERING SEARCH_NO_MATE
);
our %EXPORT_TAGS = (all => \@EXPORT_OK);

my @REASON = (
    'the position is fine',
    'there is no position',
    'the position is too long',
    'the position is not three or four fields with single spaces between them',
    'the board is not nine ranks',
    'the board has a character that is not a piece, a run of 1 to 9, + or /, or two runs side by side',
    'a rank of the board is not nine squares',
    'a + is not before a pawn, lance, knight, silver, bishop or rook',
    'the side to move is not b or w',
    'the pieces in hand are not - or counted pawns, lances, knights, silvers, golds, bishops and rooks',
    'the move number is not 1 to 999999',
    'one side has two kings',
    'there are more of a piece on the board and in hand than a set has',
);

my @LETTER = (undef, qw(P L N S G B R K));

my @DECLARE_REASON = (
    'the impasse may be declared',
    'the king is not in the enemy camp',
    'there are fewer than ten other pieces in the enemy camp',
    'the king is in check',
    'there are not enough points',
);

my @FAULT_REASON = (
    'the move is allowed',
    'that is not a move',
    'there is no piece of yours there',
    'you have none of that piece in hand',
    'that piece cannot move there',
    'a piece cannot be dropped onto another',
    'that piece may not promote on that move',
    'that piece must promote on that move',
    'a piece cannot be dropped where it could never move',
    'you already have an unpromoted pawn on that file',
    'that would leave your king in check',
    'a pawn may not be dropped to give mate',
);

my @DROP_REASON = (
    'the drop is allowed',
    'that is not a square, or not a piece a hand holds',
    'there is none of that piece in hand',
    'the square is not empty',
    'the piece could never move from there',
    'there is already an unpromoted pawn of the same side on that file',
    'it leaves the king in check',
    'a pawn may not be dropped to give mate',
);
my %KIND = (P => PAWN, L => LANCE, N => KNIGHT, S => SILVER, G => GOLD, B => BISHOP, R => ROOK, K => KING);
my %SIDE = (b => BLACK, w => WHITE);

has _ptr => (is => 'rw', private => 1);

has _hold => (is => 'rw', private => 1);

has _want_empty => (is => 'ro', init_arg => 'empty', private => 1, default => 0);

has _want_sfen => (is => 'ro', init_arg => 'sfen', private => 1);

has _history => (is => 'rw', private => 1);

has _trail => (is => 'rw', private => 1);

has cap => (is => 'ro', default => 500);

my %ADOPTING;

sub BUILD {
    my ($self) = @_;
    my $cap = $self->cap;
    Carp::croak("Game::Shogi::Engine: the cap is a move count of 1 or more, not '" . ($cap // 'undef') . "'")
        unless defined $cap && $cap =~ /\A[0-9]+\z/ && $cap >= 1;
    my $given = $self->_ptr;
    if ($given) {
        if (delete $ADOPTING{$given}) {
            $self->_hold(_hold_board($given));
            return;
        }
        $self->_ptr(0);
        Carp::croak("Game::Shogi::Engine: a board is made by new, from_sfen or clone");
    }

    my $sfen = $self->_want_sfen;
    if (defined $sfen) {
        my ($ptr, $err) = _of_sfen($sfen);
        Carp::croak("Game::Shogi::Engine: the SFEN was refused: $REASON[$err]")
            unless defined $ptr;
        $self->_ptr($ptr);
        $self->_hold(_hold_board($ptr));
        return;
    }

    $self->_ptr($self->_want_empty ? _new_empty() : _new_board());
    Carp::croak("Game::Shogi::Engine: the board was not built") unless $self->_ptr;
    $self->_hold(_hold_board($self->_ptr));
    return;
}

my $adopt = sub {
    my ($class, $ptr, $cap) = @_;
    $ADOPTING{$ptr} = 1;
    return $class->new(_ptr => $ptr, (defined $cap ? (cap => $cap) : ()));
};

sub from_sfen {
    my ($class, $sfen) = @_;
    my ($ptr, $err) = _of_sfen(defined $sfen ? $sfen : '');
    return (undef, $err) unless defined $ptr;
    return ($adopt->(ref($class) || $class, $ptr), POS_OK);
}

sub reason {
    my ($class, $code) = @_;
    return defined $code && $code =~ /\A[0-9]+\z/ ? $REASON[$code] : undef;
}

sub clone {
    my ($self) = @_;
    return $adopt->(ref($self), _copy_board($self->_ptr), $self->cap);
}

sub _token_of {
    my ($piece) = @_;
    return undef if $piece == EMPTY || $piece >= OFF;
    my ($side, $kind) = ($piece >> 4 & 1, $piece & 15);
    my $promoted = $kind > KING;
    my $letter = $LETTER[ $promoted ? _unpromoted($kind) : $kind ];
    $letter = lc $letter if $side == WHITE;
    return ($promoted ? '+' : '') . $letter;
}

sub _piece_of {
    my ($token) = @_;
    return undef unless defined $token && $token =~ /\A(\+?)([PLNSGBRKplnsgbrk])\z/;
    my ($plus, $letter) = ($1, $2);
    my $kind = $KIND{ uc $letter };
    if ($plus) {
        $kind = _promoted($kind);
        return undef unless $kind;
    }
    return (($letter eq lc $letter ? WHITE : BLACK) << 4) | $kind;
}

sub _side_of {
    my ($side) = @_;
    return defined $side ? $SIDE{$side} : undef;
}

sub _hand_kind {
    my ($letter) = @_;
    return undef unless defined $letter && $letter =~ /\A[PLNSGBRplnsgbr]\z/;
    return $KIND{ uc $letter };
}

sub at {
    my ($self, $sq) = @_;
    return undef unless _is_sq($sq);
    return _token_of(_at($self->_ptr, $sq));
}

sub put {
    my ($self, $sq, $token) = @_;
    my $piece = _piece_of($token);
    _put($self->_ptr, $sq, $piece) if _is_sq($sq) && defined $piece;
    return $self;
}

sub lift {
    my ($self, $sq) = @_;
    _lift($self->_ptr, $sq) if _is_sq($sq);
    return $self;
}

sub hand {
    my ($self, $side, $letter) = @_;
    my ($s, $k) = (_side_of($side), _hand_kind($letter));
    return 0 unless defined $s && defined $k;
    return _hand($self->_ptr, $s, $k);
}

sub set_hand {
    my ($self, $side, $letter, $count) = @_;
    my ($s, $k) = (_side_of($side), _hand_kind($letter));
    _set_hand($self->_ptr, $s, $k, $count)
        if defined $s && defined $k && defined $count && $count =~ /\A[0-9]+\z/;
    return $self;
}

sub hands {
    my ($self) = @_;
    my %hands = (b => {}, w => {});
    for my $side (qw(b w)) {
        for my $letter (qw(R B G S N L P)) {
            my $n = $self->hand($side, $letter);
            $hands{$side}{$letter} = $n if $n;
        }
    }
    return \%hands;
}

sub side_to_move { _to_move($_[0]->_ptr) == WHITE ? 'w' : 'b' }

sub set_side_to_move {
    my ($self, $side) = @_;
    my $s = _side_of($side);
    _set_to_move($self->_ptr, $s) if defined $s;
    return $self;
}

sub move_number { _move_number($_[0]->_ptr) }

sub set_move_number {
    my ($self, $n) = @_;
    _set_move_number($self->_ptr, $n) if defined $n && $n =~ /\A[0-9]+\z/ && $n <= MOVE_MAX;
    return $self;
}

sub king_square {
    my ($self, $side) = @_;
    my $s = _side_of($side);
    return undef unless defined $s;
    my $sq = _king_sq($self->_ptr, $s);
    return $sq < 0 ? undef : $sq;
}

sub sfen { _to_sfen($_[0]->_ptr) }
sub key  { _key_hex($_[0]->_ptr) }

sub _is_sq { defined $_[0] && $_[0] =~ /\A[0-9]+\z/ && $_[0] < SQUARES }

sub _move_string {
    my ($m) = @_;
    my $to = __PACKAGE__->square_name(($m >> 7) & 127);
    return $LETTER[ ($m >> 16) & 15 ] . '*' . $to if ($m >> 15) & 1;
    my $from = __PACKAGE__->square_name($m & 127);
    return $from . $to . (($m >> 14) & 1 ? '+' : '');
}

sub _move_of {
    my ($usi) = @_;
    return undef unless defined $usi;
    if ($usi =~ /\A([PLNSGBR])\*([1-9][a-i])\z/) {
        return (1 << 15) | ($KIND{$1} << 16) | (__PACKAGE__->square($2) << 7);
    }
    return undef unless $usi =~ /\A([1-9][a-i])([1-9][a-i])(\+?)\z/;
    my ($from, $to) = (__PACKAGE__->square($1), __PACKAGE__->square($2));
    return $from | ($to << 7) | ($3 ? 1 << 14 : 0);
}

sub attacked {
    my ($self, $sq, $by) = @_;
    my $s = _side_of($by);
    return 0 unless defined $s && _is_sq($sq);
    return _attacked($self->_ptr, $sq, $s) ? 1 : 0;
}

sub in_check {
    my ($self, $side) = @_;
    my $s = _side_of($side);
    return 0 unless defined $s;
    return _in_check($self->_ptr, $s) ? 1 : 0;
}

sub pseudo_moves { map { _move_string($_) } _pseudo_moves($_[0]->_ptr) }
sub board_moves  { map { _move_string($_) } _board_moves($_[0]->_ptr) }

sub do_move {
    my ($self, $usi) = @_;
    my $m = _move_of($usi);
    return 0 unless defined $m;
    my $trail = $self->_trail_now;
    my $record = _do_move($self->_ptr, $m);
    return 0 unless defined $record;
    my $history = $self->_history;
    $self->_history($history = []) unless $history;
    push @$history, $record;
    push @$trail, [ $self->key, _pack($self->_ptr), $self->in_check($self->side_to_move) ];
    return 1;
}

sub undo_move {
    my ($self) = @_;
    my $history = $self->_history;
    return 0 unless $history && @$history;
    return 0 unless _undo_move($self->_ptr, $history->[-1]);
    pop @$history;
    my $trail = $self->_trail;
    pop @$trail if $trail && @$trail > 1;
    return 1;
}

sub drops          { map { _move_string($_) } _drops($_[0]->_ptr) }
sub legal          { map { _move_string($_) } _legal($_[0]->_ptr) }
sub has_legal_move { _has_legal_move($_[0]->_ptr) ? 1 : 0 }

sub drop_fault {
    my ($self, $letter, $sq) = @_;
    my $k = _hand_kind($letter);
    return DROP_BAD unless defined $k && _is_sq($sq) && $letter eq uc $letter;
    return _drop_fault($self->_ptr, $k, $sq);
}

sub drop_reason {
    my ($class, $code) = @_;
    return defined $code && $code =~ /\A[0-9]+\z/ ? $DROP_REASON[$code] : undef;
}

my @PERFT = qw(nodes captures drops promotions checks mates);

sub perft {
    my ($self, $depth) = @_;
    return 0 unless defined $depth && $depth =~ /\A[0-9]+\z/;
    return (_perft($self->_ptr, $depth))[0];
}

sub perft_counts {
    my ($self, $depth) = @_;
    return undef unless defined $depth && $depth =~ /\A[0-9]+\z/;
    my @counts = _perft($self->_ptr, $depth);
    return { map { $PERFT[$_] => $counts[$_] } 0 .. $#PERFT };
}

my @STATUS = qw(ongoing mate no_move);

sub status { $STATUS[ _status($_[0]->_ptr) ] }

sub _other { $_[0] eq 'b' ? 'w' : 'b' }

sub outcome {
    my ($self) = @_;
    my $s = _status($self->_ptr);
    return $self->repetition // $self->_capped unless $s;
    require Game::Shogi::Result;
    return Game::Shogi::Result->new(
        how    => $STATUS[$s],
        winner => _other($self->side_to_move),
        ply    => $self->move_number - 1,
    );
}

sub _trail_now {
    my ($self) = @_;
    my $trail = $self->_trail;
    return $trail if $trail;
    $self->_trail($trail = [ [ $self->key, _pack($self->_ptr), 0 ] ]);
    return $trail;
}

sub packed { _pack($_[0]->_ptr) }

sub evaluate {
    my ($self, $flags) = @_;
    return _evaluate($self->_ptr, defined $flags && $flags =~ /\A[0-9]+\z/ ? $flags : 0);
}

sub history {
    my ($self) = @_;
    my $trail = $self->_trail;
    return () unless $trail && $trail->[-1][1] eq _pack($self->_ptr);
    return map { $_->[0] } @$trail[ 0 .. $#$trail - 1 ];
}

sub search {
    my ($self, %opt) = @_;
    my $budget = $opt{nodes} // 60_000;
    Carp::croak("Game::Shogi::Engine: a search needs a node budget of 1 or more, not '$budget'")
        unless $budget =~ /\A[0-9]+\z/ && $budget >= 1;
    my $history = $opt{history};
    unless (ref $history eq 'ARRAY') {
        my $trail = $self->_trail;
        $history = $trail && $trail->[-1][1] eq _pack($self->_ptr)
            ? [ map { $_->[0] } @$trail[ 0 .. $#$trail - 1 ] ]
            : [];
    }
    my ($move, $nodes, $depth, $score, $stopped) = _search($self->_ptr, $budget, $opt{depth} // 0,
        ($opt{seed} // 0) & 0xFFFFFFFF, $opt{flags} // 0, $history);
    my $usi = $move ? _move_string($move) : undef;
    return $usi unless wantarray;
    return ($usi, { nodes => $nodes, depth => $depth, score => $score, stopped => $stopped });
}

sub repetition {
    my ($self) = @_;
    my $trail = $self->_trail;
    return undef unless $trail && @$trail >= REP_TIMES;
    return undef unless $trail->[-1][1] eq _pack($self->_ptr);
    my ($code, $loser) = _repetition([ map { $_->[0] } @$trail ], [ map { $_->[1] } @$trail ],
                                     [ map { $_->[2] } @$trail ]);
    return undef unless $code;
    require Game::Shogi::Result;
    return Game::Shogi::Result->new(
        how    => $code == 2 ? 'perpetual_check' : 'sennichite',
        winner => $code == 2 ? ($loser == WHITE ? 'b' : 'w') : undef,
        ply    => $self->move_number - 1,
    );
}

sub _capped {
    my ($self) = @_;
    return undef if $self->move_number - 1 < $self->cap || $self->in_check($self->side_to_move);
    require Game::Shogi::Result;
    return Game::Shogi::Result->new(how => 'cap', winner => undef, ply => $self->move_number - 1);
}

sub impasse_points {
    my ($self, $side) = @_;
    my $s = _side_of($side);
    return undef unless defined $s;
    return _impasse_points($self->_ptr, $s);
}

sub impasse_pieces {
    my ($self, $side) = @_;
    my $s = _side_of($side);
    return undef unless defined $s;
    return _impasse_pieces($self->_ptr, $s);
}

sub declare_fault { _declare_fault($_[0]->_ptr) }
sub can_declare   { _declare_fault($_[0]->_ptr) == DECLARE_OK ? 1 : 0 }

sub declare_reason {
    my ($class, $code) = @_;
    return defined $code && $code =~ /\A[0-9]+\z/ ? $DECLARE_REASON[$code] : undef;
}

sub declare {
    my ($self) = @_;
    return undef unless $self->can_declare && !_status($self->_ptr) && $self->move_number - 1 < $self->cap;
    require Game::Shogi::Result;
    return Game::Shogi::Result->new(
        how    => 'impasse_declared',
        winner => $self->side_to_move,
        ply    => $self->move_number - 1,
    );
}

sub resign {
    my ($self, $side) = @_;
    return undef unless defined $side && $side eq $self->side_to_move && !_status($self->_ptr);
    require Game::Shogi::Result;
    return Game::Shogi::Result->new(
        how    => 'resign',
        winner => _other($side),
        ply    => $self->move_number - 1,
    );
}

sub move_fault {
    my ($self, $usi) = @_;
    my $m = _move_of($usi);
    return FAULT_BAD unless defined $m;
    return _move_fault($self->_ptr, $m);
}

sub fault_reason {
    my ($class, $code) = @_;
    return defined $code && $code =~ /\A[0-9]+\z/ ? $FAULT_REASON[$code] : undef;
}

sub moves_made {
    my $history = $_[0]->_history;
    return $history ? scalar @$history : 0;
}

sub abi_version { _abi_version() }
sub live        { _live() }
sub tables_ok   { _tables_ok() }
sub squares     { SQUARES }

sub square {
    my (undef, $name) = @_;
    return undef unless defined $name && $name =~ /\A([1-9])([a-i])\z/;
    return _sq_of($1, ord($2) - ord('a') + 1);
}

sub square_name {
    my (undef, $sq) = @_;
    return undef unless _is_sq($sq);
    return _file_of($sq) . chr(ord('a') + _rank_of($sq) - 1);
}

sub sq_of {
    my (undef, $file, $rank) = @_;
    return undef unless defined $file && defined $rank
        && $file =~ /\A[0-9]+\z/ && $rank =~ /\A[0-9]+\z/;
    my $sq = _sq_of($file, $rank);
    return $sq < 0 ? undef : $sq;
}

sub file_of { _is_sq($_[1]) ? _file_of($_[1]) : undef }
sub rank_of { _is_sq($_[1]) ? _rank_of($_[1]) : undef }

sub step {
    my (undef, $sq, $dfile, $drank) = @_;
    return undef unless _is_sq($sq) && defined $dfile && defined $drank
        && $dfile =~ /\A-?[0-9]+\z/ && $drank =~ /\A-?[0-9]+\z/;
    my $to = _step($sq, $dfile, $drank);
    return $to < 0 ? undef : $to;
}

sub in_zone {
    my (undef, $side, $sq) = @_;
    my $s = _side_of($side);
    return 0 unless defined $s && _is_sq($sq);
    return _in_zone($s, $sq) ? 1 : 0;
}

sub last_distance {
    my (undef, $side, $sq) = @_;
    my $s = _side_of($side);
    return undef unless defined $s && _is_sq($sq);
    return _last_distance($s, $sq);
}

sub promoted {
    my (undef, $token) = @_;
    my $piece = _piece_of($token);
    return undef unless defined $piece && ($piece & 15) <= KING && _promoted($piece & 15);
    return '+' . $token;
}

sub unpromoted {
    my (undef, $token) = @_;
    return undef unless defined _piece_of($token);
    (my $base = $token) =~ s/\A\+//;
    return $base;
}

sub set_count {
    my (undef, $letter) = @_;
    return 0 unless defined $letter && $letter =~ /\A[PLNSGBRKplnsgbrk]\z/;
    return _set_count($KIND{ uc $letter });
}

sub zobrist {
    my (undef, $side, $token, $sq) = @_;
    my ($s, $piece) = (_side_of($side), _piece_of($token));
    return _zobrist_hex(-1, 0, -1) unless defined $s && defined $piece && _is_sq($sq);
    return _zobrist_hex($s, $piece & 15, $sq);
}

sub zobrist_hand {
    my (undef, $side, $letter, $count) = @_;
    my ($s, $k) = (_side_of($side), _hand_kind($letter));
    return _zobrist_hand_hex(-1, 0, 0) unless defined $s && defined $k
        && defined $count && $count =~ /\A[0-9]+\z/;
    return _zobrist_hand_hex($s, $k, $count);
}

sub zobrist_move { _zobrist_move_hex() }

1;

__END__

=head1 NAME

Game::Shogi::Engine - the shogi board: squares, pieces, hands and the key

=head1 SYNOPSIS

    use Game::Shogi::Engine qw(:all);

    my $board = Game::Shogi::Engine->new;
    print $board->sfen, "\n";
    print $board->key, "\n";

    my $sq = Game::Shogi::Engine->square('7g');
    print $board->at($sq), "\n";                      # P

    my ($copy, $code) = Game::Shogi::Engine->from_sfen($board->sfen);
    print Game::Shogi::Engine->reason($code), "\n" unless $copy;

=head1 DESCRIPTION

The board of shogi and nothing that judges a move: the 81 squares and their
names, the promotion zone, the pieces and what each promotes to, the forty
pieces of a set, the two hands, whose turn it is, the move number, a key that
names the position, and the position written as SFEN.

Squares are numbered 0 to 80 in SFEN order: rank a first, and in each rank
file 9 first, so 0 is C<9a>, 8 is C<1a> and 80 is C<1i>. A square also has a
name, its file digit and its rank letter, as USI writes it (C<7g>).

Black moves first in an even game and is written in capitals, and White in
lower case, as SFEN does. A side is C<'b'> or C<'w'>.

A piece is its SFEN token: C<P L N S G B R K> for the base pieces, and C<+P>,
C<+L>, C<+N>, C<+S>, C<+B> and C<+R> for the promoted ones, in lower case for
White.

=head1 CONSTRUCTORS

=head2 new

    Game::Shogi::Engine->new
    Game::Shogi::Engine->new(empty => 1)
    Game::Shogi::Engine->new(sfen => $sfen)

The start of an even game, Black to move, move 1. With C<empty>, every square
and both hands are empty. With C<sfen>, the board that SFEN writes. Croaks
when the SFEN is refused, with the reason.

=head2 from_sfen

    my ($board, $code) = Game::Shogi::Engine->from_sfen($sfen);

The board an SFEN writes, and C<POS_OK>; or C<undef> and the code that says
why the SFEN was refused (see L</reason>). The move number may be left off,
and is then 1.

=head2 clone

A board of its own with the same position.

=head1 THE POSITION

=head2 sfen

The position as SFEN: the board rank a first, C</> between the ranks; the
side to move; the hands, rook to pawn and Black's first, or C<->; the move
number. The start is

    lnsgkgsnl/1r5b1/ppppppppp/9/9/9/PPPPPPPPP/1B5R1/LNSGKGSNL b - 1

=head2 reason

    Game::Shogi::Engine->reason($code)

The refusal code from L</from_sfen> in words. The codes, which are
exportable, are C<POS_OK>, C<POS_NULL>, C<POS_LONG>, C<POS_FIELDS>,
C<POS_RANKS>, C<POS_LETTER>, C<POS_WIDTH>, C<POS_PROMOTE>, C<POS_SIDE>,
C<POS_HAND>, C<POS_MOVE>, C<POS_KINGS> and C<POS_COUNT>, and an SFEN is
checked in that order.

An SFEN is refused for its shape and not for its sense: two pawns on a file,
or a pawn on the last rank, load. The two exceptions are counts a set fixes:
two kings of one side, and more of a piece than a set has.

=head2 key

The position's key as sixteen hex digits. It names every piece, both hands
and the side to move, and not the move number. Two boards with the same key
are the same position.

=head2 at

    $board->at($sq)

The piece on a square as its token, or C<undef> for an empty square or a
number that is not a square.

=head2 put

    $board->put($sq, '+r')

Puts a piece on a square, replacing what was there. It judges nothing: the
key and the kings follow, and a square or a token that is not one is ignored.
Returns the board.

=head2 lift

    $board->lift($sq)

Empties a square. Returns the board.

=head2 hand

    $board->hand('b', 'P')

How many of a piece a side holds in hand. The piece is a base piece, rook to
pawn, in either case.

=head2 set_hand

    $board->set_hand('w', 'R', 1)

Sets how many of a piece a side holds, from 0 to as many as a set has, and
keeps the key. Anything else is ignored. Returns the board.

=head2 hands

Both hands as a hash reference, C<< { b => { P => 2 }, w => {} } >>, each
holding only the pieces it has.

=head2 side_to_move

C<'b'> or C<'w'>.

=head2 set_side_to_move

Makes it a side's turn. Returns the board.

=head2 move_number

The move number, as SFEN counts it: 1 for the first move of the game, and one
more for each move by either side.

=head2 set_move_number

Sets it, from 1 to C<MOVE_MAX>. Returns the board.

=head2 king_square

    $board->king_square('b')

The square of a side's king, or C<undef> when it has none. Where L</put> has
given a side two, it is the one put last.

=head1 THE BOARD MOVES

A move is its USI string: the square it leaves, the square it reaches, and a
C<+> when it promotes, as C<7g7f> or C<8h2b+>. Where promotion is optional a
move is listed twice, with the C<+> first; where it is forced, only with it.
A drop is the piece's letter in capitals, for either side, a C<*> and the
square, as C<P*5e>.

=head2 attacked

    $board->attacked($sq, 'w')

True when a piece of that side could move onto the square now, whatever
stands there, and whatever the move would do to its own king.

=head2 in_check

    $board->in_check('b')

True when a side's king is attacked; false when it is not, or it has none.

=head2 pseudo_moves

Every move of the side to move's pieces on the board, without asking whether
it leaves its own king attacked, square by square in square order.

=head2 board_moves

The same, less every move that leaves the mover's own king attacked. A side
with no king has them all.

=head2 do_move

    $board->do_move('7g7f')

Makes a move: anything on the square it reaches goes into the mover's hand as
its base piece, the piece promotes if the move says so, the turn passes and
the move number counts on. Returns 1, or 0 and changes nothing when the move
is not a piece of the side to move, lands on its own piece, promotes a piece
that cannot, takes a king, or would fill a hand past the set. It does B<not>
ask whether the piece moves that way or whether the king is safe: take moves
from L</board_moves> for that.

=head2 undo_move

Takes back the last move L</do_move> made on this board. Returns 1, or 0 when
there is none, or when the board no longer shows it (a L</put>, L</lift> or
setter since has changed it). A L</clone> starts with no moves to take back.

=head2 moves_made

How many moves L</do_move> has made on this board and L</undo_move> has not
taken back.

=head1 THE DROPS

A piece in hand may be dropped on any empty square, unpromoted, except: a
pawn or lance on the last rank or a knight on either of the last two, where
it could never move; a pawn on a file where its side already has an
unpromoted pawn; and a pawn dropped to give mate. Like any move, a drop may
not leave its own king attacked. L</do_move> makes a drop of a piece in hand
onto an empty square and asks none of these; L</drops> and L</legal> list
only the drops that pass them all.

=head2 drops

The legal drops of the side to move: each piece it holds in the order rook,
bishop, gold, silver, knight, lance, pawn, and for each, every square it may
go on in square order.

=head2 legal

Every legal move of the side to move: L</board_moves>, then L</drops>.

=head2 has_legal_move

True when the side to move has a legal move.

=head2 drop_fault

    $board->drop_fault('P', $sq)

Why the side to move may not drop that piece there, as a code, or
C<DROP_OK>. The piece is a capital letter, rook to pawn. The codes, which are
exportable, are C<DROP_OK>, C<DROP_BAD>, C<DROP_NOT_HELD>, C<DROP_OCCUPIED>,
C<DROP_DEAD>, C<DROP_TWO_PAWNS>, C<DROP_IN_CHECK> and C<DROP_PAWN_MATE>,
asked in that order.

=head2 drop_reason

    Game::Shogi::Engine->drop_reason($code)

A drop code in words.

=head2 perft

    $board->perft(4)

How many sequences of legal moves of that many plies there are from the
board. It leaves the board as it was.

=head2 perft_counts

    my $c = $board->perft_counts(5);

The same, with the last ply's moves counted by what they are, as a hash
reference: C<nodes>, C<captures>, C<drops>, C<promotions>, C<checks> and
C<mates>.

=head1 HOW A POSITION ENDS

A side with no legal move has lost: when it is in check that is mate, and
when it is not, every move left to it would break a rule, which in shogi
loses too. Repetition and the impasse need the game's history, which a board
does not keep.

=head2 status

C<'ongoing'>, C<'mate'> or C<'no_move'>, for the side to move.

=head2 outcome

A L<Game::Shogi::Result> when the side to move has lost, or C<undef> while
it has a move.

=head2 resign

    my $result = $board->resign('b');

A L<Game::Shogi::Result> for that side resigning. Only the side to move may,
and only while it has a move; anything else is C<undef>. It does not change
the board.

=head2 move_fault

    $board->move_fault('5h4h')

Why the side to move may not make a move, as a code, or C<FAULT_OK>
exactly for the moves L</legal> lists. A move with two faults gives the one
asked first: whose piece it is, whether a drop is held, whether the piece
reaches, whether a drop's square is empty, whether the promotion is right,
whether a drop could ever move, two pawns, the king, and the pawn-drop mate.
The codes, which are exportable, are C<FAULT_OK>, C<FAULT_BAD>,
C<FAULT_NOT_YOURS>, C<FAULT_NOT_HELD>, C<FAULT_CANNOT_REACH>,
C<FAULT_OCCUPIED>, C<FAULT_PROMOTE_NOT_ALLOWED>, C<FAULT_PROMOTE_REQUIRED>,
C<FAULT_DEAD>, C<FAULT_TWO_PAWNS>, C<FAULT_IN_CHECK> and C<FAULT_PAWN_MATE>.

=head2 fault_reason

    Game::Shogi::Engine->fault_reason($code)

A fault code in words, as a player would read it.

=head1 WHAT NEEDS THE HISTORY

A board keeps the positions L</do_move> has reached on it, from the one it held
when L</do_move> was first called, and L</undo_move> takes them back off. A
L</clone> starts with none. Changing the board any other way (L</put>,
L</lift>, a setter) does not add to them, and repetition is not judged until
the board is again the last position they hold.

=head2 cap

The move count at which a game stops as a draw: 500 unless C<new> is given
another (C<< cap => 300 >>). At the cap, a side in check plays on until it is
not. Y line 128 is the Japan Shogi Association's rule.

=head2 outcome

As well as mate and no move: C<sennichite>, a draw, when the position stands
for the fourth time; C<perpetual_check>, a loss for the side that gave check
with every move since it first stood; and C<cap>, a draw, at the cap.

=head1 THE SEARCH

=head2 evaluate

    $board->evaluate
    $board->evaluate(EVAL_NO_KING_SAFETY)

The position's worth to the side to move, in centipawns: the pieces on the
board and in hand (a piece in hand worth a little more), its king's guards
and attackers, and a bonus for a king in the enemy camp. The flags turn terms
off, for measuring what each is worth.

=head2 search

    my $usi = $board->search(nodes => 60_000, seed => $n);
    my ($usi, $info) = $board->search(nodes => 60_000, depth => 4, flags => SEARCH_NO_MATE);

The move to play, found by an alpha-beta search of at most C<nodes> nodes
(60,000 when not given) and C<depth> plies (no ceiling when not given), its
equal-scoring moves told apart by C<seed>. C<history>, an array reference of the keys of
the positions the game stood in before this one, defaults to L</history>; a
position reached again scores as a draw. C<undef> when the side to move has no
move. In list context, also C<nodes>, C<depth> (the deepest iteration
finished), C<score> and C<stopped> in a hash reference. The budget is in nodes
and never in time, so a search plays the same move on any machine, and it
leaves the board as it was.

=head2 history

The keys of the positions L</do_move> reached before this one, oldest first:
what L</search> treats as already stood in. Empty for a clone, and when the
board has been changed another way since.

=head2 packed

The position as PACKED bytes: the squares, both hands and the side to move,
not the move number. Two boards with the same bytes are the same position
as repetition counts one.

=head2 repetition

A L<Game::Shogi::Result> for the fourth time the position stands, or C<undef>.

=head2 impasse_points

    $board->impasse_points('b')

The points a side would declare with: a rook or bishop, promoted or not, 5,
any other piece 1, counting only its pieces in the enemy camp (not the king)
and its hand.

=head2 impasse_pieces

How many of a side's pieces, not the king, stand in the enemy camp.

=head2 declare_fault

Why the side to move may not declare the impasse, or C<DECLARE_OK>: its king
is in the enemy camp, ten of its other pieces are there, it is not in check,
and it has 28 points as Black or 27 as White, asked in that order. The codes
are exportable: C<DECLARE_OK>, C<DECLARE_NO_KING>, C<DECLARE_FEW_PIECES>,
C<DECLARE_IN_CHECK> and C<DECLARE_FEW_POINTS>.

=head2 can_declare

True when the side to move may declare.

=head2 declare_reason

A declaration code in words.

=head2 declare

A L<Game::Shogi::Result> for the side to move declaring the impasse and
winning, or C<undef> when it may not, the game is already over, or the cap
has been reached. It does not change the board.

=head1 THE BOARD

These are the same for every board, and may be called on the class.

=head2 squares

81.

=head2 square

    Game::Shogi::Engine->square('7g')

The square a name names, or C<undef>.

=head2 square_name

The name of a square, as USI writes it.

=head2 sq_of

    Game::Shogi::Engine->sq_of($file, $rank)

The square at a file and a rank, each 1 to 9, rank 1 being rank a. C<undef>
off the board.

=head2 file_of

The file of a square, 1 to 9.

=head2 rank_of

The rank of a square, 1 for rank a to 9 for rank i.

=head2 step

    Game::Shogi::Engine->step($sq, $dfile, $drank)

The square that many files and ranks away, or C<undef> off the board. A
C<$drank> of -1 is towards rank a, which is forward for Black. Only one file
across and two ranks along are served, which is as far as any single step or
a knight's jump goes; anything wider is C<undef>.

=head2 in_zone

    Game::Shogi::Engine->in_zone('b', $sq)

True for the three ranks furthest from a side, where its pieces may promote.

=head2 last_distance

    Game::Shogi::Engine->last_distance('w', $sq)

How many ranks lie beyond a square as a side faces: 0 on the furthest rank, 8
on its own back rank.

=head2 promoted

    Game::Shogi::Engine->promoted('S')      # +S

The token of what a piece promotes to, or C<undef> for a gold, a king or a
piece already promoted.

=head2 unpromoted

    Game::Shogi::Engine->unpromoted('+r')   # r

The base piece of a token. A base piece is its own.

=head2 set_count

    Game::Shogi::Engine->set_count('P')     # 18

How many of a base piece a whole set has, both sides together.

=head2 zobrist

=head2 zobrist_hand

=head2 zobrist_move

    Game::Shogi::Engine->zobrist('b', '+R', $sq)
    Game::Shogi::Engine->zobrist_hand('w', 'P', 3)
    Game::Shogi::Engine->zobrist_move

The numbers the key is made of, as hex: one for each piece of each side on
each square, one for each count of each piece in each side's hand, and one
for White to move. A hand of none is all zeros.

=head1 FOR TESTS

=head2 abi_version

The version of the board's C interface.

=head2 tables_ok

True when the board was built and every count agreed with what it should be.

=head2 live

How many boards exist and have not been let go.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
