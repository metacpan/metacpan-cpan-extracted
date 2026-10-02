#!/usr/bin/env perl
# ABSTRACT: The former App::Raider packages load as empty reserved stubs

use strict;
use warnings;
use Test2::Bundle::More;

for my $module (qw(
  App::Raider
  App::Raider::FileTools
  App::Raider::Plugin::Situation
  App::Raider::Plugin::Trace
  App::Raider::Skill
  App::Raider::WebTools
)) {
  ok(eval "require $module; 1", 'load '.$module) or diag $@;
  ok(!$module->can('new') && !$module->can('run'), $module.' is a stub without behavior');
}

done_testing;
