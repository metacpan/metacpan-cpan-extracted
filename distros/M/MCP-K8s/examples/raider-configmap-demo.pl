#!/usr/bin/env perl
# PODNAME: raider-configmap-demo.pl
# ABSTRACT: Live demo — AI creates, reads, updates, and cleans up a ConfigMap

=head1 SYNOPSIS

  # Requires a working kubeconfig and LANGERTHA_ANTHROPIC_API_KEY
  LANGERTHA_ANTHROPIC_API_KEY=sk-ant-... perl -Ilib examples/raider-configmap-demo.pl

  # With specific context/namespace
  MCP_K8S_CONTEXT=my-cluster MCP_K8S_NAMESPACES=default \
    LANGERTHA_ANTHROPIC_API_KEY=sk-ant-... perl -Ilib examples/raider-configmap-demo.pl

=head1 DESCRIPTION

This script demonstrates MCP::K8s + Langertha::Raider working together:
a real AI assistant uses the MCP tools to perform a safe, harmless operation
on your Kubernetes cluster.

B<What it does:>

=over 4

=item 1. Discovers RBAC permissions (calls C<k8s_permissions>)

=item 2. Creates a ConfigMap named C<mcp-k8s-demo> with test data

=item 3. Reads the ConfigMap back to verify it was created

=item 4. Updates it with new data using C<k8s_apply>

=item 5. Deletes the ConfigMap to clean up

=back

The entire lifecycle is driven by the AI — it decides which tools to call
based on the instructions. Tool calls and timing are printed live.

B<Requirements:>

=over 4

=item * C<LANGERTHA_ANTHROPIC_API_KEY> environment variable set

=item * A kubeconfig with access to at least one namespace (or C<MCP_K8S_TOKEN>)

=item * C<create>, C<get>, C<patch>, C<delete> permissions on C<configmaps>

=item * L<Net::Async::MCP> 0.004 or newer — 0.003 predates the stateless
protocol revision MCP 0.15 speaks and fails with C<-32602 Missing protocol version>

=back

B<Safety:> Only creates a single ConfigMap with test data. Cleans up after
itself. No pods, deployments, or anything compute-related.

=cut

use strict;
use warnings;
use IO::Async::Loop;
use Future::AsyncAwait;
use Net::Async::MCP;
use Langertha::Engine::Anthropic;
use Langertha::Raider;
use MCP::K8s;
use Time::HiRes qw( gettimeofday tv_interval );

binmode STDOUT, ':encoding(UTF-8)';
binmode STDERR, ':encoding(UTF-8)';

# ── ANSI colors ─────────────────────────────────────────────────────
my $BOLD   = "\e[1m";
my $DIM    = "\e[2m";
my $GREEN  = "\e[32m";
my $CYAN   = "\e[36m";
my $YELLOW = "\e[33m";
my $BLUE   = "\e[34m";
my $WHITE  = "\e[37m";
my $RESET  = "\e[0m";

# Disable colors if not a terminal
unless (-t STDOUT) {
  $BOLD = $DIM = $GREEN = $CYAN = $YELLOW = $BLUE = $WHITE = $RESET = '';
}

# ── Helpers ──────────────────────────────────────────────────────────
sub banner {
  my ($text) = @_;
  my $line = '-' x 60;
  print "\n${BOLD}${CYAN}$line${RESET}\n";
  print "${BOLD}${WHITE}  $text${RESET}\n";
  print "${BOLD}${CYAN}$line${RESET}\n\n";
}

sub info  { printf "${DIM}%s${RESET}\n", join('', @_) }
sub ok    { printf "${GREEN}%s${RESET}\n", join('', @_) }
sub label { printf "  ${BOLD}%-20s${RESET} %s\n", $_[0], $_[1] }

sub fmt_ms {
  my ($ms) = @_;
  return sprintf("%.0fms", $ms)  if $ms < 1000;
  return sprintf("%.1fs", $ms / 1000);
}

# ── Pre-flight ───────────────────────────────────────────────────────
die "${BOLD}LANGERTHA_ANTHROPIC_API_KEY not set${RESET}\n"
  unless $ENV{LANGERTHA_ANTHROPIC_API_KEY};

banner("MCP::K8s + Langertha::Raider Demo");

print "${BOLD}Connecting to Kubernetes cluster...${RESET}\n";
my $k8s = MCP::K8s->new;
my $server = $k8s->server;
ok("Connected!");
label("Namespaces:", join(', ', @{ $k8s->namespaces }));
label("Tools:", scalar(@{ $server->tools }));
print "\n";

# ── Tool registry (for per-tool stats) ──────────────────────────────
my %tool_stats;    # name => { calls => N, total_ms => N }
my $total_calls = 0;

# Wrap each tool's code to print live progress with timing
for my $tool (@{ $server->tools }) {
  my $orig_code = $tool->code;
  my $name = $tool->name;
  $tool_stats{$name} = { calls => 0, total_ms => 0 };
  $tool->code(sub {
    my ($t, $args) = @_;
    $total_calls++;
    $tool_stats{$name}{calls}++;

    # Build detail string
    my @info;
    push @info, $args->{resource} if $args->{resource};
    push @info, $args->{name} if $args->{name};
    push @info, "ns=$args->{namespace}" if $args->{namespace};
    my $detail = @info ? ' ' . join(', ', @info) : '';

    printf "  ${YELLOW}[%d]${RESET} ${BOLD}%s${RESET}${DIM}%s${RESET} ",
      $total_calls, $name, $detail;

    my $t0 = [gettimeofday];
    my $result = $orig_code->($t, $args);
    my $elapsed = tv_interval($t0) * 1000;
    $tool_stats{$name}{total_ms} += $elapsed;

    printf "${DIM}(%s)${RESET}\n", fmt_ms($elapsed);
    return $result;
  });
}

# ── Wire up async MCP transport ─────────────────────────────────────
my $loop = IO::Async::Loop->new;
my $mcp = Net::Async::MCP->new(server => $server);
$loop->add($mcp);

# ── AI Engine ────────────────────────────────────────────────────────
my $model = $ENV{MCP_K8S_DEMO_MODEL} || 'claude-sonnet-5';
info("Model: $model");
print "\n";

my $engine = Langertha::Engine::Anthropic->new(
  model       => $model,
  mcp_servers => [$mcp],
);

# ── Raider ───────────────────────────────────────────────────────────
my $iteration_t0;

my $raider = Langertha::Raider->new(
  engine         => $engine,
  max_iterations => 15,
  on_iteration   => sub {
    my ($raider, $iteration) = @_;

    # Show timing for previous iteration
    if ($iteration_t0 && $iteration > 2) {
      my $prev_ms = tv_interval($iteration_t0) * 1000;
      info(sprintf("  iteration took %s", fmt_ms($prev_ms)));
    }

    $iteration_t0 = [gettimeofday];
    printf "\n${BLUE}--- Iteration %d ---%s\n", $iteration, $RESET;

    # Show token count if available
    if ($raider->has_last_prompt_tokens) {
      info(sprintf("  prompt tokens: %s", $raider->_last_prompt_tokens));
    }

    return;
  },
  mission => <<'MISSION',
You are demonstrating MCP::K8s capabilities. Follow these steps exactly:

1. First, call k8s_permissions to see what you can do.
2. Create a ConfigMap named "mcp-k8s-demo" with this data:
   - greeting: "Hello from MCP::K8s!"
   - version: "1.0"
   - created-by: "langertha-raider"
3. Read the ConfigMap back using k8s_get to verify it exists.
4. Update it using k8s_apply to add a new key: updated: "true"
5. Delete the ConfigMap to clean up.

After each step, briefly confirm what happened. Be concise.
If any step fails due to permissions, report it and skip to the next step.
MISSION
);

# ── Run the demo ─────────────────────────────────────────────────────
async sub main {
  await $mcp->initialize;

  banner("Raid: Full ConfigMap Lifecycle");

  my $raid_t0 = [gettimeofday];
  printf "${BLUE}--- Iteration 1 ---${RESET}\n";
  $iteration_t0 = [gettimeofday];

  my $response = await $raider->raid_f(
    'Please run through the full ConfigMap demo now.'
  );

  my $raid_elapsed = tv_interval($raid_t0) * 1000;

  # ── AI Response ──────────────────────────────────────────────────
  banner("AI Response");
  print $response, "\n";

  # ── Metrics Summary ──────────────────────────────────────────────
  banner("Session Metrics");

  my $m = $raider->metrics;

  label("Total time:", fmt_ms($raid_elapsed));
  label("Iterations:", $m->{iterations});
  label("Tool calls:", $m->{tool_calls});

  if ($raider->has_last_prompt_tokens) {
    label("Last prompt tokens:", $raider->_last_prompt_tokens);
  }

  # ── Per-tool breakdown ───────────────────────────────────────────
  my @used_tools = sort { $tool_stats{$b}{calls} <=> $tool_stats{$a}{calls} }
                   grep { $tool_stats{$_}{calls} > 0 } keys %tool_stats;

  if (@used_tools) {
    print "\n${BOLD}  Tool Breakdown:${RESET}\n";
    printf "  ${DIM}%-25s %6s %10s${RESET}\n", 'Tool', 'Calls', 'Time';
    printf "  ${DIM}%-25s %6s %10s${RESET}\n", '-' x 25, '-' x 6, '-' x 10;
    for my $name (@used_tools) {
      my $s = $tool_stats{$name};
      printf "  %-25s %6d %10s\n", $name, $s->{calls}, fmt_ms($s->{total_ms});
    }
    my $total_tool_ms = 0;
    $total_tool_ms += $_->{total_ms} for values %tool_stats;
    printf "  ${DIM}%-25s %6s %10s${RESET}\n", '-' x 25, '-' x 6, '-' x 10;
    printf "  ${BOLD}%-25s %6d %10s${RESET}\n",
      'TOTAL', $total_calls, fmt_ms($total_tool_ms);

    # LLM thinking time = total - tool time
    my $llm_ms = $raid_elapsed - $total_tool_ms;
    printf "\n  ${DIM}LLM thinking: %s  |  K8s API: %s${RESET}\n",
      fmt_ms($llm_ms), fmt_ms($total_tool_ms);
  }

  # ── Session history stats ────────────────────────────────────────
  my @hist = @{ $raider->session_history };
  if (@hist) {
    my %roles;
    $roles{$_->{role} // 'unknown'}++ for @hist;
    print "\n${BOLD}  Conversation:${RESET}\n";
    label("Messages:", scalar @hist);
    for my $role (sort keys %roles) {
      label("  $role:", $roles{$role});
    }
  }

  print "\n";
  ok("Demo complete!");
}

main()->get;
