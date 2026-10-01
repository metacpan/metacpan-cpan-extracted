#!/usr/bin/env perl
# k164: an error the constructor of the class being built raises -- Moo's
# "Missing required arguments", a Type::Tiny exception for a value of the
# wrong type -- named a line inside lib/IO/K8s.pm ("... at lib/IO/K8s.pm
# line 976."), the line where IO::K8s calls the constructor, for every
# public entry point: new_object, inflate, struct_to_object,
# json_to_object, load_yaml, and in a .pk8s manifest it did not name the
# manifest line either. Moo croaks from the frame of the class being built
# and Type::Tiny ignores @CARP_NOT, so neither can be told that the caller
# of IO::K8s is the one to blame.
#
# Approved contract:
#   * such an error names the line that called the entry point -- in a
#     .pk8s the manifest line of the Kind call -- the same line a croak
#     from IO::K8s names;
#   * the message text is otherwise unchanged;
#   * a Type::Tiny exception stays the same exception object, its context
#     (package, file, line) pointing at that caller;
#   * an error that blames any other place -- here a user class whose
#     BUILD dies -- keeps its own location, and a direct ->new is
#     untouched.
#
# Pure local fixtures -- no network, no cluster.

use strict;
use warnings;
use Test::More;
use Path::Tiny qw(tempdir);
use Scalar::Util qw(blessed);
use lib 'lib';

use IO::K8s;
use IO::K8s::Api::Apps::V1::DeploymentSpec;

my $THIS = __FILE__;
my $k8s  = IO::K8s->new;

my $MISSING = qr/\AMissing required arguments: selector, template at /;
my $DEPLOYMENT_SPEC = 'IO::K8s::Api::Apps::V1::DeploymentSpec';

# A string error is reported at this file, at exactly $line, and nowhere
# inside the distribution.
sub at_caller {
    my ($label, $err, $line, $file) = @_;
    $file //= $THIS;
    like("$err", qr/ at \Q$file\E line $line\.$/, $label.': reported at the caller\'s line');
    unlike("$err", qr{lib/IO/K8s[\w/]*\.pm line}, $label.': not a line inside the distribution');
}

# A Type::Tiny exception stays an object, its context moved to $line of
# this file in package $package.
sub tt_at_caller {
    my ($label, $err, $line, $package) = @_;
    ok(blessed($err) && $err->isa('Error::TypeTiny::Assertion'), $label.': still an Error::TypeTiny::Assertion')
        or return diag("got: $err");
    my $context = $err->context;
    is_deeply({ map { $_ => $context->{$_} } qw(package file line) },
        { package => $package // 'main', file => $THIS, line => $line },
        $label.': context names the caller');
    like("$err", qr/ at \Q$THIS\E line $line$/m, $label.': stringifies with the caller\'s line');
    unlike("$err", qr{lib/IO/K8s[\w/]*\.pm line}, $label.': not a line inside the distribution');
}

my $deployment_without_template = {
    kind       => 'Deployment',
    apiVersion => 'apps/v1',
    metadata   => { name => 'web' },
    spec       => { replicas => 1 },
};

my $deployment_with_bad_replicas = {
    kind       => 'Deployment',
    apiVersion => 'apps/v1',
    metadata   => { name => 'web' },
    spec       => { replicas => 'many', selector => {}, template => {} },
};

# ===========================================================================
# Moo's "Missing required arguments", through each entry point
# ===========================================================================

# Claim: a required field missing in a nested object names the line that
# called the entry point, for every public way into IO::K8s.
subtest 'missing required arguments name the caller, every entry point' => sub {
    my %json = map { $_ => $k8s->json->encode($_ eq 'doc' ? $deployment_without_template : $deployment_without_template->{spec}) }
        qw(doc spec);
    # Each case records the line its entry point is called on.
    my @cases = (
        [ 'new_object',              __LINE__, sub { $k8s->new_object('Deployment', $deployment_without_template) } ],
        [ 'new_object, nested list', __LINE__, sub { $k8s->new_object('Deployment', spec => { replicas => 1 }) } ],
        [ 'inflate, hashref',        __LINE__, sub { $k8s->inflate($deployment_without_template) } ],
        [ 'inflate, JSON text',      __LINE__, sub { $k8s->inflate($json{doc}) } ],
        [ 'struct_to_object, 1 arg', __LINE__, sub { $k8s->struct_to_object($deployment_without_template) } ],
        [ 'struct_to_object, class', __LINE__, sub { $k8s->struct_to_object('+'.$DEPLOYMENT_SPEC, { replicas => 1 }) } ],
        [ 'json_to_object, 1 arg',   __LINE__, sub { $k8s->json_to_object($json{doc}) } ],
        [ 'json_to_object, class',   __LINE__, sub { $k8s->json_to_object('+'.$DEPLOYMENT_SPEC, $json{spec}) } ],
    );
    for my $case (@cases) {
        my ($label, $line, $code) = @$case;
        eval { $code->() };
        like($@, $MISSING, $label.': the Moo message');
        at_caller($label, $@, $line);
    }
};

# Claim: deep in the tree -- a Container inside the Pod template of a
# Deployment -- the error still names the caller.
subtest 'a missing required argument deep in the tree names the caller' => sub {
    my $deployment = {
        metadata => { name => 'web' },
        spec     => {
            selector => { matchLabels => { app => 'web' } },
            template => { spec => { containers => [ { image => 'nginx' } ] } },
        },
    };
    eval { $k8s->new_object('Deployment', $deployment) }; my $line = __LINE__;
    like($@, qr/\AMissing required arguments: name at /, 'the Moo message');
    at_caller('Container in a Deployment', $@, $line);
};

# Claim: a YAML document with a missing required field names the line that
# called load_yaml, and so does its entry under collect_errors.
subtest 'load_yaml names the caller' => sub {
    my $yaml = "apiVersion: apps/v1\nkind: Deployment\nmetadata:\n  name: web\nspec:\n  replicas: 1\n";
    eval { $k8s->load_yaml($yaml) }; my $line = __LINE__;
    like($@, $MISSING, 'the Moo message');
    at_caller('load_yaml', $@, $line);

    my ($objects, $errors) = $k8s->load_yaml($yaml, collect_errors => 1); $line = __LINE__;
    is(scalar @$errors, 1, 'collect_errors: one error');
    like($errors->[0], qr{\ADeployment/web: Missing required arguments: selector, template at },
        'collect_errors: kind/name and the Moo message');
    at_caller('load_yaml collect_errors', $errors->[0], $line);
};

# Claim: the message is exactly what a direct ->new says, apart from the
# location -- nothing but the " at FILE line N." changes.
subtest 'the message text is unchanged' => sub {
    eval { $DEPLOYMENT_SPEC->new(replicas => 1) };
    (my $direct = $@) =~ s/ at \S+ line \d+\.\n\z//;
    eval { $k8s->struct_to_object('+'.$DEPLOYMENT_SPEC, { replicas => 1 }) };
    (my $through = $@) =~ s/ at \S+ line \d+\.\n\z//;
    is($through, $direct, 'same message as a direct ->new');
};

# ===========================================================================
# Type::Tiny exceptions
# ===========================================================================

# Claim: a value of the wrong type names the caller, and the exception
# stays an Error::TypeTiny::Assertion with the same message and
# explanation, its context pointing at the caller.
subtest 'a Type::Tiny exception names the caller and stays an object' => sub {
    eval { $k8s->new_object('Deployment', $deployment_with_bad_replicas) }; my $line = __LINE__;
    my $err = $@;
    tt_at_caller('new_object', $err, $line);
    like($err->message, qr/\AValue "many" did not pass type constraint "Maybe\[Int\]" \(in \$args->\{"replicas"\}\)\z/,
        'new_object: the Type::Tiny message');

    eval { $k8s->inflate($deployment_with_bad_replicas) }; $line = __LINE__;
    tt_at_caller('inflate', $@, $line);

    eval { $DEPLOYMENT_SPEC->new(replicas => 'many', selector => {}, template => {}) };
    my $direct = $@;
    is($err->message, $direct->message, 'the same message as a direct ->new');
    is_deeply($err->explain, $direct->explain, 'the same explanation as a direct ->new');
};

# Claim: the context names the calling package, not just its file.
subtest 'a Type::Tiny exception names the calling package' => sub {
    my ($err, $line);
    {
        package Test130::Caller;
        eval { $k8s->inflate($deployment_with_bad_replicas) }; $line = __LINE__;
        $err = $@;
    }
    tt_at_caller('from Test130::Caller', $err, $line, 'Test130::Caller');
};

# Claim: a class add_crd generates from a CustomResourceDefinition reports
# the caller as well -- the rule is IO::K8s's, not the shipped classes'.
subtest 'a class from add_crd names the caller' => sub {
    my $crd_k8s = IO::K8s->new;
    $crd_k8s->add_crd({
        kind => 'CustomResourceDefinition',
        spec => {
            group => 'k164.example.com',
            names => { kind => 'Dial', plural => 'dials' },
            scope => 'Namespaced',
            versions => [ { name => 'v1', served => 1, storage => 1, schema => { openAPIV3Schema => {
                type       => 'object',
                properties => { spec => { type => 'object', properties => { turns => { type => 'integer' } } } },
            } } } ],
        },
    });
    eval { $crd_k8s->new_object('Dial', { spec => { turns => 'lots' } }) }; my $line = __LINE__;
    tt_at_caller('Dial spec.turns', $@, $line);
};

# ===========================================================================
# .pk8s manifests
# ===========================================================================

my $dir = tempdir();
sub pk8s {
    my ($name, $code) = @_;
    my $file = $dir->child($name);
    $file->spew_utf8($code);
    return "$file";
}

# Claim: in a .pk8s manifest a missing required field and a value of the
# wrong type name the manifest line of the Kind call.
subtest '.pk8s: the manifest line of the Kind call' => sub {
    my $file = pk8s('missing.pk8s', <<'PK8S');
ConfigMap { name => 'a' };

Deployment { name => 'web', spec => { replicas => 1 } };
PK8S
    eval { $k8s->load($file) };
    like($@, qr/\AError loading \Q$file\E: Missing required arguments: selector, template at /,
        'missing: prefix and the Moo message');
    at_caller('.pk8s missing', $@, 3, $file);

    $file = pk8s('type.pk8s', <<'PK8S');
ConfigMap { name => 'a' };

Deployment { name => 'web', spec => { replicas => 'many', selector => {}, template => {} } };
PK8S
    eval { $k8s->load($file) };
    like($@, qr/\AError loading \Q$file\E: Value "many" did not pass type constraint/, 'type: prefix and message');
    like($@, qr/ at \Q$file\E line 3$/m, 'type: file and line 3');
    unlike($@, qr{lib/IO/K8s[\w/]*\.pm line}, 'type: not a line inside the distribution');
};

# ===========================================================================
# GUARDS
# ===========================================================================

# Claim: a direct constructor call reports its own line, as before.
subtest 'GUARD: a direct ->new still names its own line' => sub {
    eval { $DEPLOYMENT_SPEC->new(replicas => 1) }; my $line = __LINE__;
    like($@, $MISSING, 'the Moo message');
    at_caller('direct new', $@, $line);
};

# Claim: under $Carp::Verbose, where Carp answers with a full backtrace
# rather than one line, the errors still come through whole -- the Moo
# message with its backtrace, the Type::Tiny exception as an object.
subtest 'GUARD: $Carp::Verbose leaves the errors whole' => sub {
    local $Carp::Verbose = 1;
    eval { $k8s->inflate($deployment_without_template) };
    like($@, $MISSING, 'the Moo message');
    like($@, qr/\n\s+\S+ called at /, 'with a backtrace');

    eval { $k8s->inflate($deployment_with_bad_replicas) };
    ok(blessed($@) && $@->isa('Error::TypeTiny::Assertion'), 'still an Error::TypeTiny::Assertion');
};

# Claim: an error that blames any place but IO::K8s's constructor call
# keeps its location -- here a die in the BUILD of a user class (an `after`
# modifier, so the role's own BUILD stays), reached through new_object.
my $BUILD_LINE;
{
    package Test130::Boom;
    use IO::K8s::Resource;
    k8s name => Str;
    after BUILD => sub { die 'boom' }; BEGIN { $BUILD_LINE = __LINE__ }
}
subtest 'GUARD: an error blaming another place keeps it' => sub {
    eval { $k8s->new_object('+Test130::Boom', { name => 'x' }) };
    like($@, qr/\Aboom at \Q$THIS\E line $BUILD_LINE\.$/, 'the BUILD line, not the caller\'s');
};

done_testing;
