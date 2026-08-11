#!/usr/bin/perl
use strict;
use warnings;
use File::Spec;

my $target = shift @ARGV;
die "No target specified" unless $target;

print "Generating proxy: $target\n";

open my $fh, '>', $target or die "Cannot open $target for writing: $!";

if ($target =~ /\.ps1$/) {

  # PowerShell Proxy
  print $fh <<'EOF';
# Proxy to the Perl implementation
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
& perl "$scriptDir\gcloud-auth.pl" @Args
EOF
} else {
  # Shell Proxy
  print $fh <<'EOF';
#!/bin/sh
# Proxy to the Perl implementation
exec perl "$0.pl" "$@"
EOF
}

close $fh;
chmod 0755, $target;
print "Proxy generated successfully.\n";
