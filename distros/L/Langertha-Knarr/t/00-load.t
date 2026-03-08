use strict;
use warnings;
use Test::More;

my @modules = qw(
  Langertha::Knarr
  Langertha::Knarr::Config
  Langertha::Knarr::Router
  Langertha::Knarr::Tracing
  Langertha::Knarr::Proxy::OpenAI
  Langertha::Knarr::Proxy::Anthropic
  Langertha::Knarr::Proxy::Ollama
  Langertha::Knarr::CLI
  Langertha::Knarr::CLI::Cmd::Start
  Langertha::Knarr::CLI::Cmd::Models
  Langertha::Knarr::CLI::Cmd::Check
  Langertha::Knarr::CLI::Cmd::Init
  Langertha::Knarr::CLI::Cmd::Container
);

for my $mod (@modules) {
  require_ok($mod);
}

done_testing;
