package Game::Xiangqi::Notation;

use 5.010;
use strict;
use warnings;

use Game::Xiangqi::Engine ':all';

our $VERSION = '0.01';

my $E = 'Game::Xiangqi::Engine';

my %LETTER = (
    GENERAL()  => 'K',
    ADVISOR()  => 'A',
    ELEPHANT() => 'E',
    CHARIOT()  => 'R',
    HORSE()    => 'H',
    CANNON()   => 'C',
    SOLDIER()  => 'P',
);

my %DIAGONAL = (ADVISOR() => 1, ELEPHANT() => 1, HORSE() => 1);

sub iccs_of {
    my ($class, $mv) = @_;
    my ($from, $to) = ($E->move_from($mv), $E->move_to($mv));
    return undef unless $E->on_board($from) && $E->on_board($to);
    return sprintf('%s%d%s%d',
        ('a' .. 'i')[ $E->file_of($from) ], $E->rank_of($from),
        ('a' .. 'i')[ $E->file_of($to) ],   $E->rank_of($to));
}

sub move_of_iccs {
    my ($class, $s) = @_;
    return undef unless defined $s && $s =~ /\A([a-i])([0-9])([a-i])([0-9])\z/;
    my %f = map { ('a' .. 'i')[$_] => $_ } 0 .. 8;
    return $E->move($E->point_of($f{$1}, $2), $E->point_of($f{$3}, $4));
}

sub wxf_file {
    my ($class, $file, $colour) = @_;
    return $colour == RED ? 9 - $file : $file + 1;
}

sub wxf_of {
    my ($class, $board, $mv) = @_;
    my ($from, $to) = ($E->move_from($mv), $E->move_to($mv));
    my $piece = $board->at($from);
    return undef unless $piece && $piece != BORDER;

    my $colour = Game::Xiangqi::Engine::colour_of($piece);
    my $kind   = Game::Xiangqi::Engine::kind_of($piece);
    my $letter = $LETTER{$kind} or return undef;

    my ($ff, $fr) = ($E->file_of($from), $E->rank_of($from));
    my ($tf, $tr) = ($E->file_of($to),   $E->rank_of($to));

    my @same = grep {
        $board->at($_) == $piece && $E->file_of($_) == $ff
    } $E->all_points;

    my $head;
    if (@same > 1) {
        my @order = sort {
            $colour == RED ? $E->rank_of($b) <=> $E->rank_of($a)
                           : $E->rank_of($a) <=> $E->rank_of($b)
        } @same;
        my ($idx) = grep { $order[$_] == $from } 0 .. $#order;
        $head = @same == 2 ? ($idx == 0 ? "+$letter" : "-$letter")
                           : ($idx + 1) . $letter;
    }
    else {
        $head = $letter . $class->wxf_file($ff, $colour);
    }

    my $dir = $tr == $fr ? '.'
            : ($colour == RED ? ($tr > $fr ? '+' : '-')
                              : ($tr < $fr ? '+' : '-'));

    my $tail = $dir eq '.'            ? $class->wxf_file($tf, $colour)
             : $DIAGONAL{$kind}       ? $class->wxf_file($tf, $colour)
             :                          abs($tr - $fr);

    return "$head$dir$tail";
}

1;

__END__

=head1 NAME

Game::Xiangqi::Notation - ICCS coordinates, and WXF for the reader

=head1 SYNOPSIS

    use Game::Xiangqi::Notation;
    my $N = 'Game::Xiangqi::Notation';

    $N->iccs_of($mv);              # 'h2e2'
    $N->move_of_iccs('h2e2');      # the packed move back
    $N->wxf_of($board, $mv);       # 'C2.5'

=head1 THE LOG STORES ICCS AND CARRIES WXF BESIDE IT

B<ICCS coordinates are what C<play> takes and what a replay walks.> A file
letter C<a> to C<i> from Red's left and a rank digit C<0> to C<9> from Red's own
side, so a move is four characters and means the same thing to both players and
to a reader six months later.

B<WXF notation is what the reader sees, and it is never parsed back.> There is
deliberately no C<move_of_wxf> in this module, and its absence is the point.

=head2 WXF is relative to the side that wrote it

Files run B<1 to 9 from the mover's own right>, so Red counts right to left
across the board and Black counts left to right. The same string means two
different moves depending on who played it: C<C2.5> is a Red cannon going from
the h file to the e file, and it is equally a Black cannon going from the b file
to the e file.

That is why every call here takes the board: the colour comes from the piece,
and there is no way to spell a WXF move without knowing whose it is.

And it is why the parser is missing. A log that stored only WXF would be
unreplayable the day its reader forgot which side wrote a line, and the reader
is a person six months later looking at C</games/:id/log>. Chess made the same
split for the same reason: it stores UCI and carries SAN for the reader.

=head2 Which pieces carry a distance and which carry a file

After C<+> or C<->, B<the chariot, the cannon, the general and the soldier carry
how many ranks they moved>, and B<the advisor, the elephant and the horse carry
the destination file>, because their rank change is implied by the piece. After
C<.> every piece carries the destination file. Getting this backwards produces
strings that look right and name the wrong square.

=head2 Two on a file, and three

Two identical pieces on one file take C<+> for the front one and C<-> for the
rear I<instead of> the file number, which could not tell them apart. Three or
more are numbered from the front. Five soldiers on one file is legal and rare,
and the general case is implemented rather than the common one.

B<Front means nearer the enemy>, so the order reverses with the colour.

=head1 METHODS

=head2 iccs_of

    Game::Xiangqi::Notation->iccs_of($move);      # 'h2e2'

A packed move as ICCS coordinates: the from point then the to point, file letter
C<a> to C<i> and rank digit C<0> to C<9>, always from Red's left and Red's end.
B<This is what the log stores.>

=head2 move_of_iccs

    my $move = Game::Xiangqi::Notation->move_of_iccs('h2e2');

The reverse. Returns C<undef> for anything that is not four characters naming two
points on the board, and B<judges nothing else>: a well-formed move that is illegal
in the position still parses, because deciding that is the board's job and not the
parser's.

=head2 wxf_of

    Game::Xiangqi::Notation->wxf_of($position, $move);    # 'C2.5'

The move in WXF notation, which needs the position because WXF names a piece and a
file rather than two points, and because two pieces of one kind on one file are
written as the front one and the back one.

Returns C<undef> if the move's from point holds nothing.

=head2 wxf_file

    Game::Xiangqi::Notation->wxf_file($file_index, $colour);

The WXF file number for a board file, which is B<not> the same number for the two
sides: files are counted one to nine from the mover's own right, so Red's file 1 and
Black's file 1 are opposite ends of the board.

=cut
