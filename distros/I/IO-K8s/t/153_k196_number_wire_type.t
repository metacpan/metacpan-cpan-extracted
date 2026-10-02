#!/usr/bin/env perl
# k196: a field the Kubernetes OpenAPI types `type: number` (format double)
# must go out as a JSON number. JSONSchemaProps declared minimum, maximum and
# multipleOf as Str, and since k145 a Str value is serialized as a JSON
# string on purpose -- so 1.109 sent {"minimum":"1","maximum":"65535"} and
# the API server refused every CRD carrying a bound (live: Gateway API
# v1.6.1, "cannot unmarshal string into Go struct field
# JSONSchemaProps...minimum of type float64").
#
# Claims:
#   * the three JSONSchemaProps number fields are Num (is_num) and go out
#     as JSON numbers -- also when the value arrives as a Perl string ("1",
#     "0.5", what a quoted YAML scalar or a hand-built hash hands in);
#   * that holds through every path a CRD takes: struct_to_object ->
#     object_to_json, inflate of a whole CRD -> to_json / to_yaml, a class's
#     to_crd -> object_to_json / to_yaml, and to_yaml -> load_yaml -> to_json;
#   * a non-numeric bound is refused, as any Num field refuses it;
#   * statically: every scalar field of a shipped core class has the kind
#     its upstream property declares (Str <-> string, Int <-> integer,
#     Num <-> number, Bool <-> boolean), so a class that types a number as
#     Str again fails here, not at the API server -- and compare_to_schema
#     describes a Num field as number.
#
# Wire types are checked on the JSON / YAML text: Perl cannot tell 1 from
# "1". Local fixtures only (lib/, spec/), no network, no cluster.

use strict;
use warnings;
use Test::More;
use Test::Exception;
use File::Find;
use FindBin;
use JSON::MaybeXS ();
use Path::Tiny qw( path );

use IO::K8s;
use IO::K8s::ApiextensionsApiserver::Pkg::Apis::Apiextensions::V1::JSONSchemaProps;
use IO::K8s::ApiextensionsApiserver::Pkg::Apis::Apiextensions::V1::CustomResourceDefinition;

my $ROOT  = path($FindBin::Bin)->parent;
my $PROPS = 'IO::K8s::ApiextensionsApiserver::Pkg::Apis::Apiextensions::V1::JSONSchemaProps';
my $k8s   = IO::K8s->new;

{
    package Test::K196::Bounded;
    use IO::K8s::APIObject
        api_version     => 'k196.example.com/v1',
        resource_plural => 'boundeds';
    with 'IO::K8s::Role::Namespaced';

    k8s port  => Int, { minimum => '1',   maximum => '65535' };
    k8s ratio => Num, { minimum => '0.5', maximum => '2.5' };

    1;
}

# A JSON number for $key somewhere in $text: "key":<number> -- never "key":"...".
sub json_number {
    my ($text, $key, $num, $name) = @_;
    like($text, qr/"\Q$key\E":\Q$num\E(?:[,}\]])/, "$name: $key is the JSON number $num");
}

sub no_quoted_bounds {
    my ($text, $name) = @_;
    unlike($text, qr/"(?:minimum|maximum|multipleOf)":"/, "$name: no bound is a JSON string")
        or diag join "\n", $text =~ /("(?:minimum|maximum|multipleOf)":"[^"]*")/g;
}

subtest 'the JSONSchemaProps number fields are Num' => sub {
    my $info = $PROPS->_k8s_attr_info;
    for my $f (qw( minimum maximum multipleOf )) {
        ok($info->{$f}{is_num}, "$f is is_num");
        ok(!$info->{$f}{is_str}, "$f is not is_str");
    }
};

subtest 'the reported reproduction: struct_to_object -> object_to_json' => sub {
    my $o = $k8s->struct_to_object($PROPS, { type => 'integer', minimum => 1, maximum => 65535 });
    my $json = $k8s->object_to_json($o);
    json_number($json, minimum => 1,     'numbers in');
    json_number($json, maximum => 65535, 'numbers in');
    no_quoted_bounds($json, 'numbers in');
};

subtest 'Perl strings ("1", "0.5") go out as JSON numbers' => sub {
    my $o = $k8s->struct_to_object($PROPS,
        { type => 'number', minimum => '1', maximum => '0.5e1', multipleOf => '0.5' });
    my $json = $k8s->object_to_json($o);
    json_number($json, minimum    => 1,   'strings in');
    json_number($json, maximum    => 5,   'strings in');
    json_number($json, multipleOf => 0.5, 'strings in');
    no_quoted_bounds($json, 'strings in');

    like($o->to_yaml, qr/^minimum: 1$/m,      'to_yaml: minimum is a plain YAML number');
    like($o->to_yaml, qr/^multipleOf: 0\.5$/m, 'to_yaml: multipleOf is a plain YAML number');
};

subtest 'a non-numeric bound is refused' => sub {
    throws_ok { $k8s->struct_to_object($PROPS, { minimum => 'one' }) }
        qr/minimum/, 'minimum => "one" fails the Num constraint';
};

# A CRD as YAML text with the bounds quoted -- YAML::PP hands them in as
# Perl strings -- and one with plain numbers, nested the way Gateway API
# nests them (properties -> items -> properties).
my $CRD_YAML = <<'YAML';
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: widgets.k196.example.com
spec:
  group: k196.example.com
  names: { kind: Widget, plural: widgets, singular: widget, listKind: WidgetList }
  scope: Namespaced
  versions:
  - name: v1
    served: true
    storage: true
    schema:
      openAPIV3Schema:
        type: object
        properties:
          spec:
            type: object
            properties:
              port:   { type: integer, format: int32, minimum: "1", maximum: "65535" }
              weight: { type: number, minimum: 0, maximum: 1, multipleOf: "0.5" }
              listeners:
                type: array
                items:
                  type: object
                  properties:
                    port: { type: integer, minimum: 1, maximum: 65535 }
YAML

subtest 'a CRD from YAML: load_yaml -> to_json / to_yaml -> load_yaml again' => sub {
    my ($crd) = @{ $k8s->load_yaml($CRD_YAML) };
    isa_ok($crd, 'IO::K8s::ApiextensionsApiserver::Pkg::Apis::Apiextensions::V1::CustomResourceDefinition');

    my $json = $crd->to_json;
    no_quoted_bounds($json, 'load_yaml -> to_json');
    json_number($json, maximum    => 65535, 'load_yaml -> to_json');
    json_number($json, multipleOf => 0.5,   'load_yaml -> to_json');

    my $yaml = $crd->to_yaml;
    unlike($yaml, qr/(?:minimum|maximum|multipleOf): ['"]/, 'to_yaml: no bound is quoted');

    my ($again) = @{ $k8s->load_yaml($yaml) };
    my $json2 = $again->to_json;
    no_quoted_bounds($json2, 'to_yaml -> load_yaml -> to_json');
    is($json2, $json, 'the YAML round trip gives the same JSON');
};

subtest 'a class with bounds: to_crd -> object_to_json / to_yaml' => sub {
    my $crd  = Test::K196::Bounded->to_crd;
    my $json = $k8s->object_to_json($crd);
    no_quoted_bounds($json, 'to_crd');
    json_number($json, maximum => 65535, 'to_crd');
    json_number($json, minimum => 0.5,   'to_crd');
    json_number($json, maximum => 2.5,   'to_crd');

    unlike($crd->to_yaml, qr/(?:minimum|maximum): ['"]/, 'to_crd -> to_yaml: no bound is quoted');

    my $round = $k8s->json_to_object(ref $crd, $json);
    is($k8s->object_to_json($round), $json, 'to_crd JSON -> json_to_object -> object_to_json is stable');
};

subtest 'shipped Gateway API v1.6.1 CRDs keep their bounds numeric' => sub {
    my $dir = $ROOT->child(qw( spec crd GatewayAPI v1.6.1 ));
    plan skip_all => 'spec/crd/GatewayAPI/v1.6.1 not available (spec/ is not shipped in the dist)'
        unless $dir->is_dir;
    my $bounds = 0;
    for my $file (sort $dir->children(qr/\.yaml\z/)) {
        my @objs = @{ $k8s->load_yaml("$file") };
        for my $crd (@objs) {
            my $json = $crd->to_json;
            $bounds += () = $json =~ /"(?:minimum|maximum|multipleOf)":/g;
            no_quoted_bounds($json, $file->basename);
        }
    }
    cmp_ok($bounds, '>', 50, "checked $bounds bounds");
};

# ----------------------------------------------------------------------------
# Static: every core scalar field has its upstream kind
# ----------------------------------------------------------------------------

sub defkey_to_perl_class {
    my ($key) = @_;
    return unless $key =~ /^io\.k8s\./;
    my @parts = split /\./, substr($key, length 'io.k8s.');
    my $kind  = pop @parts;
    return join '::', 'IO::K8s',
        ( map { join '', map { ucfirst } grep { length } split /-/, $_ } @parts ), $kind;
}

subtest 'every core scalar field has the kind its upstream property declares' => sub {
    my @have = grep { $ROOT->child('spec', $_)->is_file } qw( v1.37.0.json v1.36.3.json );
    plan skip_all => 'spec/v1.37.0.json not available (spec/ is not shipped in the dist)'
        unless grep { $_ eq 'v1.37.0.json' } @have;

    my @modules;
    find(sub {
        return unless /\.pm$/;
        (my $mod = $File::Find::name) =~ s{^\Q$ROOT\E/lib/}{};
        $mod =~ s{/}{::}g;
        $mod =~ s{\.pm$}{};
        push @modules, $mod;
    }, "$ROOT/lib/IO/K8s");
    for my $mod (@modules) { eval "require $mod; 1" or fail("load $mod: $@") }

    my @specs = map {
        my $d = JSON::MaybeXS->new->decode($ROOT->child('spec', $_)->slurp_raw)->{definitions};
        my %for_class;
        for my $key (keys %$d) {
            my $class = defkey_to_perl_class($key) or next;
            $for_class{$class} = $key;
        }
        { defs => $d, for_class => \%for_class };
    } @have;

    # Scalar kind flag -> the OpenAPI type it stands for. Quantity, Time
    # and IntOrStr are $refs or formats upstream and are not scalar kinds here.
    my %WANT = ( is_str => 'string', is_int => 'integer', is_num => 'number', is_bool => 'boolean' );
    my $CORE = qr/^IO::K8s::(?:Api|Apimachinery|ApiextensionsApiserver|KubeAggregator)::/;
    my $registry = \%IO::K8s::Resource::_attr_registry;
    my ($checked, $numbers, @wrong) = (0, 0);

    for my $class (sort grep { /$CORE/ } keys %$registry) {
        my ($spec) = grep { $_->{for_class}{$class} } @specs or next;
        my $props = $spec->{defs}{ $spec->{for_class}{$class} }{properties} // {};
        for my $attr (sort keys %{ $registry->{$class} }) {
            my $entry = $registry->{$class}{$attr};
            next if $entry->{is_quantity} || $entry->{is_time} || $entry->{is_int_or_string};
            my ($flag) = grep { $entry->{$_} } sort keys %WANT or next;
            my $prop = $props->{ $entry->{json_key} // $attr } or next;
            next if $prop->{'$ref'};
            $checked++;
            $numbers++ if ($prop->{type} // '') eq 'number';
            push @wrong, "$class.$attr: declared " . ($flag =~ s/^is_//r)
                . ", upstream type " . ($prop->{type} // '(none)')
                unless ($prop->{type} // '') eq $WANT{$flag};
        }
    }

    # compare_to_schema, the per-class form of this check, reads Num as
    # number (it had no arm for it and reported 'unknown').
    my $props_def = $specs[0]{defs}{ $specs[0]{for_class}{$PROPS} };
    my @num_mismatch = grep { $_->{attr} =~ /^(?:minimum|maximum|multipleOf)\z/ }
        @{ $PROPS->compare_to_schema($props_def)->{type_mismatch} };
    is_deeply(\@num_mismatch, [], 'compare_to_schema: the number fields match upstream')
        or diag explain \@num_mismatch;

    cmp_ok($checked, '>', 1000, "checked $checked scalar fields against the schema");
    cmp_ok($numbers, '>=', 3, "$numbers of them are upstream type: number");
    is_deeply(\@wrong, [], 'every scalar field matches its upstream type')
        or diag join "\n", @wrong;
};

done_testing;
