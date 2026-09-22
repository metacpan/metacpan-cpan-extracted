#!/usr/bin/env perl
# Tests for Kubernetes::REST::CLI::Crd2Class, the MooX::Options class behind
# bin/kube_crd2class (CRD design D15, karr #24).
#
# The -f path is cluster-free by construction: it reads a CRD manifest and
# delegates the whole schema-to-DSL job to IO::K8s (IO::K8s::CRD ->load /
# ->served_versions / ->generate, IO::K8s::CRD::Emitter ->render). These
# tests drive a small embedded CRD through run()/_render_crds and assert the
# actual emitter output - the DSL lines, the Kind, the apiVersion, the field
# options and the POD - not merely that it ran. The --from-cluster path injects
# a mocked Kubernetes::REST (Test::Kubernetes::Mock) as the lazy `api` and
# asserts it renders the same source as -f for the same CRD.
#
# IO::K8s::CRD ships with IO::K8s (>= 1.108); run with the neighbouring lib
# prepended for consistency with the rest of the CRD increment:
#   PERL5LIB=/home/getty/dev/io-k8s-p5/lib prove -lv t/40_cli_crd2class.t

use strict;
use warnings;
use Test::More;
use Test::Exception;
use FindBin;
use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/lib";
use File::Temp qw( tempfile tempdir );
use Path::Tiny qw( path );
use JSON::MaybeXS;
use Test::Kubernetes::Mock qw( mock_api );

use Kubernetes::REST::CLI::Crd2Class;

# A two-served-version CRD: v1 (storage) with a required field, a constrained
# integer and a described field; v1beta1 (served, not storage) with one field.
my $CRD_YAML = <<'YAML';
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: crontabs.stable.example.com
spec:
  group: stable.example.com
  scope: Namespaced
  names:
    plural: crontabs
    kind: CronTab
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
              required: [cronSpec]
              properties:
                cronSpec:
                  type: string
                  description: The cron schedule expression.
                replicas:
                  type: integer
                  minimum: 0
                image:
                  type: string
    - name: v1beta1
      served: true
      storage: false
      schema:
        openAPIV3Schema:
          type: object
          properties:
            spec:
              type: object
              properties:
                cronSpec:
                  type: string
YAML

sub write_crd {
    my ($fh, $path) = tempfile(SUFFIX => '.yaml', UNLINK => 1);
    print $fh $CRD_YAML;
    close $fh;
    return $path;
}

# ---------------------------------------------------------------------------
# _render_crds: the emitter output, block by block (the real assertion that
# the IO::K8s emitter was actually driven).
# ---------------------------------------------------------------------------
{
    my $cli = Kubernetes::REST::CLI::Crd2Class->new(file => write_crd());
    my $crds = IO::K8s::CRD->load($cli->file);
    my $blocks = $cli->_render_crds($crds);

    ok(ref $blocks eq 'ARRAY', '_render_crds returns an arrayref of blocks');

    # Each served version yields a Kind class and a Spec class: 2 x 2 = 4.
    is(scalar @$blocks, 4, 'both served versions rendered, Kind + Spec each');

    my %by_path = map { $_->[0] => $_ } @$blocks;

    my $v1 = $by_path{'IO/K8s/Stable/V1/CronTab.pm'};
    ok($v1, 'v1 CronTab class rendered at the expected relative path');
    is($v1->[1], 'stable.example.com/v1', 'v1 block carries its apiVersion');
    like($v1->[2], qr/^package IO::K8s::Stable::V1::CronTab;/m,
        'v1 Kind renders the right package');
    like($v1->[2], qr/api_version\s*=>\s*'stable\.example\.com\/v1'/,
        'v1 Kind DSL carries api_version');
    like($v1->[2], qr/resource_plural\s*=>\s*'crontabs'/,
        'v1 Kind DSL carries resource_plural');
    like($v1->[2], qr/with 'IO::K8s::Role::Namespaced'/,
        'namespaced scope renders the Namespaced role');

    my $spec = $by_path{'IO/K8s/Stable/V1/CronTabSpec.pm'};
    ok($spec, 'v1 CronTabSpec nested class rendered');
    like($spec->[2], qr/use IO::K8s::Resource;/, 'nested spec is a Resource class');
    like($spec->[2], qr/k8s cronSpec\s*=> Str, \{ required => 'schema' \}/,
        'required field renders required => schema option');
    like($spec->[2], qr/k8s replicas\s*=> Int, \{ minimum => 0 \}/,
        'integer minimum renders as a field option');
    like($spec->[2], qr/k8s image\s*=> Str;/, 'plain string field renders');
    like($spec->[2], qr/=attr cronSpec\n\nThe cron schedule expression\./,
        'schema description lands in the =attr POD');

    my $beta = $by_path{'IO/K8s/Stable/V1beta1/CronTab.pm'};
    ok($beta, 'the non-storage served version is rendered too');
    like($beta->[2], qr/api_version\s*=>\s*'stable\.example\.com\/v1beta1'/,
        'v1beta1 block carries its own apiVersion');
}

# ---------------------------------------------------------------------------
# run(): STDOUT carries every rendered version under a path banner.
# ---------------------------------------------------------------------------
{
    my $cli = Kubernetes::REST::CLI::Crd2Class->new(file => write_crd());
    my $out = '';
    {
        open my $fh, '>', \$out or die $!;
        local *STDOUT = $fh;
        is($cli->run, 0, 'run returns 0 on the -f path');
    }
    like($out, qr/package IO::K8s::Stable::V1::CronTab;/,
        'run prints the v1 Kind source to STDOUT');
    like($out, qr/package IO::K8s::Stable::V1beta1::CronTab;/,
        'run prints the v1beta1 Kind source to STDOUT');
    like($out, qr/# IO\/K8s\/Stable\/V1\/CronTab\.pm  \(stable\.example\.com\/v1\)/,
        'each block is printed under a path + apiVersion banner');
}

# ---------------------------------------------------------------------------
# --namespace overrides the derived base; --output_dir writes a tree.
# ---------------------------------------------------------------------------
{
    my $cli = Kubernetes::REST::CLI::Crd2Class->new(
        file => write_crd(), namespace => 'My::K8s',
    );
    my $blocks = $cli->_render_crds(IO::K8s::CRD->load($cli->file));
    like($blocks->[0][2], qr/^package My::K8s::V1::CronTab;/m,
        '--namespace sets the base package for the rendered classes');

    my $dir = tempdir(CLEANUP => 1);
    my $wcli = Kubernetes::REST::CLI::Crd2Class->new(
        file => write_crd(), output_dir => $dir,
    );
    my $err = '';
    {
        open my $efh, '>', \$err or die $!;
        local *STDERR = $efh;
        is($wcli->run, 0, 'run returns 0 when writing to --output_dir');
    }
    my $written = path($dir, 'IO/K8s/Stable/V1/CronTab.pm');
    ok(-f $written, 'run writes each class under --output_dir');
    like($written->slurp_utf8, qr/package IO::K8s::Stable::V1::CronTab;/,
        'the written file holds the rendered source');
    like($err, qr/wrote .*CronTab\.pm/, 'written paths are logged to STDERR');
}

# ---------------------------------------------------------------------------
# --from-cluster: a mocked Kubernetes::REST serves a CronTab CRD (same shape
# as $CRD_YAML). Injecting the mock as the lazy `api` attribute keeps the test
# cluster-free; the CRD is fetched via $api->list('CustomResourceDefinition'),
# matched on spec.names.kind, and must render byte-for-byte what -f renders
# from the equivalent manifest.
# ---------------------------------------------------------------------------

# The cluster's CRD list, mirroring $CRD_YAML: v1 (storage) + v1beta1 (served).
sub crontab_crd_list {
    return {
        apiVersion => 'apiextensions.k8s.io/v1',
        kind       => 'CustomResourceDefinitionList',
        items      => [ {
            apiVersion => 'apiextensions.k8s.io/v1',
            kind       => 'CustomResourceDefinition',
            metadata   => { name => 'crontabs.stable.example.com' },
            spec => {
                group => 'stable.example.com',
                scope => 'Namespaced',
                names => { plural => 'crontabs', kind => 'CronTab' },
                versions => [
                    {
                        name => 'v1', served => JSON->true, storage => JSON->true,
                        schema => { openAPIV3Schema => { type => 'object', properties => { spec => {
                            type => 'object', required => ['cronSpec'], properties => {
                                cronSpec => { type => 'string', description => 'The cron schedule expression.' },
                                replicas => { type => 'integer', minimum => 0 },
                                image    => { type => 'string' },
                            } } } } },
                    },
                    {
                        name => 'v1beta1', served => JSON->true, storage => JSON->false,
                        schema => { openAPIV3Schema => { type => 'object', properties => { spec => {
                            type => 'object', properties => { cronSpec => { type => 'string' } },
                        } } } },
                    },
                ],
            },
        } ],
    };
}

sub mock_crontab_api {
    my $api = mock_api();
    $api->io->add_response(
        'GET', '/apis/apiextensions.k8s.io/v1/customresourcedefinitions',
        crontab_crd_list(),
    );
    return $api;
}

{
    my $ccli = Kubernetes::REST::CLI::Crd2Class->new(
        from_cluster => 'CronTab', api => mock_crontab_api(),
    );

    # Same CRD via -f, for the equivalence assertion.
    my $fcli = Kubernetes::REST::CLI::Crd2Class->new(file => write_crd());

    my $c_blocks = $ccli->_render_crds($ccli->_crds_from_cluster('CronTab'));
    my $f_blocks = $fcli->_render_crds(IO::K8s::CRD->load($fcli->file));

    is_deeply($c_blocks, $f_blocks,
        '--from-cluster renders byte-identical source to -f for the same CRD');

    my $out = '';
    {
        open my $fh, '>', \$out or die $!;
        local *STDOUT = $fh;
        is($ccli->run, 0, 'run returns 0 on the --from-cluster path');
    }
    like($out, qr/package IO::K8s::Stable::V1::CronTab;/,
        'run prints the cluster CRD source to STDOUT');
    like($out, qr/package IO::K8s::Stable::V1beta1::CronTab;/,
        'both served versions come from the cluster');
}

# A Kind the cluster does not serve is a clear error, not an empty run.
{
    my $cli = Kubernetes::REST::CLI::Crd2Class->new(
        from_cluster => 'Widget', api => mock_crontab_api(),
    );
    throws_ok { $cli->run } qr/no CustomResourceDefinition on the cluster serves kind 'Widget'/,
        '--from-cluster with an unknown Kind dies clearly';
}

# ---------------------------------------------------------------------------
# No input at all is a usage error.
# ---------------------------------------------------------------------------
{
    my $cli = Kubernetes::REST::CLI::Crd2Class->new;
    throws_ok { $cli->run } qr/no input given/,
        'run without --file or --from-cluster is a usage error';
}

done_testing;
