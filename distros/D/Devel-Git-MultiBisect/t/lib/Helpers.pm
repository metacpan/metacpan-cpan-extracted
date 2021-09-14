package Helpers;
use 5.14.0;
use warnings;
use Carp;
use Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(
    test_report
    test_commit_range
    test_transitions_data
);
{
    no warnings 'once';
    *ok = *Test::More::ok;
    *is = *Test::More::is;
    *note = *Test::More::note;
}

sub test_report {
    my $r = shift;
    return 1 if not defined $r;
    for my $k ( qw| commit commit_short file md5_hex | ) {
        return 0 unless exists $r->{$k};
    }
    return 1;
}

sub test_commit_range {
    my ($this_commit_range, $first, $last) = @_;
    ok($this_commit_range, "get_commits_range() returned true value");
    is(ref($this_commit_range), 'ARRAY', "get_commits_range() returned array ref");
    is($this_commit_range->[0], $first, "Got expected first commit in range");
    is($this_commit_range->[-1], $last, "Got expected last commit in range");
    note("Observed " . scalar(@{$this_commit_range}) . " commits in range");
}

sub test_transitions_data {
    my $transitions = shift;
    is(ref($transitions), 'HASH',
        "inspect_transitions() returned hash reference");
    is(scalar(keys %{$transitions}), 3,
        "inspect_transitions() has 3 elements");
    for my $k ( qw| newest oldest | ) {
        is(ref($transitions->{$k}), 'HASH',
            "Got hashref as value for '$k'");
        for my $l ( qw| idx md5_hex file | ) {
            ok(exists $transitions->{$k}->{$l},
                "Got key '$l' for '$k'");
        }
    }
    is(ref($transitions->{transitions}), 'ARRAY',
        "Got arrayref as value for 'transitions'");
    my @arr = @{$transitions->{transitions}};
    for my $t (@arr) {
        is(ref($t), 'HASH',
            "Got hashref as value for element in 'transitions' array");
        for my $m ( qw| newer older | ) {
            ok(exists $t->{$m}, "Got key '$m'");
            is(ref($t->{$m}), 'HASH', "Got hashref");
            for my $n ( qw| idx md5_hex file | ) {
                ok(exists $t->{$m}->{$n},
                    "Got key '$n'");
            }
        }
    }
    return @arr;
}

1;

