use warnings;
use strict;

use IPC::Shareable;
IPC::Shareable->testing_set('IPC::Shareable');
use Test::More;

use FindBin;
use lib $FindBin::Bin;
use IPCShareableTest qw(assert_clean_process unique_glue require_free_sem_sets);

require_free_sem_sets();


# Class method call croaks
{
    eval { IPC::Shareable->seg_map };
    like $@, qr/must be called as an object method/, "seg_map: croaks when called as class method ok";
}

# Single segment (scalar, no children)
{
    my $k = tie my $sv, 'IPC::Shareable', { key => unique_glue('sm74a'), create => 1, exclusive => 1, destroy => 1 , serializer => 'storable' };
    $sv = 'hello';

    my $map = $k->seg_map;

    like $map, qr/IPC::Shareable Segment Map/, "single seg: header present ok";
    like $map, qr/={10,}/,                         "single seg: separator present ok";
    like $map, qr/\[known.*owner\]/,            "single seg: known+owner tags present ok";
    like $map, qr/key:\s+0x/,                  "single seg: key line present ok";
    like $map, qr/seg_id:\s+\d+/,              "single seg: seg_id present ok";
    like $map, qr/sem_id:\s+\d+/,              "single seg: sem_id present ok";
    like $map, qr/1: SEM_MARKER=1/,            "single seg: slot 1 SEM_MARKER=1 ok";
    like $map, qr/2: READERS=0/,               "single seg: slot 2 readers=0 ok";
    like $map, qr/3: WRITERS=0/,               "single seg: slot 3 writers=0 ok";
    like $map, qr/4: PROTECTED=0/,             "single seg: slot 4 PROTECTED=0 ok";
    like $map, qr/Children:\s+\(none\)/,       "single seg: no children ok";
    like $map, qr/Content:\s+"hello"/,         "single seg: Content shows scalar value ok";

    IPC::Shareable->clean_up_all;
}

# Protected segment - PROTECTED semaphore slot should reflect the value
{
    my $kp = tie my %h, 'IPC::Shareable', {
        key       => unique_glue('sm74b'),
        create    => 1,
        exclusive => 1,
        destroy   => 0,
        protected => 777,
            serializer => 'storable',
    };
    $h{x} = 1;

    my $map = $kp->seg_map;

    like $map, qr/PROTECTED=777/, "protected seg: PROTECTED=777 in semaphore slot ok";

    IPC::Shareable->clean_up_protected(777);
}

# Nested segment (hash with a reference child) - parent and child both appear
{
    my $kn = tie my %h, 'IPC::Shareable', { key => unique_glue('sm74c'), create => 1, exclusive => 1, destroy => 1 , serializer => 'storable' };
    $h{nested} = { val => 42 };

    # Force a read to ensure child segment is created
    my $val = $h{nested}{val};

    my $map = $kn->seg_map;

    like $map, qr/Children:\s+0x[0-9a-f]+/,      "nested seg: parent has child hex key ok";
    like $map, qr/Content:.*<child: 0x[0-9a-f]+>/, "nested seg: parent Content shows child reference ok";
    like $map, qr/Content:.*\bval\b.*"42"/,          "nested seg: child Content shows its own data ok";

    IPC::Shareable->clean_up_all;
}

# Object method only shows its own segment tree, not other segments
{
    my $k1 = tie my $sv1, 'IPC::Shareable', { key => unique_glue('sm74d'), create => 1, exclusive => 1, destroy => 1 , serializer => 'storable' };
    my $k2 = tie my $sv2, 'IPC::Shareable', { key => unique_glue('sm74e'), create => 1, exclusive => 1, destroy => 1 , serializer => 'storable' };
    $sv1 = 'first';
    $sv2 = 'second';

    my $hex1 = $k1->{_key_hex};
    my $hex2 = $k2->{_key_hex};

    my $map1 = $k1->seg_map;
    my $map2 = $k2->seg_map;

    like   $map1, qr/\Q$hex1\E/, "object method: shows its own segment ok";
    unlike $map1, qr/\Q$hex2\E/, "object method: does not show other segments ok";
    like   $map2, qr/\Q$hex2\E/, "object method k2: shows its own segment ok";
    unlike $map2, qr/\Q$hex1\E/, "object method k2: does not show other segments ok";

    IPC::Shareable->clean_up_all;
}

IPC::Shareable::_end;

assert_clean_process();

done_testing();
