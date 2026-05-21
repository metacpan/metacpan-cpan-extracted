#!/usr/bin/env perl
#ABSTRACT: Release script for MCP-Wiki - builds Docker image after CPAN release

use strict;
use warnings;
use Path::Tiny;

my $archive = $ARGV[0] or die "Usage: $0 <archive>";
my $dir = $ARGV[1] or die "Usage: $0 <archive> <dir>";
my $version = $ARGV[2] or die "Usage: $0 <archive> <dir> <version>";

print "Building Docker image for MCP-Wiki $version\n";

my $docker_build_args = $ENV{MCP_WIKI_DOCKER_BUILD_ARGS} // '';
my @cmd = ('docker', 'build');

if ($docker_build_args) {
    push @cmd, split(/\s+/, $docker_build_args);
}

push @cmd, (
    '--build-arg', "MCP_WIKI_VERSION=$version",
    '-t', "raudssus/mcp-wiki:$version",
    '-t', 'raudssus/mcp-wiki:latest',
    $dir,
);

print "Running: @cmd\n";
system(@cmd) == 0 or die "docker build failed";

print "Pushing to Docker Hub...\n";
system('docker', 'push', "raudssus/mcp-wiki:$version") == 0 or die "push failed";
system('docker', 'push', 'raudssus/mcp-wiki:latest') == 0 or die "push latest failed";

print "Done!\n";