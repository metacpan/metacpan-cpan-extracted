#!/usr/bin/env perl
# ABSTRACT: Basic load test

use strict;
use warnings;
use Test2::Bundle::More;

ok(eval { require Langertha::Raider::CLI; 1 },            'load Langertha::Raider::CLI')            or diag $@;
ok(eval { require Langertha::Raider::FileTools; 1 }, 'load Langertha::Raider::FileTools') or diag $@;

for my $module (qw(
  Langertha::Raider::Hall::ACP::SubStream
  Langertha::Raider::Hall::Cron
  Langertha::Raider::Hall::MCP
  Langertha::Raider::Hall::Protocol
  Langertha::Raider::Hall::Raider
  Langertha::Raider::Hall::Telegram
  Langertha::Raider::Packs::Collection
  Langertha::Raider::Packs::Pack
  Langertha::Raider::Session
  Langertha::Raider::Session::Journal
  Langertha::Raider::SessionStore
)) {
  ok(eval "require $module; 1", 'load '.$module) or diag $@;
}

# Loading a parent module alone has to pull in the classes it instantiates;
# checked in a fresh interpreter so nothing loaded above can mask a gap.
for my $case (
  [ 'Langertha::Raider::Hall', qw(
    Langertha::Raider::Hall::ACP Langertha::Raider::Hall::ACP::SubStream
    Langertha::Raider::Hall::Cron Langertha::Raider::Hall::MCP
    Langertha::Raider::Hall::Protocol Langertha::Raider::Hall::Raider
    Langertha::Raider::Hall::Telegram
  ) ],
  [ 'Langertha::Raider::Packs', qw(
    Langertha::Raider::Packs::Collection Langertha::Raider::Packs::Pack
  ) ],
) {
  my ( $parent, @classes ) = @$case;
  my $code = 'use '.$parent.'; print join(",", grep { !$_->can("new") } qw( '.join(' ', @classes).' ))';
  my $missing = `$^X @{[ map { "-I$_" } grep { !ref } @INC ]} -e '$code' 2>&1`;
  is($missing, '', $parent.' makes its part classes available');
}

can_ok('Langertha::Raider::CLI', qw( new run raid_f raider ));

my $server = Langertha::Raider::FileTools::build_file_tools_server();
isa_ok($server, 'MCP::Server');

done_testing;
