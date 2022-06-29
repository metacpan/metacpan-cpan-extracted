#!/usr/bin/env perl
# PHASE THREE: nuggits_ops.pl extended testing. Including Pull, Checkout, and Merge
use Test2::V0;
use Test2::Plugin::BailOnFail; # TODO: Can we set per-subtest instead?
use strict;
use warnings;
use v5.10;
use File::Slurp qw(read_file write_file edit_file append_file edit_file_lines);
use FindBin;
use Cwd qw(getcwd);
use lib $FindBin::Bin; # Add local test lib to path
use TestDriver;
use Git::Nuggit::Status; # Invoke Nuggit Status function directly (functions are procedural and self-containd)

# Format: name, function, optional arguments
my @tests = (
    # Checkout Safe functions
    ["Safe checkout validations", \&test_safe_exist],
    ["Verify clone/safe-checkout when submodule is on a different branch", \&clone_default_branch_test],
    ["Detached HEAD handling", \&detached_test],

    # TODO: Submodule deletion tests, including status+checkout+commit behavior when deletion is unstaged
    
    # Create Branch Cases (currently implicit in merge casese)

    # Checkout Branch Cases, ref-first model

    # Checkout Branch Cases, commit-first model

    ## Merge Cases
    ["Basic Merge (ref-first) Test of Root, No conflicts", \&base_merge_test0],
    ["Basic Merge (ref-first) Test of Root, Conflict requiring user-intervention", \&base_merge_test1],
    
    # Simple merge, no conflicts
    ["Simple Merge", \&merge_test1],
    ["Simple Merge with conflict resolution", \&merge_test2],
    
    # Simple merge, auto-resolvable conflicts
    # Merge with manual resolution in submodule
    # Merge with submodule conflict
    
    # Pull Cases
    ["Simple Pull", \&pull_test],

    # Repeat all ops-focused tests for ref-first
    ["Basic Merge (branch-first) Test of Root, No conflicts", \&base_merge_test0, 1],
    ["Basic Merge (branch-first) Test of Root, Conflict requiring user-intervention", \&base_merge_test1, 1],
    ["Simple Merge (branch-first)", \&merge_test1, 1],
    ["Simple Merge (branch-first) with conflict resolution", \&merge_test2, 1],

    
   );


# Initialize Driver.  This function will also automaticallly parse command-line arguments
# TODO: If this script needs to parse arguments, ensure Getoptions is configured appropriately for multi-passes

my $drv = new TestDriver(\@tests); # Setup

$drv->begin(); # Initialize

$drv->run(); # Run

# Simple Merge, no conflict, root only
sub base_merge_test0 {
    my $branch1 = "master";
    my $branch2 = "branch2";
    my $fn1 = "README.md";
    my $fn2 = "test.md"; # A new file
    my $msg1 = "Root file write, branch2";
    my $msg2 = "This is a new file";
    my $mode_flag = (shift) ? "--branch-first": ""; # If parameter was given, run test in ref-first mode

    # This is a single-user test
    # This function will clone a particular repo (in the tmptest/tests/user1), in simulation of a particular developer.
    #    root
    #       @SM1
    #       @SM2
    #            @SM3
    my $user = $drv->create_user("user1");

    ## Setup
    # Create a new branch from current point
    ok($drv->cmd("ngt checkout $mode_flag -b $branch2"), "Checkout $branch2");

    # Make a set of non-conflicting changes in first branch
    $drv->test_write({msg => $msg1, fn => $fn1});

    # Switch to second branch and make set of non-conflicting changees
    ok($drv->cmd("ngt checkout $mode_flag $branch1"), "Run Ngt checkout $branch1");
    $drv->create_file($fn2, $msg2);

    # Merge
    ok($drv->cmd("ngt merge $mode_flag $branch2"));

    # Verify status
    my $status = get_status();
    ok( status_check($status) );

    # Verify file contents
    my @lines;
    ok( (@lines = read_file($fn1, chomp => 1))[-1] eq $msg1, "$fn1 ends with expected line");
    ok( (@lines = read_file($fn2, chomp => 1))[-1] eq $msg2, "$fn2 ends with expected line");


    done_testing;
}
# Simple Merge with conflict, root only
sub base_merge_test1 {
    my $branch1 = "master";
    my $branch2 = "branch2";
    my $fn1 = "README.md";
    my $fn2 = $fn1; # A deliberate conflict
    my $msg1 = "Root file write, branch2";
    my $msg2 = "This is a conflicting change";
    my $mode_flag = (shift) ? "--branch-first": ""; # If parameter was given, run test in ref-first mode

    # This is a single-user test
    my $user = $drv->create_user("user1");

    ## Setup
    # Create a new branch from current point
    ok($drv->cmd("ngt checkout $mode_flag -b $branch2"), "Checkout $branch2");

    # Make a set of non-conflicting changes in first branch
    $drv->test_write({msg => $msg1, fn => $fn1});

    # Switch to second branch and make set of non-conflicting changees
    ok($drv->cmd("ngt checkout $mode_flag $branch1"), "Run Ngt checkout $branch1");

    ok($drv->create_file($fn2, $msg2));

    # Merge
    ok(dies{($drv->cmd("ngt merge $mode_flag $branch2"), "Expect merge conflict");});

    # Verify status
    my $status = get_status();
    ok( $status->{status} == STATE('CONFLICT') );

    # Verify Conflict file exists (we now save conflict state even if only in root)
    ok(-e ".nuggit/merge_conflict", "conflict file exists");

    # Conflict resolution does not need to be farther tested in this case
    
    done_testing;
}


# Simple Merge test, no conflicts
sub merge_test1 {
    my $branch1 = "master";
    my $branch2 = "branch2";
    my $fn1 = "README.md";
    my $fn2 = "sub2/README.md";
    my $fn3 = "sub1/sub3/README.md";
    # This is a single-user test
    my $user = $drv->create_user("user1");
    my $mode_flag = (shift) ? "--branch-first": ""; # If parameter was given, run test in ref-first mode

    ## Setup
    # Create a new branch from current point
    ok($drv->cmd("ngt checkout $mode_flag -b $branch2"), "Created branch $branch2");

    # But first verify post-checkout status in detail
    subtest "Validate Checkout Status" => sub {
        my $status = get_status({'all' => 1});
        ok( $status->{status} == STATE('CLEAN'), "Status is clean after changing branches" );
        ok( $status->{unstaged_files_cnt} == 0 && $status->{staged_files_cnt}==0, "No untracked files or refs" );
        ok( !$status->{detached_heads_flag}, "No detached heads");
        ok( $status->{branch_status_flag} == 0, "No detached heads or submodules on wrong branch" );
    };
    
    # Make a set of non-conflicting changes in first branch
    my $msg1 = $drv->test_write({title => "Root file write, branch2", fn => $fn1});
    my $msg2 = $drv->test_write({title => "Sub3 file write, branch2", fn => $fn2});

    # Switch to second branch and make set of non-conflicting changees
    ok($drv->cmd("ngt checkout $mode_flag $branch1"));

    # But first verify post-checkout status in detail
    subtest "Validate Checkout Status" => sub {
        my $status = get_status({'all' => 1});
        ok( $status->{status} == STATE('CLEAN'), "Status is clean after changing branches" );
        ok( $status->{unstaged_files_cnt} == 0 && $status->{staged_files_cnt}==0, "No untracked files or refs" );
        ok( !$status->{detached_heads_flag}, "No detached heads");
        ok( $status->{branch_status_flag} == 0, "No detached heads or submodules on wrong branch" );
    };
    
    my $msg3 = $drv->test_write({title => "Sub3 file write, branch1", fn => $fn3});
       
    # Merge
    ok($drv->cmd("ngt merge $mode_flag $branch2")); # TODO: Flag for testing with rebase and/or branch-first

    # Verify status
    my $status = get_status();
    ok( status_check($status) );

    # Verify file contents
    my @lines;
    ok( (@lines = read_file($fn1, chomp => 1))[-1] eq $msg1, "$fn1 ends with expected line");
    ok( (@lines = read_file($fn2, chomp => 1))[-1] eq $msg2, "$fn2 ends with expected line");
    ok( (@lines = read_file($fn3, chomp => 1))[-1] eq $msg3, "$fn3 ends with expected line");
    done_testing;
}

# Simple Merge test with conflicts, single-user
sub merge_test2 {
    my $branch1 = "master";
    my $branch2 = "branch2";
    my $fn1 = "README.md";
    my $fn2 = "sub1/sub3/README.md";
    my ($msg1, $msg2, $msg3);
    my $mode_flag = (shift) ? "--branch-first": ""; # If parameter was given, run test in ref-first mode

    # This is a single-user test
    my $user = $drv->create_user("user1");

    ## Setup
    subtest "Write content in branch $branch2" => sub {
        # Create a new branch from current point
        ok($drv->cmd("ngt checkout $mode_flag -b $branch2"), "Created branch $branch2");

        # But first verify post-checkout status in detail
        subtest "Validate Checkout Status" => sub { # TODO: convert to drv fn
            my $status = get_status({'all' => 1});
            ok( $status->{status} == STATE('CLEAN'), "Status is clean after changing branches" );
            ok( $status->{unstaged_files_cnt} == 0 && $status->{staged_files_cnt}==0, "No untracked files or refs" );
            ok( !$status->{detached_heads_flag}, "No detached heads");
            ok( $status->{branch_status_flag} == 0, "No detached heads or submodules on wrong branch" );
        };
    
        # Make a set of non-conflicting changes in first branch
        $msg1 = $drv->test_write({title => "Root file write, branch2", fn => $fn1});
        $msg2 = $drv->test_write({title => "Sub3 file write, branch2", fn => $fn2});
    };

    subtest "Write conflicting content in $branch1" => sub {
        # Switch to second branch and make set of non-conflicting changees
        ok($drv->cmd("ngt checkout $mode_flag $branch1"));

        # But first verify post-checkout status in detail
        subtest "Validate Checkout Status" => sub {
            my $status = get_status({'all' => 1});
            ok( $status->{status} == STATE('CLEAN'), "Status is clean after changing branches" );
            ok( $status->{unstaged_files_cnt} == 0 && $status->{staged_files_cnt}==0, "No untracked files or refs" );
            ok( !$status->{detached_heads_flag}, "No detached heads");
            ok( $status->{branch_status_flag} == 0, "No detached heads or submodules on wrong branch" );
        };
    
        $msg3 = $drv->test_write({title => "Sub3 file write, branch1", fn => $fn2});
    };

    subtest "Merge and resolve conflict" => sub {
        # Merge
        # TODO: Flag for testing with rebase and/or branch-first
        ok(dies{$drv->cmd("ngt merge $mode_flag $branch2")}); 

        # Verify conflicted stqtus status
        ok(-e '.nuggit/merge_conflict', 'Merge Conflict config file exists');
        my $status = get_status();
        is( $status->{status}, STATE('CONFLICT'), "Repository in conflicted state");
        is( file_status($status, $fn2)->{status}, STATE('CONFLICT'), "$fn2 in conflict state" );

        # Verify merge continue fails if we haven't resolved errors
        ok(dies{$drv->cmd("ngt merge --continue --no-edit")}, "Merge continue fails if we haven't resolved file conflicts");

        # Edit file (remove any line starting with << == or >> for easy simulated resolution)
        edit_file_lines { $_ = '' if /^[=<>]+/ } $fn2;
        ok($drv->cmd("ngt add $fn2"), "Add conflicted file");

        ok(dies {
            $drv->cmd("ngt commit -m \"Commit with conflict should fail\"");
        }, "Commit with unresolved conflict should fail");
        ok($drv->cmd("ngt merge --continue --no-edit"));

        
        # Verify file contents
        my @lines;
        ok( (@lines = read_file($fn1, chomp => 1))[-1] eq $msg1, "$fn1 ends with expected line");
        @lines = read_file($fn2, chomp => 1);
        is ($lines[-1], $msg2, "fn2 ends with expected line");
        is ($lines[-2], $msg3, "fn2 line -2 matches expected input");

        # TODO: Verify undo commit with 'ngt checkout HEAD~1' -- ref-first mode only
        
    };
    done_testing;
}


# TODO: Multi-user merge conflict test

# TODO: Multi-user test, pull new submodule
# TODO: Submodule addition, changing branches
# TODO: Conflict in submodule reference.  Handling should be automatic for ref-first mode
# TODO: Conflict in submodule creation/deletion.  Defer for now


sub pull_test {
    my $branch1 = "master";
    my $branch2 = "branch2";
    my $fn1 = "README.md";
    my $fn2 = "sub2/README.md";
    my $fn3 = "sub1/sub3/README.md";
    # This is a single-user test
    my $user = $drv->create_user("user1");
    my $user2 = $drv->create_user("user2");

    # Make a set of non-conflicting changes in user1 and push
    $drv->cd_user('user1');
    my $msg1 = $drv->test_write({title => "Root file write, user1", fn => $fn1});
    my $msg2 = $drv->test_write({title => "Sub3 file write, user2", fn => $fn2});
    # Note: test_write automatically invokes push

    # Switch to second user and make set of non-conflicting changees
    $drv->cd_user('user2');    
    my $msg3 = $drv->test_write({title => "Sub3 file write, user2", fn => $fn3, 'skip_push' => 1});
       
    # Pull/Merge
    ok($drv->cmd("ngt pull --no-edit"));

    subtest "Validate Checkout Status" => sub {
        my $status = get_status({'all' => 1});
        ok( $status->{status} == STATE('CLEAN'), "Status is clean after changing branches" );
        ok( $status->{unstaged_files_cnt} == 0 && $status->{staged_files_cnt}==0, "No untracked files or refs" );
        ok( !$status->{detached_heads_flag}, "No detached heads");
        ok( $status->{branch_status_flag} == 0, "No detached heads or submodules on wrong branch" );
    };

    
    # Verify status
    my $status = get_status();
    ok( status_check($status) );

    # Verify file contents
    my $verify = sub {
        my @lines;
        ok( (@lines = read_file($fn1, chomp => 1))[-1] eq $msg1, "$fn1 ends with expected line");
        ok( (@lines = read_file($fn2, chomp => 1))[-1] eq $msg2, "$fn2 ends with expected line");
        ok( (@lines = read_file($fn3, chomp => 1))[-1] eq $msg3, "$fn3 ends with expected line");
        done_testing;
    };
    subtest "Verify content after pull for user2" => $verify;

    # Push changes from user2 and pull from user1
    ok( $drv->cmd("ngt push") );

    $drv->cd_user("user1");
    ok( $drv->cmd("ngt pull --no-edit") );
    subtest "Verify content after pull for user1" => $verify;
}

sub test_safe_exist
{
    # Create user1 && user1 ngt instance [$ngt object does not preserve state relevant to this fn to require re-init]
    my $user1 = $drv->create_user("user1");

    # 1. Verify current branch (default/master) is safe to checkout

    # Create new branch1 (manually) from current point

    # 2. Verify new branch1 is safe to checkout

    # Create a test commit on master
    $drv->test_write({title => "Add commit on master", fn => "README.md"});

    # 3a. Verify new branch1 is NOT safe to checkout

    # Checkout new branch2

    # 3b. Verify branch1 is NOT safe to checkout

    # 4a. Verify a branch3 that does not exist returns error if autocreate=0

    # 4b. Verify a branch3 that does not exist is created and checked out if autocreate=1

    # Note: At this point branch1 -> master, branch2, branch3

    ## Remote Tests
    # Create user2 and user2 ngt instancek 
    # User1 pushes changes (new branches, and commits on master)

    # User2 fetches changes.  New branches will exist remotely, and master will be a commit behind

    # 4c. User2 - Verify master is still safe to checkout (despite remote being ahead)
    # 5. User2 - Verify branch2 (does not exist locally) is safe to checkout, and do so
    # User2 - Verify branch1 is NOT safe to checkout
    # Checkout branch1
    # 6. Verify branch3 (does not exist locallly, remote is ahead) is NOT safe to checkout

    # User1 pulls master into branch1 (ff-merge) and pushes
    # User2 fetches
    # 7. User2 verified branch1 is NOT safe to checkout (from local), but reports that remote is
       # Current behavior will be to warn user for manual correction - consider automated handling later.

    done_testing;
}


# NOTE: May need to test case where a submodule is explicitly on a different branch than root
#  Verify that said branch differs from master, then do a fresh clone and verify state
sub clone_default_branch_test {
    # Test reliability of cloning a repository where at least one submodule is on a different branch than root
    my $branch1 = "master";
    my $branch2 = "branch2";
    my $child_branch = "child/branch";
    my $msg1 = "Sub2 write on $child_branch";
    my $fn1 = "sub2/README.md";
    my $fn2 = "sub1/README.md";
    my $msg2 = "Sub1 write for branch clone verification";

    # Create first user
    my $user1 = $drv->create_user("user1");

    # Create new branch for a single submodule
    subtest "Create branch in single submodule" => sub {
        $drv->cd_user('user1');
        
        ok(chdir("sub2"));
        $drv->cmd("git checkout -b $child_branch");
        
        # Set $child_branch as tracking branch (updates .gitmodules)
        $drv->cd_user('user1');
        $drv->cmd("git submodule set-branch --branch $child_branch sub2");
        $drv->cmd('ngt commit -am "Updated tracking branch"');

        # Update a file. Note: Ngt normally disallows commits to submodules on different branches unless explicitly ignored
        $drv->test_write({msg => $msg1, fn => $fn1, no_branch_check => 1});
    };

    subtest "Verify Clone has expected state" => sub {
        # Create second user, cloning specified branch
        #  Note: create_user fn will automatically verify that there are no DETACHED HEADs
        my $user2 = $drv->create_user("user2", {skip_branch_check => 1});

        # TODO: Verify both user dirs are at the same commit

        # Verify we have correct file/contents
        my @lines;
        ok( (@lines = read_file($fn1, chomp => 1))[-1] eq $msg1, "$fn1 ends with expected line");

        # Verify State is clean
        my $status = get_status({'all' => 1});
        ok( status_check($status) );

        # Verify sub1 and sub3 are on master, and sub2 is on $child_branch
        ok( $status->{branch_status_flag} == 1, "Verify one or more submodules reported as on different branches");
        ok( $status->{objects}->{sub2}->{'branch.head'} eq $child_branch, "Verify child branch is on expected non-standard branch $child_branch");

    };

    # Create a new branch off master in user1 and push.
    #  Expect sub2 to be on the default $child_branch
    subtest "Verify behavior on clone of alt branch" => sub {
        $drv->cd_user("user1");
        
        # Create new branch
        $drv->cmd("ngt checkout -b $branch2");
        $drv->test_write({msg => $msg2, fn => $fn2});
        
        # Create a new user on new branch. Let create_user verify clean slate and consistent branches
        my $user3 = $drv->create_user("user3", {branch => $branch2});

        # Switch back to branch1 in user3 and verify state
        $drv->cd_user("user3");
        $drv->cmd("ngt checkout $branch1");
        my $status = get_status({'all' => 1});
        ok( status_check($status) );
        ok( $status->{branch_status_flag} == 1, "Verify one or more submodules reported as on different branches");
        ok( $status->{objects}->{sub2}->{'branch.head'} eq $child_branch, "Verify child branch is on expected non-standard branch $child_branch");
        
        
    };

    # Delete 'master' in non-default sub2, then switch to master branch and verify state
    # This is a contrived extension of above test to reproduce an observed bug
    subtest "Contrived Case of deleted local master with ref-first checkout of tracking branch" => sub {
        # Go back to user1, which is still on $branch2
        $drv->cd_user("user1");
        ok( chdir("sub2") );
        $drv->cmd("git branch -d $branch1");

        # Checkout master branch, which should automatically invoke 'checkout --safe' in ref-first mode
        $drv->cmd("ngt checkout $branch1");
        chdir(".."); # Go up a directory.  get_status() by design does not automatically upcurse
        my $status = get_status({'all' => 1});
        ok( status_check($status) );
        ok( $status->{branch_status_flag} == 1, "Verify one or more submodules reported as on different branches");
        ok( $status->{objects}->{sub2}->{'branch.head'} eq $child_branch, "Verify child branch is on expected non-standard branch $child_branch");
        
    };
}

sub detached_test
{
    my $fn1 = "sub1/README.md";
    my $msg1 = "A detached commit";
    
    # TODO: Consider extending with second user to test clone behavior with out-of-sync references
    my $user = $drv->create_user("user1");

    # Get root repo current SHA
    #  Available as $status->{'branch.oid'}
    my $status = get_status({'all' => 1});
    
    # Make a commit
    $drv->test_write({msg => $msg1, fn => $fn1});

    # Checkout original commit at root.
    $drv->cmd("ngt checkout ".$status->{'branch.oid'});

    # Verify status
    # Expect detached HEAD in root and sub1, original (master) branch in sub2 and sub3
    $status = get_status({'all' => 1});

    ok( $status->{branch_status_flag} == 1, "Verify overall status indicates submodules on different branches");
    ok( $status->{detached_heads_flag} > 0, "Verify detached head flag is set");
    ok( $status->{objects}->{sub1}->{'branch.head'} eq '(detached)', "Verify sub1 is detached");
    
}
