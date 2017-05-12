# -*- perl -*-
# t/005-run-test_files-on-one-commit.t
use strict;
use warnings;
use Devel::Git::MultiBisect::AllCommits;
use Devel::Git::MultiBisect::Opts qw( process_options );
use Test::More tests => 30;
use Cwd;
use File::Spec;

my $cwd = cwd();

my (%args, $params, $self);
my ($good_gitdir, $good_last_before, $good_last);
my ($target_args, $full_targets);

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

my ($commits, $outputs, $timings);
$commits = $self->get_commits_range();
$outputs = $self->run_test_files_on_one_commit($commits->[0]);
ok($outputs, "run_test_files_on_one_commit() returned true value");
is(ref($outputs), 'ARRAY', "run_test_files_on_one_commit() returned array ref");
is(scalar(@{$outputs}), scalar(@{$target_args}), "Got expected number of output files");
for my $f (map { $_->{file} } @{$outputs}) {
    ok(-f $f, "run_test_files_on_one_commit generated $f");
}
ok(! defined($self->get_timings()),
    "get_timings() returned undefined value");

# Try with no arg to run_test_files_on_one_commit
$target_args = [ File::Spec->catdir( qw| t 46_func_hashes_alt_dual_unsorted.t | ) ];
$full_targets = $self->set_targets($target_args);
ok($full_targets, "set_targets() returned true value");
is(ref($full_targets), 'ARRAY', "set_targets() returned array ref");
is_deeply(
    [ map { $_->{path} } @{$full_targets} ],
    [ map { File::Spec->catfile($self->{gitdir}, $_) } @{$target_args} ],
    "Got expected full paths to target files for testing",
);
$outputs = $self->run_test_files_on_one_commit();
ok($outputs, "run_test_files_on_one_commit() returned true value");
is(ref($outputs), 'ARRAY', "run_test_files_on_one_commit() returned array ref");
is(scalar(@{$outputs}), scalar(@{$target_args}), "Got expected number of output files");
for my $f (map { $_->{file} } @{$outputs}) {
    ok(-f $f, "run_test_files_on_one_commit generated $f");
}

note("Test excluded targets argument");

$target_args = [
    File::Spec->catdir( qw| t 44_func_hashes_mult_unsorted.t |),
    File::Spec->catdir( qw| t 45_func_hashes_alt_dual_sorted.t |),
];
$full_targets = $self->set_targets($target_args);
ok($full_targets, "set_targets() returned true value");
is(ref($full_targets), 'ARRAY', "set_targets() returned array ref");

my $excluded_targets;

$excluded_targets = [
    File::Spec->catdir( qw| t 45_func_hashes_alt_dual_sorted.t |),
];
$outputs = $self->run_test_files_on_one_commit($commits->[0], $excluded_targets);
ok($outputs, "run_test_files_on_one_commit() returned true value");
is(ref($outputs), 'ARRAY', "run_test_files_on_one_commit() returned array ref");
is(
    scalar(@{$outputs}),
    scalar(@{$target_args}) - scalar(@{$excluded_targets}),
    "Got expected number of output files, considering excluded targets"
);
for my $f (map { $_->{file} } @{$outputs}) {
    ok(-f $f, "run_test_files_on_one_commit generated $f");
}

$excluded_targets = [];
$outputs = $self->run_test_files_on_one_commit($commits->[0], $excluded_targets);
ok($outputs, "run_test_files_on_one_commit() returned true value");
is(ref($outputs), 'ARRAY', "run_test_files_on_one_commit() returned array ref");
is(
    scalar(@{$outputs}),
    scalar(@{$target_args}) - scalar(@{$excluded_targets}),
    "Got expected number of output files, considering excluded targets"
);
for my $f (map { $_->{file} } @{$outputs}) {
    ok(-f $f, "run_test_files_on_one_commit generated $f");
}

{

    $excluded_targets = { File::Spec->catdir( qw| t 45_func_hashes_alt_dual_sorted.t |) => 1 };
    local $@;
    eval {
        $outputs = $self->run_test_files_on_one_commit($commits->[0], $excluded_targets);
    };
    like($@, qr/excluded_targets, if defined, must be in array reference/,
        "Got expected error message for non-array-ref argument to run_test_files_on_one_commit()");
}
