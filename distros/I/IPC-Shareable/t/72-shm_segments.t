use warnings;
use strict;

use IPC::Shareable;
IPC::Shareable->testing_set('IPC::Shareable');
use IPC::SysV qw(IPC_CREAT IPC_RMID);
use Test::More;

my $segs_before = IPC::Shareable::seg_count();
my $sems_before = IPC::Shareable::sem_count();
warn "Segs Before: $segs_before\n" if $ENV{PRINT_SEGS};

# -----------------------------------------------------------------------
# shm_segments() - basic return type
# -----------------------------------------------------------------------

{
    my $segs = IPC::Shareable->shm_segments;
    is ref($segs), 'HASH', "shm_segments() returns a hash ref";
}

# -----------------------------------------------------------------------
# shm_segments() - IPC::Shareable segments appear, keyed by hex string
# -----------------------------------------------------------------------

{
    tie my %h, 'IPC::Shareable', { key => '0x1B0B0001', create => 1, destroy => 1 , serializer => 'storable' };
    $h{test} = 'hello';

    my $segs = IPC::Shareable->shm_segments;

    ok exists $segs->{'0x1b0b0001'}, "IPC::Shareable segment appears in shm_segments() output";

    is ref($segs->{'0x1b0b0001'}), 'HASH', "...each entry is a hash ref";

    like $segs->{'0x1b0b0001'}{content}, qr/^IPC::Shareable/,
        "...segment content starts with 'IPC::Shareable' tag";

    is $segs->{'0x1b0b0001'}{local_process}, 1, "...local_process flag is set for this process's segment";
    is $segs->{'0x1b0b0001'}{known},         1, "...known is 1 for a segment tied in this process";
}

# -----------------------------------------------------------------------
# shm_segments() - non-IPC::Shareable segment is skipped
# -----------------------------------------------------------------------

{
    my $foreign_key = 0x1B0B0002;
    my $foreign_hex = sprintf '0x%08x', $foreign_key;

    my $id = shmget($foreign_key, 64, IPC_CREAT | 0666);
    ok defined($id), "created a raw (non-IPC::Shareable) segment with shmget() ok";

    shmwrite($id, 'plain foreign data', 0, 64);

    my $segs = IPC::Shareable->shm_segments;

    ok !exists $segs->{$foreign_hex},
        "shm_segments() skips segment not tagged with 'IPC::Shareable' prefix";

    # clean up the foreign segment
    my $removed = shmctl($id, IPC_RMID, 0);
    ok $removed, "foreign segment cleaned up ok";
}

# -----------------------------------------------------------------------
# shm_segments() - returns the correct number of IPC::Shareable segments
# -----------------------------------------------------------------------

{
    my $count_before = scalar keys %{ IPC::Shareable->shm_segments };

    tie my $sv, 'IPC::Shareable', { key => '0x1B0B0010', create => 1, destroy => 1 , serializer => 'storable' };
    $sv = 'scalar value';

    tie my %hv, 'IPC::Shareable', { key => '0x1B0B0020', create => 1, destroy => 1 , serializer => 'storable' };
    $hv{x} = 1;

    my $segs = IPC::Shareable->shm_segments;
    my $count_after = scalar keys %$segs;

    cmp_ok $count_after, '>=', $count_before + 2,
        "shm_segments() count increases by at least 2 after creating 2 segments";

    ok exists $segs->{'0x1b0b0010'}, "scalar segment key present ok";
    ok exists $segs->{'0x1b0b0020'}, "hash segment key present ok";

    is $segs->{'0x1b0b0010'}{local_process}, 1, "scalar segment local_process flag set ok";
    is $segs->{'0x1b0b0020'}{local_process}, 1, "hash segment local_process flag set ok";
}

# -----------------------------------------------------------------------
# shm_segments() - keys are lowercase hex strings
# -----------------------------------------------------------------------

{
    tie my %h, 'IPC::Shareable', { key => '0x1B0B0030', create => 1, destroy => 1 , serializer => 'storable' };
    $h{v} = 1;

    my $segs = IPC::Shareable->shm_segments;

    my @non_lower = grep { $_ ne lc($_) } keys %$segs;
    is scalar(@non_lower), 0, "all keys in shm_segments() are lowercase hex strings";

    my @missing_flags = grep {
        !exists $segs->{$_}{child_keys}    ||
        !exists $segs->{$_}{content}       ||
        !exists $segs->{$_}{local_process} ||
        !exists $segs->{$_}{known}
    } keys %$segs;
    is scalar(@missing_flags), 0, "all entries have child_keys/content/local_process/known keys";

    is_deeply $segs->{'0x1b0b0030'}{child_keys}, [], "child_keys is empty arrayref for segment with no children";
}

# -----------------------------------------------------------------------
# shm_segments() - child_keys is an arrayref of child hex keys when
# a JSON segment has nested children
# -----------------------------------------------------------------------

{
    tie my %h, 'IPC::Shareable', { key => '0x1B0B0040', create => 1, destroy => 1, serializer => 'json' };
    $h{a} = 1;
    $h{b} = { x => 10 };   # nested hash → child segment

    my $segs = IPC::Shareable->shm_segments;

    ok exists $segs->{'0x1b0b0040'}, "parent segment with JSON child is present";

    my $ck = $segs->{'0x1b0b0040'}{child_keys};
    is ref($ck), 'ARRAY', "child_keys is an arrayref for segment with children";
    is scalar(@$ck), 1,   "...with exactly one child key";
    like $ck->[0], qr/^0x[0-9a-f]+$/, "...child key is a hex string";
}

# -----------------------------------------------------------------------
# shm_segments() - known => 0 for an IPC::Shareable-tagged segment
# that is not in any register (simulates a leftover from a dead process)
# -----------------------------------------------------------------------

{
    my $orphan_key = 0x1B0B0099;
    my $orphan_hex = sprintf '0x%08x', $orphan_key;

    # Create a segment manually and write the IPC::Shareable tag prefix,
    # but never register it — so it will appear as known => 0.
    my $id = shmget($orphan_key, 128, IPC_CREAT | 0666);
    ok defined($id), "created unregistered-simulating segment with shmget() ok";

    my $tag = 'IPC::Shareable' . 'fake_orphan_data';
    shmwrite($id, $tag, 0, 128);

    my $segs = IPC::Shareable->shm_segments;

    ok exists $segs->{$orphan_hex},
        "unregistered segment appears in shm_segments() output";

    is $segs->{$orphan_hex}{known},          0, "...known is 0 for unregistered segment";
    is $segs->{$orphan_hex}{local_process}, 0, "...local_process is 0 for unregistered segment";

    # unknown_segments() method
    my @unknown = IPC::Shareable->unknown_segments;
    ok scalar(@unknown) >= 1, "unknown_segments() returns at least one entry";
    ok grep({ $_ eq $orphan_hex } @unknown), "unknown_segments() includes the unregistered segment key";
    ok !grep({ $_ eq '0x1b0b0001' } @unknown), "unknown_segments() excludes a registered segment";

    shmctl($id, IPC_RMID, 0);
}

# -----------------------------------------------------------------------
# remove() - class method with key, all key format variants
# Each creates a tagged-but-unregistered segment, then removes it via
# IPC::Shareable->remove($key) and confirms it is gone from shm_segments()
# -----------------------------------------------------------------------

{
    # text key: gets CRC'd internally — ask the module for the resulting int
    my $text_key     = 'removetest';
    my $text_int     = IPC::Shareable->_shm_key($text_key);
    my $text_hex     = sprintf '0x%08x', $text_int;

    my $id1 = shmget($text_int, 128, IPC_CREAT | 0666);
    shmwrite($id1, 'IPC::Shareablefake', 0, 128);
    ok exists(IPC::Shareable->shm_segments->{$text_hex}),
        "text key: segment exists before remove()";
    IPC::Shareable->remove($text_key);
    ok !exists(IPC::Shareable->shm_segments->{$text_hex}),
        "text key: gone after IPC::Shareable->remove('removetest')";

    # integer key: decimal integer, used as-is
    my $int_key = 454328512;   # 0x1B0B00C0
    my $int_hex = sprintf '0x%08x', $int_key;

    my $id2 = shmget($int_key, 128, IPC_CREAT | 0666);
    shmwrite($id2, 'IPC::Shareablefake', 0, 128);
    ok exists(IPC::Shareable->shm_segments->{$int_hex}),
        "int key: segment exists before remove()";
    IPC::Shareable->remove($int_key);
    ok !exists(IPC::Shareable->shm_segments->{$int_hex}),
        "int key: gone after IPC::Shareable->remove(454328512)";

    # hex literal key: Perl evaluates 0x1B0B00D0 to an integer at compile time
    my $hex_lit_int = 0x1B0B00D0;
    my $hex_lit_hex = sprintf '0x%08x', $hex_lit_int;

    my $id3 = shmget($hex_lit_int, 128, IPC_CREAT | 0666);
    shmwrite($id3, 'IPC::Shareablefake', 0, 128);
    ok exists(IPC::Shareable->shm_segments->{$hex_lit_hex}),
        "hex literal key: segment exists before remove()";
    IPC::Shareable->remove(0x1B0B00D0);
    ok !exists(IPC::Shareable->shm_segments->{$hex_lit_hex}),
        "hex literal key: gone after IPC::Shareable->remove(0x1B0B00D0)";

    # hex string key: string of the form '0x...'
    my $hex_str_key = '0x1B0B00E0';
    my $hex_str_hex = lc($hex_str_key);

    my $id4 = shmget(hex($hex_str_key), 128, IPC_CREAT | 0666);
    shmwrite($id4, 'IPC::Shareablefake', 0, 128);
    ok exists(IPC::Shareable->shm_segments->{$hex_str_hex}),
        "hex string key: segment exists before remove()";
    IPC::Shareable->remove($hex_str_key);
    ok !exists(IPC::Shareable->shm_segments->{$hex_str_hex}),
        "hex string key: gone after IPC::Shareable->remove('0x1B0B00E0')";
}

# -----------------------------------------------------------------------
# unknown_segments() - fork-and-exit produces a real orphan from the
# parent's point of view. The child creates a tied segment with
# destroy => 0 and exits; the parent never tied the key, so its
# global_register has no entry for it.
# -----------------------------------------------------------------------

{
    my $orphan_key = '0x1B0B00F0';
    my $orphan_hex = lc $orphan_key;

    pipe(my $r, my $w) or die "pipe: $!";

    my $pid = fork;
    defined $pid or die "fork: $!";

    if ($pid == 0) {
        close $r;
        tie my %h, 'IPC::Shareable', {
            key        => $orphan_key,
            create     => 1,
            exclusive  => 1,
            destroy    => 0,
            serializer => 'storable',
        };
        $h{leftover} = 1;
        print $w "created\n";
        close $w;
        exit 0;
    }

    close $w;
    my $line = <$r>;
    close $r;
    waitpid($pid, 0);

    my @unknown = IPC::Shareable->unknown_segments;
    ok scalar(grep { $_ eq $orphan_hex } @unknown),
        "unknown_segments(): fork+exit orphan key present from parent's view";

    IPC::Shareable->remove($orphan_key);
    ok !exists(IPC::Shareable->shm_segments->{$orphan_hex}),
        "fork+exit orphan: removed via remove(\$key) ok";
}

IPC::Shareable::_end;

my $segs_after = IPC::Shareable::seg_count();
warn "Segs After: $segs_after\n" if $ENV{PRINT_SEGS};
is $segs_after, $segs_before, "segment count restored to original after cleanup";
my $sems_after = IPC::Shareable::sem_count();
is $sems_after, $sems_before, "All semaphore sets cleaned up ok";

# -----------------------------------------------------------------------
# shm_segments() and unknown_segments() called as object methods
# -----------------------------------------------------------------------

{
    my $k = tie my %h, 'IPC::Shareable', { key => '0x1B0B0050', create => 1, destroy => 1 , serializer => 'storable' };
    $h{x} = 1;

    my $segs = $k->shm_segments;
    is ref($segs), 'HASH', "shm_segments() as object method returns hash ref";
    ok exists $segs->{'0x1b0b0050'}, "shm_segments() as object method shows our segment";

    my @unknown = $k->unknown_segments;
    ok !grep({ $_ eq '0x1b0b0050' } @unknown),
        "unknown_segments() as object method excludes our registered segment";

    IPC::Shareable->clean_up_all;
}

# -----------------------------------------------------------------------
# shm_segments($filter_key) - filter to a specific segment tree
# -----------------------------------------------------------------------

{
    # Create two unrelated segments plus a parent-with-child (JSON serializer
    # creates child segments for nested refs).
    tie my %parent, 'IPC::Shareable', {
        key        => '0x1B0B0060',
        create     => 1,
        destroy    => 1,
        serializer => 'json',
    };
    tie my %other, 'IPC::Shareable', {
        key    => '0x1B0B0070',
        create => 1,
        destroy => 1,
            serializer => 'storable',
    };

    $parent{child} = { nested => 1 };   # creates a child segment
    $other{x}      = 1;

    # Filter to just the parent key — should include parent and its child,
    # but not the unrelated segment.
    my $filtered = IPC::Shareable->shm_segments('0x1B0B0060');

    is ref($filtered), 'HASH',
        "shm_segments(filter) returns a hash ref";

    ok exists $filtered->{'0x1b0b0060'},
        "shm_segments(filter) includes the requested segment";

    ok !exists $filtered->{'0x1b0b0070'},
        "shm_segments(filter) excludes unrelated segment";

    # Filter to a key that doesn't exist — should return an empty hash.
    my $empty = IPC::Shareable->shm_segments('0x1B0BFFFF');
    is ref($empty), 'HASH',
        "shm_segments(nonexistent filter) still returns a hash ref";
    is scalar(keys %$empty), 0,
        "shm_segments(nonexistent filter) returns empty hash";

    IPC::Shareable->clean_up_all;
}

done_testing;
