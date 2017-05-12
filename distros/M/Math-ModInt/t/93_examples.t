# Copyright (c) 2009-2013 Martin Becker.  All rights reserved.
# This package is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: 93_examples.t 15 2013-05-31 16:52:22Z demetri $

# Checking whether all scripts in the examples directory run fine.
# These are tests for the distribution maintainer, mostly.
# Example scripts are intended rather to be simple than bullet-proof.
# However, if you do run into problems with them, other than perhaps
# some unmet dependencies, feel free to let me know.

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl t/93_examples.t'

use 5.006;
use strict;
use warnings;
use Test;
use lib "t/lib";
use Test::MyUtils;

BEGIN {
    use_or_bail('File::Spec');
    maintainer_only('d_fork');
    plan tests => 10;
}

my $examples_dir = 'examples';
my $shebang_pat  = qr{^#!/usr/bin/perl\s};
my $this_perl    = Test::MyUtils::this_perl();
my $stdin_file   = File::Spec->devnull;
my $stdout_file  = 't/example.out';
my $stderr_file  = 't/example.err';
my $timeout_secs = 10;

my $files_count       = 0;
my @not_executable    = ();
my @not_readable      = ();
my @bogus_shebang     = ();
my @trouble_executing = ();
my @bad_exit_code     = ();
my @stdout_empty      = ();
my @stderr_nonempty   = ();
my @timed_out         = ();

ok(-x $this_perl, 1, 'perl binary is executable');

foreach my $script_path (glob File::Spec->catfile($examples_dir, '*.pl')) {
    ++$files_count;
    print "# checking script file $script_path...\n";
    if (!-x $script_path) {
        push @not_executable, $script_path;
    }
    if (open SCRIPT, '<', $script_path) {
        my $first_line = <SCRIPT>;
        close SCRIPT;
        if (!defined($first_line) || $first_line !~ /$shebang_pat/) {
            push @bogus_shebang, $script_path;
        }
        if (!run_script($script_path)) {
            push @trouble_executing, $script_path;
        }
    }
    else {
        push @not_readable, $script_path;
    }
}
ok 0 < $files_count, 1, "found some example scripts ($files_count in total)";

foreach my $desc (
    ['executable',                 \@not_executable],
    ['readable',                   \@not_readable],
    ['with standard shebang line', \@bogus_shebang],
    ['started successfully',       \@trouble_executing],
    ['terminated successfully',    \@bad_exit_code],
    ['generating output',          \@stdout_empty],
    ['run without warnings',       \@stderr_nonempty],
    ['finished in time',           \@timed_out],
) {
    my ($text, $list) = @{$desc};
    foreach my $script (@{$list}) {
        print "# not $text: $script\n";
    }
    ok 0+@{$list}, 0, "all scripts $text";
}

sub run_script {
    my ($script) = @_;
    my $pid = fork();
    return 0 if !defined $pid;
    if (!$pid) {
        $ENV{'PATH'} = $examples_dir;                   # anything untainted
        open STDIN,  '<', $stdin_file  or exit 200;
        open STDOUT, '>', $stdout_file or exit 201;
        open STDERR, '>', $stderr_file or exit 202;
        exec $this_perl, '-Mlib=blib/lib', $script or exit 203;
    }
    my $exit_status = 0;;
    my $terminated  = 0;
    {
        local $SIG{'ALRM'} = sub { $terminated = 1; kill 'KILL', $pid; };
        alarm($timeout_secs);
        $exit_status = waitpid($pid, 0)? $?: -1;
        alarm(0);
    }
    if ($terminated) {
        push @timed_out, $script;
    }
    elsif ($exit_status) {
        push @bad_exit_code, $script;
    }
    else {
        if (-s $stderr_file) {
            push @stderr_nonempty, $script;
        }
        if (-z $stdout_file) {
            push @stdout_empty, $script;
        }
    }
    unlink $stdout_file, $stderr_file;
    return 1;
}

__END__
