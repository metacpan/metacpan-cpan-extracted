#!/usr/bin/perl

use 5.028;
use strict;
use warnings;
use lib 't/lib';

use Test::More;
use Git::Annex;
use Git::Annex::BatchCommand;
use t::Setup;
use t::Util;
use Scalar::Util qw(looks_like_number);
use Try::Tiny;

plan skip_all => "git-annex not available" unless git_annex_available;

with_temp_annexes {
    my (undef, $source1) = @_;

    my $annex = Git::Annex->new($source1->dir);
    #<<<
    try {
        my $nope = Git::Annex::BatchCommand->new;
    } catch {
        ok grep(/not enough arguments/, $_), "it requires an annex";
    };
    try {
        my $nope = $annex->batch;
    } catch {
        ok grep(/not enough arguments/, $_), "it requires a command";
    };
    #>>>

    my $batch = $annex->batch("find", "--in=here");

    # TODO there are races here due to the (faint) possibility of PID reuse
    my $first_pid = $batch->{_pid};
    ok looks_like_number $first_pid, "it stores a PID";
    ok kill(0, $first_pid), "the PID is a running process";
    $batch->restart;
    ok !kill(0, $first_pid), "the old PID is no longer a running process";
    my $second_pid = $batch->{_pid};
    isnt $first_pid, $second_pid, "it starts a new process";
    ok looks_like_number $second_pid, "it stores a PID again";
    ok kill(0, $second_pid), "the new PID is a running process";

    ok grep(/\A--batch\z/, @{ $batch->{_cmd} }),
      "it passes --batch to git-annex";
    my ($response1, $response2) = $batch->say("foo/foo2/baz", "foo/foo2/baz");
    is $response1, $response2, "it returns a list in list context";
    my ($response3, $response4) = $batch->say("foo/foo2/baz", "foo/bar");
    is_deeply [$response3, $response4], ["foo/foo2/baz", ""],
      "it returns results in the correct order";
    my $response5 = $batch->say("foo/foo2/baz");
    is $response5, "foo/foo2/baz", "it returns a single result into a scalar";
    my ($response6) = $batch->say("foo/foo2/baz");
    is $response6, "foo/foo2/baz", "it still returns a list in list context";
    is $batch->ask("foo/foo2/baz"), "foo/foo2/baz",
      "you can ask as well as say";

    undef $batch;
    ok !kill(0, $second_pid),
      "it cleans up the process when object goes out of scope";
};

done_testing;
