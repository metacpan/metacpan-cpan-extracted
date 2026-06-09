use warnings;
use strict;

use IPC::Shareable qw(SEM_TESTING);
use IPC::Semaphore;
use String::CRC32;
use Test::More;

use FindBin;
use lib $FindBin::Bin;
use IPCShareableTest qw(assert_clean_process unique_glue);


my $DIST = unique_glue('IPC::Shareable::Test::69');
my $expected_hash = (String::CRC32::crc32($DIST) & 0x7FFF) || 1;

# 1. testing_set() croaks with no argument or empty string
{
    my $ok = eval { IPC::Shareable->testing_set(); 1 };
    is $ok, undef, "testing_set() croaks with no argument";
    like $@, qr/requires/, "...error message mentions 'requires'";

    $ok = eval { IPC::Shareable->testing_set(''); 1 };
    is $ok, undef, "testing_set() croaks with empty string";
    like $@, qr/requires/, "...error message mentions 'requires'";
}

# 2. Explicit testing => $DIST without testing_set() — 5-slot semaphore,
#    SEM_TESTING holds the correct hash
{
    tie my %h, 'IPC::Shareable', {
        key     => unique_glue('tf02'),
        create  => 1,
        destroy => 1,
        testing => $DIST,
    };

    my $knot = tied(%h);
    my $sem  = $knot->sem;
    my $stat = $sem->stat;

    is $stat->nsems, 5, "Segment created with testing => DIST has 5 semaphore slots";
    is $sem->getval(SEM_TESTING), $expected_hash,
        "SEM_TESTING holds the correct CRC32 hash of the dist name";

    is $knot->attributes('testing'), $DIST,
        "attributes('testing') returns original dist string on the creating process";

    tied(%h)->clean_up_all;
}

# 3. Segment created without testing => has 4 semaphore slots
{
    tie my %h, 'IPC::Shareable', {
        key     => unique_glue('tf03'),
        create  => 1,
        destroy => 1,
    };

    my $knot = tied(%h);
    my $stat = $knot->sem->stat;

    is $stat->nsems, 4, "Segment without testing => has 4 semaphore slots";

    tied(%h)->clean_up_all;
}

# 4. testing_set() — subsequent ties auto-tag; testing => 0 opts out
{
    IPC::Shareable->testing_set($DIST);

    tie my %auto, 'IPC::Shareable', {
        key     => unique_glue('tf04a'),
        create  => 1,
        destroy => 1,
    };

    my $auto_stat = tied(%auto)->sem->stat;
    is $auto_stat->nsems, 5, "Auto-tagged tie after testing_set() has 5 slots";
    is tied(%auto)->sem->getval(SEM_TESTING), $expected_hash,
        "Auto-tagged tie has correct SEM_TESTING hash";

    tie my %no, 'IPC::Shareable', {
        key     => unique_glue('tf04b'),
        create  => 1,
        destroy => 1,
        testing => 0,
    };

    my $no_stat = tied(%no)->sem->stat;
    is $no_stat->nsems, 4, "testing => 0 opts out of auto-tagging (4 slots)";

    tied(%auto)->clean_up_all;
    tied(%no)->clean_up_all;
    # $_testing_dist stays set; that's the realistic test-file pattern.
}

# 5. clean_up_testing() removes only matching segments, not others
{
    my $other_dist = unique_glue('IPC::Shareable::Test::OTHER');

    tie my %target, 'IPC::Shareable', {
        key     => unique_glue('tf05t'),
        create  => 1,
        destroy => 0,       # must survive to be found by clean_up_testing
        testing => $DIST,
    };

    tie my %other, 'IPC::Shareable', {
        key     => unique_glue('tf05o'),
        create  => 1,
        destroy => 1,
        testing => $other_dist,
    };

    my $segs_mid = keys %{ IPC::Shareable::global_register() };
    cmp_ok $segs_mid, '>=', 2, "At least 2 segments in register before cleanup";

    my $removed = IPC::Shareable::clean_up_testing($DIST);
    is $removed, 1, "clean_up_testing() removed exactly 1 segment (the DIST one)";

    # The other dist segment should still exist
    my $reg = IPC::Shareable::global_register();
    my $other_knot = tied(%other);
    ok exists $reg->{ $other_knot->seg->id },
        "The other-dist segment was NOT removed by clean_up_testing(DIST)";

    tied(%other)->clean_up_all;
}

# 6. clean_up_testing() finds orphans (segments not in global_register)
{
    # Create a segment, capture its key, clear global_register by untying
    my $key_str = unique_glue('tf06o');

    {
        tie my %orphan, 'IPC::Shareable', {
            key     => $key_str,
            create  => 1,
            destroy => 0,
            testing => $DIST,
        };
        # Let it go out of scope without destroy — simulates a crash leaving orphan
    }

    # At this point the segment still exists on the system but the inner
    # scope's tied variable has been untied — clean_up_testing() must still
    # find and remove it via the system-wide ipcs scan.

    my $removed = IPC::Shareable::clean_up_testing($DIST);
    cmp_ok $removed, '>=', 1,
        "clean_up_testing() removed the orphaned segment not in global_register";
}

# 7. Child/nested segments inherit the testing attribute
{
    IPC::Shareable->testing_set($DIST);

    tie my %parent, 'IPC::Shareable', {
        key     => unique_glue('tf07'),
        create  => 1,
        destroy => 1,
    };

    $parent{nested} = { inner => 42 };   # triggers _magic_tie for child

    my $reg = IPC::Shareable::global_register();
    my @children = grep {
        my $k = $reg->{$_};
        defined $k && $k->attributes('magic')
    } keys %$reg;

    my $child_knot = $reg->{ $children[0] };
    my $child_stat = $child_knot->sem->stat;

    is $child_stat->nsems, 5,
        "Child segment created via _magic_tie has 5 semaphore slots";
    is $child_knot->sem->getval(SEM_TESTING), $expected_hash,
        "Child segment SEM_TESTING holds the correct hash";

    tied(%parent)->clean_up_all;
}

# 8. clean_up_testing() ignores protected — both-attributed segments are removed
{
    tie my %both, 'IPC::Shareable', {
        key       => unique_glue('tf08'),
        create    => 1,
        destroy   => 0,
        protected => 9999,
        testing   => $DIST,
    };

    my $reg      = IPC::Shareable::global_register();
    my $knot     = tied(%both);
    my $seg_id   = $knot->seg->id;

    ok exists $reg->{$seg_id}, "Both-attributed segment is in register before cleanup";

    my $removed = IPC::Shareable::clean_up_testing($DIST);
    is $removed, 1, "clean_up_testing() removed the protected+testing segment";

    $reg = IPC::Shareable::global_register();
    ok !exists $reg->{$seg_id}, "Both-attributed segment is gone from register";
}

# 9. clean_up_testing() returns the count of removed segments
{
    tie my %a, 'IPC::Shareable', { key => unique_glue('tf09a'), create => 1, destroy => 0, testing => $DIST };
    tie my %b, 'IPC::Shareable', { key => unique_glue('tf09b'), create => 1, destroy => 0, testing => $DIST };

    my $removed = IPC::Shareable::clean_up_testing($DIST);
    is $removed, 2, "clean_up_testing() returns count of removed segments (2)";
}

# 10. Seg/sem counts return to baseline after final cleanup
{
    # Catch any leftovers from this test file
    IPC::Shareable::clean_up_testing($DIST);
    IPC::Shareable::clean_up_all();
    IPC::Shareable::_end();
}

assert_clean_process();


done_testing();
