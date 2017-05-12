#!perl -T

use strict;
use warnings;

use Test::More tests => 85;
use Test::NoWarnings;
use Test::Differences;

BEGIN {
    require_ok('Hash::Map');
}

note 'constructors';
{
    my $package = 'Hash::Map';
    isa_ok(
        scalar $package->new,
        $package,
        'constructor new',
    );
    isa_ok(
        scalar $package->target_ref({t => 1}),
        $package,
        'constructor target_ref',
    );
    isa_ok(
        scalar $package->set_target_ref({t => 1}),
        $package,
        'constructor target_ref',
    );
    isa_ok(
        scalar $package->target(t => 1),
        $package,
        'constructor target',
    );
    isa_ok(
        scalar $package->set_target,
        $package,
        'constructor set_target',
    );
    isa_ok(
        scalar $package->source_ref({s => 1}),
        $package,
        'constructor source_ref',
    );
    isa_ok(
        scalar $package->set_source_ref({s => 1}),
        $package,
        'constructor source_ref',
    );
    isa_ok(
        scalar $package->source(s => 1),
        $package,
        'constructor source',
    );
    isa_ok(
        scalar $package->set_source,
        $package,
        'constructor set_source',
    );
    isa_ok(
        scalar $package->combine,
        $package,
        'constructor combine',
    );
}

note 'set_source, set_target';
{
    my $obj = Hash::Map
        ->set_source(s => 11)
        ->set_target(t => 12);
    eq_or_diff(
        $obj->source_ref,
        { s => 11 },
        'data of set_source',
    );
    eq_or_diff(
        $obj->target_ref,
        { t => 12 },
        'data of set_target',
    );

    $obj->set_source;
    eq_or_diff(
        $obj->source_ref,
        {},
        'data of empty set_source',
    );
    $obj
        ->set_target
        ->set_source_ref({s => 21});
    eq_or_diff(
        $obj->target_ref,
        {},
        'data of empty set_target',
    );
    eq_or_diff(
        $obj->source_ref,
        { s => 21 },
        'data of empty set_target',
    );

    $obj->set_target_ref({t => 22});
    eq_or_diff(
        $obj->target_ref,
        { t => 22 },
        'data of empty set_target',
    );
}

note 'get';
{
    my $obj = Hash::Map->new;
    $obj->target_ref->{t} = 't',
    $obj->source_ref->{s} = 's',
    eq_or_diff(
        { $obj->target },
        { t => 't' },
        'target',
    );
    eq_or_diff(
        { $obj->source },
        { s => 's' },
        'source',
    );
}

note 'clone';
{
    my $obj = Hash::Map->new;
    isnt(
        scalar $obj->target_ref,
        scalar $obj->clone_target->target_ref,
        'clone target',
    );
    isnt(
        scalar $obj->source_ref,
        scalar $obj->clone_source->source_ref,
        'clone source',
    );
}

note 'keys';
{
    my $obj = Hash::Map
        ->set_source(s1 => 11, s2 => 12)
        ->set_target(t1 => 21, t2 => 22);
    eq_or_diff(
        [ sort $obj->source_keys ],
        [ qw( s1 s2 ) ],
        'source keys',
    );
    eq_or_diff(
        [ sort $obj->target_keys ],
        [ qw( t1 t2 ) ],
        'target keys',
    );
    eq_or_diff(
        [ sort @{ $obj->source_keys_ref } ],
        [ qw( s1 s2 ) ],
        'source keys ref',
    );
    eq_or_diff(
        [ sort @{ $obj->target_keys_ref } ],
        [ qw( t1 t2 ) ],
        'target keys ref',
    );
}

note 'values';
{
    my $obj = Hash::Map
        ->set_source(s1 => 11, s2 => 12)
        ->set_target(t1 => 21, t2 => 22);
    eq_or_diff
        [ sort $obj->source_values ],
        [ qw( 11 12 ) ],
        'source values';
    eq_or_diff
        [ sort $obj->target_values ],
        [ qw( 21 22 ) ],
        'target values';
    eq_or_diff
        [ sort @{ $obj->source_values_ref } ],
        [ qw( 11 12 ) ],
        'source values ref';
    eq_or_diff
        [ sort @{ $obj->target_values_ref } ],
        [ qw( 21 22 ) ],
        'target values ref';
}

note 'exists';
{
    my $obj = Hash::Map
        ->set_source(s1 => undef)
        ->set_target(t1 => undef);
    ok(
        $obj->exists_source('s1'),
        'source s1 exists',
    );
    ok(
        ! $obj->exists_source('s2'),
        'source s2 not exists',
    );
    ok(
        $obj->exists_target('t1'),
        'target t1 exists',
    );
    ok(
        ! $obj->exists_target('t2'),
        'target t2 not exists',
    );
}

note 'combine';
{
    my $obj = Hash::Map->target(t1 => 11, t2 => 12);
    $obj->combine(
        Hash::Map->target(t2 => 22, t3 => 23),
        Hash::Map->target(t3 => 33, t4 => 34),
    );
    eq_or_diff(
        { $obj->target },
        {
            t1 => 11,
            t2 => 22,
            t3 => 33,
            t4 => 34,
        },
        'combined target',
    );
}

note 'delete';
{
    eq_or_diff(
        scalar Hash::Map
            ->target(a => 11, b => 12, c => 13, d => 14)
            ->delete_keys(qw(a c))
            ->target_ref,
        {b => 12, d => 14},
        'delete_keys',
    );
    eq_or_diff(
        scalar Hash::Map
            ->target_ref({ a => 21, b => 22, c => 23, d => 24 })
            ->delete_keys_ref([ qw(a c) ])
            ->target_ref,
        {b => 22, d => 24},
        'delete_keys_ref',
    );
}

note 'copy keys';
{
    eq_or_diff(
        scalar Hash::Map
            ->target(a => 11)
            ->source(b => 12, c => 13, d => 14)
            ->copy_keys(qw(c d))
            ->target_ref,
        {a => 11, c => 13, d => 14},
        'copy_keys',
    );
    eq_or_diff(
        scalar Hash::Map
            ->target_ref({ a => 21 })
            ->source_ref({ b => 22, c => 23, d => 24 })
            ->copy_keys_ref([ qw(c d) ])
            ->target_ref,
        {a => 21, c => 23, d => 24},
        'copy_keys_ref',
    );
}

note 'copy keys with code_ref';
{
    my $obj = Hash::Map->new;
    eq_or_diff(
        scalar $obj
            ->target(a => 11)
            ->source(b => 12, c => 13, d => 14)
            ->copy_keys(
                qw(c d),
                sub {
                    eq_or_diff(
                        shift,
                        $obj,
                        'copy_keys with code_ref, object in code_ref',
                    );
                    return "p_$_";
                },
            )
            ->target_ref,
        {a => 11, p_c => 13, p_d => 14},
        'copy_keys with code_ref',
    );
    eq_or_diff(
        scalar $obj
            ->target_ref({ a => 21 })
            ->source_ref({ b => 22, c => 23, d => 24 })
            ->copy_keys_ref(
                [ qw(c d) ],
                sub {
                    eq_or_diff(
                        shift,
                        $obj,
                        'copy_keys_ref with code_ref, object in code_ref',
                    );
                    return "p_$_";
                },
            )
            ->target_ref,
        {a => 21, p_c => 23, p_d => 24},
        'copy_keys_ref with code_ref',
    );
}

note 'map keys';
{
    eq_or_diff(
        scalar Hash::Map
            ->target(a => 11)
            ->source(b => 12, c => 13)
            ->map_keys(
                b => q{c},
                c => q{d},
            )
            ->target_ref,
        {a => 11, c => 12, d => 13},
        'map_keys',
    );
    eq_or_diff(
        scalar Hash::Map
            ->target_ref({ a => 21 })
            ->source_ref({ b => 22, c => 23 })
            ->map_keys_ref({
                b => q{c},
                c => q{d},
            })
            ->target_ref,
        {a => 21, c => 22, d => 23},
        'map_keys_ref',
    );
}

note 'merge hash';
{
    eq_or_diff(
        scalar Hash::Map
            ->target(a => 11)
            ->merge_hash(
                a => 12,
                b => 13,
            )
            ->target_ref,
        {a => 12, b => 13},
        'merge_hash',
    );
    eq_or_diff(
        scalar Hash::Map
            ->target_ref({ a => 21 })
            ->merge_hashref({
                a => 22,
                b => 23,
            })
            ->target_ref,
        {a => 22, b => 23},
        'merge_hash_ref',
    );
}

note 'modify';
{
    my $obj = Hash::Map->new;
    eq_or_diff(
        scalar $obj
            ->target(a => 11, b => 12)
            ->modify(
                a => sub {
                    eq_or_diff(
                        shift,
                        $obj,
                        'modify, object in code_ref',
                    );
                    return "pa_$_";
                },
                b => sub {
                    return "pb_$_";
                },
            )
            ->target_ref,
        {a => 'pa_11', b => 'pb_12'},
        'modify',
    );
    eq_or_diff(
        scalar $obj
            ->target_ref({ a => 21, b => 22 })
            ->modify_ref({
                a => sub {
                    eq_or_diff(
                        shift,
                        $obj,
                        'modify_ref, object in code_ref',
                    );
                    return "pa_$_";
                },
                b => sub {
                    return "pb_$_";
                },
            })
            ->target_ref,
        {a => 'pa_21', b => 'pb_22'},
        'modify_ref',
    );
}

note 'copy keys + modify';
{
    my $obj = Hash::Map->new;
    eq_or_diff(
        scalar $obj
            ->source(a => 11, b => 12)
            ->copy_modify(
                a => sub {
                    eq_or_diff(
                        shift,
                        $obj,
                        'copy_modify, object in code_ref',
                    );
                    return "pa_$_";
                },
                b => sub {
                    return "pb_$_";
                },
            )
            ->target_ref,
        {a => 'pa_11', b => 'pb_12'},
        'copy_modify',
    );
    eq_or_diff(
        scalar $obj
            ->source_ref({ a => 21, b => 22 })
            ->copy_modify_ref({
                a => sub {
                    eq_or_diff(
                        shift,
                        $obj,
                        'copy_modify_ref, object in code_ref',
                    );
                    return "pa_$_";
                },
                b => sub {
                    return "pb_$_";
                },
            })
            ->target_ref,
        {a => 'pa_21', b => 'pb_22'},
        'copy_modify_ref',
    );
    eq_or_diff(
        scalar $obj
            ->source(a => 31, b => 32)
            ->copy_modify_identical(
                qw(a b),
                sub {
                    my ($self, $key) = @_;
                    eq_or_diff(
                        $self,
                        $obj,
                        'copy_modify_identical, object in code_ref',
                    );
                    return "p${key}_$_";
                },
            )
            ->target_ref,
        {a => 'pa_31', b => 'pb_32'},
        'copy_modify_identical',
    );
    eq_or_diff(
        scalar $obj
            ->source_ref({ a => 41, b => 42 })
            ->copy_modify_identical_ref(
                [ qw(a b) ],
                sub {
                    my ($self, $key) = @_;
                    eq_or_diff(
                        $self,
                        $obj,
                        'copy_modify_identical_ref, object in code_ref',
                    );
                    return "p${key}_$_";
                },
            )
            ->target_ref,
        {a => 'pa_41', b => 'pb_42'},
        'copy_modify_identical_ref',
    );
}

note 'map keys + modify';
{
    my $obj = Hash::Map->new;
    eq_or_diff(
        scalar $obj
            ->source(a => 11, b => 12)
            ->map_modify(
                a => b => sub {
                    eq_or_diff(
                        shift,
                        $obj,
                        'map_modify, object in code_ref',
                    );
                    return "pab_$_";
                },
                b => c => sub {
                    return "pbc_$_";
                },
            )
            ->target_ref,
        {b => 'pab_11', c => 'pbc_12'},
        'map_modify',
    );
    eq_or_diff(
        scalar $obj
            ->source_ref({ a => 21, b => 22 })
            ->map_modify_ref([
                a => b => sub {
                    eq_or_diff(
                        shift,
                        $obj,
                        'map_modify_ref, object in code_ref',
                    );
                    return "pab_$_";
                },
                b => c => sub {
                    return "pbc_$_";
                },
            ])
            ->target_ref,
        {b => 'pab_21', c => 'pbc_22'},
        'map_modify_ref',
    );
    eq_or_diff(
        scalar $obj
            ->source(a => 31, b => 32)
            ->map_modify_identical(
                a => q{b},
                b => q{c},
                sub {
                    my ($self, $key_source, $key_target) = @_;
                    eq_or_diff(
                        $self,
                        $obj,
                        'map_modify_identical, object in code_ref',
                    );
                    return "p${key_source}${key_target}_$_";
                },
            )
            ->target_ref,
        {b => 'pab_31', c => 'pbc_32'},
        'map_modify_identical',
    );
    eq_or_diff(
        scalar $obj
            ->source_ref({ a => 41, b => 42})
            ->map_modify_identical_ref(
                {a => q{b}, b => q{c}},
                sub {
                    my ($self, $key_source, $key_target) = @_;
                    eq_or_diff(
                        $self,
                        $obj,
                        'map_modify_identical_ref, object in code_ref',
                    );
                    return "p${key_source}${key_target}_$_";
                },
            )
            ->target_ref,
        {b => 'pab_41', c => 'pbc_42'},
        'map_modify_identical_ref',
    );
}

note 'iteration with each';
{
    my $obj = Hash::Map
        ->set_source(s1 => 11, s2 => 12)
        ->set_target(t1 => 21, t2 => 22);
    # source
    {
        my ($key, $value) = $obj->each_source;
        is(
            $value,
            $obj->source_ref->{$key},
            '1st source iteration',
        );
    }
    {
        my ($key, $value) = $obj->each_source;
        is(
            $value,
            $obj->source_ref->{$key},
            '2nd source iteration',
        );
    }
    eq_or_diff(
        [ $obj->each_source ],
        [],
        'empty source iteration',
    );
    # target
    {
        my ($key, $value) = $obj->each_target;
        is(
            $value,
            $obj->target_ref->{$key},
            '1st target iteration',
        );
    }
    {
        my ($key, $value) = $obj->each_target;
        is(
            $value,
            $obj->target_ref->{$key},
            '2nd target iteration',
        );
    }
    eq_or_diff(
        [ $obj->each_target ],
        [],
        'empty target iteration',
    );
}

note 'iteration with code reference';
{
    my $obj = Hash::Map
        ->set_source(s1 => 11, s2 => 12)
        ->set_target(t1 => 21, t2 => 22);
    # source
    {
        my $iterator_code = $obj->source_iterator;
        {
            my ($key, $value) = $iterator_code->();
            eq_or_diff(
                [ $key, $value ],
                [ $key, $obj->source_ref->{$key} ],
                '1st source iteration',
            );
        }
        {
            my ($key, $value) = $iterator_code->();
            eq_or_diff(
                [ $key, $value ],
                [ $key, $obj->source_ref->{$key} ],
                '2nd source iteration',
            );
        }
        eq_or_diff(
            [ $iterator_code->() ],
            [],
            '3rd source iteration',
        );
    }
    # target
    {
        my $iterator_code = $obj->target_iterator;
        {
            my ($key, $value) = $iterator_code->();
            eq_or_diff(
                [ $key, $value ],
                [ $key, $obj->target_ref->{$key} ],
                '1st target iteration',
            );
        }
        {
            my ($key, $value) = $iterator_code->();
            eq_or_diff(
                [ $key, $value ],
                [ $key, $obj->target_ref->{$key} ],
                '2nd target iteration',
            );
        }
        eq_or_diff(
            [ $iterator_code->() ],
            [],
            '3rd target iteration',
        );
    }
}
