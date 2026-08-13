#!/usr/bin/env perl
# Regression coverage for karr ticket #2:
# KubeAggregator's CamelCase prefix was not recognised by Resource.pm's
# _expand_class, so APIService's spec/status resolved to non-existent
# IO::K8s::Api::KubeAggregator::V1::APIServiceSpec classes instead of the
# shipped IO::K8s::KubeAggregator::Pkg::Apis::Apiregistration::V1::* ones.
#
# Four attribute declarations are affected — they are all covered here via
# the APIService and APIServiceSpec inflate paths:
#
#   APIService->spec                  -> APIServiceSpec
#   APIService->status                -> APIServiceStatus
#   APIServiceSpec->service           -> ServiceReference
#   APIServiceStatus->conditions[]    -> APIServiceCondition
#
# The test asserts each of the four target classes is now found under the
# right namespace, and that the APIService round-trips both ways.

use strict;
use warnings;
use Test::More;
use JSON::MaybeXS;

use IO::K8s;

my $k8s = IO::K8s->new;
my $json = JSON::MaybeXS->new(utf8 => 0, canonical => 1, allow_nonref => 1);

my $NS_PKG  = 'IO::K8s::KubeAggregator::Pkg::Apis::Apiregistration::V1';
my $NS_WRONG = 'IO::K8s::Api::KubeAggregator::V1';

# Canonical upstream object under the package namespace.
my $hash = {
    apiVersion => 'apiregistration.k8s.io/v1',
    kind       => 'APIService',
    metadata   => { name => 'v1.example.com' },
    spec => {
        group                 => 'example.com',
        version               => 'v1',
        groupPriorityMinimum  => 1000,
        versionPriority       => 10,
        caBundle              => 'QmFkQ0FCdW5kbGU=',   # base64
        insecureSkipTLSVerify => JSON::MaybeXS::false,
        service               => {
            name      => 'api-svc',
            namespace => 'apiregistration',
            port      => 443,
        },
    },
};

subtest 'APIService inflates without dying on missing class' => sub {
    my $obj = eval { $k8s->struct_to_object("${NS_PKG}::APIService", $hash) };
    is($@, '', 'no exception') or BAIL_OUT("inflate failed: $@");
    isa_ok($obj, $NS_PKG . '::APIService');
};

subtest 'spec/status/conditions/service all resolve to the KubeAggregator namespace, not the wrong Api namespace' => sub {
    my $obj = $k8s->struct_to_object("${NS_PKG}::APIService", $hash);

    is(ref($obj->spec),
        "${NS_PKG}::APIServiceSpec",
        'spec is the shipped KubeAggregator::Pkg class, not the wrong Api class');
    isnt(ref($obj->spec),
        "${NS_WRONG}::APIServiceSpec",
        'spec does NOT collapse to the wrong Api::KubeAggregator namespace');

    is(ref($obj->spec->service),
        "${NS_PKG}::ServiceReference",
        'service is the shipped ServiceReference class');

    # Status wasn't supplied in the input, but the attribute slot exists and
    # the class is loadable from the wrong namespace. This is what the
    # ticket called out as "dead code" prefix entry.
    ok(eval { $k8s->load_class("${NS_PKG}::APIServiceStatus");    1 }, 'APIServiceStatus is loadable');
    ok(eval { $k8s->load_class("${NS_PKG}::APIServiceCondition"); 1 }, 'APIServiceCondition is loadable');
    ok(eval { $k8s->load_class("${NS_PKG}::ServiceReference");    1 }, 'ServiceReference is loadable');
    ok(!eval { $k8s->load_class("${NS_WRONG}::APIServiceStatus");  1 },
        'wrong-namespace class is genuinely not shipped (sanity)');
};

subtest 'APIServiceStatus with a populated conditions array resolves APIServiceCondition correctly' => sub {
    my $h = {
        %$hash,
        status => {
            conditions => [
                { type => 'Available', status => 'True',
                  message => 'ok', reason => 'Local' },
            ],
        },
    };
    my $obj = $k8s->struct_to_object("${NS_PKG}::APIService", $h);
    my $status = $obj->status;
    isa_ok($status, "${NS_PKG}::APIServiceStatus");

    my $cond = $status->conditions->[0];
    isa_ok($cond, "${NS_PKG}::APIServiceCondition");
    is($cond->type,    'Available', 'condition type round-trips');
    is($cond->status,  'True',     'condition status round-trips');
    is($cond->message, 'ok',       'condition message round-trips');
};

subtest 'full APIService round-trip: inflate then object_to_json matches input' => sub {
    my $obj = $k8s->struct_to_object("${NS_PKG}::APIService", $hash);
    my $back = $k8s->object_to_struct($obj);

    is($json->encode($back),
        $json->encode($hash),
        'serialised output equals the original input byte-for-byte (canonical)');

    # And the inflate->struct->inflate path is idempotent.
    my $again = $k8s->struct_to_object("${NS_PKG}::APIService", $back);
    is($json->encode($k8s->object_to_struct($again)),
        $json->encode($hash),
        'inflate -> struct -> inflate is idempotent');
};

done_testing;