use warnings;
use strict;

use Test::More;
use IPC::Shareable;

my $segs_before = IPC::Shareable::seg_count();
my $sems_before = IPC::Shareable::sem_count();
warn "Segs Before: $segs_before\n" if $ENV{PRINT_SEGS};

# _key_str_to_int: decimal integer string
{
    my $result = IPC::Shareable::_key_str_to_int('454328512');
    is $result, 454328512, "_key_str_to_int: decimal string returns its numeric value";
}

# _key_str_to_int: plain text CRC path — CRC below MAX_KEY_INT_SIZE
{
    my $result = IPC::Shareable::_key_str_to_int('bar');   # crc32=1996459178, under limit
    ok defined($result), "_key_str_to_int: text key 'bar' returns defined integer";
    like "$result", qr/^\d+$/, "_key_str_to_int: 'bar' result is a non-negative integer";
}

# _key_str_to_int: plain text CRC path — CRC above MAX_KEY_INT_SIZE
{
    my $result = IPC::Shareable::_key_str_to_int('foo');   # crc32=2356372769, OVER limit
    ok defined($result), "_key_str_to_int: text key 'foo' (CRC > limit) returns defined integer";
    like "$result", qr/^\d+$/, "_key_str_to_int: 'foo' result is a non-negative integer";
    cmp_ok $result, '<', 0x80000000, "_key_str_to_int: 'foo' result was reduced below MAX_KEY_INT_SIZE";
}

# _encode_json_prepare: fallthrough return for non-HASH/ARRAY/SCALAR/REF ref type.
# We use a CODE ref here because its reftype is 'CODE' on every Perl version.
# Regexp refs report reftype 'SCALAR' on 5.10.1 and 'Regexp' from 5.12 onwards,
# which would steer this test through the SCALAR/REF branch on old Perls.
{
    my $code   = sub { 42 };
    my $result = IPC::Shareable::_encode_json_prepare($code);
    is ref($result), 'CODE',
        "_encode_json_prepare: non-HASH/ARRAY/SCALAR/REF ref returned unchanged";
    is $result->(), 42, "_encode_json_prepare: returned coderef is the same one passed in";
}

# _decode_json: returns undef when segment data lacks the IPC::Shareable tag
{
    package FakeSeg;
    sub new  { bless { _d => $_[1] }, $_[0] }
    sub data { $_[0]->{_d} }
    package main;

    my $seg    = FakeSeg->new("untagged content -- no IPC::Shareable prefix here");
    my $result = IPC::Shareable::_decode_json($seg, undef);
    is $result, undef, "_decode_json: returns undef for untagged segment data";
}

# _is_child: returns undef when the value is not tied to IPC::Shareable
{
    my $plain  = {};   # plain untied hashref
    my $result = IPC::Shareable::_is_child($plain);
    is $result, undef, "_is_child: returns undef for an untied hashref";
}

# _magic_tie: croaks for an unsupported ref type
{
    my $knot = tie my %h, 'IPC::Shareable', { create => 1, destroy => 1 , serializer => 'storable' };

    my $code = sub { 42 };   # CODE ref — not HASH/ARRAY/SCALAR

    is eval { IPC::Shareable::_magic_tie($knot, $code, 'x'); 1 }, undef,
        "_magic_tie: croaks when value type is CODE";
    like $@, qr/Variables of type CODE not implemented/,
        "_magic_tie: error message names the bad type";
}

IPC::Shareable->clean_up_all;
IPC::Shareable::_end;

my $segs_after = IPC::Shareable::seg_count();
warn "Segs After: $segs_after\n" if $ENV{PRINT_SEGS};
is $segs_after, $segs_before, "segment count restored after cleanup";
my $sems_after = IPC::Shareable::sem_count();
is $sems_after, $sems_before, "All semaphore sets cleaned up ok";

done_testing;
