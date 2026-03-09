#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

# Using an IO::K8s class in a non-K8s package must NOT
# leak the k8s DSL function or Moo sugar into that package.

{
    package My::App;
    use Moo;
    use IO::K8s::Api::Core::V1::Secret;

    has k8s => (is => 'ro');
}

ok(My::App->can('k8s'), 'My::App has k8s accessor');
ok(!My::App->does('IO::K8s::Role::Resource'),
    'My::App does NOT compose IO::K8s::Role::Resource');

my $app = My::App->new(k8s => 'hello');
is($app->k8s, 'hello', 'k8s accessor works normally');

done_testing;
