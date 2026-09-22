#!/usr/bin/env perl
# D1: an IO::K8s built with strict => 1 dies on an unknown field at any
# nesting level, naming class and field; the flag never leaks out of the
# call, and a non-strict instance in the same process still preserves.
use strict;
use warnings;
use Test::More;
use Test::Exception;

use IO::K8s;

my $strict = IO::K8s->new(strict => 1);
my $lax    = IO::K8s->new;

ok(!$lax->strict, 'strict is off by default');

throws_ok {
    $strict->inflate({
        apiVersion => 'v1', kind => 'Pod',
        metadata   => { name => 'x' },
        spec       => { containers => [], bogus => 1 },
    });
} qr/^Unknown field 'bogus' for IO::K8s::Api::Core::V1::PodSpec$/m,
    'inflate: unknown spec field dies naming class and field';

throws_ok {
    $strict->new_object('Pod',
        metadata => { name => 'x' },
        spec     => { containers => [ { name => 'c', typo => 1 } ] },
    );
} qr/Unknown field 'typo' for IO::K8s::Api::Core::V1::Container/,
    'new_object: unknown field inside an array element dies';

throws_ok {
    $strict->json_to_object('Pod', '{"metadata":{"name":"x"},"spec":{"containers":[],"nope":true}}');
} qr/Unknown field 'nope' for IO::K8s::Api::Core::V1::PodSpec/,
    'json_to_object honours strict';

throws_ok {
    $strict->struct_to_object('Pod', { metadata => { name => 'x' }, oops => 1 });
} qr/Unknown field 'oops' for IO::K8s::Api::Core::V1::Pod/,
    'struct_to_object honours strict';

throws_ok {
    $strict->new_object('Pod',
        metadata => { name => 'x' },
        spec     => { containers => [], zzz => 1, aaa => 1 },
    );
} qr/^Unknown field 'aaa' for IO::K8s::Api::Core::V1::PodSpec$/m,
    'two unknown keys on one object: the die names the alphabetically first';

subtest 'inline-struct coercer path is covered' => sub {
    # AgentSandbox's v1beta1 track is modeled to full depth (D5/D6, k95) and
    # coerces spec through the regular named-class path now; v1alpha1 (D7
    # back-compat, unmodeled below the top level) is the distribution's
    # remaining inline-struct example -- 'operatingMode' is a v1beta1-only
    # field, so it is unknown on the v1alpha1 inline spec.
    my $sb = IO::K8s->new(strict => 1, with => ['IO::K8s::AgentSandbox']);
    throws_ok {
        $sb->struct_to_object(
            'IO::K8s::AgentSandbox::V1alpha1::Sandbox',
            {
                metadata => { name => 'x', namespace => 'd' },
                spec     => { operatingMode => 'Running', shutdownPolicy => 'Retain' },
            },
        );
    } qr/Unknown field 'operatingMode' for IO::K8s::AgentSandbox::V1alpha1::Sandbox::_Spec/,
        'the k91 example dies under strict';
};

lives_ok {
    $strict->inflate({ apiVersion => 'v1', kind => 'Pod', metadata => { name => 'x' } });
} 'apiVersion and kind in the struct are not unknown fields';

is($IO::K8s::Resource::STRICT, 0, 'the flag is restored after a strict call');

is(
    $lax->new_object('Pod', metadata => { name => 'x' }, spec => { containers => [], bogus => 1 })
        ->TO_JSON->{spec}{bogus},
    1,
    'a non-strict instance in the same process still preserves',
);

subtest 'load_yaml goes through inflate and inherits strict' => sub {
    throws_ok {
        $strict->load_yaml("apiVersion: v1\nkind: Pod\nmetadata:\n  name: x\nspec:\n  containers: []\n  bogus: 1\n");
    } qr/Unknown field 'bogus'/, 'load_yaml dies';
    my ($objects, $errors) = $strict->load_yaml(
        "apiVersion: v1\nkind: Pod\nmetadata:\n  name: x\nspec:\n  containers: []\n  bogus: 1\n",
        collect_errors => 1,
    );
    is(scalar @$objects, 0, 'collect_errors: nothing inflated');
    like($errors->[0], qr/Pod\/x: Unknown field 'bogus'/, 'collect_errors: the error is collected with kind/name');
};

done_testing;
