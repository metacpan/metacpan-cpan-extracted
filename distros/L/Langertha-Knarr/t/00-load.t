use strict;
use warnings;
use Test::More;

my @modules = qw(
  Langertha::Knarr
  Langertha::Knarr::Config
  Langertha::Knarr::Router
  Langertha::Knarr::Tracing
  Langertha::Knarr::RequestLog
  Langertha::Knarr::Request
  Langertha::Knarr::Session
  Langertha::Knarr::Stream
  Langertha::Knarr::Handler
  Langertha::Knarr::Handler::Code
  Langertha::Knarr::Handler::Engine
  Langertha::Knarr::Handler::Raider
  Langertha::Knarr::Handler::Router
  Langertha::Knarr::Handler::A2AClient
  Langertha::Knarr::Handler::ACPClient
  Langertha::Knarr::Handler::Passthrough
  Langertha::Knarr::Handler::Tracing
  Langertha::Knarr::Handler::RequestLog
  Langertha::Knarr::Protocol
  Langertha::Knarr::Protocol::OpenAI
  Langertha::Knarr::Protocol::Anthropic
  Langertha::Knarr::Protocol::Ollama
  Langertha::Knarr::Protocol::A2A
  Langertha::Knarr::Protocol::ACP
  Langertha::Knarr::Protocol::AGUI
  Langertha::Knarr::PSGI
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
