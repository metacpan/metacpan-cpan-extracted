use strict;
use warnings;
use Test::More;
use Config;

plan skip_all => 'author test: set AUTHOR_TESTING=1' unless $ENV{AUTHOR_TESTING};
plan skip_all => 'valgrind not found'
    unless `which valgrind 2>/dev/null` =~ /\S/;

# t/17 is deliberately absent: the forked child's leak is by design and does
# resolve to td_reader, so it would be attributed to us
my @tests = qw(
    t/00_use.t
    t/01_execute.t
    t/02_transport.t
    t/03_pump_lifecycle.t
    t/07_close.t
    t/08_multi_client.t
    t/18_dispatch_hardening.t
);

# the attribution below reports "not ours" both when nothing of ours leaked
# and when the frame regex stopped matching; these tell those apart
my ($records, $framed) = (0, 0);

for my $t (@tests) {
    my $cmd = "valgrind --error-exitcode=99 --leak-check=full"
        . " --show-leak-kinds=definite --errors-for-leak-kinds=definite"
        . " --num-callers=20"
        . " \"$Config{perlpath}\" -Iblib/lib -Iblib/arch $t 2>&1";
    my $out = `$cmd`;
    my $rc = $? >> 8;

    my ($invalid) = $out =~ /Invalid (read|write)/;

    # TDLib is a large C++ library with its own allocation habits, and which
    # of them valgrind calls a definite leak varies by build -- the prebuilt
    # and from-source Aliens disagree. Chasing those is a treadmill, so
    # attribute each leak instead: a record is ours only if the allocation
    # happens in one of our own C functions, which are plain C names. A
    # frame in the td:: namespace is TDLib allocating for itself.
    my @ours;
    for my $rec (split /^==\d+==\s*$/m, $out) {
        next unless $rec =~ /definitely lost in loss record/;
        $records++;
        my @frames = $rec =~ /^==\d+==\s+(?:at|by) 0x[0-9A-F]+: (.+?) \(/mg;
        # skip valgrind's own interceptors to reach the real allocation site
        shift @frames while @frames && $frames[0] =~ /^(?:operator new|malloc|calloc|realloc|strdup)/;
        next unless @frames;
        $framed++;
        push @ours, $frames[0] if $frames[0] =~ /^(?:td_|XS_EV__Telegram)/;
    }

    if ($invalid) {
        fail "$t: valgrind reported an invalid access";
        diag $out =~ s/^/  /gmr;
    } elsif (@ours) {
        fail "$t: leaked from our own code (@ours)";
        diag $out =~ s/^/  /gmr;
    } elsif ($rc != 0 && $rc != 99) {
        fail "$t: test failure under valgrind (rc=$rc)";
        diag $out =~ s/^/  /gmr;
    } else {
        pass "$t: no leak attributable to our code";
    }
}

# TDLib leaks a little of its own on every run, so records are expected. What
# would be wrong is records we could not read: that is the attribution regex
# having drifted, and it would silently clear us of every leak.
diag sprintf 'parsed %d of %d definite-leak records', $framed, $records;
ok !$records || $framed, 'the leak records were parsed, not just counted';

done_testing;
