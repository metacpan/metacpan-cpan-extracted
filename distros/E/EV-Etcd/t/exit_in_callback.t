#!/usr/bin/env perl
# exit() from a callback must still release the client and gRPC: the client
# is freed while exit unwinds, and its DESTROY must not wait for a callback
# that will never return
use strict;
use warnings;
BEGIN { delete @ENV{qw(http_proxy https_proxy grpc_proxy)} }
use lib 'blib/lib', 'blib/arch';
use Test::More;
use File::Temp qw(tempfile);
use File::Spec;

BEGIN { eval { require EV }; plan skip_all => 'EV required' if $@ }

plan skip_all => 'needs /proc/self/task' unless -d '/proc/self/task';
plan skip_all => 'gRPC stays up until exit on macOS' if $^O eq 'darwin';

my ($fh, $script) = tempfile(SUFFIX => '.pl', UNLINK => 1);
print $fh <<'EOF';
use strict;
use warnings;
use EV;
use EV::Etcd;
my $c = EV::Etcd->new(endpoints => ['127.0.0.1:1'], max_retries => 0);
my $w;
if ($ARGV[0] eq 'watch') { $w = $c->watch('/k', sub { exit 0 }) }
elsif ($ARGV[0] eq 'fork') {
    # The child must leave the dropped client alone: it has no gRPC threads
    $c->get('/k', sub {
        undef $c;
        my $pid = fork;
        if (!$pid) { alarm 10; exit 0 }
        waitpid $pid, 0;
        print "child=$?\n";
        EV::break;
    });
}
else { $c->get('/k', sub { exit 0 }) }
EV::run;
END {
    my $threads = 0;
    for (1 .. 300) {
        opendir my $d, "/proc/$$/task" or last;
        $threads = grep { /^\d+$/ } readdir $d;
        last if $threads == 1;
        select undef, undef, undef, 0.01;
    }
    print "threads=$threads\n";
}
EOF
close $fh;

my @inc = map { '-I' . File::Spec->rel2abs($_) } 'blib/lib', 'blib/arch';
for my $kind (qw(get watch)) {
    my $out = `"$^X" @inc "$script" $kind 2>&1`;
    is($?, 0, "$kind: the process exits normally");
    like($out, qr/^threads=1$/m, "$kind: gRPC is shut down after exit() from its callback")
        or diag $out;
}

my $out = `"$^X" @inc "$script" fork 2>&1`;
like($out, qr/^child=0$/m, 'a child forked in a callback after dropping the client exits promptly')
    or diag $out;

done_testing;
