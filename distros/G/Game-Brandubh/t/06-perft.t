use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";

use Game::Brandubh::Engine ':all';
use Game::Brandubh::Test::Squares qw(sq name wire roller transform SYMMETRIES);
my $E = 'Game::Brandubh::Engine';

# THERE IS NO PUBLISHED PERFT TABLE FOR THIS GAME, so t/perft.txt has two
# authors and says which wrote each row:
#
#   hand   counted by a person from the diagram, before any program ran
#   twin   counted by a second implementation, in another language, written
#          from the rules text alone and never from this engine's source
#
# A row is: source, rule set, kind, depth, count, position. There are two kinds
# and so two ladders, so that a wrong number says which half is wrong:
#
#   slides     a move relocates a piece and captures nothing
#   captures   a move captures as well; nothing ends the walk, and a side
#              whose king has been taken moves what it has left
#
# The deepest rows are skipped unless EXTENDED_TESTING is set. They are the
# same check, only slower.

my $DEEP = $ENV{EXTENDED_TESTING} ? 99 : 4;

sub rows {
    open my $fh, '<', "$FindBin::Bin/perft.txt" or die "t/perft.txt: $!";
    my @rows;
    while (my $line = <$fh>) {
        chomp $line;
        next if $line =~ /\A#/ || $line !~ /\S/;
        my ($source, $label, $kind, $depth, $count, $position) = split /\t/, $line;
        push @rows, { source => $source, label => $label, kind => $kind,
                      depth => $depth, count => $count, position => $position };
    }
    return @rows;
}

sub variant_of {
    my ($label) = @_;
    my %v = map { split /=/ } grep { $_ ne 'default' } split /,/, $label;
    return %v ? \%v : undef;
}

my @ALL = rows();
my @ROWS = grep { $_->{kind} eq 'slides' } @ALL;

sub count_of {
    my ($bd, $row) = @_;
    my $v = variant_of($row->{label});
    return $row->{kind} eq 'captures' ? $bd->perft($row->{depth}, $v) : $bd->perft_slides($row->{depth}, $v);
}

subtest 'the rows a person counted' => sub {
    my @hand = grep { $_->{source} eq 'hand' } @ROWS;
    is(scalar(@hand), 2, 'two of them');
    for my $row (@hand) {
        my ($bd) = $E->of_string($row->{position});
        is($bd->perft_slides($row->{depth}, variant_of($row->{label})), $row->{count},
            "$row->{count} at depth $row->{depth} from $row->{position}");
    }
};

subtest 'the rows the twin counted' => sub {
    my @twin = grep { $_->{source} eq 'twin' } @ROWS;    # the slides
    cmp_ok(scalar(@twin), '>=', 250, 'there are ' . scalar(@twin) . ' of them');
    my (%by_label, %positions, @bad);
    my ($ran, $skipped) = (0, 0);
    for my $row (@twin) {
        $by_label{ $row->{label} }++;
        $positions{ $row->{position} }++;
        if ($row->{depth} > $DEEP) { $skipped++; next }
        my ($bd, $err) = $E->of_string($row->{position});
        if (!$bd) { push @bad, "refused: $row->{position}"; next }
        my $got = count_of($bd, $row);
        $ran++;
        push @bad, "$row->{label} depth $row->{depth} $row->{position}: $got, the twin says $row->{count}"
            unless $got eq $row->{count};
    }
    is(scalar(keys %positions), 21, 'from twenty-one positions');
    is(join(' ', sort keys %by_label), 'default throne_pass=0 throne_reentry=1', 'under three rule sets');
    cmp_ok($ran, '>=', 250, "$ran rows were run" . ($skipped ? " and $skipped deeper ones left for EXTENDED_TESTING" : ''));
    is(scalar(@bad), 0, 'and the engine agrees with every one')
        or diag(join "\n", @bad[0 .. ($#bad < 4 ? $#bad : 4)]);
};

subtest 'the twin\'s rows with captures played' => sub {
    my @twin = grep { $_->{source} eq 'twin' && $_->{kind} eq 'captures' } @ALL;
    cmp_ok(scalar(@twin), '>=', 250, 'there are ' . scalar(@twin) . ' of them');
    my (%by_label, %positions, @bad);
    my ($ran, $skipped, $differs) = (0, 0, 0);
    for my $row (@twin) {
        $by_label{ $row->{label} }++;
        $positions{ $row->{position} }++;
        if ($row->{depth} > $DEEP) { $skipped++; next }
        my ($bd, $err) = $E->of_string($row->{position});
        if (!$bd) { push @bad, "refused: $row->{position}"; next }
        my $got = count_of($bd, $row);
        $ran++;
        push @bad, "$row->{label} depth $row->{depth} $row->{position}: $got, the twin says $row->{count}"
            unless $got eq $row->{count};
        $differs++ if $got ne $bd->perft_slides($row->{depth}, variant_of($row->{label}));
    }
    is(scalar(keys %positions), 21, 'from twenty-one positions');
    is(join(' ', sort keys %by_label), 'default king_everywhere_two=1 king_strong=1', 'under three rule sets');
    cmp_ok($ran, '>=', 250, "$ran rows were run" . ($skipped ? " and $skipped deeper ones left for EXTENDED_TESTING" : ''));
    is(scalar(@bad), 0, 'and the engine agrees with every one')
        or diag(join "\n", @bad[0 .. ($#bad < 4 ? $#bad : 4)]);

    # if the capture ladder were the slide ladder, this subtest would be the
    # one above run twice
    cmp_ok($differs, '>', 50, "$differs of those counts differ from the slide count of the same row");
};

subtest 'the two ladders part at the third move from the set-up' => sub {
    my $bd = $E->new;
    is($bd->perft(1), $bd->perft_slides(1), 'forty either way');
    is($bd->perft(2), $bd->perft_slides(2), 'and 960: nothing can be taken in two moves');
    is($bd->perft_slides(3), '39568', 'three moves of slides');
    is($bd->perft(3), '39512', 'and fifty-six fewer once a piece can have been taken');
    is($bd->to_string, '3a3/3a3/3d3/aadkdaa/3d3/3a3/3a3 a', 'the board is as it was');
};

subtest 'a count is a string of digits, and the board is left alone' => sub {
    my $bd = $E->new;
    my $before = $bd->to_string;
    my $key = $bd->key_hex;
    like($bd->perft_slides(4), qr/\A[0-9]+\z/, 'digits and nothing else');
    is($bd->perft_slides(0), '1', 'depth 0 is the position itself');
    is($bd->perft_slides(-3), '1', 'and so is a depth below it');
    is($bd->to_string, $before, 'the position is as it was');
    is($bd->key_hex, $key, 'and so is its key');
};

# THE CHECK THAT NEEDS NO SECOND AUTHOR. The board, the throne and the corners
# are the same under all eight symmetries of a square, so a position and its
# image must have the same number of moves at every depth, and the image of
# the move list must be the move list of the image. A generator that mishandles
# one direction or one corner fails here whatever the twin thinks.

sub image_of {
    my ($bd, $map) = @_;
    my $c = $E->new(empty => 1);
    for my $s ($E->all_squares) {
        my $piece = $bd->at($s);
        next if $piece == EMPTY;
        $c->put(sq(transform($map, name($s))), $piece);
    }
    $c->set_side($bd->side);
    return $c;
}

subtest 'the eight symmetries' => sub {
    my $roll = roller(8);
    my @symmetries = SYMMETRIES;
    is(scalar(@symmetries), 8, 'eight of them');

    my (%images, $n);
    for my $s (@symmetries) {
        my $where = join ',', map { transform($s->[1], $_) } qw(a1 b1 a2 d4 g7);
        $images{$where}++;
    }
    is(scalar(keys %images), 8, 'and they are eight different maps');

    my ($boards, $bad_count, $bad_list, $bad_captures, $with_captures) = (0, 0, 0, 0, 0);
    for my $i (1 .. 500) {
        my $bd = $E->new(empty => 1);
        my $density = 4 + $roll->(6);
        for my $s ($E->all_squares) {
            my $what = $roll->($density);
            $bd->put($s, $what) if $what >= 1 && $what <= 3;
        }
        $bd->set_side($roll->(2) ? DEFENDERS : ATTACKERS);
        $boards++;

        my $count = $bd->perft_slides(3);
        my $captures = $bd->perft(3);
        $with_captures++ if $captures ne $count;
        my @moves = map { wire($_) } $bd->moves;
        for my $s (@symmetries) {
            my ($label, $map) = @$s;
            my $image = image_of($bd, $map);
            $bad_count++ unless $image->perft_slides(3) eq $count;
            $bad_captures++ unless $image->perft(3) eq $captures;
            my $want = join ' ', sort map {
                transform($map, substr($_, 0, 2)) . transform($map, substr($_, 2, 2))
            } @moves;
            my $got = join ' ', sort map { wire($_) } $image->moves;
            $bad_list++ unless $got eq $want;
        }
    }
    is($boards, 500, 'five hundred boards, counted');
    is($bad_count, 0, 'the count three moves deep is the same under all eight');
    is($bad_list, 0, 'and the image of the list is the list of the image');
    is($bad_captures, 0, 'the count with captures played is the same under all eight too');
    cmp_ok($with_captures, '>', 250, "and on $with_captures of the boards a capture changed that count");
};

subtest 'the set-up is its own image eight times over' => sub {
    my $bd = $E->new;
    for my $s (SYMMETRIES) {
        is(image_of($bd, $s->[1])->to_string, $bd->to_string, "under: $s->[0]");
    }
};

done_testing();
