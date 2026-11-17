#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

for (qw(
  Langertha::Holmgang
  Langertha::Holmgang::Report
  Langertha::Holmgang::Evaluation
  Langertha::Holmgang::Haystack
  Langertha::Holmgang::Random
  Langertha::Holmgang::Error
  Langertha::Holmgang::Expectation
  Langertha::Holmgang::Template
  Langertha::Holmgang::ToolSchema
  Langertha::Holmgang::World
  Langertha::Holmgang::Case
  Langertha::Holmgang::Suite
  Langertha::Holmgang::Structure
  Langertha::Holmgang::Grader
  Langertha::Holmgang::Lint
  Langertha::Holmgang::Loader
  Langertha::Holmgang::Target
  Langertha::Holmgang::Runner
  Langertha::Holmgang::CLI
  Langertha::Holmgang::Role::Simulator
  Langertha::Holmgang::Role::AnswerWorld
  Langertha::Holmgang::Simulators
  Langertha::Holmgang::Shell
  Langertha::Holmgang::Shell::Filter
  Langertha::Holmgang::Sim::Linux
  Langertha::Holmgang::Sim::Linux::Nft
  Langertha::Holmgang::Sim::Linux::Calendar
  Langertha::Holmgang::Sim::Linux::Monitoring
  Langertha::Holmgang::Sim::Linux::Sshd
  Langertha::Holmgang::Sim::Linux::Logrotate
  Langertha::Holmgang::Sim::Linux::Accounts
  Langertha::Holmgang::Sim::RouterOS
  Langertha::Holmgang::Sim::IOS
  Langertha::Holmgang::Sim::Linux::Kubernetes
  Langertha::Holmgang::Sim::Linux::Backup
  Langertha::Holmgang::Sim::Linux::Storage
  Langertha::Holmgang::Sim::Linux::Dns
  Langertha::Holmgang::Sim::Linux::Postfix
  Langertha::Holmgang::Sim::Linux::Postgres
  Langertha::Holmgang::Sim::Linux::MariaDB
  Langertha::Holmgang::Sim::Linux::Redis
  Langertha::Holmgang::Sim::Linux::RedisService
  Langertha::Holmgang::Sim::Linux::Http
  Langertha::Holmgang::Sim::Linux::Nginx
  Langertha::Holmgang::Sim::Linux::Pki
  Langertha::Holmgang::Sim::Linux::SshAccess
  Langertha::Holmgang::Sim::Linux::Docker
  Langertha::Holmgang::Sim::Linux::Git
  Langertha::Holmgang::Sim::Linux::Helm
  Langertha::Holmgang::Sim::Kueche
)) {
  use_ok($_);
}

done_testing;
