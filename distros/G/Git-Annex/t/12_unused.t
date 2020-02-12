#!/usr/bin/perl

use 5.028;
use strict;
use warnings;
use lib 't/lib';

use Try::Tiny;
use Test::More;
use Git::Annex;
use t::Setup;
use t::Util;
use Storable;
use Data::Compare;
use Time::HiRes qw(time);
use File::Slurp;
use File::Spec::Functions qw(catfile);
use Scalar::Util qw(looks_like_number);

plan skip_all => "git-annex not available" unless git_annex_available;

with_temp_annexes {
    my (undef, $source1) = @_;
    $source1->rm("foo/foo2/baz");
    $source1->commit({ message => "rm" });

    my $annex = Git::Annex->new($source1->dir);

    $annex->git->config(qw(annex.used-refspec +refs/heads/*));
    my @unused = @{ $annex->unused };
    is $annex->{_unused}{unused_args}{used_refspec}, "+refs/heads/*",
      "uses configured annex.used-refspec";
    $annex->git->config(qw(--unset annex.used-refspec));
    @unused = @{ $annex->unused(used_refspec => "+refs/heads/*") };
    is $annex->{_unused}{unused_args}{used_refspec}, "+refs/heads/*",
      "uses passed used_refspec";
    @unused = @{ $annex->unused };
    is $annex->{_unused}{unused_args}{used_refspec},
      "+refs/heads/*:-refs/heads/synced/*",
      "uses default --used-refspec";

    ok @unused == 1, "there is one unused file";
    my %unused_file = %{ $unused[0] };
    ok !$unused_file{tmp}, "unused file is not a tmp file";
    ok !$unused_file{bad}, "unused file is not a bad file";
    ok looks_like_number $unused_file{number}, "unused file has a number";
    ok $unused_file{key} =~ /^SHA256E-/, "unused file has a key";

    my ($_unused, $cache_timestamp) = read_cache($annex);
    ok Compare(\@unused, $_unused->{unused}), "it caches its results";
    sleep 1;
    my $cmd_time = time;
    @unused = @{ $annex->unused };
    ($_unused, $cache_timestamp) = read_cache($annex);
    ok $_unused->{timestamp} < $cmd_time
      && Compare(\@unused, $_unused->{unused}),
      "it returns results from the cache";

    @unused = @{ $annex->unused(used_refspec => "+refs/heads/*") };
    ok $cache_timestamp < $annex->{_unused}{timestamp},
      "changing the used_refspec invalidates the cache";
    sleep 1;
    ($_unused, $cache_timestamp) = read_cache($annex);
    write_file catfile(qw(source1 extra)), "extra\n";
    $source1->add("extra");
    $source1->commit({ message => "add" });
    @unused = @{ $annex->unused(used_refspec => "+refs/heads/*") };
    ok $cache_timestamp < $annex->{_unused}{timestamp},
      "committing to a branch invalidates the cache";
    sleep 1;
    ($_unused, $cache_timestamp) = read_cache($annex);
    $source1->checkout("git-annex");
    write_file catfile(qw(source1 extra)), "extra\n";
    $source1->add("extra");
    $source1->commit({ message => "add" });
    $source1->checkout("master");
    @unused = @{ $annex->unused(used_refspec => "+refs/heads/*") };
    ok $cache_timestamp == $annex->{_unused}{timestamp},
      "committing to git-annex branch does not invalidate the cache";
    ($_unused, $cache_timestamp) = read_cache($annex);
    $source1->annex("unused");
    sleep 1;
    @unused = @{ $annex->unused(used_refspec => "+refs/heads/*") };
    ok $cache_timestamp < $annex->{_unused}{timestamp},
      "running `git annex unused` invalidates the cache";

    ($_unused, $cache_timestamp) = read_cache($annex);
    ok !exists $unused_file{log_lines}, "unused file was not logged";
    sleep 1;
    @unused = @{ $annex->unused(used_refspec => "+refs/heads/*", log => 1) };
    %unused_file = %{ $unused[0] };
    my $annex_unused = $annex->_git_path(qw(annex unused));
    my $annex_unused_timestamp = (stat $annex_unused)[9];
    ok $annex_unused_timestamp <= $cache_timestamp,
      "asking for logs does not invalidate (most of) the cache";
    ok grep(/add/, @{ $unused_file{log_lines} }),
      "log lines contain correct commit message";
    ($_unused, $cache_timestamp) = read_cache($annex);
    @unused = @{ $annex->unused(used_refspec => "+refs/heads/*") };
    ok $cache_timestamp == $annex->{_unused}{timestamp},
      "turning logs off again does not invalidate the cache";
    %unused_file = %{ $unused[0] };
    ok grep(/add/, @{ $unused_file{log_lines} }),
      "log lines still contain correct commit message";
};

with_temp_annexes {
    my (undef, $source1) = @_;
    corrupt_annexed_file $source1, "foo/foo2/baz";
    try { $source1->annex("fsck") };
    my $annex = Git::Annex->new($source1->dir);
    my @unused = @{ $annex->unused };
    ok @unused == 1, "there is one unused file";
    my %unused_file = %{ $unused[0] };
    ok !$unused_file{tmp}, "unused file is not a tmp file";
    ok $unused_file{bad}, "unused file is a bad file";
    ok looks_like_number $unused_file{number}, "unused file has a number";
    ok $unused_file{key} =~ /^SHA256E-/, "unused file has a key";
};

# TODO somehow generate some tmp files (.git/annex/tmp) and check
# those are identified with the 'tmp' hash key

sub read_cache {
    my $annex = shift;
    my $cache = retrieve $annex->_unused_cache;
    my $cache_timestamp = $cache->{timestamp};
    return ($cache, $cache_timestamp);
}

done_testing;
