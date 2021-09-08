# -*- perl -*-
# t/011-run-test_files-combined.t
use 5.14.0;
use warnings;
use Devel::Git::MultiBisect::AllCommits;
use Devel::Git::MultiBisect::Transitions;
use Devel::Git::MultiBisect::Opts qw( process_options );
use Test::More tests => 351;
use Carp;
use Cwd;
use File::Spec;
use File::Temp qw( tempdir );
use List::Util qw(first);
use lib qw( t/lib );
use Helpers qw( test_report );

# Objective of this test program is to replace t/010-run-test_files-combined.t
# running the same unit tests but from git checkouts on the tester's local
# disk rather than from submodules bundled with the CPAN distribution.
#
# We will have to setup envvars which can be checked before the various blocks
# of unit tests are run.  Since CPANtesters will presumably not have these
# envvars set up, they will be running a much smaller test suite.

note("Block 1");

SKIP: {
    skip "No git checkout of List-Compare found", 34
    unless (
        $ENV{PERL_LIST_COMPARE_GIT_CHECKOUT_DIR}
            and
        (-d $ENV{PERL_LIST_COMPARE_GIT_CHECKOUT_DIR})
    );
    my $startdir = cwd();
    chdir $ENV{PERL_LIST_COMPARE_GIT_CHECKOUT_DIR}
        or croak "Unable to change to List-Compare checkout directory";

    my (%args, $params, $self);
    my ($good_gitdir, $good_last_before, $good_last);
    my ($target_args, $full_targets);

    $good_gitdir = cwd();
    $good_last_before = '2614b2c2f1e4c10fe297acbbea60cf30e457e7af';
    $good_last = 'd304a207329e6bd7e62354df4f561d9a7ce1c8c2';
    %args = (
        gitdir => $good_gitdir,
        last_before => $good_last_before,
        last => $good_last,
        verbose => 1,
        # Until development is complete, we will want to be able to inspect
        # files created in the outputdir.
        outputdir => tempdir( CLEANUP => 0 ),
    );
    $params = process_options(%args);
    $self = Devel::Git::MultiBisect::AllCommits->new($params);
    ok($self, "new() returned true value");
    isa_ok($self, 'Devel::Git::MultiBisect::AllCommits');
    for my $d (qw| gitdir outputdir |) {
        ok(defined $self->{$d}, "'$d' has been defined");
        ok(-d $self->{$d}, "'$d' exists: $self->{$d}");
    }

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

    chdir $startdir or croak "Unable to return to $startdir";
}

#####

note("Block 2");

SKIP: {
    skip "No git checkout of List-Compare found", 33
    unless (
        $ENV{PERL_LIST_COMPARE_GIT_CHECKOUT_DIR}
            and
        (-d $ENV{PERL_LIST_COMPARE_GIT_CHECKOUT_DIR})
    );
    my $startdir = cwd();
    chdir $ENV{PERL_LIST_COMPARE_GIT_CHECKOUT_DIR}
        or croak "Unable to change to List-Compare checkout directory";

    ##### run_test_files_on_all_commits() #####

    my (%args, $params, $self);
    my ($good_gitdir, $good_last_before, $good_last);
    my ($target_args, $full_targets);
    my ($rv, $transitions, $all_outputs, $all_outputs_count, $expected_count, $first_element);
    my ($timings);

    $good_gitdir = cwd();
    $good_last_before = '2614b2c2f1e4c10fe297acbbea60cf30e457e7af';
    $good_last = 'd304a207329e6bd7e62354df4f561d9a7ce1c8c2';
    %args = (
        gitdir => $good_gitdir,
        last_before => $good_last_before,
        last => $good_last,
        verbose => 1,
        # Until development is complete, we will want to be able to inspect
        # files created in the outputdir.
        outputdir => tempdir( CLEANUP => 0 ),
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

    chdir $startdir or croak "Unable to return to $startdir";
}

#####

note("Block 3");

SKIP: {
    skip "No git checkout of dummyrepo found", 31
    unless (
        $ENV{PERL_DUMMYREPO_GIT_CHECKOUT_DIR}
            and
        (-d $ENV{PERL_DUMMYREPO_GIT_CHECKOUT_DIR})
    );
    my $startdir = cwd();
    chdir $ENV{PERL_DUMMYREPO_GIT_CHECKOUT_DIR}
        or croak "Unable to change to List-Compare checkout directory";

    my (%args, $params, $self);
    my ($good_gitdir, $good_last_before, $good_last);
    my ($target_args, $full_targets);
    my ($rv, $transitions, $all_outputs, $all_outputs_count, $expected_count, $first_element);

    # So that we have a basis for comparison, we'll first run already tested
    # methods over the 'dummyrepo'.

    $good_gitdir = cwd();
    $good_last_before = '92a79a3dc5bba45930a52e4affd91551aa6c78fc';
    $good_last = 'efdd091cf3690010913b849dcf4fee290f399009';
    %args = (
        gitdir => $good_gitdir,
        last_before => $good_last_before,
        last => $good_last,
        verbose => 0,
        # Until development is complete, we will want to be able to inspect
        # files created in the outputdir.
        outputdir => tempdir( CLEANUP => 0 ),
    );
    $params = process_options(%args);
    $target_args = [ File::Spec->catdir( qw| t 001_load.t | ) ];

    note("First object");

    $self = Devel::Git::MultiBisect::AllCommits->new($params);
    ok($self, "new() returned true value");
    isa_ok($self, 'Devel::Git::MultiBisect::AllCommits');

    $full_targets = $self->set_targets($target_args);
    ok($full_targets, "set_targets() returned true value");
    is(ref($full_targets), 'ARRAY', "set_targets() returned array ref");
    is_deeply(
        [ map { $_->{path} } @{$full_targets} ],
        [ map { File::Spec->catfile($self->{gitdir}, $_) } @{$target_args} ],
        "Got expected full paths to target files for testing",
    );

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

    undef $self;

    #######################################

    note("Second object");

    $self = Devel::Git::MultiBisect::AllCommits->new($params);
    ok($self, "new() returned true value");
    isa_ok($self, 'Devel::Git::MultiBisect::AllCommits');

    $full_targets = $self->set_targets($target_args);
    ok($full_targets, "set_targets() returned true value");
    is(ref($full_targets), 'ARRAY', "set_targets() returned array ref");
    is_deeply(
        [ map { $_->{path} } @{$full_targets} ],
        [ map { File::Spec->catfile($self->{gitdir}, $_) } @{$target_args} ],
        "Got expected full paths to target files for testing",
    );

    chdir $startdir or croak "Unable to return to $startdir";
}

#####

note("Block 4");

SKIP: {
    skip "No git checkout of dummyrepo found", 197
    unless (
        $ENV{PERL_DUMMYREPO_GIT_CHECKOUT_DIR}
            and
        (-d $ENV{PERL_DUMMYREPO_GIT_CHECKOUT_DIR})
    );
    my $startdir = cwd();
    chdir $ENV{PERL_DUMMYREPO_GIT_CHECKOUT_DIR}
        or croak "Unable to change to List-Compare checkout directory";

    my (%args, $params);
    my ($good_gitdir, $good_first, $good_last);
    my ($target_args, $full_targets);
    my ($rv, $all_outputs, $all_outputs_count, $expected_count, $first_element);

    # In this test file we'll use a different (newer) range of commits in the
    # 'dummyrepo' repository.  In this range there will exist 2 test files for
    # targeting.

    # So that we have a basis for comparison, we'll first run already tested
    # methods over the 'dummyrepo'.

    $good_gitdir = cwd();
    $good_first = 'd2bd2c75a2fd9afd3ac65a808eea2886d0e41d01';
    $good_last = '199494ee204dd78ed69490f9e54115b0e83e7d39';
    %args = (
        gitdir => $good_gitdir,
        first => $good_first,
        last => $good_last,
        verbose => 0,
        # Until development is complete, we will want to be able to inspect
        # files created in the outputdir.
        outputdir => tempdir( CLEANUP => 0 ),
    );
    $params = process_options(%args);
    $target_args = [
        File::Spec->catdir( qw| t 001_load.t | ),
        File::Spec->catdir( qw| t 002_add.t  | ),
    ];

    note("First object");

    my ($ACself, $ACtransitions);
    $ACself = Devel::Git::MultiBisect::AllCommits->new($params);
    ok($ACself, "new() returned true value");
    isa_ok($ACself, 'Devel::Git::MultiBisect::AllCommits');

    $full_targets = $ACself->set_targets($target_args);
    ok($full_targets, "set_targets() returned true value");
    is(ref($full_targets), 'ARRAY', "set_targets() returned array ref");
    is_deeply(
        [ map { $_->{path} } @{$full_targets} ],
        [ map { File::Spec->catfile($ACself->{gitdir}, $_) } @{$target_args} ],
        "Got expected full paths to target files for testing",
    );

    $all_outputs = $ACself->run_test_files_on_all_commits();
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
        scalar(@{$ACself->get_commits_range}) * scalar(@{$target_args}),
        "Got expected number of output files"
    );

    $rv = $ACself->get_digests_by_file_and_commit();
    ok($rv, "get_digests_by_file_and_commit() returned true value");
    is(ref($rv), 'HASH', "get_digests_by_file_and_commit() returned hash ref");
    cmp_ok(scalar(keys %{$rv}), '==', scalar(@{$target_args}),
        "Got expected number of elements: one for each of " . scalar(@{$target_args}) . " test files targeted");
    $first_element = first { $_ } keys %{$rv};
    is(ref($rv->{$first_element}), 'ARRAY', "Records are array references");
    is(
        scalar(@{$rv->{$first_element}}),
        scalar(@{$ACself->get_commits_range}),
        "Got 1 element for each of " . scalar(@{$ACself->get_commits_range}) . " commits"
    );
    is(ref($rv->{$first_element}->[0]), 'HASH', "Records are hash references");
    for my $k ( qw| commit file md5_hex | ) {
        ok(exists $rv->{$first_element}->[0]->{$k}, "Record has '$k' element");
    }

    $ACtransitions = $ACself->examine_transitions($rv);
    ok($ACtransitions, "examine_transitions() returned true value");
    is(ref($ACtransitions), 'HASH', "examine_transitions() returned hash ref");
    cmp_ok(scalar(keys %{$ACtransitions}), '==', scalar(@{$target_args}),
        "Got expected number of elements: one for each of " . scalar(@{$target_args}) . " test files targeted");
    $first_element = first { $_ } keys %{$ACtransitions};
    is(ref($ACtransitions->{$first_element}), 'ARRAY', "Records are array references");
    $expected_count = scalar(@{$ACself->get_commits_range}) - 1;
    is(
        scalar(@{$ACtransitions->{$first_element}}),
        $expected_count,
        "Got 1 element for each of $expected_count transitions between commits"
    );
    is(ref($ACtransitions->{$first_element}->[0]), 'HASH', "Records are hash references");
    for my $k ( qw| older newer compare | ) {
        ok(exists $ACtransitions->{$first_element}->[0]->{$k}, "Record has '$k' element");
    }

    #######################################

    note("Second object");

    my ($Tself, $Ttransitions, $commit_range, $idx, $initial_multisected_outputs, $initial_multisected_outputs_undef_count);
    my ($multisected_outputs, $timings);

    $Tself = Devel::Git::MultiBisect::Transitions->new({ %{$params}, verbose => 1 });
    ok($Tself, "new() returned true value");
    isa_ok($Tself, 'Devel::Git::MultiBisect::Transitions');

    $commit_range = $Tself->get_commits_range;

    $full_targets = $Tself->set_targets($target_args);
    ok($full_targets, "set_targets() returned true value");
    is(ref($full_targets), 'ARRAY', "set_targets() returned array ref");
    is_deeply(
        [ map { $_->{path} } @{$full_targets} ],
        [ map { File::Spec->catfile($Tself->{gitdir}, $_) } @{$target_args} ],
        "Got expected full paths to target files for testing",
    );

    note("_prepare_for_multisection()");

    # This method, while publicly available and therefore warranting testing, is
    # now called within multisect_all_targets() and only needs to be explicitly
    # called if, for some reason (e.g., testing), you wish to call
    # _multisect_one_target() by itself.

    {
        # error case: premature run of _multisect_one_target()
        local $@;
        eval { $rv = $Tself->_multisect_one_target(0); };
        like($@,
            qr/\QYou must run _prepare_for_multisection() before any stand-alone run of _multisect_one_target()\E/,
            "Got expected error message for premature _multisect_one_target()"
        );
    }

    $initial_multisected_outputs = $Tself->_prepare_for_multisection();
    ok($initial_multisected_outputs, "_prepare_for_multisection() returned true value");
    is(ref($initial_multisected_outputs), 'HASH', "_prepare_for_multisection() returned hash ref");
    for my $target (keys %{$initial_multisected_outputs}) {
        ok(defined $initial_multisected_outputs->{$target}->[0], "first element for $target is defined");
        ok(defined $initial_multisected_outputs->{$target}->[-1], "last element for $target is defined");
        is(ref($initial_multisected_outputs->{$target}->[0]), 'HASH', "first element for $target is a hash ref");
        is(ref($initial_multisected_outputs->{$target}->[-1]), 'HASH', "last element for $target is a hash ref");
        $initial_multisected_outputs_undef_count = 0;
        for my $idx (1 .. ($#{$initial_multisected_outputs->{$target}} - 1)) {
            $initial_multisected_outputs_undef_count++
                if defined $initial_multisected_outputs->{$target}->[$idx];
        }
        ok(! $initial_multisected_outputs_undef_count,
            "After _prepare_for_multisection(), internal elements for $target are all as yet undefined");
    }

    {
        {
            local $@;
            eval { my $rv = $Tself->_multisect_one_target(); };
            like($@, qr/Must supply index of test file within targets list/,
                "_multisect_one_target: got expected failure message for lack of argument");
        }
        {
            local $@;
            eval { my $rv = $Tself->_multisect_one_target('not a number'); };
            like($@, qr/Must supply index of test file within targets list/,
                "_multisect_one_target: got expected failure message for lack of argument");
        }
    }

    note("multisect_all_targets()");

    $rv = $Tself->multisect_all_targets();
    ok($rv, "multisect_all_targets() returned true value");
    $timings = $Tself->get_timings();
    ok(exists $timings->{elapsed}, "get_timings(): elapsed time recorded");
    ok(exists $timings->{runs},
        "get_timings(): number of runs recorded: $timings->{runs}");
    ok(exists $timings->{mean}, "get_timings(): mean time recorded");

    note("get_multisected_outputs()");

    $multisected_outputs = $Tself->get_multisected_outputs();
    is(ref($multisected_outputs), 'HASH',
        "get_multisected_outputs() returned hash reference");
    is(scalar(keys %{$multisected_outputs}), scalar(@{$target_args}),
        "get_multisected_outputs() has one element for each target");
    for my $target (keys %{$multisected_outputs}) {
        my @reports = @{$multisected_outputs->{$target}};
        is(scalar(@reports), scalar(@{$commit_range}),
            "Array for $target has " . scalar(@{$commit_range}) . " elements, as expected");
        for my $r (@reports) {
            ok(test_report($r),
                "Each element is either undefined or a hash ref with expected keys");
        }
    }

    note("inspect_transitions()");

    $Ttransitions = $Tself->inspect_transitions();
    is(ref($Ttransitions), 'HASH',
        "get_multisected_outputs() returned hash reference");
    is(scalar(keys %{$Ttransitions}), scalar(@{$target_args}),
        "get_multisected_outputs() has one element for each target");
    for my $target (keys %{$Ttransitions}) {
        for my $k ( qw| newest oldest transitions | ) {
            ok(exists $Ttransitions->{$target}->{$k},
                "Got '$k' element for '$target', as expected");
        }
        for my $k ( qw| newest oldest | ) {
            is(ref($Ttransitions->{$target}->{$k}), 'HASH',
                "Got hashref as value for '$k' for '$target'");
            for my $l ( qw| idx md5_hex file | ) {
                ok(exists $Ttransitions->{$target}->{$k}->{$l},
                    "Got key '$l' for '$k' for '$target'");
            }
        }
        is(ref($Ttransitions->{$target}->{transitions}), 'ARRAY',
            "Got arrayref as value for 'transitions' for $target");
        my @arr = @{$Ttransitions->{$target}->{transitions}};
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
    }

    note("Comparison of AllCommits vs. Transitions on same repository and commit range");

    my (%AC, %T);
    for my $target (sort keys %{$ACtransitions}) {
        for my $commit (@{$ACtransitions->{$target}}) {
            $AC{$commit->{newer}->{idx}}++
                if $commit->{compare} eq 'different';
        }
    }
    for my $target (sort keys %{$Ttransitions}) {
        for my $commit (@{$Ttransitions->{$target}->{transitions}}) {
            $T{$commit->{newer}->{idx}}++
        }
    }
    is_deeply(\%AC, \%T, "Same list of indexes of transitional commits via both classes");

    chdir $startdir or croak "Unable to return to $startdir";
}

note("Block 5");

SKIP: {
    skip "No git checkout of List-Compare found", 56
    unless (
        $ENV{PERL_LIST_COMPARE_GIT_CHECKOUT_DIR}
            and
        (-d $ENV{PERL_LIST_COMPARE_GIT_CHECKOUT_DIR})
    );
    my $startdir = cwd();
    chdir $ENV{PERL_LIST_COMPARE_GIT_CHECKOUT_DIR}
        or croak "Unable to change to List-Compare checkout directory";

    note("Using Devel::Git::MultiBisect::Transitions on a commit range with no transitions");

    my (%args, $params);
    my ($good_gitdir, $good_last);
    my ($target_args, $full_targets);
    my ($rv);

    my ($self, $good_last_before, $transitions);
    my ($multisected_outputs);

    $good_gitdir = cwd();
    $good_last_before = '2614b2c2f1e4c10fe297acbbea60cf30e457e7af';
    $good_last = 'd304a207329e6bd7e62354df4f561d9a7ce1c8c2';
    %args = (
        gitdir => $good_gitdir,
        last_before => $good_last_before,
        last => $good_last,
        # Until development is complete, we will want to be able to inspect
        # files created in the outputdir.
        outputdir => tempdir( CLEANUP => 0 ),
    );
    $params = process_options(%args);

    $self = Devel::Git::MultiBisect::Transitions->new($params);
    ok($self, "new() returned true value");
    isa_ok($self, 'Devel::Git::MultiBisect::Transitions');

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

    $rv = $self->multisect_all_targets();
    ok($rv, "multisect_all_targets() returned true value");

    note("get_multisected_outputs()");

    $multisected_outputs = $self->get_multisected_outputs();
    is(ref($multisected_outputs), 'HASH',
        "get_multisected_outputs() returned hash reference");
    is(scalar(keys %{$multisected_outputs}), scalar(@{$target_args}),
        "get_multisected_outputs() has one element for each target");
    for my $target (keys %{$multisected_outputs}) {
        my @reports = @{$multisected_outputs->{$target}};
        for my $r (@reports) {
            ok(test_report($r),
                "Each element is either undefined or a hash ref with expected keys");
        }
    }

    $transitions = $self->inspect_transitions();
    is(ref($transitions), 'HASH',
        "get_multisected_outputs() returned hash reference");
    is(scalar(keys %{$transitions}), scalar(@{$target_args}),
        "get_multisected_outputs() has one element for each target");
    for my $target (keys %{$transitions}) {
        for my $k ( qw| newest oldest transitions | ) {
            ok(exists $transitions->{$target}->{$k},
                "Got '$k' element for '$target', as expected");
        }
        for my $k ( qw| newest oldest | ) {
            is(ref($transitions->{$target}->{$k}), 'HASH',
                "Got hashref as value for '$k' for '$target'");
            for my $l ( qw| idx md5_hex file | ) {
                ok(exists $transitions->{$target}->{$k}->{$l},
                    "Got key '$l' for '$k' for '$target'");
            }
        }
        is(ref($transitions->{$target}->{transitions}), 'ARRAY',
            "Got arrayref as value for 'transitions' for $target");
        ok(! scalar(@{$transitions->{$target}->{transitions}}),
            "There were no changes for '$target' in commit range, hence no transitions");
    }

    chdir $startdir or croak "Unable to return to $startdir";
}

__END__
