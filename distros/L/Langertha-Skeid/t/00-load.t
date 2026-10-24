use strict;
use warnings;
use Test::More;

my @modules = qw(
  Langertha::Skeid
  Langertha::Skeid::Proxy
  Langertha::Skeid::Proxy::Realtime
  Langertha::Skeid::Proxy::RelayContent
  Langertha::Skeid::Protocol
  Langertha::Skeid::Protocol::Anthropic
  Langertha::Skeid::Protocol::Audio
  Langertha::Skeid::Protocol::Documents
  Langertha::Skeid::Protocol::MCP
  Langertha::Skeid::Protocol::Ollama
  Langertha::Skeid::Protocol::RawBody
  Langertha::Skeid::Protocol::Realtime
  Langertha::Skeid::Protocol::Rerank
  Langertha::Skeid::UsageStore
  Langertha::Skeid::UsageStore::JsonLog
  Langertha::Skeid::UsageStore::DBI
  Langertha::Skeid::KeyBroker
  Langertha::Skeid::CapacityProbe
  Langertha::Skeid::CapacityProbe::Prometheus
  Langertha::Skeid::CapacityProbe::Custom
  Langertha::Skeid::CapacityProbe::Registry
  Langertha::Skeid::Registry
  Langertha::Skeid::CustomerSource
  Langertha::Skeid::CustomerSource::DBI
  Langertha::Skeid::Secret
);

for my $mod (@modules) {
  require_ok($mod);
}

done_testing;
