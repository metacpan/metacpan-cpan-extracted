#!/usr/bin/env perl
# IO::K8s::load_class memoises successful loads (k102 measurement round).
#
# load_class is on the hot path -- once per nested object on every inflate,
# once per hashref coercion into a named class -- and each call used to go
# through Module::Runtime::require_module, which re-validates the module
# name, rebuilds the notional filename and re-checks %INC to reach a hit
# that has been true since the first call. Memoising the successes is worth
# ~15% of a full inflate.
#
# The danger is not the hit, it is what gets remembered. A memo over a
# *load* is not a memo over a value:
#
#   * a FAILED load must never be recorded. A class that is not loadable
#     right now may be loadable a moment later -- IO::K8s::AutoGen builds
#     classes into a per-instance namespace at runtime, the k8s DSL builds
#     inline-struct packages the same way, and both only become visible to
#     require_module once Moo has registered them in %INC. A negative entry
#     would pin the first answer forever and surface as a Heisenbug: the
#     same call succeeds or fails depending on what asked first.
#
#   * a package that exists WITHOUT ever being require'd must keep working.
#     Moo enters generated packages into %INC as '(eval NNN)', which is why
#     require_module finds them; the memo must not be stricter than that.
#
# So these tests are deliberately not "a loaded class is found again" --
# that one passes with or without the memo and proves nothing here.
#
# Pure local fixtures -- no network, no cluster.

use strict;
use warnings;
use Test::More;
use lib 'lib';
use IO::K8s;

# ----------------------------------------------------------------------------
# A failed load is not remembered
# ----------------------------------------------------------------------------
# The load-bearing assertion is the third one: after the package appears,
# the very next call must succeed. A memo that stored the failure would
# still die there, and no amount of "it dies twice" would show it.

subtest 'failed load is retried, never cached as broken' => sub {
    my $k8s = IO::K8s->new;
    my $late = 'IO::K8s::Test::LoadClassMemo::BornLate';

    my $first = eval { $k8s->load_class($late); 1 };
    ok(!$first, 'first load of an absent class dies');
    like($@, qr/Can't locate/, '  ... with the usual require message');

    my $second = eval { $k8s->load_class($late); 1 };
    ok(!$second, 'second load of a still-absent class dies again');
    like($@, qr/Can't locate/, '  ... still the real require error, not a memo');

    # The package now appears the way IO::K8s::AutoGen and the inline-struct
    # DSL make one appear: built at runtime, never on disk. Moo registers it
    # in %INC itself, so nothing here seeds %INC by hand.
    eval "package $late; use IO::K8s::Resource; k8s name => Str; 1"
        or die "could not build the runtime class: $@";
    ok(defined $INC{'IO/K8s/Test/LoadClassMemo/BornLate.pm'},
        'Moo registered the runtime-built package in %INC');

    ok(eval { $k8s->load_class($late); 1 },
        'load_class succeeds once the package exists')
        or diag "load_class still refuses a class that now exists: $@";

    is(ref($late->new(name => 'x')), $late, '  ... and the class is usable');
};

# ----------------------------------------------------------------------------
# Runtime-built packages are not treated worse than the uncached path
# ----------------------------------------------------------------------------

subtest 'AutoGen class with no file on disk stays loadable' => sub {
    my $spec = { definitions => {
        'com.example.v1.Widget' => {
            type => 'object',
            properties => { size => { type => 'integer' } },
            'x-kubernetes-group-version-kind' =>
                [ { group => 'example.com', version => 'v1', kind => 'Widget' } ],
        },
    } };

    my $k8s = IO::K8s->new(openapi_spec => $spec);
    my $class = $k8s->expand_class('Widget');
    like($class, qr/^IO::K8s::_AUTOGEN_/, 'Widget auto-generated into the instance namespace');

    ok(eval { $k8s->load_class($class); 1 }, 'load_class accepts the generated class')
        or diag $@;
    ok(eval { $k8s->load_class($class); 1 }, '  ... and again on the memoised path')
        or diag $@;

    my $obj = $k8s->new_object('Widget', { size => 3 });
    is($obj->size, 3, 'the generated class round-trips through new_object');
};

subtest 'inline-struct package built by the k8s DSL stays loadable' => sub {
    # k116 routes hashref coercion into an inline struct through
    # _struct_to_object_expanded, so this hits load_class on a package that
    # only ever existed in memory.
    {
        package IO::K8s::Test::LoadClassMemo::Inline;
        use IO::K8s::Resource;
        k8s name => Str;
        k8s spec => { replicas => Int };
    }

    my $one = IO::K8s::Test::LoadClassMemo::Inline->new(
        name => 'a', spec => { replicas => 1 });
    my $two = IO::K8s::Test::LoadClassMemo::Inline->new(
        name => 'b', spec => { replicas => 2 });

    is($one->spec->replicas, 1, 'first build coerces the inline struct');
    is($two->spec->replicas, 2, 'second build takes the memoised path and still coerces');
    isnt(ref($one->spec), 'HASH', '  ... to an object, not a passed-through hashref');
};

# ----------------------------------------------------------------------------
# The memo is per class name, and shared by both call styles
# ----------------------------------------------------------------------------

subtest 'memo does not leak between class names' => sub {
    my $k8s = IO::K8s->new;
    ok(eval { $k8s->load_class('IO::K8s::Api::Core::V1::Pod'); 1 }, 'a real class loads');
    ok(!eval { $k8s->load_class('IO::K8s::Test::LoadClassMemo::StillAbsent'); 1 },
        'an absent class still dies after an unrelated success');
};

subtest 'memo is shared between the class-method and instance call styles' => sub {
    # t/51 calls IO::K8s->load_class(...) directly; both styles must agree.
    my $class = 'IO::K8s::Api::Apps::V1::Deployment';
    ok(eval { IO::K8s->load_class($class); 1 }, 'class-method call loads');
    ok(eval { IO::K8s->new->load_class($class); 1 }, 'instance call agrees');
    ok(eval { IO::K8s->new->load_class($class); 1 }, 'a second instance agrees too');
};

# ----------------------------------------------------------------------------
# The memo actually memoises
# ----------------------------------------------------------------------------
# Without reaching into the lexical cache, the one observable difference
# between "memoised" and "calls require_module every time" is what happens
# after a successful load's %INC entry is taken away: require_module would
# go looking for the file again, the memo does not.
#
# This pins the deliberate trade-off, not an accident. load_class answers
# "has this name been loaded in this process", and a package does not
# un-load when someone edits %INC; a caller that wants a module re-read
# (Module::Refresh and friends) was never served by load_class anyway.

subtest 'a successful load is not re-required when %INC is edited' => sub {
    my $k8s = IO::K8s->new;
    my $ghost = 'IO::K8s::Test::LoadClassMemo::Ghost';
    my $file  = 'IO/K8s/Test/LoadClassMemo/Ghost.pm';

    $INC{$file} = '(seeded by t/90)';
    ok(eval { $k8s->load_class($ghost); 1 }, 'loads while the %INC entry is present');

    delete $INC{$file};
    ok(eval { $k8s->load_class($ghost); 1 },
        'still loads after the %INC entry is removed -- the success was memoised');
};

# ----------------------------------------------------------------------------
# Bad arguments keep failing the way they did
# ----------------------------------------------------------------------------
# k39 depends on an undef class reaching load_class and dying out of
# Module::Runtime with its own message. Consulting a hash with an undef key
# on the way there would add an 'uninitialized value' warning to that path.

subtest 'undef and non-module arguments die unchanged and warn nothing' => sub {
    my $k8s = IO::K8s->new;

    for my $case ( [ undef, 'undef' ], [ '', 'empty string' ], [ 'not a module', 'garbage' ] ) {
        my ($arg, $label) = @$case;
        my @warnings;
        local $SIG{__WARN__} = sub { push @warnings, $_[0] };

        my $ok = eval { $k8s->load_class($arg); 1 };
        ok(!$ok, "load_class($label) dies");
        like($@, qr/is not a module name/,
            "  ... out of Module::Runtime, not out of the memo");
        is_deeply(\@warnings, [],
            '  ... without an uninitialized-value warning on the way');
    }

    # k39 names this message specifically: an unresolvable GVK reaches
    # load_class as undef and must die here, not earlier and not louder.
    eval { $k8s->load_class(undef) };
    is($@, "argument is not a module name\n",
        'undef still produces exactly the k39 message');
};

# ----------------------------------------------------------------------------
# Return value
# ----------------------------------------------------------------------------

subtest 'load_class returns true on both the miss and the hit' => sub {
    my $k8s = IO::K8s->new;
    my $class = 'IO::K8s::Api::Core::V1::ConfigMap';
    ok($k8s->load_class($class), 'true on the first (uncached) call');
    ok($k8s->load_class($class), 'true on the memoised call');
};

done_testing;
