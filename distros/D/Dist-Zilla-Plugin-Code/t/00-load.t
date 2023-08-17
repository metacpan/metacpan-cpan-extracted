#!perl

# vim: ts=4 sts=4 sw=4 et: syntax=perl
#
# Copyright (c) 2020-2023 Sven Kirmess
#
# Permission to use, copy, modify, and distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

use 5.006;
use strict;
use warnings;

# Automatically generated file; DO NOT EDIT.

use Test::More 0.88;

use lib qw(lib);

my @modules = qw(
  Dist::Zilla::Plugin::Code
  Dist::Zilla::Plugin::Code::AfterBuild
  Dist::Zilla::Plugin::Code::AfterRelease
  Dist::Zilla::Plugin::Code::BeforeArchive
  Dist::Zilla::Plugin::Code::BeforeBuild
  Dist::Zilla::Plugin::Code::BeforeRelease
  Dist::Zilla::Plugin::Code::BuildRunner
  Dist::Zilla::Plugin::Code::EncodingProvider
  Dist::Zilla::Plugin::Code::FileFinder
  Dist::Zilla::Plugin::Code::FileGatherer
  Dist::Zilla::Plugin::Code::FileMunger
  Dist::Zilla::Plugin::Code::FilePruner
  Dist::Zilla::Plugin::Code::Initialization
  Dist::Zilla::Plugin::Code::InstallTool
  Dist::Zilla::Plugin::Code::LicenseProvider
  Dist::Zilla::Plugin::Code::MetaProvider
  Dist::Zilla::Plugin::Code::NameProvider
  Dist::Zilla::Plugin::Code::PrereqSource
  Dist::Zilla::Plugin::Code::ReleaseStatusProvider
  Dist::Zilla::Plugin::Code::Releaser
  Dist::Zilla::Plugin::Code::TestRunner
  Dist::Zilla::Plugin::Code::VersionProvider
  Dist::Zilla::PluginBundle::Code
);

plan tests => scalar @modules;

for my $module (@modules) {
    require_ok($module) or BAIL_OUT();
}
