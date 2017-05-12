#!perl

requires 'perl', '5.8.5';

requires 'Carp';
requires 'Config::General';
requires 'Data::Dumper';
requires 'Exporter';
requires 'File::Slurp';
requires 'File::stat';
requires 'Geo::IP';
requires 'Getopt::Long';
requires 'HTTP::BrowserDetect';
requires 'IO::File';
requires 'IO::Handle';
requires 'IO::Select';
requires 'IO::Socket::INET';
requires 'JSON';
requires 'Log::Log4perl';
requires 'Log::Log4perl::Appender::ScreenColoredLevels';
requires 'Moose';
requires 'Moose::Role';
requires 'Pod::Usage';
requires 'Search::Elasticsearch';
requires 'Sys::Hostname';
requires 'Template';
requires 'Template::Stash';
requires 'Tie::IxHash';
requires 'Time::HiRes';
requires 'Time::Piece';
requires 'Time::Seconds';
requires 'URI';
requires 'UUID';
requires 'base';
requires 'locale';
requires 'strict';
requires 'vars';
requires 'warnings';
requires 'Redis';
requires 'Net::Lumberjack';

on 'test' => sub {
  requires 'Test::More';
  requires 'Test::Pod';
  requires 'File::Find';
};

on 'develop' => sub {
  requires 'Dist::Zilla::Plugin::Prereqs::FromCPANfile';
  requires 'Dist::Zilla::Plugin::MetaProvides::Package';
  requires 'Dist::Zilla::Plugin::AutoPrereqs';
  requires 'Dist::Zilla::Plugin::ChangelogFromGit';
  requires 'Dist::Zilla::Plugin::Git::NextVersion';
  requires 'Dist::Zilla::Plugin::OurPkgVersion';
  requires 'Dist::Zilla::Plugin::PodSyntaxTests';
  requires 'Dist::Zilla::Plugin::PodWeaver';
  requires 'Dist::Zilla::Plugin::Prereqs';
  requires 'Dist::Zilla::Plugin::Test::Perl::Critic';
  requires 'Dist::Zilla::Plugin::TravisYML';
  requires 'Dist::Zilla::PluginBundle::Basic';
  requires 'Dist::Zilla::PluginBundle::Git';
  requires 'Software::License::GPL_2';
};

