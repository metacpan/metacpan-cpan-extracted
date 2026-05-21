#!/usr/bin/env perl
# Smoke test the fork-safety contract from the CAVEATS POD: a client created
# in the parent must not be used in the child, and the child's DESTROY of an
# inherited client warns and exits cleanly without crashing.
use strict;
use warnings;
use lib 'blib/lib', 'blib/arch';
use Test::More;

BEGIN { eval { require EV }; plan skip_all => 'EV required' if $@ }
use EV;
use EV::Etcd;

my $available = 0;
eval {
    my $c = EV::Etcd->new(endpoints => ['127.0.0.1:2379'], timeout => 2);
    $c->status(sub { $available = 1 if !$_[1]; EV::break });
    my $t = EV::timer(3, 0, sub { EV::break });
    EV::run;
};
plan skip_all => 'etcd not available on 127.0.0.1:2379' unless $available;

my $client = EV::Etcd->new(endpoints => ['127.0.0.1:2379']);
ok($client, 'client created');

my $pid = fork();
defined $pid or BAIL_OUT("fork failed: $!");

if ($pid == 0) {
    # Child: drop the inherited client. DESTROY should detect the pid mismatch,
    # warn, and free Perl-side resources without touching the parent's gRPC
    # state. Exit cleanly.
    undef $client;
    exit 0;
}

waitpid $pid, 0;
my $child_status = $?;

is($child_status & 0x7f, 0, 'child did not die from a signal');
is($child_status >> 8, 0, 'child exited 0');

# Parent's client must still work
my $put_ok;
$client->put("/test_fork_$$", "parent-still-alive", sub { $put_ok = !$_[1]; EV::break });
my $t = EV::timer(3, 0, sub { EV::break });
EV::run;
ok($put_ok, 'parent client still functional after child exit');

$client->delete("/test_fork_$$", sub { EV::break });
my $td = EV::timer(2, 0, sub { EV::break });
EV::run;

done_testing();
