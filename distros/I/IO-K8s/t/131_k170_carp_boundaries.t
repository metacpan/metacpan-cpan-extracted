#!/usr/bin/env perl
# k170: three Carp boundaries inside the distribution still showed through.
#   * to_crd: an error IO::K8s::CRD raises for the class named the to_crd
#     line in lib/IO/K8s/Role/APIObject.pm;
#   * IO::K8s::CRD->generate, directly and through IO::K8s->add_crd: an
#     error IO::K8s::AutoGen raises -- the first one and the remembered one
#     a later request for the same class rethrows (k149) -- named the
#     generate line in lib/IO/K8s/CRD.pm;
#   * IO::K8s::List, through inflate: its own croak named the FROM_STRUCT
#     call in lib/IO/K8s.pm, a croak of IO::K8s's shape helpers it calls
#     named lib/IO/K8s/List.pm, and so did a constructor error for an item
#     once k164 hands such an error to Carp's answer.
#
# Approved contract, the k165 rule carried on: a module declares in
# @CARP_NOT the distribution modules it works with on a public path.
# IO::K8s::CRD trusts IO::K8s, IO::K8s::AutoGen and IO::K8s::Role::APIObject,
# IO::K8s::List trusts IO::K8s. So each of those errors names the line that
# called to_crd, generate, add_crd, inflate or IO::K8s::List->FROM_STRUCT /
# from_json -- and a caller in any other package still sees its own line.
#
# Pure local fixtures -- no network, no cluster.

use strict;
use warnings;
use Test::More;
use lib 'lib';

use IO::K8s;
use IO::K8s::CRD;
use IO::K8s::List;

my $THIS = __FILE__;
my $k8s  = IO::K8s->new;

# The error is reported at this file, at exactly $line, and nowhere inside
# the distribution.
sub at_caller {
    my ($label, $err, $line) = @_;
    like($err, qr/ at \Q$THIS\E line $line\.$/, $label.': reported at the caller\'s line');
    unlike($err, qr{lib/IO/K8s[\w/]*\.pm line}, $label.': not a line inside the distribution');
}

# ===========================================================================
# to_crd (IO::K8s::Role::APIObject -> IO::K8s::CRD)
# ===========================================================================

# A pattern with /i cannot be emitted as ECMA262: crd_for_class croaks (k110).
my $INSIDE_LINE;
{
    package Test131::PatFlag;
    use IO::K8s::APIObject
        api_version     => 'k170.example.com/v1',
        resource_plural => 'patflags';
    k8s mode => Str, { pattern => qr/\Aabort\z/i };
    sub crd_from_inside { $_[0]->to_crd } BEGIN { $INSIDE_LINE = __LINE__ }
}
my $PATTERN = qr/\AIO::K8s::CRD: pattern for Test131::PatFlag\.mode cannot be emitted as ECMA262: it uses case-insensitive matching/;

# Claim: to_crd reports CRD's error at the line that called it, as a class
# method and as an object method.
subtest 'to_crd: an IO::K8s::CRD error names the caller' => sub {
    eval { Test131::PatFlag->to_crd }; my $line = __LINE__;
    like($@, $PATTERN, 'class method: the k110 message');
    at_caller('to_crd, class method', $@, $line);

    my $obj = Test131::PatFlag->new(mode => 'abort');
    eval { $obj->to_crd }; $line = __LINE__;
    like($@, $PATTERN, 'object method: the k110 message');
    at_caller('to_crd, object method', $@, $line);
};

# ===========================================================================
# IO::K8s::CRD->generate and add_crd (IO::K8s::CRD -> IO::K8s::AutoGen)
# ===========================================================================

# A CRD whose schema has a $ref no definition answers: AutoGen refuses it.
sub crd_with_unresolvable_ref {
    my ($group) = @_;
    return {
        kind => 'CustomResourceDefinition',
        spec => {
            group    => $group,
            names    => { kind => 'Knob', plural => 'knobs' },
            scope    => 'Namespaced',
            versions => [ { name => 'v1', served => 1, storage => 1, schema => { openAPIV3Schema => {
                type       => 'object',
                properties => { spec => { type => 'object', properties => {
                    dial => { '$ref' => '#/definitions/Missing' },
                } } },
            } } } ],
        },
    };
}
my $UNRESOLVED = qr/\ACannot resolve the \$ref 'Missing' for field 'dial' of \S+::Knob::Spec: /;

# Claim: an AutoGen error through add_crd names the add_crd line.
subtest 'add_crd: an IO::K8s::AutoGen error names the caller' => sub {
    eval { IO::K8s->new->add_crd(crd_with_unresolvable_ref('add.k170.example.com')) }; my $line = __LINE__;
    like($@, $UNRESOLVED, 'the AutoGen message');
    at_caller('add_crd', $@, $line);
};

# Claim: through a direct generate, the first failure names the generate
# line, and the remembered failure a second request rethrows (k149) names
# the second call's line, the original error inside it naming the first.
subtest 'generate: the first and the remembered AutoGen error name the caller' => sub {
    my $crd = crd_with_unresolvable_ref('gen.k170.example.com');

    eval { IO::K8s::CRD->generate($crd, 'Test131::Gen') }; my $first = __LINE__;
    like($@, $UNRESOLVED, 'first: the AutoGen message');
    at_caller('generate, first', $@, $first);

    eval { IO::K8s::CRD->generate($crd, 'Test131::Gen') }; my $second = __LINE__;
    like($@, qr/\AIO::K8s::AutoGen: \S+::Knob failed to generate earlier in this namespace and stays failed; /,
        'second: the remembered-failure message');
    like($@, qr/Original error: Cannot resolve the \$ref 'Missing' .* at \Q$THIS\E line $first\. at /,
        'second: the original error, naming the first call');
    at_caller('generate, second', $@, $second);
};

# ===========================================================================
# IO::K8s::List, through inflate and directly
# ===========================================================================

# Claim: each kind of List error reached through inflate names the line
# that called inflate -- List's own croak, IO::K8s's shape helpers called
# by List, and a constructor error for an item.
subtest 'inflate: List errors name the caller' => sub {
    my @cases = (
        [ 'item_class a reference', qr/\AIO::K8s::List->FROM_STRUCT: item_class must be a class name, got a reference of type HASH at /,
          { kind => 'PodList', apiVersion => 'v1', item_class => {}, items => [] } ],
        [ 'items not an array',     qr/\ACannot inflate IO::K8s::List field items: expected an array \(a JSON array\) of IO::K8s::Api::Core::V1::Pod, got a plain scalar at /,
          { kind => 'PodList', apiVersion => 'v1', items => 'x' } ],
        [ 'an item not a hash',     qr/\ACannot inflate IO::K8s::Api::Core::V1::Pod: expected a hash \(a JSON object\), got a plain scalar while inflating IO::K8s::List field items at element 0 at /,
          { kind => 'PodList', apiVersion => 'v1', items => [ 'x' ] } ],
        [ 'an item missing a required field', qr/\AMissing required arguments: name at /,
          { kind => 'PodList', apiVersion => 'v1', items => [ { spec => { containers => [ {} ] } } ] } ],
    );
    for my $case (@cases) {
        my ($label, $message, $struct) = @$case;
        eval { $k8s->inflate($struct) }; my $line = __LINE__;
        like($@, $message, $label.': the message');
        at_caller('inflate, '.$label, $@, $line);
    }
};

# Claim: called directly, IO::K8s::List->FROM_STRUCT and ->from_json name
# their caller for IO::K8s's shape helpers as well, not List.pm.
subtest 'IO::K8s::List directly: errors name the caller' => sub {
    eval { IO::K8s::List->FROM_STRUCT({ kind => 'PodList', apiVersion => 'v1', items => 'x' }, $k8s) }; my $line = __LINE__;
    like($@, qr/\ACannot inflate IO::K8s::List field items: /, 'FROM_STRUCT: the message');
    at_caller('FROM_STRUCT, items not an array', $@, $line);

    eval { IO::K8s::List->FROM_STRUCT([], $k8s) }; $line = __LINE__;
    like($@, qr/\ACannot inflate IO::K8s::List: expected a hash/, 'FROM_STRUCT: the envelope message');
    at_caller('FROM_STRUCT, no hash', $@, $line);

    eval { IO::K8s::List->from_json('{"kind":"PodList","apiVersion":"v1","items":["x"]}', $k8s) }; $line = __LINE__;
    like($@, qr/\ACannot inflate IO::K8s::Api::Core::V1::Pod: expected a hash/, 'from_json: the item message');
    at_caller('from_json, an item not a hash', $@, $line);

    my $pod_list = { kind => 'PodList', apiVersion => 'v1', items => [ { spec => { containers => [ {} ] } } ] };
    eval { IO::K8s::List->FROM_STRUCT($pod_list, $k8s) }; $line = __LINE__;
    like($@, qr/\AMissing required arguments: name at /, 'FROM_STRUCT: the Moo message for an item');
    at_caller('FROM_STRUCT, an item missing a required field', $@, $line);
};

# ===========================================================================
# GUARDS
# ===========================================================================

# Claim: trusting IO::K8s::Role::APIObject does not skip a caller in
# another package -- a class calling to_crd from its own method sees that
# method's line.
subtest 'GUARD: a to_crd call inside another package names that line' => sub {
    eval { Test131::PatFlag->crd_from_inside };
    like($@, $PATTERN, 'the k110 message');
    at_caller('to_crd from Test131::PatFlag', $@, $INSIDE_LINE);
};

done_testing;
