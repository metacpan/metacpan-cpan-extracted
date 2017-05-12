#!/usr/bin/env perl

use strict;
use warnings;

use Test::Most;

use Dist::Zilla::PluginBundle::ROKR;
use Dist::Zilla::PluginBundle::ROKR::Basic;
use Dist::Zilla::Plugin::CopyReadmeFromBuild;
use Dist::Zilla::Plugin::CopyMakefilePLFromBuild;
use Dist::Zilla::Plugin::DynamicManifest;
use Dist::Zilla::Plugin::SurgicalPkgVersion;
use Dist::Zilla::Plugin::SurgicalPodWeaver;
use Dist::Zilla::Plugin::UpdateGitHub;

ok( 1 );

done_testing;
