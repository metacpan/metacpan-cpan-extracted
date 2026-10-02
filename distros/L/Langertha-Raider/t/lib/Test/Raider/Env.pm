package Test::Raider::Env;
# ABSTRACT: Keep tests off real engines and the real home directory

use strict;
use warnings;
use Exporter 'import';
use File::Temp qw( tempdir );

our @EXPORT_OK = qw( clear_engine_env isolate_home );

# Envs the installed Langertha engines read for a base URL or token but
# that don't end in _API_KEY, so the regex below doesn't catch them
# (checked against Langertha::Engine::* in the installed Langertha; see
# karr #52).
my @EXTRA_ENGINE_ENV = qw( HF_TOKEN REPLICATE_API_TOKEN OLLAMA_URL WHISPER_URL );

=func clear_engine_env

    use Test::Raider::Env qw( clear_engine_env );
    clear_engine_env();

Deletes every C<%ENV> entry that could let a raider subprocess reach a
real, paid engine: every variable whose name ends in C<_API_KEY>
(C<ANTHROPIC_API_KEY>, C<OPENAI_API_KEY>, C<MINIMAX_API_KEY>, the
C<LANGERTHA_*_API_KEY> alternates, and any engine added to
L<Langertha::Raider::CLI/env_var_for_engine> or autodetection later, since
the whole family follows that naming convention) plus the token/base-URL
envs that don't fit that pattern (C<HF_TOKEN>, C<REPLICATE_API_TOKEN>,
C<OLLAMA_URL>, C<WHISPER_URL>).

Call this once, before a test spawns C<bin/raider> or drives
L<Langertha::Raider::Hall>'s C<spawn> against the real binary, so a key
that merely happens to be set in the test runner's own environment (a
developer's shell, a CI secret meant for a different job) can never reach
the child process. Live tests opt in to real engines explicitly instead
(C<TEST_LIVE=1> plus a C<TEST_LANGERTHA_*_API_KEY>) and must not call this.

=cut

sub clear_engine_env {
  delete @ENV{ grep { /_API_KEY$/ } keys %ENV };
  delete @ENV{ @EXTRA_ENGINE_ENV };
  return;
}

=func isolate_home

    use Test::Raider::Env qw( isolate_home );
    my $home = isolate_home();

Points C<$ENV{HOME}> at a fresh temporary directory (removed at exit) and
returns it, so nothing the test builds reads the developer's real
F<~/.raider/> (packs in F<~/.raider/packs/>, see
L<Langertha::Raider::Packs/build_packs>). Call it once at the top of any
test that loads packs.

=cut

sub isolate_home {
  $ENV{HOME} = tempdir(CLEANUP => 1);
  return $ENV{HOME};
}

1;
