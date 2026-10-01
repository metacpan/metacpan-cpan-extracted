#!/usr/bin/env perl
# k185: the mirror of k181. AutoGen's core-class reuse check (D5, k148) let
# the 'string' schema kind match not only a Str registry field but an
# IntOrStr, a Quantity and a Time one as well. So a plain `type: string`
# field reused a core class typed for one of those, and the reused type then
# corrupted the value:
#   * {host: string, port: string} reused Core::V1::TCPSocketAction, whose
#     port is IntOrStr, and IntOrStr sends a numeric-looking string out as a
#     number -- the schema's "8080" came back as 8080;
#   * {medium: string, mode: integer, sizeLimit: string} reused
#     Core::V1::EmptyDirVolumeSource, whose sizeLimit is Quantity, and the
#     strict Quantity check then rejected a sizeLimit "big".
#
# Claims:
#   * a plain `type: string` field is compatible with a Str field only: not
#     IntOrStr, Quantity or Time, so those shapes get their own nested class
#     typed Str and the value stays the string the schema asked for;
#   * the int-or-string kind is untouched (k181): it still matches an
#     IntOrStr field and a Quantity one, so a controller-gen port or
#     ResourceList still reuses the core class -- the fix is not too broad.
#
# Pure local fixtures -- no network, no cluster.
use strict;
use warnings;
use Test::More;
use JSON::MaybeXS ();

use IO::K8s;
use IO::K8s::AutoGen;

my $true = JSON::MaybeXS::true();

my $class = IO::K8s::AutoGen::get_or_generate('com.example.v1.K185Thing', {
    type       => 'object',
    properties => {
        # {host, port: string}: the TCPSocketAction shape, but port a plain
        # string instead of int-or-string.
        probe => {
            type       => 'object',
            properties => {
                host => { type => 'string' },
                port => { type => 'string' },
            },
        },
        # {medium, mode, sizeLimit: string}: the EmptyDirVolumeSource shape
        # (mode is Int, so it stays integer to keep the shape a candidate),
        # but sizeLimit a plain string instead of a Quantity.
        vol => {
            type       => 'object',
            properties => {
                medium    => { type => 'string' },
                mode      => { type => 'integer' },
                sizeLimit => { type => 'string' },
            },
        },
        # An honest int-or-string port: this MUST still reuse TCPSocketAction.
        iosProbe => {
            type       => 'object',
            properties => {
                host => { type => 'string' },
                port => { 'x-kubernetes-int-or-string' => $true },
            },
        },
    },
}, {}, 'IO::K8s::_AUTOGEN_k185');

my $info = $class->_k8s_attr_info;

subtest 'a plain string does not reuse an IntOrStr or Quantity field' => sub {
    my $probe = $info->{probe}{class};
    isnt($probe, 'IO::K8s::Api::Core::V1::TCPSocketAction',
        '{host, port: string} does not reuse TCPSocketAction (port IntOrStr)');
    ok($probe->_k8s_attr_info->{port}{is_str}, 'its port is typed Str');

    my $vol = $info->{vol}{class};
    isnt($vol, 'IO::K8s::Api::Core::V1::EmptyDirVolumeSource',
        '{medium, mode, sizeLimit: string} does not reuse EmptyDirVolumeSource (sizeLimit Quantity)');
    ok($vol->_k8s_attr_info->{sizeLimit}{is_str}, 'its sizeLimit is typed Str');
};

subtest 'the wire keeps a string a string' => sub {
    my $obj = $class->new(probe => { host => 'h', port => '8080' });
    is($obj->to_json, '{"probe":{"host":"h","port":"8080"}}',
        'port "8080" stays the JSON string "8080", not the number 8080');

    my $vol = eval { $class->new(vol => { medium => 'Memory', mode => 493, sizeLimit => 'big' }) };
    ok($vol, 'sizeLimit "big" does not fail a strict Quantity check')
        or diag($@);
    is($vol && $vol->to_json, '{"vol":{"medium":"Memory","mode":493,"sizeLimit":"big"}}',
        'sizeLimit "big" round-trips as a plain string, mode stays a number');

    my $doc = '{"probe":{"host":"h","port":"8080"},"vol":{"medium":"Memory","mode":493,"sizeLimit":"big"}}';
    is($class->from_json($doc)->to_json, $doc, 'from_json -> to_json keeps the JSON types');
};

subtest '_field_compatible: a plain string matches is_str only' => sub {
    my $ctx = { defs => {}, active => {} };
    my $fc  = sub { IO::K8s::AutoGen::_field_compatible($_[0], $_[1], $ctx) };
    my $str = { type => 'string' };

    ok($fc->({ is_str => 1 }, $str),           'string is compatible with a Str field');
    ok(!$fc->({ is_int_or_string => 1 }, $str), 'string is NOT compatible with an IntOrStr field');
    ok(!$fc->({ is_quantity => 1 }, $str),      'string is NOT compatible with a Quantity field');
    ok(!$fc->({ is_time => 1 }, $str),          'string is NOT compatible with a Time field');
};

subtest 'a date-time string and Quantity/Time $refs keep their typed kind' => sub {
    # These are the reuses the plain-string narrowing must NOT take with it:
    # a `format: date-time` string, and a $ref to resource.Quantity /
    # meta.v1.Time, still carry the value's real type, so a CRD condition
    # still reuses a Time field and a ResourceList a Quantity map (k178, k139).
    my $ctx = { defs => {}, active => {} };
    my $fc  = sub { IO::K8s::AutoGen::_field_compatible($_[0], $_[1], $ctx) };

    my $date_time = { type => 'string', format => 'date-time' };
    ok($fc->({ is_time => 1 }, $date_time), 'a date-time string matches a Time field');
    ok($fc->({ is_str => 1 }, $date_time),  'a date-time string also fits a Str field (lossless)');
    ok(!$fc->({ is_int_or_string => 1 }, $date_time), 'but not an IntOrStr field');
    ok(!$fc->({ is_quantity => 1 }, $date_time),      'and not a Quantity field');
    # the discriminator: a plain string, unlike a date-time one, is not a Time
    ok(!$fc->({ is_time => 1 }, { type => 'string' }), 'a plain string does NOT match a Time field');

    my $q_ref = { '$ref' => '#/definitions/io.k8s.apimachinery.pkg.api.resource.Quantity' };
    ok($fc->({ is_quantity => 1 }, $q_ref), 'a $ref to resource.Quantity matches a Quantity field');
    ok(!$fc->({ is_time => 1 }, $q_ref),    'a $ref to resource.Quantity does not match a Time field');
    my $t_ref = { '$ref' => '#/definitions/io.k8s.apimachinery.pkg.apis.meta.v1.Time' };
    ok($fc->({ is_time => 1 }, $t_ref),     'a $ref to meta.v1.Time matches a Time field');
    ok(!$fc->({ is_quantity => 1 }, $t_ref), 'a $ref to meta.v1.Time does not match a Quantity field');
};

subtest 'int-or-string is untouched: it still reuses an IntOrStr/Quantity field' => sub {
    is($info->{iosProbe}{class}, 'IO::K8s::Api::Core::V1::TCPSocketAction',
        '{host, port: int-or-string} still reuses TCPSocketAction');
    is($class->new(iosProbe => { host => 'h', port => 8080 })->to_json,
        '{"iosProbe":{"host":"h","port":8080}}', 'and there 8080 stays a number');

    my $ctx = { defs => {}, active => {} };
    my $fc  = sub { IO::K8s::AutoGen::_field_compatible($_[0], $_[1], $ctx) };
    my $ios = { 'x-kubernetes-int-or-string' => $true };
    ok($fc->({ is_int_or_string => 1 }, $ios), 'int-or-string still matches an IntOrStr field');
    ok($fc->({ is_quantity => 1 }, $ios),      'int-or-string still matches a Quantity field (controller-gen)');
    ok(!$fc->({ is_str => 1 }, $ios),          'int-or-string still does not match a Str field');
};

done_testing;
