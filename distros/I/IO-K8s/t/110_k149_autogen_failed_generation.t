#!/usr/bin/env perl
# k149: a failed root generation in IO::K8s::AutoGen must not leave a usable
# half-built class behind.
#
# Confirmed repro:
#   IO::K8s->new(openapi_spec => { definitions => {
#       'review.v1.Widget' => {
#           type => 'object',
#           'x-kubernetes-group-version-kind' =>
#               [{ group => 'review.example', version => 'v1', kind => 'Widget' }],
#           properties => {
#               okay    => { type => 'string' },
#               zbroken => { '$ref' => '#/definitions/Missing' },
#           },
#       },
#   }})->inflate({ kind => 'Widget', apiVersion => 'review.example/v1',
#                  okay => 'x', zbroken => { a => 1 } });
# dies correctly the first time ("Cannot resolve the $ref 'Missing'"), but an
# identical second call on the SAME instance SUCCEEDS and returns an object
# with no api_version() method.
#
# Cause, in lib/IO/K8s/AutoGen.pm:
#   get_or_generate (~103-110) returns the cached class name the instant
#   %_generated is set for it; _generate_class (~185) sets that flag at
#   ~209-210, BEFORE the per-property loop (~274-281) that can croak on an
#   unresolved $ref (_croak_unresolved_ref, ~347). Class identity (api_version/
#   kind) and role composition only happen afterwards, at ~284-311 -- never
#   reached once the loop has died. So the first call dies with the class
#   already permanently marked "generated", and every later call for that
#   same class name hits the early-return at ~107 and hands back the
#   half-built package: attributes declared before the death exist, but no
#   identity, no APIObject role, no api_version/kind/metadata.
#   A nested class started as a side effect of the same doomed run
#   (_nested_class, ~439-467, tracked via %_nested_origin) is subject to the
#   very same problem: it can finish generating cleanly before its *sibling*
#   field kills the parent, and nothing currently un-does that.
#   clear_cache (~1195-1201) only resets AutoGen's own %_generated/
#   %_nested_origin/etc -- it does not (and structurally cannot) touch
#   IO::K8s.pm's own per-instance %_autogen_cache (_autogen_class_for), so a
#   class that already "succeeded" broken once keeps being handed out
#   unchanged even after clear_cache.
#
# Approved fix contract (NOT implemented by this file -- these are
# regression tests pinning it down before the fix exists):
#   - Root generation is a small transaction: on failure, EVERY class newly
#     started during that run, for that namespace, is permanently marked
#     failed -- including a dependency that itself finished cleanly.
#   - Retrying an identical request reproduces the ORIGINAL error.
#   - A class that was already complete before the failing run started is
#     untouched.
#   - clear_cache() does not revive a half-built class.
#   - The repaired schema works normally in a fresh IO::K8s instance / a
#     fresh AutoGen namespace.
#
# Pure local fixtures -- no network, no cluster.

use strict;
use warnings;
use Test::More;
use Test::Exception;
use lib 'lib';

use IO::K8s;
use IO::K8s::AutoGen;

# ---- fixtures --------------------------------------------------------

# The confirmed-bug schema: a Widget with one good field and one field whose
# $ref cannot be resolved against the (deliberately incomplete) spec.
sub widget_schema_with_unresolvable_ref {
    return {
        type => 'object',
        'x-kubernetes-group-version-kind' =>
            [ { group => 'review.example', version => 'v1', kind => 'Widget' } ],
        properties => {
            okay    => { type => 'string' },
            zbroken => { '$ref' => '#/definitions/Missing' },
        },
    };
}

sub widget_openapi_spec {
    return { definitions => { 'review.v1.Widget' => widget_schema_with_unresolvable_ref() } };
}

# A->B->A: A's fields are named so 'aaa_child' (a good $ref to B) is
# generated before 'zzz_broken' (the unresolvable $ref) -- properties are
# walked in sorted key order (AutoGen.pm ~274 `for my $prop (sort keys
# %$properties)`), so B is fully generated as a side effect BEFORE A's own
# failure is discovered. B in turn references back to A.
sub mutual_ref_defs_with_trailing_break {
    return {
        'review.v1.A' => {
            type => 'object',
            'x-kubernetes-group-version-kind' =>
                [ { group => 'review.example', version => 'v1', kind => 'A' } ],
            properties => {
                aaa_child  => { '$ref' => '#/definitions/review.v1.B' },
                zzz_broken => { '$ref' => '#/definitions/Missing' },
            },
        },
        'review.v1.B' => {
            type       => 'object',
            properties => {
                back => { '$ref' => '#/definitions/review.v1.A' },
                name => { type => 'string' },
            },
        },
    };
}

# A clean (no error anywhere) mutual reference, for the "this already works"
# guard.
sub mutual_ref_defs_clean {
    return {
        'review.v1.MutA' => {
            type => 'object',
            'x-kubernetes-group-version-kind' =>
                [ { group => 'review.example', version => 'v1', kind => 'MutA' } ],
            properties => {
                name  => { type => 'string' },
                buddy => { '$ref' => '#/definitions/review.v1.MutB' },
            },
        },
        'review.v1.MutB' => {
            type       => 'object',
            properties => {
                label => { type => 'string' },
                back  => { '$ref' => '#/definitions/review.v1.MutA' },
            },
        },
    };
}

# ============================================================================
# RED: a failed root generation must fail closed on every later, related
# request -- never hand back a usable-looking half-built class.
# ============================================================================

# Claim: an unresolvable $ref makes class generation fail every time it is
# requested, not just the first time -- inflate() must never silently swap
# in the half-built class it left behind.
subtest 'k149 RED: a second identical inflate must fail exactly like the first' => sub {
    my $k8s = IO::K8s->new(openapi_spec => widget_openapi_spec());

    throws_ok {
        $k8s->inflate({
            kind => 'Widget', apiVersion => 'review.example/v1',
            okay => 'x', zbroken => { a => 1 },
        });
    } qr/Missing/, 'first inflate dies naming the unresolved ref (confirmed baseline)';

    throws_ok {
        $k8s->inflate({
            kind => 'Widget', apiVersion => 'review.example/v1',
            okay => 'x', zbroken => { a => 1 },
        });
    } qr/Missing/,
      'second identical inflate on the same instance dies the same way '
    . '(currently: succeeds with a class that has no api_version method)';
};

# Claim: clear_cache() exists "mainly for testing" (its own comment) but must
# never be the reason a permanently-failed generation starts looking
# successful. Once a broken class has already been handed out once, wiping
# AutoGen's cache and retrying must still fail closed, not keep serving the
# same broken class through a cache clear_cache never touches.
subtest 'k149 RED: clear_cache does not revive a previously half-built class' => sub {
    can_ok('IO::K8s::AutoGen', 'clear_cache');

    my $k8s = IO::K8s->new(openapi_spec => widget_openapi_spec());

    # Prime the failure the same way the previous subtest demonstrated:
    # a first call dies, an identical second call currently "succeeds"
    # (the k149 bug) and gets cached at the IO::K8s instance level, a cache
    # AutoGen::clear_cache cannot see.
    eval {
        $k8s->inflate({ kind => 'Widget', apiVersion => 'review.example/v1', okay => 'x', zbroken => {} });
    };
    eval {
        $k8s->inflate({ kind => 'Widget', apiVersion => 'review.example/v1', okay => 'x', zbroken => {} });
    };

    IO::K8s::AutoGen::clear_cache();

    throws_ok {
        $k8s->inflate({ kind => 'Widget', apiVersion => 'review.example/v1', okay => 'x', zbroken => {} });
    } qr/Missing/,
      'a further identical inflate after clear_cache still dies naming the unresolved ref '
    . '(currently: still succeeds, serving the same stale half-built class)';
};

# Claim: a dependency class (B) generated only as a side effect of a run
# that ultimately fails (A's own later field) must not survive that failure
# as a usable class, even though B itself never errored -- the failing run
# is the unit of transactional rollback, not the individual class.
subtest 'k149 RED: a class generated only as a side effect of a failed root run must not survive it' => sub {
    my $ns   = 'IO::K8s::_AUTOGEN_k149_ab_sideeffect';
    my $defs = mutual_ref_defs_with_trailing_break();

    throws_ok {
        IO::K8s::AutoGen::get_or_generate(
            'review.v1.A', $defs->{'review.v1.A'}, $defs, $ns,
            api_version => 'review.example/v1', kind => 'A', resource_plural => 'as',
        );
    } qr/Missing/, 'generating A dies on its own unresolved ref, after B was generated as a side effect';

    my $b_class = IO::K8s::AutoGen::def_to_class('review.v1.B', $ns);
    my @finished = IO::K8s::AutoGen::generated_classes();
    ok(!(grep { $_ eq $b_class } @finished),
        'B does not appear as a finished class in generated_classes once the run that started it failed '
      . '(currently: B is fully generated, independently usable, and IS listed)');

    dies_ok {
        IO::K8s::AutoGen::get_or_generate('review.v1.B', $defs->{'review.v1.B'}, $defs, $ns);
    } 'requesting B again after the run failed must fail closed too, not hand back the orphaned class '
    . '(currently: succeeds and returns a fully working B)';

    throws_ok {
        IO::K8s::AutoGen::get_or_generate(
            'review.v1.A', $defs->{'review.v1.A'}, $defs, $ns,
            api_version => 'review.example/v1', kind => 'A', resource_plural => 'as',
        );
    } qr/Missing/,
      'retrying A reproduces the original error, not a half-built class '
    . '(currently: succeeds with a class that has no api_version method)';
};

# ============================================================================
# GUARDS: behaviour the fix must not break. These already pass today.
# ============================================================================

# Claim: generating a valid class twice is a genuine cache hit -- the same
# class comes back both times, no work is repeated.
subtest 'GUARD: a successful generation is cached and repeat requests return the identical class' => sub {
    my $ns     = 'IO::K8s::_AUTOGEN_k149_cachehit';
    my $schema = {
        type => 'object',
        'x-kubernetes-group-version-kind' =>
            [ { group => 'review.example', version => 'v1', kind => 'Cached' } ],
        properties => { name => { type => 'string' } },
    };
    my $defs = { 'review.v1.Cached' => $schema };

    my $first = IO::K8s::AutoGen::get_or_generate(
        'review.v1.Cached', $schema, $defs, $ns,
        api_version => 'review.example/v1', kind => 'Cached', resource_plural => 'cacheds',
    );
    my $second = IO::K8s::AutoGen::get_or_generate(
        'review.v1.Cached', $schema, $defs, $ns,
        api_version => 'review.example/v1', kind => 'Cached', resource_plural => 'cacheds',
    );
    is($second, $first, 'the second request returns the exact same class name');
    is($first->can('api_version') ? $first->api_version : undef, 'review.example/v1',
        'the cached class is a genuinely complete, usable class');
};

# Claim: a field referencing its own class (A.child => A) already works and
# round-trips -- the fix must not regress this established self-reference
# support.
subtest 'GUARD: a clean self-reference generates and round-trips' => sub {
    my $ns     = 'IO::K8s::_AUTOGEN_k149_selfref';
    my $schema = {
        type => 'object',
        'x-kubernetes-group-version-kind' =>
            [ { group => 'review.example', version => 'v1', kind => 'Node' } ],
        properties => {
            name  => { type => 'string' },
            child => { '$ref' => '#/definitions/review.v1.Node' },
        },
    };
    my $defs = { 'review.v1.Node' => $schema };

    my $class = IO::K8s::AutoGen::get_or_generate(
        'review.v1.Node', $schema, $defs, $ns,
        api_version => 'review.example/v1', kind => 'Node', resource_plural => 'nodes',
    );
    my $node = $class->new(name => 'root', child => { name => 'kid' });
    isa_ok($node->child, $class, 'the nested child inflates to the same generated class');
    is($node->TO_JSON->{child}{name}, 'kid', 'the self-referencing field round-trips');
};

# Claim: a genuine mutual reference (A<->B, neither side ever erroring)
# already works and round-trips both ways -- the fix must not regress this.
subtest 'GUARD: a clean mutual reference generates and round-trips both ways' => sub {
    my $ns   = 'IO::K8s::_AUTOGEN_k149_mutualok';
    my $defs = mutual_ref_defs_clean();

    my $a_class = IO::K8s::AutoGen::get_or_generate(
        'review.v1.MutA', $defs->{'review.v1.MutA'}, $defs, $ns,
        api_version => 'review.example/v1', kind => 'MutA', resource_plural => 'mutas',
    );
    my $a = $a_class->new(name => 'a1', buddy => { label => 'b1', back => { name => 'a-nested' } });
    isa_ok($a->buddy, IO::K8s::AutoGen::def_to_class('review.v1.MutB', $ns), 'buddy inflates to the B class');
    isa_ok($a->buddy->back, $a_class, 'buddy->back inflates back to the A class');
    is($a->TO_JSON->{buddy}{back}{name}, 'a-nested', 'the mutual reference round-trips through both classes');
};

# Claim: a class that finished generating cleanly before an unrelated later
# request fails must go on working exactly as before -- the fix's
# transactional rollback must be scoped to the failing run, not the whole
# namespace's history.
subtest 'GUARD: a previously-complete independent class is unaffected by a later, unrelated failure' => sub {
    my $ns   = 'IO::K8s::_AUTOGEN_k149_independent';
    my $defs = {
        'review.v1.Good' => {
            type => 'object',
            'x-kubernetes-group-version-kind' =>
                [ { group => 'review.example', version => 'v1', kind => 'Good' } ],
            properties => { name => { type => 'string' } },
        },
        'review.v1.Bad' => {
            type => 'object',
            'x-kubernetes-group-version-kind' =>
                [ { group => 'review.example', version => 'v1', kind => 'Bad' } ],
            properties => { broken => { '$ref' => '#/definitions/Missing' } },
        },
    };

    my $good_class = IO::K8s::AutoGen::get_or_generate(
        'review.v1.Good', $defs->{'review.v1.Good'}, $defs, $ns,
        api_version => 'review.example/v1', kind => 'Good', resource_plural => 'goods',
    );
    is($good_class->api_version, 'review.example/v1', 'Good generates successfully before Bad is ever touched');

    throws_ok {
        IO::K8s::AutoGen::get_or_generate(
            'review.v1.Bad', $defs->{'review.v1.Bad'}, $defs, $ns,
            api_version => 'review.example/v1', kind => 'Bad', resource_plural => 'bads',
        );
    } qr/Missing/, 'Bad fails to generate, as expected';

    my $good_again = $good_class->new(name => 'still-good');
    is($good_again->name, 'still-good', 'Good keeps working after the unrelated Bad failure');
};

# Claim: once the schema is repaired, generation must work normally in a
# fresh instance/namespace -- the bug is about a namespace's poisoned state,
# not about the fixed schema being unable to generate at all.
subtest 'GUARD: a repaired schema works in a fresh namespace and has a real identity' => sub {
    my $ns            = 'IO::K8s::_AUTOGEN_k149_repaired';
    my $fixed_schema = {
        type => 'object',
        'x-kubernetes-group-version-kind' =>
            [ { group => 'review.example', version => 'v1', kind => 'Widget' } ],
        properties => {
            okay    => { type => 'string' },
            zbroken => { type => 'string' },
        },
    };
    my $defs = { 'review.v1.Widget' => $fixed_schema };

    my $class = IO::K8s::AutoGen::get_or_generate(
        'review.v1.Widget', $fixed_schema, $defs, $ns,
        api_version => 'review.example/v1', kind => 'Widget', resource_plural => 'widgets',
    );
    is($class->api_version, 'review.example/v1', 'the repaired class has a real api_version()');
    my $widget = $class->new(okay => 'x', zbroken => 'y');
    is_deeply($widget->TO_JSON,
        { apiVersion => 'review.example/v1', kind => 'Widget', okay => 'x', zbroken => 'y' },
        'the repaired class builds and serializes normally');

    # Same repair, but in a fresh IO::K8s instance via the public entry
    # point rather than the AutoGen internals directly.
    my $k8s = IO::K8s->new(openapi_spec => { definitions => $defs });
    my $obj = $k8s->inflate({ kind => 'Widget', apiVersion => 'review.example/v1', okay => 'x', zbroken => 'y' });
    is($obj->api_version, 'review.example/v1', 'the repaired schema also inflates cleanly through a fresh IO::K8s instance');
};

done_testing;
