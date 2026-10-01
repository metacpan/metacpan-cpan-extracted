#!/usr/bin/env perl
# k166: the item_class override IO::K8s::List->FROM_STRUCT reads from the
# struct was used without looking at it. A reference reached Module::Runtime
# ("argument is not a module name") when there were items to inflate, or
# Moo's type check on the item_class attribute ("Reference {} did not pass
# type constraint Maybe[Str]") when there were none; an empty string, or a
# bare '+' that is empty once stripped, died with "`' is not a module name"
# for items and was silently kept for an empty list.
#
# Approved contract:
#   * an item_class that is a reference (plain or blessed) or an empty
#     class name ('' or a bare '+') dies naming the List class, the
#     item_class argument and what it received -- with items and without,
#     on every entry point that reaches FROM_STRUCT (FROM_STRUCT directly,
#     inflate, from_json);
#   * a valid class name, with or without the leading '+', inflates exactly
#     as before; an undef item_class is still "no override".
#
# Messages are matched on class names, the argument name and the received
# shape, never on exact wording. Pure local fixtures -- no network, no
# cluster.

use strict;
use warnings;
use Test::More;
use Test::Exception;
use JSON::MaybeXS ();
use lib 'lib';

use IO::K8s;
use IO::K8s::List;

my $LIST = 'IO::K8s::List';
my $POD  = 'IO::K8s::Api::Core::V1::Pod';

my $k8s  = IO::K8s->new;
my $json = JSON::MaybeXS->new(utf8 => 1, canonical => 1);

# Every way a List payload reaches FROM_STRUCT, as name => code. from_json
# only carries what JSON can: the ref cases it cannot express are skipped.
my %entry = (
    'FROM_STRUCT' => sub { $LIST->FROM_STRUCT($_[0], $k8s) },
    'inflate'     => sub { $k8s->inflate($_[0]) },
    'from_json'   => sub { $LIST->from_json($json->encode($_[0]), $k8s) },
);

# label => [ item_class, received-shape regex, survives JSON encoding ]
my @bad = (
    [ 'a hash reference',   {},                     qr/a reference of type HASH/,        1 ],
    [ 'an array reference', [],                     qr/a reference of type ARRAY/,       1 ],
    [ 'a scalar reference', \'Pod',                 qr/a reference of type SCALAR/,      0 ],
    [ 'an object',          bless({}, 'My::K166'),  qr/an object of class My::K166/,     0 ],
    [ 'a JSON boolean',     JSON::MaybeXS::true(),  qr/an object of class \S*Boolean/,   1 ],
    [ 'an empty string',    '',                     qr/an empty string/,                 1 ],
    [ "a bare '+'",         '+',                    qr/a bare '\+'/,                     1 ],
);

# ===========================================================================
# A bad item_class dies naming the argument
# ===========================================================================

for my $case (@bad) {
    my ($label, $item_class, $shape, $json_ok) = @$case;

    # Claim: with items to inflate and with none, on every entry point, the
    # error names the List class, the item_class argument and the received
    # shape -- not Module::Runtime, not Moo's type constraint.
    subtest "item_class as $label" => sub {
        for my $name (sort keys %entry) {
            next if $name eq 'from_json' && !$json_ok;
            for my $items ([ { metadata => { name => 'a' } } ], []) {
                my $struct = { kind => 'List', item_class => $item_class, items => $items };
                my $what   = $name.' with '.scalar(@$items).' item(s)';
                throws_ok { $entry{$name}->($struct) }
                    qr/\Q$LIST\E->FROM_STRUCT: item_class .*$shape/, $what.': names class, argument and shape';
                eval { $entry{$name}->($struct) };
                unlike($@, qr/is not a module name|did not pass type constraint/,
                    $what.': not a Module::Runtime or type-constraint message');
            }
        }
    };
}

# ===========================================================================
# GUARDS
# ===========================================================================

# Claim: a valid class name, with or without '+', still inflates the items
# as that class and derives kind/apiVersion from it -- items or none.
subtest 'GUARD: a valid item_class works as before' => sub {
    for my $item_class ($POD, '+'.$POD) {
        my $list = $LIST->FROM_STRUCT({
            kind       => 'List',
            item_class => $item_class,
            items      => [ { metadata => { name => 'a' } } ],
        }, $k8s);
        isa_ok($list->items->[0], $POD, "'$item_class': item");
        is($list->kind, 'PodList', "'$item_class': kind");
        is($list->api_version, 'v1', "'$item_class': apiVersion");

        my $empty = $k8s->inflate({ kind => 'List', item_class => $item_class, items => [] });
        is($empty->kind, 'PodList', "'$item_class', empty list: kind");
    }
};

# Claim: an undef item_class is no override -- the item type is derived
# from the list's own Kind, as without the key.
subtest 'GUARD: an undef item_class is no override' => sub {
    my $list = $k8s->inflate({
        kind       => 'PodList',
        apiVersion => 'v1',
        item_class => undef,
        items      => [ { metadata => { name => 'a' } } ],
    });
    isa_ok($list->items->[0], $POD, 'item derived from PodList');
};

done_testing;
