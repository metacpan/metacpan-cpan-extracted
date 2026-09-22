#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use Test::More;
use IO::K8s;
use IO::K8s::List;

# k64: IO::K8s::List had to_json/TO_JSON but no from_json/FROM_HASH, the
# last class behaving that way after k59 made every Role::Resource class
# to_json/from_json symmetric. A caller who serialized a List and tried to read
# it back hit "Can not locate object method from_json". List is a container,
# not a Role::Resource, so it does not consume the role -- it grows its own
# from_json that decodes UTF-8 bytes and delegates to FROM_STRUCT, and its
# to_json is byte-oriented to match every other class (the k53 convention).

my $k8s = IO::K8s->new;
my $pod = $k8s->new_object('Pod', {
    metadata => { name => 'p', annotations => { note => 'grün-Ünïcöde' } },
});
my $list = IO::K8s::List->new(items => [$pod]);

my $bytes = $list->to_json;

# to_json emits a UTF-8 encoded byte string, exactly what from_json expects and
# what every Role::Resource class already produces (k53).
ok(!utf8::is_utf8($bytes), 'List->to_json emits a UTF-8 byte string, not a wide-char string');

can_ok('IO::K8s::List', 'from_json');

my $back = IO::K8s::List->from_json($bytes);
isa_ok($back, 'IO::K8s::List', 'from_json returns a List');
is(scalar @{$back->items}, 1, 'one item round-tripped');
isa_ok($back->items->[0], 'IO::K8s::Api::Core::V1::Pod', 'item inflated back to a Pod object');
is($back->items->[0]->metadata->annotations->{note}, 'grün-Ünïcöde',
   'non-ASCII annotation survives the byte-oriented round-trip');
is($back->kind, 'PodList', 'kind derived on the way back');
is($back->api_version, 'v1', 'api_version derived on the way back');

done_testing;
