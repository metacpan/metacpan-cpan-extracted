#!perl

requires 'perl', '5.8.5';

requires 'strict';
requires 'vars';
requires 'warnings';
requires 'Mail::SpamAssassin::Logger';
requires 'Mail::SpamAssassin::PersistentAddrList';
requires 'Mail::SpamAssassin::Plugin';
requires 'Mail::SpamAssassin::Util';
requires 'Redis';

on 'test' => sub {
  requires 'Test::More';
  requires 'Test::Exception';
  requires 'Test::Pod';
  requires 'File::Find';
  requires 'Test::RedisDB';
};

on 'develop' => sub {
  requires 'ExtUtils::MakeMaker';
  requires 'Dist::Zilla::Plugin::Prereqs::FromCPANfile';
  requires 'Dist::Zilla::Plugin::ChangelogFromGit';
  requires 'Dist::Zilla::Plugin::Git::NextVersion';
  requires 'Dist::Zilla::Plugin::MetaJSON';
  requires 'Dist::Zilla::Plugin::MetaResources';
  requires 'Dist::Zilla::Plugin::OurPkgVersion';
  requires 'Dist::Zilla::Plugin::PodSyntaxTests';
  requires 'Dist::Zilla::Plugin::PodWeaver';
  requires 'Dist::Zilla::Plugin::Prereqs';
  requires 'Dist::Zilla::Plugin::PruneFiles';
  requires 'Dist::Zilla::Plugin::Test::Perl::Critic';
  requires 'Dist::Zilla::PluginBundle::Basic';
  requires 'Dist::Zilla::PluginBundle::Git';
  requires 'Software::License::Apache_2_0';
};

