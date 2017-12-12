#!/usr/bin/perl -w
# -*- perl -*-

#
# Author: Slaven Rezic
#
# Copyright (C) 2017 Slaven Rezic. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# Mail: slaven@rezic.de
# WWW:  http://www.rezic.de/eserte/
#

use strict;
use FindBin;
use lib $FindBin::RealBin;

use File::Temp 'tempdir';
use Test::More 'no_plan';
use Errno ();
use Hash::Util qw(lock_keys);

use Doit;
use Doit::Log;
use Doit::Util qw(new_scope_cleanup);

use TestUtil qw(skip_utime_atime_unreliable);

sub with_unreadable_directory (&$);

my %errno_string =
    (
     EACCES => do { $! = Errno::EACCES(); "$!" }, # "Permission denied"
     EEXIST => do { $! = Errno::EEXIST(); "$!" }, # "File exists"
     ENOENT => do { $! = Errno::ENOENT(); "$!" },
     ENOTEMPTY => do { $! = Errno::ENOTEMPTY(); "$!" }, # "Directory not empty"
    );
lock_keys %errno_string;

my $tempdir = tempdir('doit_XXXXXXXX', TMPDIR => 1, CLEANUP => 1);
chdir $tempdir or die "Can't chdir to $tempdir: $!";

my $r = Doit->init;
my $has_ipc_run = $r->can_ipc_run;

######################################################################
# touch
is $r->touch("doit-test"), 1;
ok -f "doit-test";
is $r->touch("doit-test"), 1;
ok -f "doit-test";
with_unreadable_directory {
    eval { $r->touch("unreadable-dir/test") };
    like $@, qr{ERROR.*\Q$errno_string{EACCES}};
} "unreadable-dir";
is $r->touch("doit-a", "doit-b", "doit-c"), 3;
$r->unlink("doit-a", "doit-b", "doit-c");

######################################################################
# utime
is $r->utime(100000, 100000, "doit-test"), 1;
{
    my @s = stat "doit-test";
    skip_utime_atime_unreliable {
	is $s[8], 100000, 'utime changed accesstime';
    };
    is $s[9], 100000, 'utime changed modtime';
}
skip_utime_atime_unreliable {
    is $r->utime(100000, 100000, "doit-test"), 0; # should not run
};
is $r->utime(100000, 200000, "doit-test"), 1;
{
    my @s = stat "doit-test";
    skip_utime_atime_unreliable {
	is $s[8], 100000, 'accesstime still unchanged';
    };
    is $s[9], 200000, 'utime changed modtime';
}
{
    my $now = time;
    is $r->utime(undef, undef, "doit-test"), 1;
    my @s = stat "doit-test"; cmp_ok $s[9], ">=", $now;
}
eval { $r->utime(1, 2, "non-existing-file") };
like $@, qr{ERROR.*\Qutime failed: $errno_string{ENOENT}}, 'utime on non-existing file';
eval { $r->utime(1, 2, "non-existing-file-1", "non-existing-file-2") };
like $@, qr{ERROR.*\Qutime failed on all files: $errno_string{ENOENT}}, 'utime on multiple non-existing files';
$r->create_file_if_nonexisting('doit-test-2');
eval { $r->utime(1, 2, "doit-test-2", "non-existing-file") };
like $@, qr{ERROR.*\Qutime failed on some files (1/2): $errno_string{ENOENT}}, 'utime on multiple non-existing files';
$r->unlink('doit-test-2');
$r->touch('doit-a', 'doit-b', 'doit-c');
is $r->utime(100000, 100000, 'doit-a', 'doit-b', 'doit-c'), 3, 'three files were changed';
$r->unlink('doit-a', 'doit-b', 'doit-c');

######################################################################
# create_file_if_nonexisting
{
    my @s_before = stat "doit-test";
    is $r->create_file_if_nonexisting("doit-test"), 0; # already exists
    my @s_after = stat "doit-test";
    # unfortunately perl has integer timestamps, so this test is
    # unlikely to fail, even if we had a problem:
    is $s_after[9], $s_before[9], 'mtime should not change';
}

is $r->create_file_if_nonexisting('doit-test2'), 1;
ok -f 'doit-test2', 'create_file_if_nonexisting on a non-existent file';
$r->unlink('doit-test2');
with_unreadable_directory {
    eval { $r->create_file_if_nonexisting("unreadable-dir/test") };
    like $@, qr{ERROR.*\Q$errno_string{EACCES}};
} "unreadable-dir";
is $r->create_file_if_nonexisting('doit-test', 'doit-a', 'doit-b'), 2, 'only two files were missing';
$r->unlink('doit-a', 'doit-b');

######################################################################
# unlink
$r->create_file_if_nonexisting('doit-test2');
ok  -f 'doit-test2';
is $r->unlink('doit-test2'), 1;
ok !-f 'doit-test2', 'file was deleted';
is $r->unlink('non-existing-directory/test'), 0; # not throwing exceptions, as a file check is done before
SKIP: {
    skip "permissions probably work differently on Windows", 1 if $^O eq 'MSWin32';
    skip "non-writable directory not a problem for the superuser", 1 if $> == 0;

    $r->mkdir("non-writable-dir");
    $r->create_file_if_nonexisting("non-writable-dir/test");
    $r->chmod(0500, "non-writable-dir");
    eval { $r->unlink("non-writable-dir/test") };
    like $@, qr{ERROR.*\Q$errno_string{EACCES}};
    $r->chmod(0700, "non-writable-dir");
    $r->remove_tree("non-writable-dir");
}
$r->touch('doit-a', 'doit-b', 'doit-c');
is $r->unlink('not-existing', 'doit-a', 'doit-b', 'doit-c'), 3, 'three of four files were deleted';

######################################################################
# chmod
$r->create_file_if_nonexisting('doit-test2');
is $r->chmod(0755, "doit-test", "doit-test2"), 2; # changes expected
is $r->chmod(0644, "doit-test2"), 1; # one change expected
{
    local $TODO = "No noop on Windows" if $^O eq 'MSWin32';
    is $r->chmod(0755, "doit-test"), 0; # noop
}
eval { $r->chmod(0644, "does-not-exist") };
like $@, qr{chmod failed: };
eval { $r->chmod(0644, "does-not-exist-1", "does-not-exist-2") };
like $@, qr{chmod failed on all files: };
eval { $r->chmod(0644, "doit-test", "does-not-exist") };
like $@, qr{\Qchmod failed on some files (1/2): };
{
    local $TODO = "No noop on Windows" if $^O eq 'MSWin32';
    is $r->chmod(0644, "doit-test"), 0; # noop
}

######################################################################
# chown
is $r->chown(-1, -1, "doit-test"), 0;
is $r->chown($>, undef, "doit-test"), 0;
is $r->chown($>, -1, "doit-test"), 0;
is $r->chown($>, undef, "doit-test"), 0;
SKIP: {
    my @groups = split / /, $);
    my $another_group = $groups[1];
    skip "No other group available for test (we have only gids: $))", 3 if !defined $another_group || $groups[0] eq $another_group;
    is $r->chown(undef, $another_group, "doit-test"), 1;
    is $r->chown(undef, $another_group, "doit-test"), 0;

    skip "getgrnam not available on MSWin32", 1 if $^O eq 'MSWin32';
    my $another_groupname = getgrgid($another_group);
    skip "Cannot get groupname for gid $another_group", 1 if !defined $another_groupname;
    is $r->chown(undef, $another_groupname, 'doit-test'), 0;
}
SKIP: {
    skip "chown never fails on MSWin32", 2 if $^O eq 'MSWin32';
    eval { $r->chown($>, undef, "does-not-exist") };
    like $@, qr{chown failed: };
    eval { $r->chown($>, undef, "does-not-exist-1", "does-not-exist-2") };
    like $@, qr{chown failed on all files: };
    # no test case for "chown failed on some files"
}
SKIP: {
    skip "getpwnam and getgrnam not available on MSWin32", 1 if $^O eq 'MSWin32';
    eval { $r->chown("user-does-not-exist", undef, "doit-test") };
    like $@, qr{\QUser 'user-does-not-exist' does not exist };
    eval { $r->chown(undef, "group-does-not-exist", "doit-test") };
    like $@, qr{\QGroup 'group-does-not-exist' does not exist };
 SKIP: {
	my $username = (getpwuid($>))[0];
	skip "Cannot get username for uid $>", 1 if !defined $username;
	is $r->chown($username, undef, "doit-test"), 0;
    }
}

######################################################################
# rename, move
is $r->rename("doit-test", "doit-test3"), 1;
$r->move("doit-test3", "doit-test2");
is $r->rename("doit-test2", "doit-test"), 1;
eval { $r->rename("doit-test", "non-existent-directory/does-not-work") };
like $@, qr{ERROR.*\Q$errno_string{ENOENT}}, 'failed rename';
ok !-e "non-existent-directory/does-not-work", 'last rename really failed';
ok  -e "doit-test", 'file is not renamed';
eval { $r->move("doit-test", "non-existent-directory/does-not-work") };
like $@, qr{ERROR.*\Q$errno_string{ENOENT}}, 'failed rename';
ok !-e "non-existent-directory/does-not-work", 'last rename really failed';
ok  -e "doit-test", 'file is not renamed';

######################################################################
# copy
is $r->copy("doit-test", "doit-copy"), 1;
ok -e "doit-copy"
    or diag qx(ls -al);
is $r->copy("doit-test", "doit-copy"), 0; # no action
$r->unlink("doit-copy");

######################################################################
# symlink, ln_nsf
TODO: {
    todo_skip "symlinks not working on Windows", 11
	if $^O eq 'MSWin32';

    is $r->symlink("tmp/doit-test", "doit-test-symlink"), 1;
    ok -l "doit-test-symlink", 'symlink created';
    is readlink("doit-test-symlink"), "tmp/doit-test", 'symlink points to expected destination';
    is $r->symlink("tmp/doit-test", "doit-test-symlink"), 0;
    ok -l "doit-test-symlink", 'symlink still exists';
    is readlink("doit-test-symlink"), "tmp/doit-test", 'symlink did not change expected destination';
    $r->unlink("doit-test-symlink");
    ok ! -e "doit-test-symlink", 'symlink was removed';

    eval { $r->ln_nsf };
    like $@, qr{oldfile was not specified for ln_nsf};
    eval { $r->ln_nsf("tmp/doit-test") };
    like $@, qr{newfile was not specified for ln_nsf};
    is $r->ln_nsf("tmp/doit-test", "doit-test-symlink2"), 1;
    ok -l "doit-test-symlink2", 'symlink created with ln -nsf';
    is readlink("doit-test-symlink2"), "tmp/doit-test", 'symlink points to expected destination';
    is $r->ln_nsf("tmp/doit-test", "doit-test-symlink2"), 0;
    ok -l "doit-test-symlink2", 'symlink still exists (ln -nsf)';
    is readlink("doit-test-symlink2"), "tmp/doit-test", 'symlink did not change expected destination';
    is $r->ln_nsf("doit-test", "doit-test-symlink2"), 1;
    ok -l "doit-test-symlink2", 'new symlink (ln -nsf)';
    is readlink("doit-test-symlink2"), "doit-test", 'symlink was changed';
    $r->unlink("doit-test-symlink2");
    ok ! -e "doit-test-symlink2", 'symlink was removed';

    $r->mkdir("dir-for-ln-nsf-test");
    ok -d "dir-for-ln-nsf-test";
    eval { $r->ln_nsf("tmp/doit-test", "dir-for-ln-nsf-test") };
    like $@, qr{"dir-for-ln-nsf-test" already exists as a directory};
    ok -d "dir-for-ln-nsf-test", 'directory still exists after failed ln -nsf';

    with_unreadable_directory {
	eval { $r->symlink("target", "unreadable/symlink") };
	like $@, qr{ERROR.*\Q$errno_string{ENOENT}};
	eval { $r->ln_nsf("target", "unreadable/symlink") };
	like $@, qr{ln -nsf target unreadable/symlink failed};
    } "unreadable-dir";
}

######################################################################
# write_binary
$r->write_binary("doit-test", "some content\n");
$r->write_binary("doit-test", "some content\n");
$r->write_binary("doit-test", "different content\n");
$r->write_binary("doit-test", "different content\n");
$r->unlink("doit-test");
ok ! -f "doit-test";
ok ! -e "doit-test";
$r->unlink("doit-test");
eval { $r->write_binary("non-existing-dir/test", "egal\n") };
like $@, qr{ERROR.*\Q$errno_string{ENOENT}};
SKIP: {
    skip "permissions probably work differently on Windows", 1 if $^O eq 'MSWin32';
    skip "non-writable file not a problem for the superuser", 1 if $> == 0;

    $r->write_binary({quiet=>1}, "unwritable-file", "something\n");
    $r->chmod(0400, "unwritable-file");
    eval { $r->write_binary({quiet=>1, atomic=>0}, "unwritable-file", "change will fail\n") };
    like $@, qr{ERROR:.*\QCan't write to unwritable-file: $errno_string{EACCES}}, 'fail to write to unwritable file';
    $r->chmod(0000, "unwritable-file"); # now also unreadable
    eval { $r->write_binary({quiet=>1}, "unwritable-file", "something\n") }; # no change, but will fail due to unreadability
    like $@, qr{ERROR:.*\QCan't open unwritable-file: $errno_string{EACCES}}, 'fail to read from unwritable file';
    $r->unlink("unwritable-file");
}
SKIP: {
    skip "permissions work differently on Windows", 1 if $^O eq 'MSWin32';

    $r->write_binary({quiet=>1}, "permission-test", "something\n");
    $r->chmod(0751, "permission-test");
    $r->write_binary({quiet=>1}, "permission-test", "something changed\n");
    my @s = stat "permission-test";
    is(($s[2]&0777), 0751, 'permissions were preserved');
}

######################################################################
# mkdir
is $r->mkdir("doit-test"), 1;
ok -d "doit-test";
is $r->mkdir("doit-test"), 0;
ok -d "doit-test";
{
    my $umask = umask 0;
    is $r->mkdir("doit-test-0700", 0700), 1;
    ok -d "doit-test-0700";
 SKIP: {
	skip "mode setting effectively a no-op on Windows", 1 if $^O eq 'MSWin32';
	my @s = stat "doit-test-0700";
	is(($s[2] & 0777), 0700, 'mkdir call with mode');
    }
    $r->rmdir("doit-test-0700");
    umask $umask;
}
$r->create_file_if_nonexisting('file-in-the-way');
eval { $r->mkdir('file-in-the-way') };
like $@, qr{ERROR.*\Q$errno_string{EEXIST}};
eval { $r->mkdir('file-in-the-way', 0777) };
like $@, qr{ERROR.*\Q$errno_string{EEXIST}};

######################################################################
# make_path
is $r->make_path("doit-test", "doit-deep/test"), 1; # doit-test already exists, so it's just 1
ok -d "doit-deep/test";
is $r->make_path("doit-test", "doit-deep/test"), 0;
is $r->make_path("doit-deep/test2", {mode => 0700, verbose => 1}), 1;
ok -d "doit-deep/test2";
SKIP: {
    skip "mode setting effectively a no-op on Windows", 1 if $^O eq 'MSWin32';
    my @s = stat "doit-deep/test2";
    is(($s[2] & 0777), 0700, 'make_path call with mode');
}
SKIP: {
    with_unreadable_directory {
	eval { $r->make_path("unreadable-dir/test") };
	like $@, qr{mkdir unreadable-dir/test: \Q$errno_string{EACCES}}; # XXX not thrown with error()
    } "unreadable-dir";
}

######################################################################
# rmdir
is $r->rmdir("doit-test"), 1;
ok ! -d "doit-test";
ok ! -e "doit-test";
is $r->rmdir("doit-test"), 0;

$r->mkdir("non-empty-dir");
$r->touch("non-empty-dir/test");
eval { $r->rmdir("non-empty-dir") };
like $@, qr{ERROR.*(?:
		    \Q$errno_string{ENOTEMPTY}\E # FreeBSD, Linux, Windows, POSIX
		   |\Q$errno_string{EEXIST}\E # Solaris, POSIX
		   )}x;
$r->remove_tree("non-empty-dir");

######################################################################
# remove_tree
$r->mkdir("doit-test"); # doit-deep/test still exists
is $r->remove_tree("doit-test", "doit-deep/test"), 2;
ok ! -d "doit-test", 'remove_tree removed simple directory';
ok ! -d "doit-deep/test", 'remove_tree removed tree';
is $r->remove_tree("doit-test", "doit-deep/test"), 0;
$r->mkdir("doit-test");
$r->create_file_if_nonexisting("doit-test/file");
is $r->remove_tree("doit-test", {verbose=>1}), 1;
SKIP: {
    with_unreadable_directory {
	eval { $r->remove_tree("unreadable-dir") };
	local $TODO = "Does not report errors on all OS"; # no error on freebsd 9 + travis-ci machines
	like $@, qr{ERROR.*\Q$errno_string{EACCES}};
    } "unreadable-dir";
}

######################################################################
# system, run
$r->system($^X, '-le', 'print q{hello}');
$r->system($^X, '-le', 'print "hello"');
if ($has_ipc_run) {
    $r->run([$^X, '-le', 'print qq{hello}']);
}
if ($^O ne 'MSWin32') { # date is interactive on Windows
    $r->system("date");
    if ($has_ipc_run) {
	$r->run(["date"]);
    }
}
{
    my @hostname = ('hostname');
    if ($^O =~ m{^(linux|freebsd|darwin|gnukfreebsd)$}) {
	push @hostname, '-f';
    }
    $r->system(@hostname);
    if ($has_ipc_run) {
	$r->run([@hostname]);
    }
}

######################################################################
# cond_run
{
    eval { $r->cond_run };
    like $@, qr{cmd is a mandatory option for cond_run};

    eval { $r->cond_run(invalid_option => 1) };
    like $@, qr{Unhandled options: invalid_option};

    eval { $r->cond_run(cmd => "a scalar") };
    like $@, qr{cmd must be an array reference};

    is $r->cond_run(cmd => [$^X, '-le', 'print q(unconditional cond_run)']), 1;
    is $r->cond_run(if => sub { 1 }, cmd => [$^X, '-le', 'print q(always true)']), 1;
    is $r->cond_run(if => sub { 0 }, cmd => [$^X, '-le', 'die q(never true, should never happen!!!)']), 0;
    like $r->cond_run(if => sub { rand(1) < 0.5 }, cmd => [$^X, '-le', 'print q(yes)']), qr{^(0|1)$};

    is $r->cond_run(unless => sub { 1 }, cmd => [$^X, '-le', 'die q(never true, should never happen!!!)']), 0;
    is $r->cond_run(unless => sub { 0 }, cmd => [$^X, '-le', 'print q(always true)']), 1;

    ok !-e "cond-run-file", 'file for cond_run does not exist yet';
    is $r->cond_run(creates => "cond-run-file", cmd => [$^X, '-e', 'open my $ofh, ">", "cond-run-file"']), 1;
    ok  -e "cond-run-file", 'file for cond_run now exists';
    is $r->cond_run(creates => "cond-run-file", cmd => [$^X, '-e', 'die "should never happen, as file already exists"']), 0;

 SKIP: {
	skip "Requires IPC::Run", 2 if !$has_ipc_run;
	ok !-e "cond-run-file-2", "file for cond_run does not exist yet";
	is $r->cond_run(creates => "cond-run-file-2", cmd => [[$^X, '-e', 'exit 0'], '>', 'cond-run-file-2']), 1;
	ok  -e "cond-run-file-2", "file for cond_run no exists (using IPC::Run)";
	is $r->cond_run(creates => "cond-run-file-2", cmd => [[$^X, '-e', 'die "should never happen, as file already exists"'], '>', 'cond-run-file-2']), 0;
    }

    ok !-e "cond-run-file-3", "file for cond_run does not exist yet";
    is $r->cond_run(if => sub { 1 }, unless => sub { 0 }, creates => "cond-run-file-3", cmd => [$^X, '-e', 'open my $ofh, ">", "cond-run-file-3"']), 1;
    ok  -e "cond-run-file-3", "file for cond_run does not exists, with combined condition";
}

######################################################################
# install_generic_cmd
$r->install_generic_cmd('never_executed', sub { 0 }, sub { die "never executed" });
$r->never_executed();
$r->install_generic_cmd('mytest', sub {
			    my($self, $args) = @_;
			    @$args;
			}, sub {
			    my($self, $args) = @_;
			    warn "args is @$args";
			});
$r->mytest(1);
$r->mytest(0);

chdir '/'; # for File::Temp

######################################################################
# helpers

sub with_unreadable_directory (&$) {
    my($code, $unreadable_dir) = @_;
    error "not a CODE ref: $code" if ref $code ne 'CODE';
    error "missing unreadable dir" if !defined $unreadable_dir;

 SKIP: {
	skip "unreadable directories behave differently on Windows", 1 if $^O eq 'MSWin32';
	skip "unreadable directories not a problem for the superuser", 1 if $> == 0;

	$r->mkdir($unreadable_dir);
	$r->chmod(0000, $unreadable_dir);

	my $cleanup = new_scope_cleanup {
	    $r->chmod(0700, $unreadable_dir);
	    $r->rmdir($unreadable_dir);
	};

	$code->();
    }
}

__END__
