use strict;
use warnings;

use Test::Fatal;
use Test::More;
use Test::Warnings qw/:all/;
use Fcntl ':flock';    # import LOCK_* constants
use Path::Tiny;

my $tmp_dir = Path::Tiny->tempdir(CLEANUP => 1);

# the default semantics of flock(2) allows to re-set
# lock type via sequential flock invocations from
# lock owning process. That's not desired behaviour
# for tests, so, we don't allow that, to

my $locked = 0;

BEGIN {
    *CORE::GLOBAL::flock = sub {
        my ($fd, $flags) = @_;
        if ($flags & (LOCK_EX | LOCK_SH)) {
            print("locking file (current status = $locked)\n");
            if (!$locked) {
                return $locked = 1;
            }
        } elsif ($flags & LOCK_UN) {
            print("unlocking (current status = $locked)\n");
            if ($locked) {
                $locked = 0;
                return 1;
            } else {
                die("cannot unlock $fd: it wasn't locked\n");
            }
        }
    };
}

use IPC::LeaderBoard;

my $create = sub {
    return IPC::LeaderBoard::create(
        n_slots           => 2,
        slot_shared_size  => 4,
        slot_private_size => 2,
        mmaped_file       => "$tmp_dir/lb.score",
    );
};

my $attach = sub {
    return IPC::LeaderBoard::attach(
        n_slots           => 2,
        slot_shared_size  => 4,
        slot_private_size => 2,
        mmaped_file       => "$tmp_dir/lb.score",
    );
};

subtest "creation & attachments" => sub {
    $locked = 0;
    my $master = $create->();
    ok $master, "leaderboard has been created";
    my @clients = map { $attach->() } (1 .. 2);
    is scalar(@clients), 2, "multiple clients can attach to LeaderBoard";

    like(exception { $create->() }, qr/owned/, "cannot create LeaderBoard as it can be exlusively onwned once by one process",);

    undef $master;    # explicitely destroy object before creation of the new one
    $master = $create->();
    ok $master, "LeaderBoard info has been recreated - exclusively";

    undef $master;
    like(exception { $attach->() }, qr/abandoned/, "cannot attach to OnlineInfo as it seems to be abandoned",);

};

subtest "usage" => sub {
    $locked = 0;
    my $master = $create->();
    my ($slave_1, $slave_2) = map { $attach->() } (0 .. 1);

    is_deeply [$slave_1->read_slot(0)], [[(0) x 4], [(0) x 2]], "initial values";
    is_deeply [$slave_2->read_slot(1)], [[(0) x 4], [(0) x 2]], "initial values";

    # we have to read the related row, before updating it
    $slave_1->read_slot(0);
    $slave_2->read_slot(0);
    ok $slave_1->update(0, [1, 2, 3, 4], 0 => 6), "successfull shared & private update";
    ok !$slave_2->update(0, [11, 12, 13, 14], 1 => 9), "non-successfull shared update (somebody else updated the data), but successfull private";
    ok !$slave_1->update(0, [21, 22, 23, 24]), "non-successfull update (we have to re-read record), no private update";

    is_deeply [$slave_1->read_slot(0)], [[1, 2, 3, 4], [6, 9]], "assure that we get the last values we have written";
    is_deeply [$slave_2->read_slot(0)], [[1, 2, 3, 4], [6, 9]], "assure that we get the last values we have written";

    ok $slave_2->update(
        0, [11, 12, 13, 14],
        0 => 66,
        1 => 99
        ),
        "after refresh, as nobody modified it, we can update";
    is_deeply [$slave_1->read_slot(0)], [[11, 12, 13, 14], [66, 99]], "assure that we get the last values we have written";

    $slave_1->read_slot(0);
    ok !$slave_1->update(0, 0 => 7), "successfull private update (no succes of shared data update, as we don't provide values for it)";
    is_deeply [$slave_1->read_slot(0)], [[11, 12, 13, 14], [7, 99]], "assure that we get the last values we have written";
};

subtest "edge-cases" => sub {
    $locked = 0;
    my $master = $create->();
    my ($slave_1, $slave_2) = map { $attach->() } (0 .. 1);
    like(exception { $slave_1->read_slot(2) }, qr/wrong index/, "the code died in attempt to read row out of scope",);

    like(exception { $slave_1->read_slot(-1) }, qr/wrong index/, "the code died in attempt to read row out of scope",);

    like(exception { $slave_1->update(2, [1, 2, 3, 4]) }, qr/wrong index/, "the code died in attempt to write row out of scope",);

    like(exception { $slave_1->update(-1, [1, 2, 3, 4]) }, qr/wrong index/, "the code died in attempt to write row out of scope",);

    $slave_1->read_slot(0);
    like(exception { $slave_1->update(0, 2 => 5) }, qr/wrong private index/, "the code died in attempt to write private datea out of row",);

    like(exception { $slave_1->update(0, -1 => 5) }, qr/wrong private index/, "the code died in attempt to write private datea out of row",);

    like(
        exception { $slave_1->update(0, [1, 2, 3]) },
        qr/values size mismatch slot size/,
        "the code died in attempt to update shared datas with wrong vector size",
    );

    like(
        exception { $slave_1->update(0, [1, 2, 3, 4, 5]) },
        qr/values size mismatch slot size/,
        "the code died in attempt to update shared datas with wrong vector size",
    );

    # manually set spin lock to some value(5) (should be zero, by default)
    $slave_1->_score_board->set(0, 0, 5);
    my $operation_result;
    like(
        warning { $operation_result = $slave_1->update(0, [1, 2, 3, 4]) },
        qr/failed to acquire spin lock/,
        "warning emitted when spinlock wasn't acquired"
    );
    ok !$operation_result;

};

done_testing;
