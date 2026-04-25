#!/usr/bin/env perl
use strict;
use warnings;

use Getopt::Long qw( GetOptions );
use Text::ParseWords qw( shellwords );

my %opt = (
  repo   => 'Getty/p5-mcp-run',
  image  => 'raudssus/mcp-run-compress',
  target => 'runtime',
);

GetOptions(
  'archive=s' => \$opt{archive},
  'dir=s'     => \$opt{dir},
  'version=s' => \$opt{version},
  'repo=s'    => \$opt{repo},
  'image=s'   => \$opt{image},
  'target=s'  => \$opt{target},
) or die "Usage: $0 --archive FILE --dir DIR --version VERSION [--repo ORG/REPO] [--image NAME]\n";

for my $required (qw( archive dir version )) {
  die "--$required is required\n" unless defined $opt{$required} && length $opt{$required};
}

my $gh     = $ENV{GH_BIN}     || 'gh';
my $docker = $ENV{DOCKER_BIN} || 'docker';

sub run_cmd {
  my (@cmd) = @_;
  system @cmd;
  die "command failed: @cmd\n" if $?;
  return;
}

my @view = ($gh, 'release', 'view', $opt{version}, '-R', $opt{repo});
system @view;
if ($?) {
  run_cmd(
    $gh, 'release', 'create', $opt{version},
    '-R', $opt{repo},
    '--title', $opt{version},
    '--notes', 'Dist::Zilla release'
  );
}

run_cmd(
  $gh, 'release', 'upload', $opt{version},
  '-R', $opt{repo},
  $opt{archive},
  '--clobber'
);

my @extra = shellwords($ENV{MCP_RUN_DOCKER_BUILD_ARGS} // '');

run_cmd(
  $docker, 'build',
  @extra,
  '--build-arg', 'MCP_RUN_VERSION=' . $opt{version},
  '--target', $opt{target},
  '-t', $opt{image} . ':' . $opt{version},
  '-t', $opt{image} . ':latest',
  $opt{dir}
);

run_cmd($docker, 'push', $opt{image} . ':' . $opt{version});
run_cmd($docker, 'push', $opt{image} . ':latest');
