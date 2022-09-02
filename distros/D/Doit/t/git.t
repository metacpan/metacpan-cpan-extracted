#!/usr/bin/perl -w
# -*- cperl -*-

#
# Author: Slaven Rezic
#

use strict;
use FindBin;
use lib $FindBin::RealBin;

use Cwd qw(realpath getcwd);
use File::Temp qw(tempdir);
use Test::More;

use Doit;
use Doit::Util qw(in_directory);

use TestUtil qw(is_dir_eq);

my $d = Doit->init;

if (!$d->which('git')) {
    plan skip_all => 'git not in PATH';
}

plan 'no_plan';

$d->add_component('git');

my $git_less_directory;
if (-d '/' && !-d '/.git') {
    $git_less_directory = '/';
}

# Unset most GIT_* environment variables
for my $git_key (sort keys %ENV) {
    next if $git_key !~ m{^GIT_};
    # These are OK
    next if $git_key =~ m{^GIT_(
			      AUTHOR_.*
			  |   COMMITTER_.*
			  |   EDITOR
			  |   PAGER
			  |   DIFF_.*
			  |   EXTERNAL_DIFF
			  |   MERGE_VERBOSITY
			  |   SSH
			  |   ASKPASS
			  |   CONFIG_NOSYSTEM
			  |   FLUSH
			  |   TRACE.*
			  |   .*_PATHSPECS
			  |   REFLOG_ACTION
			  )$}x;
    $d->unsetenv($git_key);
}

# realpath() needed on darwin (/private/tmp vs. /tmp)
my $dir = realpath(tempdir('doit-git-XXXXXXXX', CLEANUP => 1, TMPDIR => 1));

# A private git-short-status script; should behave the same as the git_short_status command.
my $my_git_short_status;
if ($ENV{HOME} && -x "$ENV{HOME}/bin/sh/git-short-status") {
    $my_git_short_status = "$ENV{HOME}/bin/sh/git-short-status";
}

######################################################################
# Tests with the Doit repository (if checked out)
SKIP: {
#    skip "git_short_status does not work as expected (TODO)" if $ENV{GITHUB_ACTIONS}; # this does not seem to work if git-lfs is in use, which is the default with actions/checkout@v1 and may be configured with actions/checkout@v2, but is not currently
    my $self_git = eval { $d->git_root };
    skip "Not a git checkout", 1 if !$self_git;
    skip "Current git checkout is not the Doit git checkout", 1 # ... but probably a git directory in an upper directory
	if realpath("$FindBin::RealBin/..") ne realpath($self_git);
    skip "shallow repositories cannot be cloned", 1 if $d->git_is_shallow;

    my $workdir = "$dir/doit";

    run_tests($self_git, $workdir);
}

######################################################################
# Error cases
for my $meth (qw(git_repo_update git_short_status git_root git_get_commit_hash git_get_commit_files git_get_changed_files git_is_shallow git_current_branch git_config)) {
    eval { $d->$meth('unhandled-option' => 1) };
    like $@, qr{ERROR.*Unhandled options: unhandled-option}, "unhandled option in method $meth";
}

eval {
    $d->git_repo_update(
			repository => '/repo1',
			directory  => '/repo2',
			refresh    => 'invalid',
		       );
};
like $@, qr{ERROR.*refresh may be 'always' or 'never' at };

eval { $d->git_short_status('untracked_files' => 'blubber') };
like $@, qr{ERROR.*only values 'normal' or 'no' supported for untracked_files};

eval { $d->git_get_commit_files(directory => '/non-existent-directory') };
like $@, qr{ERROR.*Can't chdir to /non-existent-directory};

SKIP: {
    my @methods = qw(git_short_status git_root git_get_commit_hash git_get_commit_files git_get_changed_files git_is_shallow git_current_branch);
    skip "No git-less directory available", 2*scalar(@methods)
	if !defined $git_less_directory;
    for my $meth (@methods) {
	ok !eval { $d->$meth(directory => $git_less_directory); 1 }, "method $meth failed on non-git directory";
	in_directory {
	    ok !eval { $d->$meth; 1 }, "method $meth failed on non-git directory (using cwd)";
	} $git_less_directory;
    }
}

######################################################################
# Tests with a freshly created git repository
{
    my $workdir = "$dir/newworkdir";
    $d->mkdir($workdir);
    chdir $workdir or die "chdir failed: $!";
    $d->system(qw(git init));

    # after init checks
    is_dir_eq $d->git_root, $workdir, 'git_root in root directory';
    is_dir_eq $d->git_root(directory => getcwd), $workdir, 'git_root with directory option';
    is_deeply [$d->git_get_changed_files], [], 'no changed files in fresh empty directory';
    is_deeply [$d->git_get_changed_files(ignore_untracked => 1)], [], 'no changed files in fresh empty directory, also with ignore_untracked';
    git_short_status_check(                         $d, '', 'empty directory, not dirty');
    git_short_status_check({untracked_files=>'no'}, $d, '', 'empty directory, not dirty');
    is $d->git_current_branch, 'master';

    is $d->git_short_status, '', 'git_short_status without directory';

    # dirty
    $d->touch('testfile');
    is_deeply [$d->git_get_changed_files], ['testfile'], 'new file detected';
    is_deeply [$d->git_get_changed_files(ignore_untracked => 1)], [], 'untracked file ignored';
    git_short_status_check(                         $d, '*', 'untracked file detected');
    git_short_status_check({untracked_files=>'no'}, $d, '',  'no detection of untracked files');

    # git-add
    $d->system(qw(git add testfile));
    is_deeply [$d->git_get_changed_files], ['testfile'], 'added, but not committed file detected';
    git_short_status_check(                         $d, '<<', 'uncommitted file detected');
    git_short_status_check({untracked_files=>'no'}, $d, '<<', 'uncommitted file detected');

    is $d->git_short_status, '<<', 'git_short_status without directory';

    # untracked file
    $d->touch('untracked-file');
    ok((grep { $_ eq 'testfile'       } $d->git_get_changed_files), 'added, but not committed file detected');
    ok((grep { $_ eq 'untracked-file' } $d->git_get_changed_files), 'untracked file detected');
    git_short_status_check(                         $d, '<<*', 'uncommitted and untracked files detected');
    git_short_status_check({untracked_files=>'no'}, $d, '<<',  'no detection of untracked files');
    $d->unlink('untracked-file');

    # git-commit
    _git_commit_with_author('test commit');
    is_deeply [$d->git_get_changed_files], [], 'no changed files after commit';
    is_deeply [$d->git_get_commit_files], ['testfile'], 'git_get_commit_files';
    is_deeply [$d->git_get_commit_files(commit => 'HEAD')], ['testfile'], 'git_get_commit_files with explicit commit';
    git_short_status_check(                         $d, '', "there's no upstream, so no '<'");
    git_short_status_check({untracked_files=>'no'}, $d, '', "there's no upstream, so no '<'");

    $d->touch('multiple-files-1');
    $d->touch('multiple-files-2');
    $d->system(qw(git add multiple-files-1 multiple-files-2));
    _git_commit_with_author('two files in commit');
    is_deeply [$d->git_get_commit_files], [qw(multiple-files-1 multiple-files-2)], 'git_get_commit_files with multiple files';

    # changed file
    $d->change_file('testfile', {add_if_missing => 'some content'});
    git_short_status_check(                         $d, '<<', 'dirty after change');
    git_short_status_check({untracked_files=>'no'}, $d, '<<', 'dirty after change');

    $d->system(qw(git add testfile));
    _git_commit_with_author('actually some content');
    git_short_status_check(                         $d, '', 'freshly committed');
    git_short_status_check({untracked_files=>'no'}, $d, '', 'freshly committed');

    my $workdir2 = "$dir/newworkdir2";
    run_tests($workdir, $workdir2);

    $d->mkdir('subdir');
    in_directory {
	is_dir_eq $d->git_root, $workdir, 'git_root in subdirectory';
    } 'subdir';
    is_dir_eq $d->git_root(directory => getcwd . '/subdir'), $workdir, 'git_root with directory option set to subdirectory';

    Doit::Util::in_directory(sub {
	is_dir_eq $d->git_root, $workdir, 'in_directory call without prototype';
    }, 'subdir');

    # git_config
    eval {
	$d->git_config(key => "test.key", val => "test.val", unset => 1);
    };
    like $@, qr{ERROR.*Don't specify both 'unset' and 'val'};
    is $d->git_config(key => "test.key"), undef, 'config key does not exist yet';
    is $d->git_config(key => "test.key", val => "test.val"), 1, 'there was a change';
    is $d->git_config(key => "test.key"), "test.val", 'config key now exists';
    is $d->git_config(key => "test.key", val => "test.val2"), 1, 'there was a change';
    is $d->git_config(key => "test.key"), "test.val2", 'config key now changed';
    is $d->git_config(key => "test.key", val => "test.val2"), 0, 'test.key was not changed';
    is $d->git_config(key => "test.key"), "test.val2", 'nothing changed now';
    is $d->git_config(key => "test.key", directory => getcwd), "test.val2", 'with directory option';
    is $d->git_config(key => "test.key", unset => 1), 1, 'there was a change';
    is $d->git_config(key => "test.key"), undef, 'config key was removed';
    is $d->git_config(key => "test.key", unset => 1), 0, ' no change, key was already unset';
    is $d->git_config(key => "test.key"), undef, 'config key is still removed';
    eval { $d->git_config(key => 'i n v a l i d.key', val => "test.val3") };
    like $@, qr{Command exited with exit code};
 SKIP: {
	skip "No git-less directory available", 1 if !defined $git_less_directory;
	eval { $d->git_config(key => "non-exis.tent-key", val => "test.val4", directory => $git_less_directory) };
	like $@, qr{Command exited with exit code};
    }
    is $d->git_config(key => "test.with.newlines", val => "line1\nline2\line3\n"), 1, 'newline key was added';
    is $d->git_config(key => "test.with.newlines"),       "line1\nline2\line3\n", 'we can deal with newlines';
    is $d->git_config(key => "test.with.newlines", val => "line1\nline2\line3\another line\n"), 1, 'newline key was changed';
    is $d->git_config(key => "test.with.newlines"),       "line1\nline2\line3\another line\n", 'last change was successful';

    # various clone tests
    is $d->git_repo_update(
			   repository => "$workdir/.git",
			   repository_aliases => [$workdir],
			   directory => $workdir2,
			  ), 0, "handling repository_aliases";
    ok !$d->git_is_shallow(directory => $workdir2), 'cloned directory is not shallow';

    for my $default_branch_method_def (
	[[qw(symbolic-ref remote)]],
	['symbolic-ref',   'may-fail'],
	['remote'],
	[],
	['does-not-exist', 'expect-fail'],
    ) {
	my($default_branch_method, $possible_fail) = @$default_branch_method_def;
	my @args = (
	    directory => $workdir2,
	    method    => $default_branch_method,
	);
	if ($possible_fail) {
	    my $res = eval { $d->git_get_default_branch(@args) };
	    if ($possible_fail eq 'may-fail') {
		if (!$@) {
		    like $res, qr{^(master|main)$};
		}
	    } else {
		like $@, qr{Unhandled git_get_default_branch method 'does-not-exist'}, 'got error for unhandled method';
	    }
	} else {
	    like $d->git_get_default_branch(@args), qr{^(master|main)$}, "git_get_default_branch with method " . (!defined $default_branch_method ? "undef" : ref $default_branch_method eq 'ARRAY' ? join(", ", @$default_branch_method) : $default_branch_method);
	}
    }

    is $d->git_repo_update(
			   repository => $workdir,
			   repository_aliases => ["unused-repository-alias"],
			   directory => $workdir2,
			  ), 0, "unused repository_aliases";

    eval {
	$d->git_repo_update(
			    repository => "another-remote-url",
			    directory => $workdir2,
			   );
    };
    like $@, qr{ERROR:.*remote origin does not point to};

    eval {
	$d->git_repo_update(
			    repository => "another-remote-url",
			    repository_aliases => ['more-unmatching-aliases'],
			    directory => $workdir2,
			   );
    };
    like $@, qr{ERROR:.*remote origin does not point to.*or any of the following aliases: more-unmatching-aliases};

    eval {
	$d->git_get_commit_files(
				 directory => $workdir2,
				 commit => 'this-commit-does-not-exist',
				);
    };
    like $@, qr{ERROR.*Error while running git show this-commit-does-not-exist};

    $d->mkdir("$dir/empty_exists");
    $d->git_repo_update(repository => "$workdir/.git", directory => "$dir/empty_exists");
    ok -d "$dir/empty_exists/.git";

    {
	my $workdir3 = "$dir/newworkdir3";
	is $d->git_repo_update(
			       repository => "$workdir/.git",
			       origin     => 'my_origin',
			       directory  => $workdir3,
			      ), 1, "origin option";
	in_directory {
	    is $d->git_config(key => 'remote.my_origin.url'), "$workdir/.git", 'my_origin remote exists';
	    ok !$d->git_config(key => 'remote.origin.url'),    'no origin remote';
	} $workdir3;

	is $d->git_repo_update(
			       repository => $workdir2,
			       origin     => 'my_origin',
			       directory  => $workdir3,
			       allow_remote_url_change => 1,
			      ), 1, "allow_remote_url_change";
	in_directory {
	    is $d->git_config(key => 'remote.my_origin.url'), $workdir2, 'my_origin changed';
	} $workdir3;
    }

    {
	my $workdir4 = "$dir/newworkdir4";
	is $d->git_repo_update(
			       repository => "file://$workdir", # "--depth is ignored in local clones; use file:// instead."
			       directory  => $workdir4,
			       clone_opts => ['--depth=1'],
			      ), 1, "with clone_opts";
	in_directory {
	    my @history = split /\n/, $d->info_qx({quiet=>1}, qw(git log --oneline));
	    like $history[0], qr{actually some content};

	    local $TODO;
	    if ($d->info_qx({quiet=>1}, 'git', '--version') =~ /^git version 1\.7\./) {
		$TODO = "git version 1.7.x detected --- this version actually fetches two commits with --depth=1";
	    }
	    is scalar(@history), 1, '--depth=1 was effective'
		or diag explain(\@history);
	    ok $d->git_is_shallow, 'git_is_shallow is true';
	} $workdir4;
    }

    {
	my $repo1 = "$dir/newworkdir5";
	my $repo2 = "$dir/newworkdir6";

	is $d->git_repo_update(
			       repository => $workdir,
			       directory  => $repo1,
			      ), 1;
	is $d->git_repo_update(
			       repository => $repo1,
			       directory  => $repo2,
			      ), 1;

	in_directory {
	    $d->touch("new-file");
	    $d->system(qw(git add new-file));
	    _git_commit_with_author('new file');
	} $repo1;

	$d->write_binary("$repo2/new-file", "untracked content\n");
	eval {
	    $d->git_repo_update(
				repository => $repo1,
				directory  => $repo2,
			       );
	};
	like $@, qr{Command exited with exit code};
	$d->unlink("$repo2/new-file");

	$d->touch("$repo2/untracked");
	is $d->git_repo_update(
			       repository => $repo1,
			       directory  => $repo2,
			      ), 1, 'update works, even with untracked files';
    }

    {
	my $repo1 = "$dir/newworkdir7";
	my $repo2 = "$dir/newworkdir8";

	is $d->git_repo_update(
			       repository => $workdir,
			       directory  => $repo1,
			      ), 1;
	is $d->git_repo_update(
			       repository => $repo1,
			       directory  => $repo2,
			      ), 1;

	in_directory {
	    $d->touch("new-file");
	    $d->system(qw(git add new-file));
	    _git_commit_with_author('new file');
	} $repo1;

	$d->git_repo_update(
			    repository => $repo1,
			    directory  => $repo2,
			    refresh    => 'never',
			   );
	ok !-e "$repo2/new-file", 'refresh=>never';

	$d->git_repo_update(
			    repository => $repo1,
			    directory  => $repo2,
			    refresh    => 'always',
			   );
	ok -e "$repo2/new-file", 'refresh=>always';
    }

    { # Test branch option
	my $repo1 = "$dir/newworkdir9";
	my $repo2 = "$dir/newworkdir10";
	my $repo3 = "$dir/newworkdir10b";

	is $d->git_repo_update(repository => $workdir, directory => $repo1), 1, 'clone without --branch';
	in_directory {
	    $d->system(qw(git checkout -b branch_test));
	    is $d->git_current_branch, 'branch_test';
	    is $d->git_repo_update(repository => $workdir, directory => $repo1, branch => 'branch_test'), 0, 'no change with branch';
	    is $d->git_repo_update(repository => $workdir, directory => $repo1), 0, 'no change without branch option';
	    is $d->git_repo_update(repository => $workdir, directory => $repo1, branch => 'master'), 1, 'branch changed';
	    is $d->git_current_branch, 'master';
	} $repo1;

	is $d->git_repo_update(repository => $repo1, directory => $repo2, branch => 'branch_test'), 1, 'clone with --branch';
	in_directory {
	    my %info;
	    is $d->git_current_branch(info_ref => \%info), 'branch_test', 'clone into non-master branch';
	    ok !$info{fallback}, 'no git-status fallback was used';
	    $d->system("git", "checkout", "master");
	    is $d->git_current_branch, 'master', 'changed back to master';
	} $repo2;

	is $d->git_repo_update(repository => $repo1, directory => $repo3, branch => 'refs/remotes/origin/branch_test'), 1, 'clone and switch to branch, use refs/remotes/... syntax';
	in_directory {
	    my %info;
	    is $d->git_current_branch(info_ref => \%info), 'branch_test', 'clone into non-master branch';
	    ok !$info{fallback}, 'no git-status fallback was used';
	    $d->system("git", "checkout", "master");
	    is $d->git_current_branch, 'master', 'changed back to master';
	} $repo3;

	in_directory {
	    $d->system("git", "checkout", "branch_test");
	    $d->create_file_if_nonexisting('new_file_for_detached_branch_test');
	    $d->system(qw(git add new_file_for_detached_branch_test));
	    _git_commit_with_author('msg for detached branch test');
	} $repo1;

	is $d->git_repo_update(repository => $repo1, directory => $repo2, branch => 'origin/branch_test'), 1, 'switch + update with detached branch';
	in_directory {
	    my %info;
	    is $d->git_current_branch(info_ref => \%info), 'origin/branch_test', 'detached branch'
		or diag `git status`;
	    ok $info{detached}, 'git_current_branch knows that the branch is detached';
	    like $info{fallback}, qr{^(git-status|git-show-ref)$}, 'a fallback was used';
	    ok -f 'new_file_for_detached_branch_test', 'freshly created file exists';
	} $repo2;

	in_directory {
	    $d->create_file_if_nonexisting('new_file_2_for_detached_branch_test');
	    $d->system(qw(git add new_file_2_for_detached_branch_test));
	    _git_commit_with_author('msg 2 for detached branch test');
	} $repo1;

	is $d->git_repo_update(repository => $repo1, directory => $repo2, branch => 'origin/branch_test'), 1, 'update with detached branch, but without switch';
	in_directory {
	    my %info;
	    is $d->git_current_branch(info_ref => \%info), 'origin/branch_test', 'still in detached branch'
		or diag `git status`;
	    ok $info{detached}, 'git_current_branch knows that the branch is detached';
	    like $info{fallback}, qr{^(git-status|git-show-ref)$}, 'a fallback was used';
	    ok -f 'new_file_2_for_detached_branch_test', 'freshly created file exists';
	} $repo2;

	$d->git_repo_update(repository => $repo1, directory => $repo2, branch => 'origin/master');
	is $d->git_repo_update(repository => $repo1, directory => $repo2, branch => 'refs/remotes/origin/branch_test'), 1, 'use refs/remotes/... syntax';
	in_directory {
	    my %info;
	    is $d->git_current_branch(info_ref => \%info), 'origin/branch_test', 'still in detached branch'
		or diag `git status`;
	    ok $info{detached}, 'git_current_branch knows that the branch is detached';
	    like $info{fallback}, qr{^(git-status|git-show-ref)$}, 'a fallback was used';
	    ok -f 'new_file_2_for_detached_branch_test', 'freshly created file exists';
	} $repo2;
    }

    { # branch option on a branch not yet in the fetched remote
	my $repo1 = "$dir/newworkdir11";
	my $repo2 = "$dir/newworkdir12";

	is $d->git_repo_update(repository => $workdir, directory => $repo1), 1;
	is $d->git_repo_update(repository => $repo1,   directory => $repo2), 1;
	in_directory {
	    $d->system(qw(git checkout -b new_branch));
	} $repo1;
	is $d->git_repo_update(repository => $repo1,   directory => $repo2, branch => 'new_branch'), 1;
	is $d->git_current_branch(directory => $repo2), 'new_branch';
	is $d->git_repo_update(repository => $repo1,   directory => $repo2, branch => 'new_branch'), 0;
	is $d->git_current_branch(directory => $repo2), 'new_branch';

	# go even further: checkout a detached branch
	is $d->git_repo_update(repository => $repo1,   directory => $repo2, origin => 'some_remote', branch => 'some_remote/new_branch'), 1;
	my $git_with_show_ref_fallback;
	{
	    my %info;
	    my $current_branch = $d->git_current_branch(directory => $repo2, info_ref => \%info);
	    $git_with_show_ref_fallback = ($info{fallback}||'') eq 'git-show-ref';
	SKIP: {
		skip "cannot distinguish between origin/master and some_remote/new_branch with git-show-ref fallback", 5
		    if $git_with_show_ref_fallback;

		is $current_branch, 'some_remote/new_branch';
		ok $info{detached};

		# update again to the same branch (should be a no-op)
		is $d->git_repo_update(repository => $repo1,   directory => $repo2, origin => 'some_remote', branch => 'some_remote/new_branch'), 0;
		
		%info = ();
		$current_branch = $d->git_current_branch(directory => $repo2, info_ref => \%info);
		is $current_branch, 'some_remote/new_branch';
		ok $info{detached};
	    }
	}
    }

    { # branch option on a branch not yet in the working directory, but exists in two remotes
      # a mere "git checkout branch" fails in this situation --- one has to explicitly
      # specify the remote here: "git checkout -b branch --track remote/branch"

	# create two remotes
	for my $remote (qw(one two)) {
	    my $workdir = "$dir/newworkdir13_$remote";
	    $d->mkdir($workdir);
	    in_directory {
		$d->system(qw(git init));
		$d->touch(qw(testfile));
		$d->system(qw(git add testfile));
		_git_commit_with_author('test');
		$d->system(qw(git checkout -b testbranch));
		$d->write_binary('testfile', "some content\n");
		$d->system(qw(git add testfile));
		_git_commit_with_author('a change');
		$d->system(qw(git checkout master));
	    } $workdir;
	}
	# create working directory, using the first remote
	my $workdir = "$dir/newworkdir13_work";
	$d->git_repo_update(repository => "$dir/newworkdir13_one",
			    directory => $workdir);
	in_directory {
	    # add the 2nd remote
	    $d->system(qw(git remote add another_remote), "$dir/newworkdir13_two");
	    $d->system(qw(git fetch another_remote));
	    # now switch to the (ambigous) not-yet checked out branch
	    # This will also fail for git < 1.5.1, but hopefully
	    # such old gits do not exist anymore.
	    $d->git_repo_update(repository => "$dir/newworkdir13_one",
				directory => $workdir,
				branch => "testbranch",
			       );
	    is $d->git_current_branch, 'testbranch';
	} $workdir;
    }
}

chdir "/"; # for File::Temp cleanup

sub run_tests {
    my($repository, $directory) = @_;

    is $d->git_repo_update(repository => $repository, directory => $directory), 1, "first call is a clone of $repository";
    git_short_status_check({                       directory => $directory}, $d, '', 'not dirty after clone');
    git_short_status_check({untracked_files=>'no', directory => $directory}, $d, '', 'not dirty after clone');
    my $commit_hash = $d->git_get_commit_hash(directory => $directory);
    like $commit_hash, qr{^[0-9a-f]{40}$}, 'a sha1';
    my $current_branch = $d->git_current_branch(directory => $directory);
    my $commit_hash_with_branch = $d->git_get_commit_hash(directory => $directory, commit => $current_branch);
    is $commit_hash_with_branch, $commit_hash, 'git_get_commit_hash with commit option';
    my $commit_hash_with_abbrev_sha1 = $d->git_get_commit_hash(directory => $directory, commit => substr($commit_hash, 0, 7));
    is $commit_hash_with_abbrev_sha1, $commit_hash, 'git_get_commit_hash with abbreviated sha1';
    ok -d $directory;
    ok -d "$directory/.git";
    is $d->git_repo_update(repository => $repository, directory => $directory), 0, 'second call does nothing';
    is $d->git_get_commit_hash(directory => $directory), $commit_hash, 'unchanged commit hash';
    is $d->git_repo_update(repository => $repository, directory => $directory, quiet => 1), 0, 'third call is quiet';

    in_directory {
	$d->system(qw(git reset --hard HEAD^));
	git_short_status_check(                         $d, '>', 'remote is now newer');
	git_short_status_check({untracked_files=>'no'}, $d, '>', 'remote is now newer');

	$d->touch('untracked-file');
	git_short_status_check(                         $d, '*>', 'remote is now newer and an untracked file');
	git_short_status_check({untracked_files=>'no'}, $d, '>',  'remote is now newer, but untracked files are ignored');
	$d->unlink('untracked-file');

	$d->touch('diverging_now');
	$d->system(qw(git add diverging_now));
	_git_commit_with_author('test commit in clone');
	git_short_status_check(                         $d, '<>', 'diverged');
	git_short_status_check({untracked_files=>'no'}, $d, '<>', 'diverged');

	$d->touch('untracked-file');
	git_short_status_check(                         $d, '<*>', 'diverged and an untracked file');
	git_short_status_check({untracked_files=>'no'}, $d, '<>',  'diverged, but untracked files are ignored');
	$d->unlink('untracked-file');

	$d->system(qw(git reset --hard HEAD^)); # resolve diverged state

	is $d->git_repo_update(repository => $repository, directory => $directory), 1, 'doing a fetch';
	is $d->git_get_commit_hash, $commit_hash, 'again at the old commit hash'; # ... and without specifying $workdir
	git_short_status_check(                         $d, '', 'freshly fetched');
	git_short_status_check({untracked_files=>'no'}, $d, '', 'freshly fetched');

	$d->touch('new_file');
	git_short_status_check(                         $d, '*', 'file was touched');
	git_short_status_check({untracked_files=>'no'}, $d, '',  'file was touched, but untracked files are ignored');
	$d->system(qw(git add new_file));
	_git_commit_with_author('test commit in clone');
	git_short_status_check(                         $d, '<', 'ahead of origin');
	git_short_status_check({untracked_files=>'no'}, $d, '<', 'ahead of origin');

	$d->touch('untracked-file');
	git_short_status_check(                         $d, '<*', 'ahead of origin and an untracked file');
	git_short_status_check({untracked_files=>'no'}, $d, '<',  'ahead of origin, but untracked files are ignored');
	$d->unlink('untracked-file');

	$d->system(qw(git checkout -b new_branch));
	is $d->git_current_branch, 'new_branch';
	my $commit_hash_branch = $d->git_get_commit_hash;
	like $commit_hash_branch, qr{^[0-9a-f]{40}$}, 'a sha1';
	my $commit_hash_branch_with_branch = $d->git_get_commit_hash(directory => $directory, commit => 'new_branch');
	is $commit_hash_branch_with_branch, $commit_hash_branch, 'git_get_commit_hash with commit option';

    } $directory;

    $d->mkdir("$dir/exists");
    $d->create_file_if_nonexisting("$dir/exists/make_directory_non_empty");
    eval { $d->git_repo_update(repository => $repository, directory => "$dir/exists") };
    like $@, qr{ERROR.*No .git directory found in};

    $d->touch("$dir/file");
    eval { $d->git_repo_update(repository => $repository, directory => "$dir/file") };
    like $@, qr{ERROR.*exists, but is not a directory};
}

sub _git_commit_with_author {
    my $msg = shift;
    local $ENV{GIT_COMMITTER_NAME} = "Some Body";
    local $ENV{GIT_COMMITTER_EMAIL} = 'somebody@example.org';
    local $ENV{GIT_AUTHOR_NAME} = "Some Body";
    local $ENV{GIT_AUTHOR_EMAIL} = 'somebody@example.org';
    $d->system(qw(git commit), '-m', $msg);
}

sub git_short_status_check {
    my %options;
    if (ref $_[0] eq 'HASH') {
	%options = %{ shift @_ };
    }
    my($doit, $expected, $testname) = @_;
    my $doit_result = $doit->git_short_status(%options);
    is $doit_result, $expected, $testname;
    if ($my_git_short_status) {
	my $directory = $options{directory} ? $options{directory} : getcwd;
	my @git_short_status_opts;
	if (($options{untracked_files}||'') eq 'no') {
	} else {
	    push @git_short_status_opts, '-with-untracked';
	}
	in_directory {
	    local $ENV{PERL5OPT} = ''; # i.e. disable Devel::Cover
	    chomp(my $script_result = $doit->info_qx({quiet=>1}, $my_git_short_status, @git_short_status_opts));
	    is $script_result, $doit_result, "$testname (against $my_git_short_status)";
	} $directory;
    }
}

__END__
