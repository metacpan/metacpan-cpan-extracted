#!/usr/bin/env perl

use 5.006;
use strict;
use warnings;

use lib qw(.. .. lib);

use Scalar::Util qw(blessed);
use Git::Background;

my $git = Git::Background->new;

if ( !eval { $git->run('--invalid-arg')->get; 1; } ) {
    my $e = $@;
    die $e if !blessed $e || !$e->isa('Git::Background::Exception');

    my $exit_code = $e->exit_code;
    my $stderr    = join "\n", $e->stderr;
    warn "Git exited with exit code $exit_code\n$stderr\n";
}

# vim: ts=4 sts=4 sw=4 et: syntax=perl
