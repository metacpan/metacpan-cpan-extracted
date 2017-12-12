#!/usr/bin/perl -w
# -*- cperl -*-

#
# Author: Slaven Rezic
#

use strict;
use Test::More;

plan 'no_plan';

use Doit;

use Errno qw(ENOENT);

TODO: {
    todo_skip "Hangs on Windows, need to check why", 1 if $^O eq 'MSWin32';

{
    my $r = Doit->init;

    {
	is $r->open3({errref => \my $stderr}, $^X, '-e', 'print scalar <STDIN>'), '', 'no instr -> empty input';
	is $stderr, '', 'No stderr';
    }
    {
	is $r->open3({errref => \my $stderr}, $^X, '-e', 'print scalar <STDIN>; print STDERR "a warning"'), '', 'no instr -> empty input';
	is $stderr, "a warning", "With stderr";
    }
    {
	is $r->open3({errref => \my $stderr, instr=>"some input\n"}, $^X, '-e', 'print scalar <STDIN>; print STDERR "a warning"'), "some input\n", 'expected single-line result';
	is $stderr, "a warning", "With stderr";
    }
    {
	is $r->open3({errref => \my $stderr, instr=>"first line\nsecond line\n"}, $^X, '-e', 'print scalar <STDIN>; print STDERR "a warning"; print scalar <STDIN>;'), "first line\nsecond line\n", 'expected multi-line result';
	is $stderr, "a warning", "With stderr";
    }

    {
	my %status;
	is $r->open3({errref => \my $stderr, statusref => \%status}, $^X, '-e', 'print STDERR "a warning"; exit 0'), '';
	is $status{exitcode}, 0, 'status reference filled, exit code as expected (success)';
    }

    {
	my %status;
	is $r->open3({errref => \my $stderr, statusref => \%status}, $^X, '-e', 'print STDERR "a warning"; exit 1'), '';
	is $status{exitcode}, 1, 'status reference filled, exit code as expected (fail)';
    }

 TODO: {
	todo_skip "Tests out of sequence with perl 5.8", 1 if $] < 5.010;
	local $TODO;
	$TODO = "No expection with older perl versions" if $] < 5.014;
	my($stderr, %status);
	eval { $r->open3({errref => \$stderr, statusref => \%status}, 'this-cmd-does-not-exist-'.$$.'-'.time) };
	isnt "$@", ''; # error message seems to differ between perl versions
    }

    eval { $r->open3($^X, '-e', 'kill TERM => $$') };
    like $@, qr{^Command died with signal 15, without coredump};
    is $@->{signalnum}, 15;
    is $@->{coredump}, 'without';

    eval { $r->open3($^X, '-e', 'kill KILL => $$') };
    like $@, qr{^Command died with signal 9, without coredump};
    is $@->{signalnum}, 9;
    is $@->{coredump}, 'without';

    is $r->open3({quiet=>1}, $^X, '-e', '#nothing'), '', 'nothing returned; command is also quiet';

    is $r->info_open3($^X, '-e', 'print 42'), 42, 'info_open3 behaves as open3 in non-dry-run mode';

    ok !eval { $r->info_open3($^X, '-e', 'exit 1'); 1 };
    like $@, qr{open3 command '.* -e exit 1' failed: Command exited with exit code 1 at .* line \d+}, 'verbose error message with failed info_open3 command';
}

{
    local @ARGV = ('--dry-run');
    my $dry_run = Doit->init;
    is $dry_run->open3({instr=>"input"}, $^X, '-e', 'print scalar <STDIN>'), undef, 'no output in dry-run mode';
    is $dry_run->open3({instr=>"input",info=>1}, $^X, '-e', 'print scalar <STDIN>'), "input", 'info=>1: there is output in dry-run mode';
    is $dry_run->info_open3({instr=>"input"}, $^X, '-e', 'print scalar <STDIN>'), "input", 'info_open3 behaves like info=>1';
}

} # TODO

__END__
