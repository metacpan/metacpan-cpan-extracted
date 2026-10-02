#!/usr/bin/env bash
# Build a standalone `knarr` binary with PAR::Packer (pp).
# Run from the checkout root. Requires perl with knarr's runtime deps
# (cpanfile) and PAR::Packer on PATH/PERL5LIB. Output: $KNARR_BIN_OUT
# (default ./knarr). Same pattern as karr's single binary
# (https://github.com/Getty/karr, scripts/build-binary.sh).
set -euo pipefail

OUT="${KNARR_BIN_OUT:-./knarr}"

# Langertha core reads its OpenAPI specs (openai.yaml, ollama.yaml, ...) with
# File::ShareDir::ProjectDistDir's dist_file('Langertha', ...). pp packs no
# share tree on its own; the -a below puts it where an installed dist's share
# lands, auto/share/dist/Langertha below an @INC dir -- $PAR_TEMP/inc/lib at
# runtime -- so dist_file finds it inside the binary. knarr's own share/
# (example-config.yaml) is not packed: nothing reads it at runtime. If code
# ever calls dist_dir('Langertha-Knarr'), add
# -a "share;lib/auto/share/dist/Langertha-Knarr" and a check to verify-binary.sh.
LANGERTHA_SHARE=$(perl -MFile::ShareDir=dist_dir -e 'print dist_dir("Langertha")')

# The loaded set. pp's scanner reads source; knarr and Langertha load most
# of what they run by name: MooX::Cmd resolves Langertha::Knarr::CLI::Cmd::*
# from @ARGV, Knarr.pm use_module's Langertha::Knarr::Protocol::<name>,
# Langertha->resolve_engine_class finds Langertha::Engine::<name> from config
# (Module::Pluggable + require_module), engines use_module their
# Langertha::Spec::*, PluginHost its plugins; below that, MooseX::NonMoose
# names its metaroles as strings, MooX::TypeTiny its accessor role, and
# Future::AsyncAwait's .so loads XS::Parse::Keyword/Sublike from BOOT. Each
# of these was a startup or first-request death in a scanner-only build. So
# load every Langertha::* module for real, run the lazy loads the request path
# triggers, and hand everything that ended up in %INC to pp as -M. A module
# that does not load here (an optional dep that is not installed, e.g. Plack
# for Langertha::Knarr::PSGI) is reported and left out, like it would be
# missing on an install. LangerthaX::* is not collected: a binary carries only
# what this build knows about.
mapfile -t loaded < <(perl -Ilib - <<'PERL'
use strict;
use warnings;
use File::Find ();

my %mods = ( Langertha => 1 );
for my $dir ( grep { !ref } @INC ) {
  next unless -d "$dir/Langertha";
  File::Find::find( { no_chdir => 1, wanted => sub {
    return unless /\.pm\z/;
    ( my $m = substr $_, length($dir) + 1 ) =~ s{/}{::}g;
    $m =~ s/\.pm\z//;
    $mods{$m} = 1;
  } }, "$dir/Langertha" );
}
for my $m ( sort keys %mods ) {
  # Deprecation notices from the compat facades are noise here.
  next if eval { local $SIG{__WARN__} = sub {}; eval "require $m; 1" or die $@ };
  warn 'build-binary: not bundled, does not load: '.$m.' ('.( split /\n/, $@ )[0].")\n";
}

# Loads that happen only when the objects are used. -M on a module that is
# not installed aborts pp, which is why optional ones go through eval here.
require YAML::PP;             YAML::PP->new->load_string("a: 1\n");
require YAML::PP;             YAML::PP->new( boolean => 'JSON::PP' )->load_string("a: true\n");
require JSON::MaybeXS;        JSON::MaybeXS->new->encode( {} );
require Log::Any::Adapter;    Log::Any::Adapter->set('Stderr');
require IO::Async::Loop;      IO::Async::Loop->new;
require IO::Async::SSL;
require IO::Socket::SSL;      IO::Socket::SSL::default_ca();
require Net::Async::HTTP;
require LWP::UserAgent;
eval { require LWP::Protocol; LWP::Protocol::implementor($_) for qw( http https ); 1 };
eval { require Mozilla::CA; 1 };
eval { require OpenAPI::Modern; 1 };
require Langertha::Engine::OpenAI;
my $engine = Langertha::Engine::OpenAI->new( api_key => 'build', url => 'http://127.0.0.1:1/v1' );
eval { $engine->openapi; 1 } or warn 'build-binary: openapi slow path: '.( split /\n/, $@ )[0]."\n";

# Only modules loaded from their own file: Moose and Moo also record the
# classes they generate in %INC (Class/MOP/Class/Immutable/...,
# Method/Generate/Accessor__WITH__...), which -M cannot find.
for my $file ( sort keys %INC ) {
  next unless $file =~ m{\A[\w/]+\.pm\z};
  next unless defined $INC{$file} && !ref $INC{$file} && $INC{$file} =~ m{/\Q$file\E\z};
  ( my $m = $file ) =~ s{/}{::}g;
  $m =~ s/\.pm\z//;
  print $m, "\n";
}
PERL
)
[ "${#loaded[@]}" -gt 100 ] || { echo "ERROR: loaded set suspiciously small (${#loaded[@]})" >&2; exit 1; }
mods=()
for m in "${loaded[@]}"; do mods+=("-M" "$m"); done

# PAR_VERBATIM=1: skip pp's PAR::Filter::PodStrip, which mangles POD
# interleaved with code (Pod::Weaver =attr/=method blocks) so that a module
# swallows its own trailing `1;` and dies "did not return a true value".
#
# -I lib: the checkout's lib/ goes first on @INC for the scan, so bin/knarr's
# `use Langertha::Knarr::CLI` and the loaded set above pick up the checkout's
# modules even where knarr itself is not installed (a fresh CI container), and
# ahead of an older installed Langertha::Knarr where it is.
#
# The globs on top of the loaded set cover what is loaded by name only on
# some paths: YAML::PP's schema classes (Module::Load; missed, every command
# that reads knarr.yaml dies "Can't locate YAML/PP/Schema/Core.pm"),
# Log::Any adapters, IO::Async's internals (the loop loads
# IO::Async::Internals::TimeQueue on the first timer; missed, `knarr start`
# dies right after binding), JSON::Schema::Modern's vocabularies, and the
# MooX::Cmd / MooX::Options roles.
PAR_VERBATIM=1 pp -o "$OUT" \
  -I lib \
  "${mods[@]}" \
  -M 'Langertha::**' \
  -M 'MooX::Cmd::**' -M 'MooX::Options::**' \
  -M 'YAML::PP::**' \
  -M 'Log::Any::Adapter::**' \
  -M 'IO::Async::**' -M 'Net::Async::HTTP::**' \
  -M 'JSON::Schema::Modern::**' -M 'OpenAPI::Modern::**' \
  -a "$LANGERTHA_SHARE;lib/auto/share/dist/Langertha" \
  bin/knarr

chmod +x "$OUT"
echo "Built $OUT ($(du -h "$OUT" | cut -f1)), ${#loaded[@]} modules in the loaded set"
