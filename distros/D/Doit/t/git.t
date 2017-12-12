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
use Doit::Extcmd qw(is_in_path);
use Doit::Util qw(in_directory);

use TestUtil qw(is_dir_eq);

if (!is_in_path('git')) {
    plan skip_all => 'git not in PATH';
}

plan 'no_plan';

my $d = Doit->init;
$d->add_component('git');

# realpath() needed on darwin
my $dir = realpath(tempdir('doit-git-XXXXXXXX', CLEANUP => 1, TMPDIR => 1));

# A private git-short-status script; should behave the same.
my $my_git_short_status;
if ($ENV{HOME} && -x "$ENV{HOME}/bin/sh/git-short-status") {
    $my_git_short_status = "$ENV{HOME}/bin/sh/git-short-status";
}

# Tests with the Doit repository (if checked out)
SKIP: {
    my $self_git = $d->git_root;
    skip "Not a git checkout", 1 if !$self_git;
    skip "shallow repositories cannot be cloned", 1 if $d->git_is_shallow;

    my $workdir = "$dir/doit";

    run_tests($self_git, $workdir);
}

# Error cases
eval { $d->git_repo_update('unhandled-option' => 1) };
like $@, qr{ERROR.*Unhandled options: unhandled-option}, 'unhandled option';

eval { $d->git_short_status('unhandled-option' => 1) };
like $@, qr{ERROR.*Unhandled options: unhandled-option}, 'unhandled option';

eval { $d->git_short_status('untracked_files' => 'blubber') };
like $@, qr{ERROR.*only values 'normal' or 'no' supported for untracked_files};

# Tests with a freshly created git repository
{
    my $workdir = "$dir/newworkdir";
    $d->mkdir($workdir);
    chdir $workdir or die "chdir failed: $!";
    $d->system(qw(git init));

    # after init checks
    is_dir_eq $d->git_root, $workdir, 'git_root in root directory';
    is_deeply [$d->git_get_changed_files], [], 'no changed files in fresh empty directory';
    git_short_status_check(                         $d, '', 'empty directory, not dirty');
    git_short_status_check({untracked_files=>'no'}, $d, '', 'empty directory, not dirty');
    is $d->git_current_branch, 'master';

    # dirty
    $d->touch('testfile');
    is_deeply [$d->git_get_changed_files], ['testfile'], 'new file detected';
    git_short_status_check(                         $d, '*', 'untracked file detected');
    git_short_status_check({untracked_files=>'no'}, $d, '',  'no detection of untracked files');

    # git-add
    $d->system(qw(git add testfile));
    git_short_status_check(                         $d, '<<', 'uncommitted file detected');
    git_short_status_check({untracked_files=>'no'}, $d, '<<', 'uncommitted file detected');

    $d->touch('untracked-file');
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

    Doit::Util::in_directory(sub {
	is_dir_eq $d->git_root, $workdir, 'in_directory call without prototype';
    }, 'subdir');

    is $d->git_config(key => "test.key"), undef, 'config key does not exist yet';
    $d->git_config(key => "test.key", val => "test.val");
    is $d->git_config(key => "test.key"), "test.val", 'config key now exists';
    $d->git_config(key => "test.key", val => "test.val2");
    is $d->git_config(key => "test.key"), "test.val2", 'config key now changed';
    $d->git_config(key => "test.key", val => "test.val2");
    is $d->git_config(key => "test.key"), "test.val2", 'nothing changed now';
    $d->git_config(key => "test.key", unset => 1);
    is $d->git_config(key => "test.key"), undef, 'config key was removed';
    $d->git_config(key => "test.key", unset => 1);
    is $d->git_config(key => "test.key"), undef, 'config key is still removed';

    is $d->git_repo_update(
			   repository => "$workdir/.git",
			   repository_aliases => [$workdir],
			   directory => $workdir2,
			  ), 0, "handling repository_aliases";

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

}

chdir "/"; # for File::Temp cleanup

sub run_tests {
    my($repository, $directory) = @_;

    is $d->git_repo_update(repository => $repository, directory => $directory), 1, "first call is a clone of $repository";
    git_short_status_check({                       directory => $directory}, $d, '', 'not dirty after clone');
    git_short_status_check({untracked_files=>'no', directory => $directory}, $d, '', 'not dirty after clone');
    my $commit_hash = $d->git_get_commit_hash(directory => $directory);
    like $commit_hash, qr{^[0-9a-f]{40}$}, 'a sha1';
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
