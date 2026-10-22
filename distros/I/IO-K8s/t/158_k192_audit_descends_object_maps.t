#!/usr/bin/env perl
# k192: maint/crd-schema-audit.pl must descend into the VALUES of an object map
# (k8s name => { Class => 1 }, registry flag is_hash_of_objects). It used to key
# the descent on `is_hash`, a flag no attribute ever carries, so a class
# disagreeing with the CRD only inside a map value was never reported.
#
# The script has no callable function (it audits and exit()s at file level), so
# its only interface is the CLI: --provider, --dir, --lib. The fixture is a
# provider named VolumeSnapshot (a name the script accepts) shadowed from a
# temp --lib, plus one CRD manifest under a temp --dir. No network, no cluster.
use strict;
use warnings;
use Test::More;
use File::Path qw( make_path );
use File::Spec;
use File::Temp qw( tempdir );
use FindBin;

my $root   = File::Spec->catdir($FindBin::Bin, '..');
my $script = $ENV{K192_AUDIT_SCRIPT} // File::Spec->catfile($root, 'maint', 'crd-schema-audit.pl');
my $real   = File::Spec->catdir($root, 'lib');

my $tmp = tempdir(CLEANUP => 1);
my $lib = File::Spec->catdir($tmp, 'lib');
my $dir = File::Spec->catdir($tmp, 'crd');

sub spew {
    my ($path, $text) = @_;
    my (undef, $d) = File::Spec->splitpath($path);
    make_path($d);
    open my $fh, '>', $path or die "$path: $!";
    print {$fh} $text;
    close $fh or die "$path: $!";
}

spew("$lib/IO/K8s/VolumeSnapshot.pm", <<'PM');
package IO::K8s::VolumeSnapshot;
use Moo;
with 'IO::K8s::Role::ResourceMap';
sub resource_map { { Widget => 'VolumeSnapshot::V1::Widget' } }
1;
PM

spew("$lib/IO/K8s/VolumeSnapshot/V1/Widget.pm", <<'PM');
package IO::K8s::VolumeSnapshot::V1::Widget;
use IO::K8s::APIObject
    api_version     => 'example.com/v1',
    resource_plural => 'widgets';
k8s pools => { '+IO::K8s::VolumeSnapshot::V1::Pool' => 1 };
1;
PM

# `mode` carries a default the CRD does not declare; `size` matches the CRD.
spew("$lib/IO/K8s/VolumeSnapshot/V1/Pool.pm", <<'PM');
package IO::K8s::VolumeSnapshot::V1::Pool;
use IO::K8s::Resource;
k8s mode => Str, { default => 'fast' };
k8s size => Int;
1;
PM

spew("$dir/widgets.yaml", <<'YAML');
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: widgets.example.com
spec:
  group: example.com
  names:
    kind: Widget
    plural: widgets
  versions:
    - name: v1
      schema:
        openAPIV3Schema:
          type: object
          properties:
            pools:
              type: object
              additionalProperties:
                type: object
                properties:
                  mode:
                    type: string
                  size:
                    type: integer
YAML

my $out = qx{"$^X" "-I$real" "$script" --provider VolumeSnapshot --dir "$dir" --lib "$lib" 2>&1};

unlike $out, qr/skipped:|Can't locate|Error/, 'the fixture provider loaded and the audit ran'
    or diag $out;
like $out, qr/^\s*Widget\(v1\)\.pools\.mode\s+DEFAULT INVENTED\s/m,
    'a disagreement inside an object-map value is reported at <field>.<attr>'
    or diag $out;
unlike $out, qr/Widget\(v1\)\.pools\.size/, 'the agreeing value field is not reported'
    or diag $out;
like $out, qr/--- 1 finding\(s\)/, 'exactly the one finding'
    or diag $out;

done_testing;
