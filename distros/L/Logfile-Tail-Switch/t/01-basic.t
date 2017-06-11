#!perl

use 5.010001;
use strict;
use warnings;
use Test::More 0.98;

use File::Temp qw(tempdir);
use Logfile::Tail::Switch;
use Time::HiRes 'sleep';

my $tempdir = tempdir();
note "tempdir: $tempdir";

sub _append {
    my ($filename, $str) = @_;
    open my $fh, ">>", $filename or die;
    print $fh $str;
    close $fh;
}

subtest "no matching files" => sub {
    my $dir = "$tempdir/nomatch";
    mkdir $dir, 0755 or die;
    chdir $dir or die;

    my $tail = Logfile::Tail::Switch->new(globs => ["*"]);
    is($tail->getline, '');
};

subtest "single glob" => sub {
    my $dir = "$tempdir/single";
    mkdir $dir, 0755 or die;
    chdir $dir or die;

    _append("log-a", "one-a\n");
    _append("log-b", "one-b\n");
    my $tail = Logfile::Tail::Switch->new(globs=>["log-*"], check_freq=>0.1);
    is($tail->getline, '', "initial");
    _append("log-a", "two-a\n");
    is($tail->getline, '', "line added to log-a has no effect");
    _append("log-b", "two-b\nthree-b\n");
    is($tail->getline, "two-b\n", "line added to log-b is seen (1)");
    is($tail->getline, "three-b\n", "line added to log-b is seen (2)");
    is($tail->getline, "", "no more lines");

    _append("log-c", "one-c\ntwo-c\n");
    _append("log-d", "one-d\ntwo-d\n");
    is($tail->getline, "", "no more lines yet");
    sleep 0.11;
    is($tail->getline, "one-c\n", "line from log-c is seen (1)");
    is($tail->getline, "two-c\n", "line from log-c is seen (1)");
    is($tail->getline, "one-d\n", "line from log-d is seen (2)");
    is($tail->getline, "two-d\n", "line from log-d is seen (2)");
    is($tail->getline, "", "no more lines (2)");

    _append("log-b", "four-b\n");
    is($tail->getline, '', "line added to log-b now has no effect");
    _append("log-c", "three-c\n");
    is($tail->getline, '', "line added to log-c has no effect");
    _append("log-d", "three-d\n");
    is($tail->getline, "three-d\n", "line from log-d is seen");
};

subtest "opt:tail_new" => sub {
    my $dir = "$tempdir/opt-tail_new";
    mkdir $dir, 0755 or die;
    chdir $dir or die;

    _append("log-a", "one-a\n");
    _append("log-b", "one-b\n");
    my $tail = Logfile::Tail::Switch->new(globs=>["log-*"], check_freq=>0.1, tail_new=>1);
    is($tail->getline, '', "initial");
    _append("log-a", "two-a\n");
    is($tail->getline, '', "line added to log-a has no effect");
    _append("log-b", "two-b\nthree-b\n");
    is($tail->getline, "two-b\n", "line added to log-b is seen (1)");
    is($tail->getline, "three-b\n", "line added to log-b is seen (2)");
    is($tail->getline, "", "no more lines");

    _append("log-c", "one-c\ntwo-c\n");
    _append("log-d", "one-d\ntwo-d\n");
    is($tail->getline, "", "no more lines yet");
    sleep 0.11;
    is($tail->getline, "", "no more lines (2)");

    _append("log-b", "four-b\n");
    is($tail->getline, '', "line added to log-b now has no effect");
    _append("log-c", "three-c\n");
    is($tail->getline, '', "line added to log-c has no effect");
    _append("log-d", "three-d\n");
    is($tail->getline, "three-d\n", "line from log-d is seen");
};

subtest "two globs" => sub {
    my $dir = "$tempdir/two";
    mkdir $dir, 0755 or die;
    chdir $dir or die;

    _append("log1-a", "1one-a\n");
    _append("log1-b", "2one-b\n");
    _append("log2-a", "1one-a\n");
    _append("log2-b", "2one-b\n");
    my $tail = Logfile::Tail::Switch->new(
        globs=>["log1-*", "log2-*"], check_freq=>0.1);
    is($tail->getline, '', "initial");
    _append("log1-a", "1two-a\n");
    is($tail->getline, '', "line added to log1-a has no effect");
    _append("log2-a", "2two-a\n");
    is($tail->getline, '', "line added to log2-a has no effect");
    _append("log1-b", "1two-b\n1three-b\n");
    _append("log2-b", "2two-b\n2three-b\n");
    is($tail->getline, "1two-b\n", "line added to log1-b is seen (1)");
    is($tail->getline, "1three-b\n", "line added to log1-b is seen (2)");
    is($tail->getline, "2two-b\n", "line added to log2-b is seen (1)");
    is($tail->getline, "2three-b\n", "line added to log2-b is seen (2)");
    is($tail->getline, "", "no more lines");

    _append("log1-c", "1one-c\n1two-c\n");
    _append("log1-d", "1one-d\n1two-d\n");
    _append("log2-c", "2one-c\n2two-c\n");
    _append("log2-d", "2one-d\n2two-d\n");
    is($tail->getline, "", "no more lines yet");
    sleep 0.11;
    is($tail->getline, "1one-c\n", "line from log1-c is seen (1)");
    is($tail->getline, "1two-c\n", "line from log1-c is seen (1)");
    is($tail->getline, "1one-d\n", "line from log1-d is seen (2)");
    is($tail->getline, "1two-d\n", "line from log1-d is seen (2)");
    is($tail->getline, "2one-c\n", "line from log2-c is seen (1)");
    is($tail->getline, "2two-c\n", "line from log2-c is seen (1)");
    is($tail->getline, "2one-d\n", "line from log2-d is seen (2)");
    is($tail->getline, "2two-d\n", "line from log2-d is seen (2)");
    is($tail->getline, "", "no more lines (2)");

    _append("log1-b", "1four-b\n");
    _append("log2-b", "2four-b\n");
    is($tail->getline, '', "line added to log1-b/log2-b now has no effect");
    _append("log1-c", "1three-c\n");
    _append("log2-c", "2three-c\n");
    is($tail->getline, '', "line added to log1-c/log2-c has no effect");
    _append("log1-d", "1three-d\n");
    _append("log2-d", "2three-d\n");
    is($tail->getline, "1three-d\n", "line from log1-d is seen");
    is($tail->getline, "2three-d\n", "line from log2-d is seen");
};

# XXX truncating a log file

done_testing;
