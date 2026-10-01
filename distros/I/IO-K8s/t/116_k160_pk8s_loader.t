#!/usr/bin/env perl
# k160: IO::K8s->load (.pk8s) -- the per-call loader package, the file's
# encoding, and values passed into a manifest.
#
# Every load evaluated the file in a fresh IO::K8s::Manifest::_LOADER_*
# package holding one DSL sub per known Kind, and never removed it: roughly
# 850 KB per call, unbounded in a process that reloads manifests in a loop.
# The file was also read as bytes, so a non-ASCII literal in a manifest came
# out as mojibake where load_yaml (k159) gives characters.
#
# Approved contract:
#   * the loader package is gone after load returns -- also when the load
#     fails -- while what the manifest handed out keeps working: the
#     objects, closures, subs the manifest defined and called from those
#     closures, its package variables, even an object blessed into the
#     loader package;
#   * the file is read as UTF-8, a literal gives the same characters as the
#     same value through load_yaml; a manifest that says `use utf8;` itself
#     keeps working;
#   * load($file, vars => { ... }) makes var($name) / var($name, $default)
#     available in the manifest; an unknown name without a default dies
#     naming the file and the name; without vars, load behaves as before.
#
# The package check reads the symbol table; memory is not a test condition.
# Pure local fixtures in a temporary directory -- no network, no cluster.

use strict;
use warnings;
use utf8;
use Test::More;
use Test::Exception;
use Path::Tiny qw(tempdir);
use JSON::MaybeXS ();
use lib 'lib';

use IO::K8s;
use IO::K8s::Manifest;

my $dir = tempdir();
my $k8s = IO::K8s->new;

sub pk8s {
    my ($name, $code) = @_;
    my $file = $dir->child($name);
    $file->spew_utf8($code);
    return "$file";
}

sub loader_packages { sort grep { /\A_LOADER_/ } keys %IO::K8s::Manifest:: }

my $simple = pk8s('simple.pk8s', <<'PK8S');
ConfigMap {
    name => 'simple',
    data => { k => 'v' },
};
PK8S

# ===========================================================================
# The loader package
# ===========================================================================

# Claim: N loads leave no loader package behind.
subtest 'no loader package survives a load' => sub {
    is_deeply([ loader_packages() ], [], 'none before');
    for (1 .. 5) {
        my $objs = $k8s->load($simple);
        is($objs->[0]->metadata->name, 'simple', "load $_ worked");
    }
    is_deeply([ loader_packages() ], [], 'none after five loads');
};

# Claim: a manifest that dies at run time still reports the file and leaves
# no package behind.
subtest 'no loader package survives a failing load (run time)' => sub {
    my $bad = pk8s('dies.pk8s', <<'PK8S');
ConfigMap { name => 'before' };
die "manifest gave up\n";
PK8S
    throws_ok { $k8s->load($bad) } qr/Error loading \Q$bad\E: manifest gave up/, 'error names file';
    is_deeply([ loader_packages() ], [], 'no package left');
};

# Claim: the same holds for a manifest that does not compile.
subtest 'no loader package survives a failing load (compile time)' => sub {
    my $bad = pk8s('syntax.pk8s', <<'PK8S');
sub helper { 1 }
ConfigMap { name => 'x' ;
PK8S
    throws_ok { $k8s->load($bad) } qr/Error loading \Q$bad\E/, 'error names file';
    is_deeply([ loader_packages() ], [], 'no package left');
};

# Claim: what the manifest handed out keeps working once its package is
# gone -- a closure calling a manifest sub and a package variable, a direct
# reference to a manifest sub, and an object blessed into the loader package.
subtest 'returned closures, subs and objects outlive the package' => sub {
    my $file = pk8s('closures.pk8s', <<'PK8S');
our $count = 41;
sub helper { 'helped' }
sub greet  { 'hi from ' . $_[0]{n} }
my $obj = bless { n => 'obj' }, __PACKAGE__;

ConfigMap {
    name        => 'with-code',
    annotations => {
        cb    => sub { helper() . '-' . (++$count) },
        named => \&helper,
        obj   => $obj,
    },
};
PK8S
    my ($cm) = @{ $k8s->load($file) };
    is_deeply([ loader_packages() ], [], 'package removed');
    my $ann = $cm->metadata->annotations;
    is($ann->{cb}->(),    'helped-42', 'closure calls the manifest sub and its package variable');
    is($ann->{cb}->(),    'helped-43', 'and keeps its state');
    is($ann->{named}->(), 'helped',    'a reference to a manifest sub still runs');
    is($ann->{obj}->greet, 'hi from obj', 'an object blessed into the loader package keeps its methods');
    is($cm->metadata->name, 'with-code', 'the IO::K8s object itself is unaffected');
};

# ===========================================================================
# Encoding
# ===========================================================================

my $UMLAUT = 'Grüße aus München';
my $WIDE   = 'Preis: 5 € — 日本';

# Claim: a non-ASCII literal in a .pk8s file gives the same characters as the
# same value through load_yaml, and the JSON encodes them once.
subtest 'a UTF-8 manifest gives characters, like load_yaml' => sub {
    my $file = pk8s('utf8.pk8s', <<"PK8S");
ConfigMap {
    name        => 'utf8',
    annotations => { note => '$UMLAUT' },
    data        => { greeting => '$WIDE' },
};
PK8S
    my ($cm) = @{ $k8s->load($file) };
    is($cm->metadata->annotations->{note}, $UMLAUT, 'Umlaut literal');
    is($cm->data->{greeting},              $WIDE,   'non-Latin-1 literal');

    my ($from_yaml) = @{ $k8s->load_yaml(
        "apiVersion: v1\nkind: ConfigMap\nmetadata:\n  name: utf8\n"
        . "  annotations:\n    note: \"$UMLAUT\"\ndata:\n  greeting: \"$WIDE\"\n") };
    is_deeply($cm->TO_JSON, $from_yaml->TO_JSON, 'same structure as through load_yaml');

    my $back = JSON::MaybeXS->new(utf8 => 1)->decode($cm->to_json);
    is($back->{data}{greeting}, $WIDE, 'JSON carries the characters once-encoded');
};

# Claim: a manifest that already declared `use utf8;` -- the only way to get
# characters before -- still gets the same characters, not a second decode.
subtest 'GUARD: a manifest with its own `use utf8;` still works' => sub {
    my $file = pk8s('useutf8.pk8s', <<"PK8S");
use utf8;
ConfigMap {
    name => 'useutf8',
    data => { greeting => '$WIDE', note => '$UMLAUT' },
};
PK8S
    my ($cm) = @{ $k8s->load($file) };
    is($cm->data->{greeting}, $WIDE,   'non-Latin-1 literal');
    is($cm->data->{note},     $UMLAUT, 'Umlaut literal');
};

# ===========================================================================
# vars / var()
# ===========================================================================

my $templ = pk8s('templ.pk8s', <<'PK8S');
Deployment {
    name      => var('name'),
    namespace => var('namespace', 'default'),
    spec      => {
        replicas => var('config')->{replicas},
        selector => { matchLabels => { app => var('name') } },
        template => {
            metadata => { labels => { app => var('name') } },
            spec     => { containers => [ { name => 'app', image => var('image', 'nginx') } ] },
        },
    },
};
PK8S

# Claim: passed values reach the manifest, defaults fill the gaps, a
# reference passes through as is.
subtest 'vars reach the manifest through var()' => sub {
    my ($d) = @{ $k8s->load($templ, vars => { name => 'web', config => { replicas => 3 } }) };
    is($d->metadata->name,      'web',     'var(name)');
    is($d->metadata->namespace, 'default', 'var(namespace, default) falls back');
    is($d->spec->replicas,      3,         'a hashref value passes through');
    is($d->spec->template->spec->containers->[0]->image, 'nginx', 'second default');

    my ($d2) = @{ $k8s->load($templ,
        vars => { name => 'api', namespace => 'prod', image => 'api:1', config => { replicas => 1 } }) };
    is($d2->metadata->namespace, 'prod', 'a passed value beats the default');
    is($d2->spec->template->spec->containers->[0]->image, 'api:1', 'second passed value');
    is_deeply([ loader_packages() ], [], 'still no package left');
};

# Claim: a passed undef is a value, not a missing one.
subtest 'a passed undef is used, not the default' => sub {
    my $file = pk8s('undef.pk8s', <<'PK8S');
ConfigMap { name => 'u', data => { v => defined(var('v', 'dflt')) ? 'defined' : 'undef' } };
PK8S
    my ($cm) = @{ $k8s->load($file, vars => { v => undef }) };
    is($cm->data->{v}, 'undef', 'undef passed through');
};

# Claim: a name with no value and no default dies naming the file and the
# name.
subtest 'an unknown var without default dies naming file and name' => sub {
    throws_ok { $k8s->load($templ, vars => { name => 'web' }) }
        qr/\Q$templ\E.*'config'|'config'.*\Q$templ\E/s, 'file and name in the message';
    is_deeply([ loader_packages() ], [], 'no package left');
};

# Claim: without vars the call is the old one; var() with a default still
# works, var() without one dies.
subtest 'without vars' => sub {
    my ($cm) = @{ $k8s->load(pk8s('dflt.pk8s', "ConfigMap { name => var('n', 'fallback') };\n")) };
    is($cm->metadata->name, 'fallback', 'default used');
    throws_ok { $k8s->load($templ) } qr/'name'/, 'missing var named';
};

# Claim: vars must be a hashref, and an unknown option is a typo, not
# something to ignore.
subtest 'bad options die' => sub {
    throws_ok { $k8s->load($simple, vars => [ 1 ]) } qr/vars.*hash/i, 'vars not a hashref';
    throws_ok { $k8s->load($simple, var => { a => 1 }) } qr/unknown option.*'var'/i, 'unknown option';
};

# Claim: Kind functions and var() live side by side; var is lower case and
# cannot shadow a Kind.
subtest 'GUARD: Kind functions still work alongside var' => sub {
    my $objs = $k8s->load($simple);
    is(scalar @$objs, 1, 'one object');
    isa_ok($objs->[0], 'IO::K8s::Api::Core::V1::ConfigMap');
};

done_testing;
