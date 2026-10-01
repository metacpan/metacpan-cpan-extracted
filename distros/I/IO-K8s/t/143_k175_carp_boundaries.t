#!/usr/bin/env perl
# k175: the Carp boundaries k164/k170 left. By the same rule -- a module
# declares in @CARP_NOT the distribution modules it works with on a public
# path, and IO::K8s moves a constructor error to Carp's answer (k164) --
# these errors still named a line inside the distribution:
#   (1) Class->FROM_HASH / ->from_json, the unknown_kinds => 'unstructured'
#       fallback of new_object and inflate (both go through FROM_HASH), and
#       spec_set / spec_merge writing a hash into a typed field: a shape
#       error named lib/IO/K8s/Role/Resource.pm or Role/SpecBuilder.pm, a
#       constructor error lib/IO/K8s.pm;
#   (2) load('missing.pk8s') named lib/IO/K8s/Manifest.pm;
#   (3) an IO::K8s::AutoGen error reached through an openapi_spec instance
#       (expand_class, new_object, inflate) named lib/IO/K8s.pm;
#   (4) a shape error the union classes V1::JSONSchemaPropsOr* raise for a
#       schema arm named the union class's own file;
#   (5) inflate without a kind died with a plain `die`, naming
#       lib/IO/K8s.pm.
#
# Approved contract: each of those names the line that called into the
# distribution (FROM_HASH, from_json, new_object, inflate, struct_to_object,
# expand_class, load, spec_set, spec_merge, FROM_STRUCT), messages otherwise
# unchanged; a caller in any other package still sees its own line. A
# direct $class->new(...) whose nested coercion fails is no entry point of
# IO::K8s: it must stay at least as good as before -- a real file, never
# the "(eval N)" frame of Moo's generated constructor.
#
# Pure local fixtures -- no network, no cluster.

use strict;
use warnings;
use Test::More;
use Scalar::Util qw( blessed );
use Path::Tiny qw( tempdir );
use lib 'lib';

use IO::K8s;
use IO::K8s::Api::Apps::V1::Deployment;
use IO::K8s::Api::Core::V1::Pod;
use IO::K8s::Api::Core::V1::PodSpec;
use IO::K8s::ApiextensionsApiserver::Pkg::Apis::Apiextensions::V1::JSONSchemaProps;
use IO::K8s::ApiextensionsApiserver::Pkg::Apis::Apiextensions::V1::JSONSchemaPropsOrArray;
use IO::K8s::ApiextensionsApiserver::Pkg::Apis::Apiextensions::V1::JSONSchemaPropsOrBool;
use IO::K8s::ApiextensionsApiserver::Pkg::Apis::Apiextensions::V1::JSONSchemaPropsOrStringArray;

my $THIS = __FILE__;
my $k8s  = IO::K8s->new;

my $POD   = 'IO::K8s::Api::Core::V1::Pod';
my $V1    = 'IO::K8s::ApiextensionsApiserver::Pkg::Apis::Apiextensions::V1::';
my $PROPS = $V1.'JSONSchemaProps';

# A string error is reported at this file, at exactly $line, and nowhere
# inside the distribution.
sub at_caller {
    my ($label, $err, $line) = @_;
    like("$err", qr/ at \Q$THIS\E line $line\.$/, $label.': reported at the caller\'s line');
    unlike("$err", qr{lib/IO/K8s[\w/]*\.pm line}, $label.': not a line inside the distribution');
}

# A Type::Tiny exception stays an object, its context moved to $line.
sub tt_at_caller {
    my ($label, $err, $line) = @_;
    ok(blessed($err) && $err->isa('Error::TypeTiny::Assertion'), $label.': still an Error::TypeTiny::Assertion')
        or return diag("got: $err");
    is_deeply({ map { $_ => $err->context->{$_} } qw(package file line) },
        { package => 'main', file => $THIS, line => $line }, $label.': context names the caller');
}

my $SPEC_SHAPE      = qr/\ACannot inflate IO::K8s::Api::Core::V1::PodSpec: expected a hash \(a JSON object\), got a reference of type ARRAY while inflating /;
my $CONTAINER_SHAPE = qr/\ACannot inflate IO::K8s::Api::Core::V1::PodSpec field containers: expected an array \(a JSON array\) of IO::K8s::Api::Core::V1::Container, got a plain scalar at /;
my $MISSING_NAME    = qr/\AMissing required arguments: name at /;
my $PROPS_SHAPE     = qr/\ACannot inflate \Q$PROPS\E: expected a hash \(a JSON object\), got a plain scalar at /;

# ===========================================================================
# (1) FROM_HASH, from_json, unknown_kinds => 'unstructured', spec_*
# ===========================================================================

# Claim: FROM_HASH and from_json report every inflation error at their
# caller -- IO::K8s's shape croaks and, via k164, a constructor error.
subtest 'FROM_HASH and from_json name the caller' => sub {
    eval { $POD->FROM_HASH({ spec => [] }) }; my $line = __LINE__;
    like($@, $SPEC_SHAPE, 'FROM_HASH, object shape: the message');
    at_caller('FROM_HASH, object shape', $@, $line);

    eval { $POD->FROM_HASH({ spec => { containers => 'x' } }) }; $line = __LINE__;
    like($@, $CONTAINER_SHAPE, 'FROM_HASH, container shape: the message');
    at_caller('FROM_HASH, container shape', $@, $line);

    eval { $POD->FROM_HASH({ spec => { containers => [ {} ] } }) }; $line = __LINE__;
    like($@, $MISSING_NAME, 'FROM_HASH, missing required field: the Moo message');
    at_caller('FROM_HASH, missing required field', $@, $line);

    my $bad_port = { spec => { containers => [ { name => 'a', ports => [ { containerPort => 'x' } ] } ] } };
    eval { $POD->FROM_HASH($bad_port) }; $line = __LINE__;
    tt_at_caller('FROM_HASH, wrong type', $@, $line);

    eval { $POD->from_json('{"spec":[]}') }; $line = __LINE__;
    like($@, $SPEC_SHAPE, 'from_json, object shape: the message');
    at_caller('from_json, object shape', $@, $line);
};

# Claim: the unstructured fallback, which builds through FROM_HASH, names
# the caller of new_object and inflate.
subtest 'unknown_kinds => unstructured names the caller' => sub {
    my $loose = IO::K8s->new(unknown_kinds => 'unstructured');
    my $shape = qr/\ACannot inflate IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::ObjectMeta: expected a hash \(a JSON object\), got a reference of type ARRAY while inflating IO::K8s::Unstructured field metadata at /;

    eval { $loose->new_object('Widget', { metadata => [] }, 'k175.example.com/v1') }; my $line = __LINE__;
    like($@, $shape, 'new_object: the message');
    at_caller('new_object, unstructured', $@, $line);

    eval { $loose->inflate({ kind => 'Widget', apiVersion => 'k175.example.com/v1', metadata => [] }) }; $line = __LINE__;
    like($@, $shape, 'inflate: the message');
    at_caller('inflate, unstructured', $@, $line);
};

sub deployment {
    return IO::K8s::Api::Apps::V1::Deployment->new(
        metadata => { name => 'web' },
        spec     => { selector => {}, template => { spec => { containers => [] } } },
    );
}

# Claim: spec_set and spec_merge, handing a hash to a typed field, name
# their caller for IO::K8s's shape croaks and a constructor error.
subtest 'spec_set and spec_merge name the caller' => sub {
    my $d = deployment();

    eval { $d->spec_set('template', { spec => [] }) }; my $line = __LINE__;
    like($@, $SPEC_SHAPE, 'spec_set, object shape: the message');
    at_caller('spec_set, object shape', $@, $line);

    eval { $d->spec_set('template.spec.containers', [ { name => 'a', ports => 'x' } ]) }; $line = __LINE__;
    like($@, qr/\ACannot inflate IO::K8s::Api::Core::V1::Container field ports: expected an array /,
        'spec_set, container shape in an element: the message');
    at_caller('spec_set, container shape in an element', $@, $line);

    eval { $d->spec_set('template', { spec => { containers => [ {} ] } }) }; $line = __LINE__;
    like($@, $MISSING_NAME, 'spec_set, missing required field: the Moo message');
    at_caller('spec_set, missing required field', $@, $line);

    eval { $d->spec_merge(template => { spec => [] }) }; $line = __LINE__;
    like($@, $SPEC_SHAPE, 'spec_merge, object shape: the message');
    at_caller('spec_merge, object shape', $@, $line);
};

# ===========================================================================
# (2) load of a missing .pk8s
# ===========================================================================

# Claim: a manifest that cannot be opened names the line that called load.
subtest 'load of a missing file names the caller' => sub {
    my $missing = tempdir()->child('fehlt.pk8s');
    eval { $k8s->load("$missing") }; my $line = __LINE__;
    like($@, qr/\ACannot open \Q$missing\E: /, 'the message');
    at_caller('load, missing file', $@, $line);
};

# ===========================================================================
# (3) AutoGen through an openapi_spec instance
# ===========================================================================

sub widget_spec {
    return { definitions => { 'k175.v1.Widget' => {
        type => 'object',
        'x-kubernetes-group-version-kind' => [ { group => 'k175.example', version => 'v1', kind => 'Widget' } ],
        properties => {
            okay    => { type => 'string' },
            zbroken => { '$ref' => '#/definitions/Missing' },
        },
    } } };
}
my $UNRESOLVED = qr/\ACannot resolve the \$ref 'Missing' for field 'zbroken' of \S+::Widget: /;
my $REMEMBERED = qr/\AIO::K8s::AutoGen: \S+::Widget failed to generate earlier in this namespace and stays failed; /;

# Claim: an AutoGen error -- the first one and the remembered one a later
# request rethrows (k149) -- names the caller of expand_class, new_object
# and inflate.
subtest 'AutoGen errors through an openapi_spec instance name the caller' => sub {
    my $gen = IO::K8s->new(openapi_spec => widget_spec());
    eval { $gen->expand_class('Widget') }; my $first = __LINE__;
    like($@, $UNRESOLVED, 'expand_class, first: the AutoGen message');
    at_caller('expand_class, first', $@, $first);

    eval { $gen->new_object('Widget', { okay => 'x' }) }; my $line = __LINE__;
    like($@, $REMEMBERED, 'new_object, remembered: the k149 message');
    like($@, qr/Original error: Cannot resolve .* at \Q$THIS\E line $first\. at /,
        'new_object, remembered: the original error names the first call');
    at_caller('new_object, remembered', $@, $line);

    my $fresh = IO::K8s->new(openapi_spec => widget_spec());
    eval { $fresh->inflate({ kind => 'Widget', apiVersion => 'k175.example/v1', okay => 'x' }) }; $line = __LINE__;
    like($@, $UNRESOLVED, 'inflate, first: the AutoGen message');
    at_caller('inflate, first', $@, $line);
};

# ===========================================================================
# (4) the union classes' shape croaks
# ===========================================================================

# Claim: a shape error for the schema arm of a JSONSchemaPropsOr* union
# names the caller of FROM_STRUCT, FROM_HASH, struct_to_object or inflate.
subtest 'union shape errors name the caller' => sub {
    my @direct = (
        [ 'OrArray, a scalar',         sub { ($V1.'JSONSchemaPropsOrArray')->FROM_STRUCT(5) }, __LINE__ ],
        [ 'OrArray, a scalar element', sub { ($V1.'JSONSchemaPropsOrArray')->FROM_STRUCT([ 5 ]) }, __LINE__ ],
        [ 'OrStringArray, a scalar',   sub { ($V1.'JSONSchemaPropsOrStringArray')->FROM_STRUCT('x', $k8s) }, __LINE__ ],
        [ 'OrBool, nested in a schema', sub { ($V1.'JSONSchemaPropsOrBool')->FROM_STRUCT({ items => 5 }) }, __LINE__ ],
    );
    for my $case (@direct) {
        my ($label, $code, $line) = @$case;
        eval { $code->() };
        like($@, $PROPS_SHAPE, 'FROM_STRUCT, '.$label.': the message');
        at_caller('FROM_STRUCT, '.$label, $@, $line);
    }

    eval { $PROPS->FROM_HASH({ items => 5 }) }; my $line = __LINE__;
    like($@, $PROPS_SHAPE, 'FROM_HASH items => 5: the message');
    at_caller('FROM_HASH items => 5', $@, $line);

    # A value of the wrong type inside the schema arm: IO::K8s builds that
    # schema, so its constructor error follows Carp's answer (k164).
    eval { ($V1.'JSONSchemaPropsOrArray')->FROM_STRUCT({ type => [] }) }; $line = __LINE__;
    tt_at_caller('FROM_STRUCT, a wrong type in the schema arm', $@, $line);

    eval { $k8s->struct_to_object('+'.$PROPS, { properties => { a => { items => 5 } } }) }; $line = __LINE__;
    like($@, $PROPS_SHAPE, 'struct_to_object, nested: the message');
    at_caller('struct_to_object, nested', $@, $line);
};

# ===========================================================================
# (5) inflate without a kind
# ===========================================================================

# Claim: inflate croaks for a document without a kind -- same message,
# reported at the caller's line.
subtest 'inflate without kind croaks at the caller' => sub {
    eval { $k8s->inflate({ apiVersion => 'v1', metadata => { name => 'x' } }) }; my $line = __LINE__;
    like($@, qr/\ACannot inflate: missing 'kind' field in data at /, 'the message');
    at_caller('inflate without kind', $@, $line);

    eval { $k8s->inflate('{"apiVersion":"v1"}') }; $line = __LINE__;
    at_caller('inflate of JSON text without kind', $@, $line);
};

# ===========================================================================
# GUARDS
# ===========================================================================

# Claim: trusting IO::K8s does not skip a caller in another package -- a
# class calling FROM_HASH or spec_set from its own method sees that line.
my ($FROM_HASH_LINE, $SPEC_SET_LINE);
{
    package Test143::Builder;
    sub from_hash { IO::K8s::Api::Core::V1::Pod->FROM_HASH({ spec => [] }) } BEGIN { $FROM_HASH_LINE = __LINE__ }
    sub spec_set  { $_[1]->spec_set('template', { spec => [] }) } BEGIN { $SPEC_SET_LINE = __LINE__ }
}
subtest 'GUARD: a call inside another package names that line' => sub {
    eval { Test143::Builder->from_hash };
    like($@, $SPEC_SHAPE, 'FROM_HASH: the message');
    at_caller('FROM_HASH from Test143::Builder', $@, $FROM_HASH_LINE);

    eval { Test143::Builder->spec_set(deployment()) };
    like($@, $SPEC_SHAPE, 'spec_set: the message');
    at_caller('spec_set from Test143::Builder', $@, $SPEC_SET_LINE);
};

# Claim: spec_push, whose element writes go through the collection check,
# already named the caller and still does.
subtest 'GUARD: spec_push still names the caller' => sub {
    my $d = deployment();
    eval { $d->spec_push('template.spec.containers', { name => 'a', ports => 'x' }) }; my $line = __LINE__;
    like($@, qr/\Aspec path 'template\.spec\.containers': cannot push onto 'containers': Cannot inflate /,
        'the message');
    at_caller('spec_push', $@, $line);
};

# Claim: a direct constructor call whose nested coercion fails -- no
# entry point of IO::K8s -- is reported at a real file, the caller's line
# or a line of the distribution as before, never at the "(eval N)" frame
# of Moo's generated constructor.
subtest 'GUARD: a direct ->new with a failing nested coercion stays at a real file' => sub {
    my @cases = (
        [ 'container shape',        sub { IO::K8s::Api::Core::V1::PodSpec->new(containers => 'x') } ],
        [ 'nested container shape', sub { $POD->new(spec => { containers => 'x' }) } ],
        [ 'nested missing field',   sub { $POD->new(spec => { containers => [ {} ] }) } ],
        [ 'union schema arm',       sub { $PROPS->new(items => 5) } ],
        [ 'setter',                 sub { $POD->new->spec({ containers => 'x' }) } ],
    );
    for my $case (@cases) {
        my ($label, $code) = @$case;
        eval { $code->() };
        # The location sits on the first line; a Type::Tiny message goes
        # on with its explanation below it.
        my ($first) = split /\n/, "$@";
        ok(defined $first && length $first, $label.': dies') or next;
        unlike($first, qr/ at \(eval \d+\) line \d+/, $label.': not an (eval N) frame');
        like($first, qr/ at (?:\Q$THIS\E|\S*lib\/IO\/K8s[\w\/]*\.pm) line \d+\.?\z/,
            $label.': this file or a line of the distribution');
    }
};

done_testing;
