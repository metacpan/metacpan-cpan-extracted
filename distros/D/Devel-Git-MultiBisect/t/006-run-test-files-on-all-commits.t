# -*- perl -*-
# t/006-run-test-files-on-all-commits.t
use strict;
use warnings;
use Devel::Git::MultiBisect::AllCommits;
use Devel::Git::MultiBisect::Opts qw( process_options );
use Test::More tests => 33;
use Cwd;
use File::Spec;
use List::Util qw( first );

my $cwd = cwd();

##### run_test_files_on_all_commits() #####

my (%args, $params, $self);
my ($good_gitdir, $good_last_before, $good_last);
my ($target_args, $full_targets);
my ($rv, $transitions, $all_outputs, $all_outputs_count, $expected_count, $first_element);
my ($timings);

$good_gitdir = File::Spec->catdir($cwd, qw| t lib list-compare |);
$good_last_before = '2614b2c2f1e4c10fe297acbbea60cf30e457e7af';
$good_last = 'd304a207329e6bd7e62354df4f561d9a7ce1c8c2';
%args = (
    gitdir => $good_gitdir,
    last_before => $good_last_before,
    last => $good_last,
    verbose => 1,
);
$params = process_options(%args);
$self = Devel::Git::MultiBisect::AllCommits->new($params);
ok($self, "new() returned true value");
isa_ok($self, 'Devel::Git::MultiBisect::AllCommits');

$target_args = [
    File::Spec->catdir( qw| t 44_func_hashes_mult_unsorted.t |),
    File::Spec->catdir( qw| t 45_func_hashes_alt_dual_sorted.t |),
];
$full_targets = $self->set_targets($target_args);
ok($full_targets, "set_targets() returned true value");
is(ref($full_targets), 'ARRAY', "set_targets() returned array ref");
is_deeply(
    [ map { $_->{path} } @{$full_targets} ],
    [ map { File::Spec->catfile($self->{gitdir}, $_) } @{$target_args} ],
    "Got expected full paths to target files for testing",
);

{
    # error case: premature run of get_digests_by_file_and_commit()
    local $@;
    eval { $rv = $self->get_digests_by_file_and_commit(); };
    like($@,
        qr/\QYou must call run_test_files_on_all_commits() before calling get_digests_by_file_and_commit()\E/,
        "Got expected error message for premature get_digests_by_file_and_commit()"
    );
}

$all_outputs = $self->run_test_files_on_all_commits();
ok($all_outputs, "run_test_files_on_all_commits() returned true value");
is(ref($all_outputs), 'ARRAY', "run_test_files_on_all_commits() returned array ref");
$all_outputs_count = 0;
for my $c (@{$all_outputs}) {
    for my $t (@{$c}) {
        $all_outputs_count++;
    }
}
is(
    $all_outputs_count,
    scalar(@{$self->get_commits_range}) * scalar(@{$target_args}),
    "Got expected number of output files"
);
$timings = $self->get_timings();
ok(exists $timings->{elapsed}, "get_timings(): elapsed time recorded");
ok(exists $timings->{runs}, "get_timings(): number of runs recorded");
is($timings->{runs}, scalar(@{$self->get_commits_range}),
    "Got expected number of runs: " . scalar(@{$self->get_commits_range}));
ok(exists $timings->{mean}, "get_timings(): mean time recorded");

##### get_digests_by_file_and_commit() #####

$rv = $self->get_digests_by_file_and_commit();
ok($rv, "get_digests_by_file_and_commit() returned true value");
is(ref($rv), 'HASH', "get_digests_by_file_and_commit() returned hash ref");
cmp_ok(scalar(keys %{$rv}), '==', scalar(@{$target_args}),
    "Got expected number of elements: one for each of " . scalar(@{$target_args}) . " test files targeted");
$first_element = first { $_ } keys %{$rv};
is(ref($rv->{$first_element}), 'ARRAY', "Records are array references");
is(
    scalar(@{$rv->{$first_element}}),
    scalar(@{$self->get_commits_range}),
    "Got 1 element for each of " . scalar(@{$self->get_commits_range}) . " commits"
);
is(ref($rv->{$first_element}->[0]), 'HASH', "Records are hash references");
for my $k ( qw| commit file md5_hex | ) {
    ok(exists $rv->{$first_element}->[0]->{$k}, "Record has '$k' element");
}


##### examine_transitions #####

$transitions = $self->examine_transitions($rv);
ok($transitions, "examine_transitions() returned true value");
is(ref($transitions), 'HASH', "examine_transitions() returned hash ref");
cmp_ok(scalar(keys %{$transitions}), '==', scalar(@{$target_args}),
    "Got expected number of elements: one for each of " . scalar(@{$target_args}) . " test files targeted");
$first_element = first { $_ } keys %{$transitions};
is(ref($transitions->{$first_element}), 'ARRAY', "Records are array references");
$expected_count = scalar(@{$self->get_commits_range}) - 1;
is(
    scalar(@{$transitions->{$first_element}}),
    $expected_count,
    "Got 1 element for each of $expected_count transitions between commits"
);
is(ref($transitions->{$first_element}->[0]), 'HASH', "Records are hash references");
for my $k ( qw| older newer compare | ) {
    ok(exists $transitions->{$first_element}->[0]->{$k}, "Record has '$k' element");
}
for my $test (sort keys %$transitions) {
    my $expected_different = 0;
    my $observed_different = 0;
    for my $r (@{$transitions->{$test}}) {
        $observed_different++ if $r->{compare} eq 'different';
    }
    cmp_ok($observed_different, '==', $expected_different,
        "As expected, for $test got $expected_different 'different' for 'compare'");
}

