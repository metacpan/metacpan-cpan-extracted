#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use File::Raw;
use File::Temp qw(tempdir);

# When a chain plugin sets ctx->cancel (via the `cancel` key on the
# Perl-bridge context), the dispatcher must:
#   - return undef from slurp / spew
#   - NOT call any subsequent plugin in the chain
#   - free intermediate SVs cleanly (asan/ubsan should stay quiet)

my $dir = tempdir(CLEANUP => 1);

my @call_log;

File::Raw::register_plugin('appender_a', {
    read  => sub { push @call_log, 'a-read';  my ($p, $b) = @_; "$b|a" },
    write => sub { push @call_log, 'a-write'; my ($p, $b) = @_; "$b|a" },
});

File::Raw::register_plugin('canceller', {
    read  => sub { push @call_log, 'c-read';  $_[2]->{cancel} = 1; undef },
    write => sub { push @call_log, 'c-write'; $_[2]->{cancel} = 1; undef },
});

File::Raw::register_plugin('appender_z', {
    read  => sub { push @call_log, 'z-read';  my ($p, $b) = @_; "$b|z" },
    write => sub { push @call_log, 'z-write'; my ($p, $b) = @_; "$b|z" },
});

my $f = "$dir/c.txt";
File::Raw::spew($f, 'X');

subtest 'mid-chain READ cancel returns undef and stops' => sub {
    @call_log = ();
    my $r = File::Raw::slurp($f, plugin => ['appender_a', 'canceller', 'appender_z']);
    is($r, undef, 'slurp returns undef on cancel');
    is_deeply(\@call_log, ['a-read', 'c-read'],
        'appender_z was never invoked');
};

subtest 'mid-chain WRITE cancel does not write the file' => sub {
    @call_log = ();
    my $f2 = "$dir/cw.txt";
    my $rc = File::Raw::spew($f2, 'PAYLOAD',
        plugin => ['appender_a', 'canceller', 'appender_z']);
    ok(!$rc, 'spew returns false on cancel');
    ok(!-e $f2, 'no file was written');
    # WRITE iterates right-to-left, so appender_z runs first.
    is_deeply(\@call_log, ['z-write', 'c-write'],
        'appender_a (leftmost) was never invoked after cancel');
};

done_testing;
