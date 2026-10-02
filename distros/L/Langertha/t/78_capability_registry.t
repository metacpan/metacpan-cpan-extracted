#!/usr/bin/env perl
# ABSTRACT: Guard %ROLE_TO_CAPS against role drift — every role is classified

use strict;
use warnings;

use Test2::Bundle::More;
use Path::Tiny qw( path );

use Langertha::Role::Capabilities ();

# Every Langertha::Role::* must be on exactly one of the two axes of
# ADR 0016 decision 2 (see CONTEXT.md, "Engine composition axes"):
#
#   capability axis -> an entry in %ROLE_TO_CAPS, so engine_capabilities
#                      can advertise it from does($role) (ADR 0002)
#   everything else -> listed below, with the reason it is NOT a capability
#
# A role in neither list is drift: it was added without deciding its axis.
# That is exactly how Role::KeepAlive stayed invisible to supports() while
# Ollama happily put keep_alive on the wire (karr #90).
#
# Adding a role means adding it to one of the two — this list is the
# documented boundary, not a convenience.
my %NOT_A_CAPABILITY = (
  'Langertha::Role::Capabilities'        => 'the registry itself',
  'Langertha::Role::OpenAICompatible'    => 'wire envelope (dialect axis, ADR 0013/0016)',
  'Langertha::Role::AnthropicCompatible' => 'wire envelope (dialect axis, ADR 0013/0016)',
  'Langertha::Role::ResponsesCompatible' => 'wire envelope (dialect axis, ADR 0013/0016)',
  'Langertha::Role::HTTP'                => 'transport, not a provider feature',
  'Langertha::Role::AsyncHTTP'           => 'async HTTP transport backend selection (injected / Net::Async::HTTP / sync LWP fallback), not a provider feature',
  'Langertha::Role::JSON'                => 'serializer infrastructure',
  'Langertha::Role::OpenAPI'             => 'request generation / spec validation infrastructure',
  'Langertha::Role::Models'              => 'model discovery, composed by every engine base — a constant-true flag carries no information',
  'Langertha::Role::StaticModels'        => 'implementation swap for list_models, same feature surface as Role::Models',
  'Langertha::Role::ThinkTag'            => 'client-side response post-processing (composed by Role::Chat), never a wire field',
  'Langertha::Role::PluginHost'          => 'host-side plugin pipeline, also composed by non-engines (Chat, Embedder, ImageGen)',
  'Langertha::Role::Langfuse'            => 'engine-level observability composed by Role::Chat — constant-true for chat engines, so it carries no capability information',
  'Langertha::Role::Runnable'            => 'generic run_f execution contract, a dependency-free core primitive — not a provider capability',
);

# Read the registry out of the module source: %ROLE_TO_CAPS is lexical by
# design (ADR 0002 — one file owns the map), so the guard parses it rather
# than widening the public surface just to be testable.
my $cap_file = $INC{'Langertha/Role/Capabilities.pm'}
  or die "Langertha::Role::Capabilities not in %INC";
my $source = path($cap_file)->slurp_utf8;

my ($block) = $source =~ /^my \s* %ROLE_TO_CAPS \s* = \s* \( (.*?) ^\); /msx;
ok( defined $block, 'found the %ROLE_TO_CAPS block in Capabilities.pm' )
  or BAIL_OUT('cannot parse the capability registry — the guard is blind');

my %registry;
while ( $block =~ /^\s*'(Langertha::Role::[\w:]+)'\s*=>\s*\[qw\(\s*(.*?)\s*\)\]/msg ) {
  my ( $role, $flags ) = ( $1, $2 );
  $registry{$role} = [ split ' ', $flags ];
}

# Sanity floor: if the map's formatting ever changes shape, fail loudly here
# instead of silently passing every role below.
cmp_ok( scalar keys %registry, '>=', 19, 'parsed a plausible number of registry entries' );

my $role_dir = path($cap_file)->parent;
my @role_files;
$role_dir->visit(
  sub {
    my ($p) = @_;
    push @role_files, $p if -f $p && $p->basename =~ /\.pm\z/;
  },
  { recurse => 1 },
);

ok( scalar @role_files >= 30, 'found the Langertha::Role::* files on disk' );

for my $file ( sort @role_files ) {
  my $rel = $file->relative($role_dir)->stringify;
  $rel =~ s/\.pm\z//;
  my $role = 'Langertha::Role::' . join '::', split m{/}, $rel;

  my $in_registry  = exists $registry{$role};
  my $in_allowlist = exists $NOT_A_CAPABILITY{$role};

  ok( $in_registry || $in_allowlist,
    "$role is classified (capability registry or non-capability allowlist)" )
    or diag(
        "$role is on neither axis. Decide per ADR 0016 decision 2:\n"
      . "  capability (own attributes / lifecycle methods, separable from the dialect)\n"
      . "    -> add it to %ROLE_TO_CAPS in lib/Langertha/Role/Capabilities.pm\n"
      . "  not a capability (envelope, transport, infrastructure)\n"
      . "    -> add it to %NOT_A_CAPABILITY in this test, with the reason" );

  ok( !( $in_registry && $in_allowlist ),
    "$role is not classified both ways" );
}

# The allowlist must not rot: every entry names a role that still exists.
for my $role ( sort keys %NOT_A_CAPABILITY ) {
  my $rel = $role;
  $rel =~ s/\ALangertha::Role:://;
  $rel = join( '/', split /::/, $rel ) . '.pm';
  ok( $role_dir->child($rel)->is_file, "allowlisted $role still exists" );
}

# And the registry must not rot either: every key names a role that exists.
for my $role ( sort keys %registry ) {
  my $rel = $role;
  $rel =~ s/\ALangertha::Role:://;
  $rel = join( '/', split /::/, $rel ) . '.pm';
  ok( $role_dir->child($rel)->is_file, "registered $role exists as a role file" );
}

done_testing;
