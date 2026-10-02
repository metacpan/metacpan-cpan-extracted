use strict;
use warnings;
use Test::More;
use File::Temp qw( tempdir );
use File::Spec;

use MCP::K8s;

# =================================================================
# kubeconfig_path: an embedder that keeps its kubeconfigs outside the
# default location must be able to say which file applies. Without the
# attribute, Tier 3 built Kubernetes::REST::Kubeconfig without a path,
# so the lookup fell back to $ENV{KUBECONFIG} / ~/.kube/config -- and a
# same-named context there silently pointed the tools at another
# cluster.
#
# Real kubeconfig files in a tempdir, no cluster: Kubeconfig->api only
# parses the file and builds a Kubernetes::REST client, nothing is
# contacted.
# =================================================================

my $dir = tempdir( CLEANUP => 1 );

sub write_kubeconfig {
  my ($name, $server, $token, %opts) = @_;
  my $context = $opts{context} // 'shared-context';
  my $current = $opts{current} // $context;
  my $file = File::Spec->catfile($dir, $name);
  open my $fh, '>', $file or die 'Cannot write '.$file.': '.$!;
  print $fh <<"YAML";
apiVersion: v1
kind: Config
current-context: $current
clusters:
- name: $context-cluster
  cluster:
    server: $server
    insecure-skip-tls-verify: true
contexts:
- name: $context
  context:
    cluster: $context-cluster
    user: $context-user
users:
- name: $context-user
  user:
    token: $token
YAML
  close $fh;
  return $file;
}

my $right_file = write_kubeconfig('right.yaml', 'https://right.example:6443', 'right-token');
my $wrong_file = write_kubeconfig('wrong.yaml', 'https://wrong.example:6443', 'wrong-token');

sub tier3_env {
  delete $ENV{MCP_K8S_TOKEN};
  delete $ENV{MCP_K8S_SERVER};
  delete $ENV{MCP_K8S_CONTEXT};
}

subtest 'explicit kubeconfig_path wins over a same-named context in KUBECONFIG' => sub {
  # The bug from the ticket: KUBECONFIG points at a file whose context
  # has the same name as the one the embedder means. Only the explicit
  # path tells the two apart.
  local %ENV = %ENV;
  tier3_env();
  $ENV{KUBECONFIG} = $wrong_file;

  my $k8s = MCP::K8s->new(
    kubeconfig_path => $right_file,
    context_name    => 'shared-context',
    namespaces      => ['default'],
  );
  ok($k8s->has_kubeconfig_path, 'has_kubeconfig_path true with constructor arg');

  my $api = eval { $k8s->api };
  ok(!$@, 'api built without error') or diag('error: '.$@);
  isa_ok($api, 'Kubernetes::REST', 'Tier 3 returned a Kubernetes::REST instance');
  is($api->server->endpoint, 'https://right.example:6443',
    'server comes from the kubeconfig_path file, not from KUBECONFIG');
  is($api->credentials->token, 'right-token',
    'token comes from the kubeconfig_path file, not from KUBECONFIG');
};

subtest 'kubeconfig_path alone uses that file\'s current-context' => sub {
  local %ENV = %ENV;
  tier3_env();
  $ENV{KUBECONFIG} = $wrong_file;

  my $k8s = MCP::K8s->new(
    kubeconfig_path => $right_file,
    namespaces      => ['default'],
  );
  my $api = eval { $k8s->api };
  ok(!$@, 'api built without error') or diag('error: '.$@);
  is($api->server->endpoint, 'https://right.example:6443',
    'current-context of the kubeconfig_path file applies');
};

subtest 'without kubeconfig_path the KUBECONFIG lookup is unchanged' => sub {
  local %ENV = %ENV;
  tier3_env();
  $ENV{KUBECONFIG} = $wrong_file;

  my $k8s = MCP::K8s->new(namespaces => ['default']);
  ok(!$k8s->has_kubeconfig_path, 'has_kubeconfig_path false when not given');

  my $api = eval { $k8s->api };
  ok(!$@, 'api built without error') or diag('error: '.$@);
  is($api->server->endpoint, 'https://wrong.example:6443',
    'Kubeconfig falls back to its own KUBECONFIG lookup');
  ok(!$k8s->has_kubeconfig_path,
    'has_kubeconfig_path stays false after _build_api (no env-backed default)');
};

# Capture exactly what _build_api hands to the Kubeconfig constructor,
# same recorder shape as t/09: Kubeconfig's own kubeconfig_path default
# is a plain (non-lazy) default, so an explicit `kubeconfig_path => undef`
# would override it -- the key must be absent, not undef.
{
  package MockKubeconfigRecorder;
  our @invocations;

  sub new {
    my ($class, %args) = @_;
    push @MockKubeconfigRecorder::invocations, {%args};
    return bless { args => \%args }, __PACKAGE__;
  }

  sub api { return $_[0]; }
}

subtest 'kubeconfig_path key absent from Kubeconfig args when unset or empty' => sub {
  local %ENV = %ENV;
  tier3_env();
  delete $ENV{KUBECONFIG};

  local @MockKubeconfigRecorder::invocations;
  no warnings 'redefine';
  local *Kubernetes::REST::Kubeconfig::new =
    sub { MockKubeconfigRecorder::new(@_) };

  my $k8s_unset = MCP::K8s->new(namespaces => ['default']);
  ok(eval { $k8s_unset->api; 1 }, 'unset: api built without error') or diag('error: '.$@);
  ok(!exists $MockKubeconfigRecorder::invocations[-1]{kubeconfig_path},
    'unset: kubeconfig_path not passed (Kubeconfig keeps its own lookup)');

  my $k8s_empty = MCP::K8s->new(kubeconfig_path => '', namespaces => ['default']);
  ok(eval { $k8s_empty->api; 1 }, 'empty: api built without error') or diag('error: '.$@);
  ok(!exists $MockKubeconfigRecorder::invocations[-1]{kubeconfig_path},
    'empty: kubeconfig_path not passed (Kubeconfig keeps its own lookup)');

  my $k8s_set = MCP::K8s->new(kubeconfig_path => $right_file, namespaces => ['default']);
  ok(eval { $k8s_set->api; 1 }, 'set: api built without error') or diag('error: '.$@);
  is($MockKubeconfigRecorder::invocations[-1]{kubeconfig_path}, $right_file,
    'set: kubeconfig_path passed through verbatim');

  is(scalar @MockKubeconfigRecorder::invocations, 3,
    'Kubeconfig->new called once per instance');
};

done_testing;
