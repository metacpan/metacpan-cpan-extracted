#!/usr/bin/env perl
# k159: load_yaml's two inputs, a file path and YAML text.
#
# A file was read without an encoding layer, so YAML::PP got UTF-8 bytes
# where it expects characters: a Umlaut in an annotation came back as two
# Latin-1 characters and went out double-encoded in the JSON. And an
# argument without a newline that is not an existing file -- a mistyped
# path, 'manifests/app.yaml' -- was parsed as YAML text, resolved to one
# plain string and silently produced [].
#
# Approved contract:
#   * a file is read as UTF-8; the characters reach the objects and the JSON
#     encodes them once;
#   * a string is YAML text in decoded characters and is not re-encoded;
#   * one method, no new API: an argument with no newline that is no
#     existing file and resolves as YAML to scalars only, not a single
#     mapping, dies naming the argument; a directory dies too;
#   * empty / whitespace-only text still gives [], and a one-line YAML
#     mapping (block or flow) still loads.
#
# Pure local fixtures in a temporary directory -- no network, no cluster.

use strict;
use warnings;
use utf8;
use Test::More;
use Test::Exception;
use Path::Tiny qw(path tempdir);
use JSON::MaybeXS ();
use lib 'lib';

use IO::K8s;

my $dir = tempdir();
my $k8s = IO::K8s->new;

my $UMLAUT = 'Grüße aus München';    # Latin-1 range
my $WIDE   = 'Preis: 5 € — 日本';     # outside Latin-1

my $yaml = <<"YAML";
apiVersion: v1
kind: ConfigMap
metadata:
  name: utf8-cm
  annotations:
    note: "$UMLAUT"
  labels:
    team: "$WIDE"
data:
  greeting: "$WIDE"
YAML

# ===========================================================================
# UTF-8 file
# ===========================================================================

# Claim: the characters of a UTF-8 file arrive as characters, in the object
# and -- encoded exactly once -- in the JSON.
subtest 'a UTF-8 file round-trips to JSON' => sub {
    my $file = $dir->child('cm.yaml');
    $file->spew_utf8($yaml);

    my ($cm) = @{ $k8s->load_yaml("$file") };
    isa_ok($cm, 'IO::K8s::Api::Core::V1::ConfigMap');
    is($cm->metadata->annotations->{note}, $UMLAUT, 'Umlaut annotation read as characters');
    is($cm->metadata->labels->{team},      $WIDE,   'non-Latin-1 label read as characters');
    is($cm->data->{greeting},              $WIDE,   'non-Latin-1 data read as characters');

    my $back = JSON::MaybeXS->new(utf8 => 1)->decode($cm->to_json);
    is($back->{metadata}{annotations}{note}, $UMLAUT, 'JSON carries the Umlaut once-encoded');
    is($back->{data}{greeting},              $WIDE,   'JSON carries the wide characters once-encoded');
};

# Claim: YAML text passed as decoded characters is taken as is -- the same
# objects as from the file.
subtest 'the same YAML as a character string gives the same object' => sub {
    my ($cm) = @{ $k8s->load_yaml($yaml) };
    is($cm->metadata->annotations->{note}, $UMLAUT, 'Umlaut from text');
    is($cm->data->{greeting},              $WIDE,   'wide characters from text');
};

# Claim: collect_errors reads the file the same way.
subtest 'collect_errors reads the file as UTF-8 too' => sub {
    my $file = $dir->child('cm2.yaml');
    $file->spew_utf8($yaml);
    my ($objs, $errors) = $k8s->load_yaml("$file", collect_errors => 1);
    is_deeply($errors, [], 'no errors');
    is($objs->[0]->data->{greeting}, $WIDE, 'wide characters');
};

# ===========================================================================
# A path that does not exist is not YAML text
# ===========================================================================

# Claim: a mistyped relative path dies naming the argument instead of
# returning [].
subtest 'a mistyped path dies naming the argument' => sub {
    throws_ok { $k8s->load_yaml('manifests/app.yaml') }
        qr/load_yaml: 'manifests\/app\.yaml' is neither an existing file nor YAML text/,
        'relative path';
    my $missing = $dir->child('nope.yaml');
    throws_ok { $k8s->load_yaml("$missing") }
        qr/load_yaml: '\Q$missing\E' is neither an existing file nor YAML text/,
        'absolute path';
};

# Claim: under collect_errors it dies as well -- it is not a document error
# to collect.
subtest 'a mistyped path dies under collect_errors too' => sub {
    throws_ok { $k8s->load_yaml('manifests/app.yaml', collect_errors => 1) }
        qr/neither an existing file nor YAML text/, 'collect_errors';
};

# Claim: a directory is not a manifest and says so.
subtest 'a directory dies clearly' => sub {
    throws_ok { $k8s->load_yaml("$dir") } qr/load_yaml: '\Q$dir\E' is a directory/, 'directory';
};

# ===========================================================================
# GUARDS
# ===========================================================================

# Claim: empty and whitespace-only text keep giving [].
subtest 'GUARD: empty / whitespace-only text gives []' => sub {
    is_deeply($k8s->load_yaml(''),        [], 'empty string');
    is_deeply($k8s->load_yaml('   '),     [], 'spaces');
    is_deeply($k8s->load_yaml("\n\n"),    [], 'newlines');
    is_deeply($k8s->load_yaml('---'),     [], 'bare document marker');
    is_deeply($k8s->load_yaml('# note'),  [], 'comment only');
};

# Claim: a one-line YAML mapping is still YAML text, block or flow.
subtest 'GUARD: one-line mappings still load' => sub {
    my $objs = $k8s->load_yaml('{apiVersion: v1, kind: Namespace, metadata: {name: ns1}}');
    is(scalar @$objs, 1, 'flow mapping gives one object');
    is($objs->[0]->metadata->name, 'ns1', 'flow mapping content');

    # A block mapping without apiVersion/metadata still parses as a mapping;
    # inflating it is the usual kind-driven path.
    my $ns = $k8s->load_yaml('kind: Namespace');
    is(scalar @$ns, 1, "'kind: Namespace' gives one object");
    isa_ok($ns->[0], 'IO::K8s::Api::Core::V1::Namespace');
};

# Claim: multi-line text that resolves to scalars keeps its old behaviour
# -- the typo rule is for single-line arguments only.
subtest 'GUARD: multi-line scalar-only text still gives []' => sub {
    is_deeply($k8s->load_yaml("--- just a string\n--- another\n"), [], 'scalar documents skipped');
};

# Claim: an existing file still loads when given with no newline, as before.
subtest 'GUARD: an ASCII file still loads' => sub {
    my $file = $dir->child('ns.yaml');
    $file->spew("apiVersion: v1\nkind: Namespace\nmetadata:\n  name: plain\n");
    my ($ns) = @{ $k8s->load_yaml("$file") };
    is($ns->metadata->name, 'plain', 'plain file');
};

done_testing;
