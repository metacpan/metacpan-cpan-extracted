use strict;
use warnings;
use Test::More;
use FindBin ();

# The deep half of the cited ladder. NOT in t/, because depth 5 of the opening
# is 133 million nodes and 35 seconds on the machine this was written on, and an
# installer's smoke test should not pay that.
#
# Under RELEASE_TESTING this runs. Otherwise it skips, and the skip says what it
# would have cost.

BEGIN {
    unless ($ENV{RELEASE_TESTING} || $ENV{XQ_DEEP}) {
        require Test::More;
        Test::More::plan(skip_all =>
            'deep perft: set RELEASE_TESTING or XQ_DEEP. Roughly a minute.');
    }
}

use Game::Xiangqi::Engine ':all';
my $E = 'Game::Xiangqi::Engine';

my $FIXTURE = "$FindBin::Bin/../t/perft.txt";
open my $fh, '<', $FIXTURE or die "cannot read $FIXTURE: $!";
my (%fen, %want, $n);
while (<$fh>) {
    next if /^\s*(#|$)/;
    if (/^P\s+(\d+)\s+(.+?)\s*$/)                        { $n = $1; $fen{$n} = $2 }
    elsif (/^D\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)/) { $want{$n}[$1] = [ $2, $3, $4, $5 ] }
}

# The opening to depth 5, which is the deepest row anybody should run without a
# reason. Depth 6 is 5.4 billion nodes: the fixture carries it, and running it
# is a day's job for a machine and not a test.
subtest 'the opening, depth 5' => sub {
    my $b = $E->new(fen => $fen{1});
    my $t0 = time;
    my @got = $b->perft(5);
    diag(sprintf('depth 5 in %d seconds', time - $t0));
    is_deeply(\@got, $want{1}[5], 'all four counters exact at depth 5');
};

# The other eight positions to depth 5 as well: this is where the breadth is,
# and it is what the opening cannot give. The opening finds no mate at all
# before depth 6, so eight middlegame positions at depth 5 exercise more of the
# rules than one opening at depth 7 would.
for my $p (2 .. 11) {
    subtest "position $p, depth 5" => sub {
        my $b = $E->new(fen => $fen{$p});
        ok($b, 'loads') or return;
        my @got = $b->perft(5);
        is_deeply(\@got, $want{$p}[5], 'all four counters exact at depth 5')
            or diag("got @got, want @{$want{$p}[5]}");
    };
}

done_testing();
