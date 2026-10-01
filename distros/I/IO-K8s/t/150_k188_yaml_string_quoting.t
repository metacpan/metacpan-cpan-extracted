#!/usr/bin/env perl

# k188: TO_YAML / to_yaml dumped with YAML::PP schema [JSON], which only quotes
# what JSON itself would misread. Strings such as True, yes, on, ~, 012, 0x1F,
# 1_000, 190:20:30, .inf, +1 went out bare, and a YAML 1.1 reader (go-yaml v2
# behind kubectl, PyYAML) turns them into booleans, nulls and numbers -- a
# label "yes", an env value "on", a condition status "True" or a CRD enum
# [True, False, Unknown] then changes type on its way into the cluster.
#
# A round trip through YAML::PP's JSON schema hides this (that is how the bug
# survived), so every assertion here reloads the output under the YAML 1.1,
# Core AND JSON resolvers and compares the loaded TYPES: each structure is
# re-encoded to canonical JSON, which shows "012" (string) vs 10 (number),
# "True" vs true and "~" vs null. Real booleans and numbers must stay bare.

use strict;
use warnings;
use Test::More;
use File::Temp qw( tempdir );
use JSON::PP;
use YAML::PP;
use IO::K8s;
use IO::K8s::Api::Core::V1::Container;

# A CRD-style class carrying an enum [True False Unknown] (inline, no provider).
{
    package Test::K188::Cond;
    use IO::K8s::Resource;
    k8s type   => Str;
    k8s status => Str, { enum => [qw(True False Unknown)] };
}
{
    package Test::K188::Widget;
    use IO::K8s::APIObject
        api_version     => 'k188.example.com/v1',
        resource_plural => 'widgets';
    with 'IO::K8s::Role::Namespaced';

    k8s cond  => '+Test::K188::Cond';
    k8s phase => Str, { enum => [qw(True False Unknown)] };
}

my @WORDS = ( qw(
    True False yes No on OFF y N ~ Null 0x1F 0o14 012 1_000 190:20:30
    .inf .NaN 1e3 +1 true null 123
) );

my @SCHEMAS = (
    [ 'YAML1_1' => [qw( YAML1_1 )] ],
    [ 'Core'    => [qw( Core )] ],
    [ 'JSON'    => [qw( JSON )] ]
);

my $json = JSON::PP->new->canonical->allow_nonref->allow_blessed->convert_blessed;

sub load_as {
    my ( $yaml, $schema ) = @_;
    return YAML::PP->new( schema => $schema, boolean => 'JSON::PP' )->load_string($yaml);
}

# Assert that $yaml, read by each resolver, has the exact typed structure $want.
sub yaml_types_ok {
    my ( $yaml, $want, $name ) = @_;
    my $want_json = $json->encode($want);
    for my $s (@SCHEMAS) {
        my $got = load_as( $yaml, $s->[1] );
        is( $json->encode($got), $want_json, $name . ' [' . $s->[0] . ' reader]' );
    }
}

my %words = map { ( 'w' . $_ => $WORDS[$_] ) } 0 .. $#WORDS;

my $k8s = IO::K8s->new;

# --------------------------------------------------------------------
subtest 'preconditions: the words really are non-strings to YAML 1.1' => sub {
    # Guards the test itself: if the reader stopped resolving these, the
    # assertions below would pass vacuously.
    my $y11 = [qw( YAML1_1 )];
    for my $w (qw( True False yes No on OFF y N ~ Null 0x1F 012 1_000 190:20:30 .inf .NaN +1 true null 123 )) {
        my $got = load_as( "a: $w\n", $y11 )->{a};
        isnt( $json->encode($got), $json->encode($w), 'bare ' . $w . ' is not a string under YAML 1.1' );
    }
    # Observed with YAML::PP 0.41: its YAML1_1 loader keeps 0o14 and 1e3 as
    # strings (they are YAML 1.2 Core words); the Core reader does resolve them.
    for my $w (qw( 0o14 1e3 )) {
        my $got = load_as( "a: $w\n", [qw( Core )] )->{a};
        isnt( $json->encode($got), $json->encode($w), 'bare ' . $w . ' is not a string under Core' );
    }
};

# --------------------------------------------------------------------
subtest 'APIObject to_yaml: ConfigMap labels, annotations and data keep string type' => sub {
    my $cm = $k8s->new_object( 'ConfigMap',
        metadata => { name => 'k188', namespace => 'default', labels => { flag => 'yes' }, annotations => {%words} },
        data     => {%words}
    );
    my $yaml = $cm->to_yaml;
    yaml_types_ok( $yaml, $cm->TO_JSON, 'ConfigMap: all string values survive' );

    my $label = load_as( $yaml, [qw( YAML1_1 )] )->{metadata}{labels}{flag};
    ok( !ref $label && $label eq 'yes', 'label yes is the plain string yes under YAML 1.1' );
    like( $yaml, qr/^\s+flag: (?:"yes"|'yes')$/m, 'label yes is quoted in the raw text' );

    for my $w ( '012', '+1', '~' ) {
        my $q = quotemeta $w;
        like( $yaml, qr/^\s+w\d+: (?:"$q"|'$q')$/m, 'raw text quotes ' . $w );
    }
};

# --------------------------------------------------------------------
subtest 'Resource TO_YAML / to_yaml: env value on, plus bare Int and Bool' => sub {
    my $c = IO::K8s::Api::Core::V1::Container->new(
        name  => 'app',
        image => 'nginx',
        env   => [ { name => 'DEBUG', value => 'on' }, { name => 'MODE', value => '012' } ],
        ports => [ { containerPort => 8080 } ],
        stdin => JSON::PP::true
    );
    for my $m (qw( TO_YAML to_yaml )) {
        my $yaml = $c->$m;
        yaml_types_ok( $yaml, $c->TO_JSON, 'Container ' . $m );

        my $d = load_as( $yaml, [qw( YAML1_1 )] );
        ok( !ref $d->{env}[0]{value} && $d->{env}[0]{value} eq 'on', $m . ': env on is a plain string' );
        ok( !ref $d->{env}[1]{value} && $d->{env}[1]{value} eq '012', $m . ': env 012 is a plain string' );

        like( $yaml, qr/^\s*(?:- )?containerPort: 8080$/m, $m . ': Int stays bare in the raw text' );
        like( $yaml, qr/^stdin: true$/m, $m . ': Bool stays bare in the raw text' );
        is( ref $d->{ports}[0]{containerPort}, '', $m . ': containerPort is not a reference under YAML 1.1' );
        is( $json->encode( $d->{ports}[0]{containerPort} ), '8080', $m . ': containerPort loads as the number 8080' );
        isa_ok( $d->{stdin}, 'JSON::PP::Boolean', $m . ': stdin loads as a real boolean' );
    }
};

# --------------------------------------------------------------------
subtest 'status condition True (Deployment) and bare replicas / boolean' => sub {
    my $dep = $k8s->new_object( 'Deployment',
        metadata => { name => 'k188', namespace => 'default' },
        spec     => {
            replicas => 3,
            selector => { matchLabels => { app => 'k188' } },
            template => {
                metadata => { labels => { app => 'k188' } },
                spec     => { automountServiceAccountToken => JSON::PP::false, containers => [ { name => 'a', image => 'i' } ] }
            }
        },
        status => { conditions => [
            { type => 'Available',   status => 'True' },
            { type => 'Progressing', status => 'False' },
            { type => 'Odd',         status => 'Unknown' }
        ] }
    );
    my $yaml = $dep->to_yaml;
    yaml_types_ok( $yaml, $dep->TO_JSON, 'Deployment' );

    my $d = load_as( $yaml, [qw( YAML1_1 )] );
    is_deeply(
        [ map { $_->{status} } @{ $d->{status}{conditions} } ],
        [qw( True False Unknown )],
        'condition statuses are the strings True/False/Unknown under YAML 1.1'
    );
    ok( !ref $_->{status}, 'condition status ' . $_->{status} . ' is not a boolean object' ) for @{ $d->{status}{conditions} };

    like( $yaml, qr/^\s+replicas: 3$/m, 'replicas stays bare' );
    like( $yaml, qr/^\s+automountServiceAccountToken: false$/m, 'real boolean stays bare' );
    is( $json->encode( $d->{spec}{replicas} ), '3', 'replicas is the number 3 under YAML 1.1' );
    isa_ok( $d->{spec}{template}{spec}{automountServiceAccountToken}, 'JSON::PP::Boolean', 'automountServiceAccountToken' );
};

# --------------------------------------------------------------------
subtest 'to_crd->to_yaml: enum [True False Unknown] survives as three strings' => sub {
    my $yaml = Test::K188::Widget->to_crd->to_yaml;

    for my $s (@SCHEMAS) {
        my $d = load_as( $yaml, $s->[1] );
        my $props = $d->{spec}{versions}[0]{schema}{openAPIV3Schema}{properties};
        for my $path ( [ 'phase', $props->{phase}{enum} ], [ 'cond.status', $props->{cond}{properties}{status}{enum} ] ) {
            is( $json->encode( $path->[1] ), '["True","False","Unknown"]', $path->[0] . ' enum is three strings [' . $s->[0] . ' reader]' );
        }
    }
    like( $yaml, qr/^\s+- (?:"True"|'True')$/m,  'raw text quotes True' );
    like( $yaml, qr/^\s+- (?:"False"|'False')$/m, 'raw text quotes False' );
    like( $yaml, qr/^\s+- Unknown$/m, 'Unknown stays bare (plain string in every reader)' );
    # Whole-CRD sanity: kinds of the typed values stay as the JSON path emits.
    like( $yaml, qr/^\s+served: true$/m, 'CRD served: stays a bare boolean' );
};

# --------------------------------------------------------------------
subtest 'save writes the same quoted YAML' => sub {
    my $dir = tempdir( CLEANUP => 1 );
    my $cm  = $k8s->new_object( 'ConfigMap',
        metadata => { name => 'k188', namespace => 'default' },
        data     => {%words}
    );
    my $file = $dir . '/cm.yaml';
    $cm->save($file);
    open my $fh, '<:encoding(UTF-8)', $file or die 'cannot read ' . $file . ': ' . $!;
    my $content = do { local $/; <$fh> };
    close $fh;

    is( $content, $cm->to_yaml, 'saved file equals to_yaml' );
    yaml_types_ok( $content, $cm->TO_JSON, 'saved ConfigMap' );
};

# --------------------------------------------------------------------
subtest 'optional: PyYAML safe_load sees strings' => sub {
    my $probe = system( 'python3 -c "import yaml" >/dev/null 2>&1' );
    plan skip_all => 'python3 with PyYAML not available' if $probe != 0;

    my $cm = $k8s->new_object( 'ConfigMap',
        metadata => { name => 'k188', namespace => 'default', labels => { flag => 'yes' } },
        data     => { %words, count => '10' }
    );
    my $dir  = tempdir( CLEANUP => 1 );
    my $file = $dir . '/cm.yaml';
    $cm->save($file);

    # Report the Python type name of each value: Python's JSON output cannot
    # represent .inf/.NaN, and the type is what matters here.
    my $py = 'import yaml,json,sys; d=yaml.safe_load(open(sys.argv[1])); '
        . 'print(json.dumps({"data":{k:type(v).__name__ for k,v in d["data"].items()},"label":d["metadata"]["labels"]["flag"]}))';
    open my $ph, '-|', 'python3', '-c', $py, $file or die 'cannot run python3: ' . $!;
    my $out = do { local $/; <$ph> };
    close $ph;
    my $got = JSON::PP->new->canonical->decode($out);
    my @non_string = grep { $got->{data}{$_} ne 'str' } sort keys %{ $got->{data} };
    is_deeply( \@non_string, [], 'PyYAML reads every data value as a str' );
    is( $got->{label}, 'yes', 'PyYAML reads label yes as the string yes' );
};

done_testing;
