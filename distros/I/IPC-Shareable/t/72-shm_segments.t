use warnings;
use strict;

use IPC::Shareable;
IPC::Shareable->testing_set('IPC::Shareable');
use IPC::SysV qw(IPC_CREAT IPC_RMID);
use Test::More;

use FindBin;
use lib $FindBin::Bin;
use IPCShareableTest qw(assert_clean_process unique_glue);

# All keys are per-run unique (so two smokers running this file at once don't
# collide on the same System V segment). hexkey() returns the lowercase
# '0x........' string shm_segments() keys each entry by, computed from a glue
# (or integer) exactly the way the module does. See hexkey() at end of file.

# 0x1B0B0001-equivalent: referenced from two subtests, so defined up here.
my $basic_glue = unique_glue('shmseg_basic');
my $basic_hex  = hexkey($basic_glue);

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
    tie my %h, 'IPC::Shareable', { key => $basic_glue, create => 1, destroy => 1 , serializer => 'storable' };
    $h{test} = 'hello';

    my $segs = IPC::Shareable->shm_segments;

    ok exists $segs->{$basic_hex}, "IPC::Shareable segment appears in shm_segments() output";

    is ref($segs->{$basic_hex}), 'HASH', "...each entry is a hash ref";

    like $segs->{$basic_hex}{content}, qr/^IPC::Shareable/,
        "...segment content starts with 'IPC::Shareable' tag";

    is $segs->{$basic_hex}{local_process}, 1, "...local_process flag is set for this process's segment";
    is $segs->{$basic_hex}{known},         1, "...known is 1 for a segment tied in this process";
}

# -----------------------------------------------------------------------
# shm_segments() - non-IPC::Shareable segment is skipped
# -----------------------------------------------------------------------

{
    my $foreign_key = IPC::Shareable::_key_str_to_int(unique_glue('shmseg_foreign'));
    my $foreign_hex = hexkey($foreign_key);

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
    my $scalar_glue = unique_glue('shmseg_scalar');
    my $scalar_hex  = hexkey($scalar_glue);
    my $hash_glue   = unique_glue('shmseg_hash');
    my $hash_hex    = hexkey($hash_glue);

    my $count_before = scalar keys %{ IPC::Shareable->shm_segments };

    tie my $sv, 'IPC::Shareable', { key => $scalar_glue, create => 1, destroy => 1 , serializer => 'storable' };
    $sv = 'scalar value';

    tie my %hv, 'IPC::Shareable', { key => $hash_glue, create => 1, destroy => 1 , serializer => 'storable' };
    $hv{x} = 1;

    my $segs = IPC::Shareable->shm_segments;
    my $count_after = scalar keys %$segs;

    cmp_ok $count_after, '>=', $count_before + 2,
        "shm_segments() count increases by at least 2 after creating 2 segments";

    ok exists $segs->{$scalar_hex}, "scalar segment key present ok";
    ok exists $segs->{$hash_hex}, "hash segment key present ok";

    is $segs->{$scalar_hex}{local_process}, 1, "scalar segment local_process flag set ok";
    is $segs->{$hash_hex}{local_process}, 1, "hash segment local_process flag set ok";
}

# -----------------------------------------------------------------------
# shm_segments() - keys are lowercase hex strings
# -----------------------------------------------------------------------

{
    my $glue = unique_glue('shmseg_lower');
    my $hex  = hexkey($glue);

    tie my %h, 'IPC::Shareable', { key => $glue, create => 1, destroy => 1 , serializer => 'storable' };
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

    is_deeply $segs->{$hex}{child_keys}, [], "child_keys is empty arrayref for segment with no children";
}

# -----------------------------------------------------------------------
# shm_segments() - child_keys is an arrayref of child hex keys when
# a JSON segment has nested children
# -----------------------------------------------------------------------

{
    my $glue = unique_glue('shmseg_jsonchild');
    my $hex  = hexkey($glue);

    tie my %h, 'IPC::Shareable', { key => $glue, create => 1, destroy => 1, serializer => 'json' };
    $h{a} = 1;
    $h{b} = { x => 10 };   # nested hash → child segment

    my $segs = IPC::Shareable->shm_segments;

    ok exists $segs->{$hex}, "parent segment with JSON child is present";

    my $ck = $segs->{$hex}{child_keys};
    is ref($ck), 'ARRAY', "child_keys is an arrayref for segment with children";
    is scalar(@$ck), 1,   "...with exactly one child key";
    like $ck->[0], qr/^0x[0-9a-f]+$/, "...child key is a hex string";
}

# -----------------------------------------------------------------------
# shm_segments() - known => 0 for an IPC::Shareable-tagged segment
# that is not in any register (simulates a leftover from a dead process)
# -----------------------------------------------------------------------

{
    my $orphan_key = IPC::Shareable::_key_str_to_int(unique_glue('shmseg_orphan'));
    my $orphan_hex = hexkey($orphan_key);

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
    ok !grep({ $_ eq $basic_hex } @unknown), "unknown_segments() excludes a registered segment";

    shmctl($id, IPC_RMID, 0);
}

# -----------------------------------------------------------------------
# remove() - class method with key, all key format variants
# Each creates a tagged-but-unregistered segment, then removes it via
# IPC::Shareable->remove($key) and confirms it is gone from shm_segments()
# -----------------------------------------------------------------------

{
    # text key: gets CRC'd internally — ask the module for the resulting int
    my $text_key     = unique_glue('shmseg_removetext');
    my $text_int     = IPC::Shareable->_shm_key($text_key);
    my $text_hex     = hexkey($text_key);

    my $id1 = shmget($text_int, 128, IPC_CREAT | 0666);
    shmwrite($id1, 'IPC::Shareablefake', 0, 128);
    ok exists(IPC::Shareable->shm_segments->{$text_hex}),
        "text key: segment exists before remove()";
    IPC::Shareable->remove($text_key);
    ok !exists(IPC::Shareable->shm_segments->{$text_hex}),
        "text key: gone after IPC::Shareable->remove(text key)";

    # integer key: decimal integer, used as-is
    my $int_key = IPC::Shareable::_key_str_to_int(unique_glue('shmseg_removeint'));
    my $int_hex = hexkey($int_key);

    my $id2 = shmget($int_key, 128, IPC_CREAT | 0666);
    shmwrite($id2, 'IPC::Shareablefake', 0, 128);
    ok exists(IPC::Shareable->shm_segments->{$int_hex}),
        "int key: segment exists before remove()";
    IPC::Shareable->remove($int_key);
    ok !exists(IPC::Shareable->shm_segments->{$int_hex}),
        "int key: gone after IPC::Shareable->remove(integer)";

    # hex literal key: an integer that you'd write as 0x... in source — at
    # runtime it is just an integer, so it takes the same path as an int key
    my $hex_lit_int = IPC::Shareable::_key_str_to_int(unique_glue('shmseg_removehexlit'));
    my $hex_lit_hex = hexkey($hex_lit_int);

    my $id3 = shmget($hex_lit_int, 128, IPC_CREAT | 0666);
    shmwrite($id3, 'IPC::Shareablefake', 0, 128);
    ok exists(IPC::Shareable->shm_segments->{$hex_lit_hex}),
        "hex literal key: segment exists before remove()";
    IPC::Shareable->remove($hex_lit_int);
    ok !exists(IPC::Shareable->shm_segments->{$hex_lit_hex}),
        "hex literal key: gone after IPC::Shareable->remove(0x... integer)";

    # hex string key: string of the form '0x...'
    my $hex_str_key = hexkey(unique_glue('shmseg_removehexstr'));   # '0x........'
    my $hex_str_hex = lc($hex_str_key);

    my $id4 = shmget(hex($hex_str_key), 128, IPC_CREAT | 0666);
    shmwrite($id4, 'IPC::Shareablefake', 0, 128);
    ok exists(IPC::Shareable->shm_segments->{$hex_str_hex}),
        "hex string key: segment exists before remove()";
    IPC::Shareable->remove($hex_str_key);
    ok !exists(IPC::Shareable->shm_segments->{$hex_str_hex}),
        "hex string key: gone after IPC::Shareable->remove('0x...')";
}

# -----------------------------------------------------------------------
# unknown_segments() - fork-and-exit produces a real orphan from the
# parent's point of view. The child creates a tied segment with
# destroy => 0 and exits; the parent never tied the key, so its
# global_register has no entry for it.
# -----------------------------------------------------------------------

{
    my $orphan_glue = unique_glue('shmseg_forkorphan');
    my $orphan_hex  = hexkey($orphan_glue);

    pipe(my $r, my $w) or die "pipe: $!";

    my $pid = fork;
    defined $pid or die "fork: $!";

    if ($pid == 0) {
        close $r;
        tie my %h, 'IPC::Shareable', {
            key        => $orphan_glue,
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

    IPC::Shareable->remove($orphan_glue);
    ok !exists(IPC::Shareable->shm_segments->{$orphan_hex}),
        "fork+exit orphan: removed via remove(\$key) ok";
}

IPC::Shareable::_end;

assert_clean_process();

# -----------------------------------------------------------------------
# shm_segments() and unknown_segments() called as object methods
# -----------------------------------------------------------------------

{
    my $glue = unique_glue('shmseg_objmethod');
    my $hex  = hexkey($glue);

    my $k = tie my %h, 'IPC::Shareable', { key => $glue, create => 1, destroy => 1 , serializer => 'storable' };
    $h{x} = 1;

    my $segs = $k->shm_segments;
    is ref($segs), 'HASH', "shm_segments() as object method returns hash ref";
    ok exists $segs->{$hex}, "shm_segments() as object method shows our segment";

    my @unknown = $k->unknown_segments;
    ok !grep({ $_ eq $hex } @unknown),
        "unknown_segments() as object method excludes our registered segment";

    IPC::Shareable->clean_up_all;
}

# -----------------------------------------------------------------------
# shm_segments($filter_key) - filter to a specific segment tree
# -----------------------------------------------------------------------

{
    # Create two unrelated segments plus a parent-with-child (JSON serializer
    # creates child segments for nested refs).
    my $parent_glue = unique_glue('shmseg_filterparent');
    my $parent_hex  = hexkey($parent_glue);
    my $other_glue  = unique_glue('shmseg_filterother');
    my $other_hex   = hexkey($other_glue);

    tie my %parent, 'IPC::Shareable', {
        key        => $parent_glue,
        create     => 1,
        destroy    => 1,
        serializer => 'json',
    };
    tie my %other, 'IPC::Shareable', {
        key    => $other_glue,
        create => 1,
        destroy => 1,
            serializer => 'storable',
    };

    $parent{child} = { nested => 1 };   # creates a child segment
    $other{x}      = 1;

    # Filter to just the parent key — should include parent and its child,
    # but not the unrelated segment.
    my $filtered = IPC::Shareable->shm_segments($parent_glue);

    is ref($filtered), 'HASH',
        "shm_segments(filter) returns a hash ref";

    ok exists $filtered->{$parent_hex},
        "shm_segments(filter) includes the requested segment";

    ok !exists $filtered->{$other_hex},
        "shm_segments(filter) excludes unrelated segment";

    # Filter to a key that doesn't exist — should return an empty hash.
    my $empty = IPC::Shareable->shm_segments(unique_glue('shmseg_nonexistent'));
    is ref($empty), 'HASH',
        "shm_segments(nonexistent filter) still returns a hash ref";
    is scalar(keys %$empty), 0,
        "shm_segments(nonexistent filter) returns empty hash";

    IPC::Shareable->clean_up_all;
}

done_testing;

# Lowercase '0x........' string for a glue or integer, matching how
# shm_segments() keys its output (sprintf '0x%08x' of the integer key).
sub hexkey {
    return sprintf '0x%08x', IPC::Shareable::_key_str_to_int($_[0]);
}
