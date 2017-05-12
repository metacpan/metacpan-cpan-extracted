#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use IO::Pty::Easy;

my $pty = IO::Pty::Easy->new;
my $script = << 'EOF';
$| = 1;
if (-t *STDIN && -t *STDOUT) { print "ok" }
else { print "failed" }
EOF

my $outside_of_pty = `$^X -e '$script'`;
unlike($outside_of_pty, qr/ok/, "running outside of pty fails -t checks");

# we need to keep the script alive until we can read the output from it
$script .= "sleep 1 while 1;";
$pty->spawn("$^X -e '$script'");
like($pty->read, qr/ok/, "runs subprocess in a pty");
$pty->close;

done_testing;
