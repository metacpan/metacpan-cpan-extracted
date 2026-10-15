use strict;
use warnings;
use Test::More;
use lib 't/lib';

use Game::Xiangqi;
use Game::Xiangqi::Engine ':all';
use Game::Xiangqi::Terminal;
use Game::Xiangqi::Test::Handle;

my $T = 'Game::Xiangqi::Terminal';
my $E = 'Game::Xiangqi::Engine';

my %CHARS = (right => "\e[C", left => "\e[D", enter => "\r");

sub keysource {
    my @chars = map { split //, $CHARS{$_} } @_;
    return sub { shift @chars };
}

sub where {
    my (@lines) = @_;
    my @at;
    for my $row (0 .. $#lines) {
        my $column = index $lines[$row], '[';
        push @at, "$row:$column" if $column >= 0;
    }
    return @at;
}

sub walked {
    my ($out) = @_;
    my @lines = split /\n/, $out->text;
    my (@frames, $top);
    for my $i (0 .. $#lines) {
        $top = $i if $lines[$i] =~ /\A[09] /  && !defined $top;
        next unless defined $top && $lines[$i] =~ /\A   a /;
        push @frames, [ @lines[ $top .. $i ] ];
        $top = undef;
    }
    return map { join ',', where(@$_) } @frames;
}

sub as_drawn {
    my ($t, $points, %o) = @_;
    my %place;
    for my $pt (@$points) {
        my ($at) = where($t->board_lines(%o, cursor => $pt));
        my ($row, $column) = split /:/, $at;
        $place{$pt} = [ $row, $column, $at ];
    }
    return map { $place{$_}[2] }
           sort { $place{$a}[0] <=> $place{$b}[0] || $place{$a}[1] <=> $place{$b}[1] }
           @$points;
}

for my $seat (qw(p1 p2)) {
    my $flip = $seat eq 'p2' ? 1 : 0;

    subtest "$seat: right walks the pieces in the order they are drawn" => sub {
        my $g = Game::Xiangqi->new(seed => 'o' x 32, red => $seat);
        is($g->turn, $seat, 'the seat is to move');
        my $pos   = $g->position;
        my $count = scalar @{ $T->new(colour => 0)->origins($pos) };
        cmp_ok($count, '>', 5, "$count pieces can move, on more than one rank");

        my $out = Game::Xiangqi::Test::Handle->recorder;
        my $t   = $T->new(out => $out->fh, game => $g, colour => 0, ascii => 1,
                          picking => 1, rewind => 0,
                          keysource => keysource(('right') x $count));
        is($t->pick_move($g, $seat), 'quit', 'the keys ran out');

        my @want = as_drawn($t, $t->origins($pos), flip => $flip);
        my %rows = map { (split /:/)[0] => 1 } @want;
        cmp_ok(scalar keys %rows, '>', 1, 'the walk crosses ranks');
        is_deeply([ walked($out) ], [ @want, $want[0] ],
                  'top rank first, left to right, and round to the first');

        my $back = Game::Xiangqi::Test::Handle->recorder;
        my $u    = $T->new(out => $back->fh, game => $g, colour => 0, ascii => 1,
                           picking => 1, rewind => 0,
                           keysource => keysource(('left') x $count));
        $u->pick_move($g, $seat);
        is_deeply([ walked($back) ], [ $want[0], reverse @want ],
                  'and left is the same walk backwards');
    };

    subtest "$seat: right walks a piece's points in the order they are drawn" => sub {
        my $pos = $E->new(empty => 1);
        $pos->put($E->point_of(3, 0), RED | GENERAL);
        $pos->put($E->point_of(5, 9), BLACK | GENERAL);
        $pos->put($E->point_of(4, 4), RED | CHARIOT);
        $pos->set_side(RED);
        my $g = Game::Xiangqi->new(seed => 'o' x 32, red => $seat, position => $pos);
        is($g->turn, $seat, 'the seat is to move');

        my $probe   = $T->new(colour => 0, ascii => 1);
        my $chariot = $E->point_of(4, 4);
        my $targets = $probe->targets($g->position, $chariot);
        my $count   = scalar @$targets;
        cmp_ok($count, '>', 10, "the chariot has $count points, up, down and across");

        my @from = as_drawn($probe, $probe->origins($g->position), flip => $flip);
        my ($here) = as_drawn($probe, [$chariot], flip => $flip);
        my ($steps) = grep { $from[$_] eq $here } 0 .. $#from;

        my $out = Game::Xiangqi::Test::Handle->recorder;
        my $t   = $T->new(out => $out->fh, game => $g, colour => 0, ascii => 1,
                          picking => 1, rewind => 0,
                          keysource => keysource(('right') x $steps, 'enter',
                                                 ('right') x $count));
        is($t->pick_move($g, $seat), 'quit', 'the keys ran out');

        my @want = as_drawn($t, $targets, flip => $flip, from => $chariot);
        my @seen = walked($out);
        splice @seen, 0, $steps + 1;
        is_deeply(\@seen, [ @want, $want[0] ],
                  'top rank first, left to right, and round to the first');
    };
}

done_testing();
