#!/usr/bin/perl -w
# -*- cperl -*-

#
# Author: Slaven Rezic
#

use Doit;
use Doit::Util 'new_scope_cleanup';
use File::Glob 'bsd_glob';
use File::Temp 'tempdir';
use Test::More;

sub slurp ($) { open my $fh, shift or die $!; local $/; <$fh> }
sub slurp_utf8 ($) { open my $fh, shift or die $!; binmode $fh, ':encoding(utf-8)'; local $/; <$fh> }

return 1 if caller;

require FindBin;
{ no warnings 'once'; push @INC, $FindBin::RealBin; }
require TestUtil;

sub no_leftover_tmp ($;$) {
    my($tmp_dir, $tmp_suffix) = @_;
    $tmp_suffix = '.tmp' if !defined $tmp_suffix;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my @files = bsd_glob("$tmp_dir/*$tmp_suffix");
    is_deeply \@files, [], "no temporary file left-overs with suffix $tmp_suffix in $tmp_dir";
}

plan 'no_plan';

my $doit = Doit->init;
$doit->add_component('file');

my $doit_dryrun = do {
    local @ARGV = '--dry-run';
    Doit->init;
};
ok $doit_dryrun->is_dry_run, 'created dry-run Doit object';
# Accidentally it's not required to call add_component('file') here,
# as the add_component calls affect the class, not the object.

my $tempdir = tempdir('doit_XXXXXXXX', TMPDIR => 1, CLEANUP => 1);
$doit->mkdir("$tempdir/another_tmp");

{
    eval { $doit->file_atomic_write };
    like $@, qr{file parameter is missing}i, "too few params";
}

{
    eval { $doit->file_atomic_write("$tempdir/1st") };
    like $@, qr{code parameter is missing}i, "too few params";
    ok !-e "$tempdir/1st", "file was not created";
}

{
    eval { $doit->file_atomic_write("$tempdir/1st", "not a sub") };
    like $@, qr{code parameter should be an anonymous subroutine or subroutine reference}i, "wrong type";
    ok !-e "$tempdir/1st", "file was not created";
}

{
    eval { $doit->file_atomic_write("$tempdir/1st", sub { }, does_not_exist => 1) };
    like $@, qr{unhandled option}i, "unhandled option error";
    ok !-e "$tempdir/1st", "file was not created";
}

{
    eval { $doit->file_atomic_write("$tempdir/1st", sub { die "something failed" }) };
    like $@, qr{something failed}i, "exception in code";
    ok !-e "$tempdir/1st", "file was not created";
    no_leftover_tmp $tempdir;
}

{   # This should be the first test case creating the new file
    $doit->create_file_if_nonexisting("$tempdir/stat_reference");

    is $doit->file_atomic_write("$tempdir/1st", sub {
				    my $fh = shift;
				    binmode $fh, ':encoding(utf-8)';
				    print $fh "\x{20ac}uro\n";
				}), 1;

    ok -s "$tempdir/1st", 'Created file exists and is non-empty';
    is slurp_utf8("$tempdir/1st"), "\x{20ac}uro\n", 'expected content';

    my(@stat_reference)    = stat("$tempdir/stat_reference");
    my(@stat_atomic_write) = stat("$tempdir/1st");
    is $stat_atomic_write[4], $stat_reference[4], 'expected owner on initial creation';
    is $stat_atomic_write[5], $stat_reference[5], 'expected group on initial creation';
    is(($stat_atomic_write[2] & 07777), ($stat_reference[2] & 07777), 'expected mode on initial creation');

    no_leftover_tmp $tempdir;
}

SKIP: {   # Test with setgid bit
    skip "No gid or setgid support under Windows", 1 if $^O eq 'MSWin32';

    my @gids = split / /, $(;
    my $test_gid = $gids[-1];
    $doit->mkdir("$tempdir/setgid");
    $doit->chown(undef, $test_gid, "$tempdir/setgid");
    if ($^O =~ /bsd/ || $^O eq 'darwin') {
	# no not for setgid on BSD like systems
    } else {
	$doit->chmod(((stat "$tempdir/setgid")[2] & 07777) | 02000, "$tempdir/setgid");
    }

    $doit->create_file_if_nonexisting("$tempdir/setgid/stat_reference");

    is $doit->file_atomic_write("$tempdir/setgid/file", sub {
				    my $fh = shift;
				    print $fh "test setgid\n";
				}, tmpdir => $tempdir), 1; # use a non-setgid directory for tmpfile

    ok -s "$tempdir/setgid/file", 'Created file exists and is non-empty';
    is slurp("$tempdir/setgid/file"), "test setgid\n", 'expected content';

    my(@stat_reference)    = stat("$tempdir/setgid/stat_reference");
    my(@stat_atomic_write) = stat("$tempdir/setgid/file");
    is $stat_atomic_write[4], $stat_reference[4], 'expected owner on initial creation';
    is $stat_atomic_write[5], $stat_reference[5], 'expected group on initial creation';
    is(($stat_atomic_write[2] & 07777), ($stat_reference[2] & 07777), 'expected mode on initial creation');

    no_leftover_tmp $tempdir;
}

{
    my @stat;

    is $doit->file_atomic_write("$tempdir/my_mode", sub {
				    my $fh = shift;
				    print $fh "my special mode\n";
				}, mode => 0400), 1;

    ok -s "$tempdir/my_mode", 'Created file exists and is non-empty';
    is slurp("$tempdir/my_mode"), "my special mode\n", 'expected content';

    @stat = stat("$tempdir/my_mode");
    is(($stat[2] & 07777), ($^O eq 'MSWin32' ? 0444 : 0400), 'mode option on newly created file');

    is $doit->file_atomic_write("$tempdir/my_mode", sub {
				    my $fh = shift;
				    print $fh "changing my mode\n";
				}, mode => 0600), 1;

    is slurp("$tempdir/my_mode"), "changing my mode\n", 'content was changed';

    @stat = stat("$tempdir/my_mode");
    is(($stat[2] & 07777), ($^O eq 'MSWin32' ? 0666 : 0600), 'mode option on existing file');

    no_leftover_tmp $tempdir;
}

{
    $doit->chmod(0600, "$tempdir/1st");
    my $mode_before = (stat("$tempdir/1st"))[2];

    is $doit->file_atomic_write("$tempdir/1st", sub {
				    my $fh = shift;
				    print $fh "changed content\n";
				}), 1;
    is slurp("$tempdir/1st"), "changed content\n", 'content of existent file changed';
    my $mode_after = (stat("$tempdir/1st"))[2];
    is $mode_after, $mode_before, 'mode was preserved';
    no_leftover_tmp $tempdir;
}

{
    is $doit->file_atomic_write("$tempdir/1st", sub {
				    my($fh, $filename) = @_;
				    $doit->system($^X, '-e', 'open my $ofh, ">", shift or die $!; print $ofh "external program writing the contents\n"; close $ofh or die $!', $filename);
				}), 1;
    is slurp("$tempdir/1st"), "external program writing the contents\n", 'filename parameter was used';
    no_leftover_tmp $tempdir;
}

for my $opt_def (
		 [tmpsuffix => '.another_suffix'],
		 [tmpdir => "$tempdir/another_tmp"],
		) {
    my $opt_spec = "@$opt_def";
    is $doit->file_atomic_write("$tempdir/1st",
				sub {
				    my $fh = shift;
				    print $fh $opt_spec;
				}, @$opt_def), 1;
    is slurp("$tempdir/1st"), $opt_spec, "atomic write with opts: $opt_spec";
    if ($opt_def->[0] eq 'tmpsuffix') {
	no_leftover_tmp $tempdir, $opt_def->[1];
    } else {
	no_leftover_tmp $tempdir;
    }
}

{ # check change
    is $doit->file_atomic_write("$tempdir/checked",
				sub {
				    my $fh = shift;
				    print $fh "checked change\n";
				}, check_change => 1), 1, "checked change (non-existing file before)";

    is $doit->file_atomic_write("$tempdir/checked",
				sub {
				    my $fh = shift;
				    print $fh "checked change\n";
				}, check_change => 1), 0, 'no change detected';

    is slurp("$tempdir/checked"), "checked change\n";

    is $doit->file_atomic_write("$tempdir/checked",
				sub {
				    my $fh = shift;
				    print $fh "now there's a change\n";
				}, check_change => 1), 1, 'change on existing file';

    is slurp("$tempdir/checked"), "now there's a change\n";

    no_leftover_tmp $tempdir;
}

{ # dry-run check
    my $old_content = slurp("$tempdir/1st");
    is $doit_dryrun->file_atomic_write("$tempdir/1st", sub {
					   my $fh = shift;
					   print $fh "this is dry run mode\n";
				       }), 1;
    is slurp("$tempdir/1st"), $old_content, 'nothing changed in dry run mode';
    no_leftover_tmp $tempdir;
}

{ # dry-run with non-existing file
    for my $testfile ("$tempdir/non-existing", "$tempdir/non-existting-dir/non-existing") {
	is $doit_dryrun->file_atomic_write($testfile, sub {
					       my $fh = shift;
					       print $fh "this is dry run mode\n";
					   }), 1;
	ok !-e $testfile, 'file still non-existing after dry-run';
	no_leftover_tmp $tempdir;
    }
}

SKIP: {
    skip "No BSD::Resource available", 1
	if !eval { require BSD::Resource; 1 };
    skip "No fork on Windows", 1
	if $^O eq 'MSWin32';
    my $pid = fork;
    die "Cannot fork: $!" if !defined $pid;
    if ($pid == 0) {
	my $limit_fsize = 100;
	my $write_size = 1024;
	require BSD::Resource;
	BSD::Resource::setrlimit(BSD::Resource::RLIMIT_FSIZE(), $limit_fsize, $limit_fsize)
	    or die "Cannot limit fsize: $!";
	$SIG{XFSZ} = 'IGNORE'; # otherwise the process would be just killed
	eval {
	    $doit->file_atomic_write("$tempdir/1st",
				     sub {
					 my $fh = shift;
					 print $fh "x" x $write_size;
				     }); # should fail
	};
	if ($@ =~ m{Error while closing temporary file}) {
	    #diag "Got $@";
	    exit 0;
	} else {
	    diag "No or unexpected exception: $@";
	    exit 1;
	}
    }
    waitpid $pid, 0;
    is $?, 0, 'Write failed, probably got EFBIG';
    no_leftover_tmp $tempdir;
}

SKIP: {
    skip "No /dev/full available", 1 if !-w '/dev/full';
    my $old_content = slurp("$tempdir/1st");
    eval { 
	$doit->file_atomic_write("$tempdir/1st",
				 sub {
				     my $fh = shift;
				     print $fh "/dev/full testing\n";
				 }, tmpdir => '/dev/full');
    };
    like $@, qr{Error while closing temporary file}, 'Cannot write to /dev/full as expected';
    is slurp("$tempdir/1st"), $old_content, 'content still unchanged';
    no_leftover_tmp $tempdir;
}

SKIP: {
    my $res = get_another_filesystem(); # note: %$res contains also a scope_cleanup guard
    skip $res->{skip}, 1 if $res->{skip};

    my $other_fs_dir = $res->{other_fs_dir};

    $doit->utime(0,0,"$tempdir/1st");
    my $mode_before = (stat("$tempdir/1st"))[2];
    my $time = time;
    is $doit->file_atomic_write("$tempdir/1st",
				sub {
				    my $fh = shift;
				    print $fh "File::Copy::move testing\n";
				}, tmpdir => $other_fs_dir), 1;
    is slurp("$tempdir/1st"), "File::Copy::move testing\n", "content OK after using cross-mount move";
    my $mode_after = (stat("$tempdir/1st"))[2];
    is $mode_after, $mode_before, 'mode was preserved';
    my $mtime_after = (stat("$tempdir/1st"))[9];
    cmp_ok $mtime_after, ">=", $time, 'current mtime';

    is $doit->file_atomic_write("$tempdir/fresh",
				sub {
				    my $fh = shift;
				    print $fh "fresh file with File::Copy::move\n";
				}, tmpdir => $other_fs_dir), 1;
    is slurp("$tempdir/fresh"), "fresh file with File::Copy::move\n", "cross-mount move with fresh file";

    {
	my @stat;

	is $doit->file_atomic_write("$tempdir/my_fresh_mode",
				    sub {
					my $fh = shift;
					print $fh "using mode and File::Copy::move (fresh)\n";
				    }, tmpdir => $other_fs_dir, mode => 0400), 1;
	is slurp("$tempdir/my_fresh_mode"), "using mode and File::Copy::move (fresh)\n", "cross-mount move with fresh file";
	@stat = stat("$tempdir/my_fresh_mode");
	is(($stat[2] & 07777), ($^O eq 'MSWin32' ? 0444 : 0400), 'mode option on newly created file');

	is $doit->file_atomic_write("$tempdir/my_fresh_mode",
				    sub {
					my $fh = shift;
					print $fh "using mode and File::Copy::move (existing)\n";
				    }, tmpdir => $other_fs_dir, mode => 0600), 1;
	is slurp("$tempdir/my_fresh_mode"), "using mode and File::Copy::move (existing)\n", "cross-mount move with existing file";
	@stat = stat("$tempdir/my_fresh_mode");
	is(($stat[2] & 07777), ($^O eq 'MSWin32' ? 0666 : 0600), 'mode option on existing file');
    }

    { # dry-run check
	my $old_content = slurp("$tempdir/1st");
	is $doit_dryrun->file_atomic_write("$tempdir/1st", sub {
					       my $fh = shift;
					       print $fh "this is dry run mode\n";
					   }, tmpdir => $other_fs_dir), 1;
	is slurp("$tempdir/1st"), $old_content, 'nothing changed in dry run mode';
	no_leftover_tmp $other_fs_dir, '';
    }
}

# Find or even create another filesystem for
# cross-mount tests. Currently implemted:
# - if /run/user/$uid exists, then use this one (usually
#   it's on a separate tmpfs)
# - if a lot of conditions match (linux, no container,
#   sudo possible...), then create a filesystem on
#   the fly; it will cleaned up later
sub get_another_filesystem {
    if ($ENV{XDG_RUNTIME_DIR} && -d $ENV{XDG_RUNTIME_DIR} && -w $ENV{XDG_RUNTIME_DIR}) {
	my $xdg_dev     = (stat $ENV{XDG_RUNTIME_DIR})[0];
	my $tempdir_dev = (stat $tempdir)[0];
	if ($xdg_dev != $tempdir_dev) {
	    my $other_fs_dir = tempdir('doit_XXXXXXXX', DIR => $ENV{XDG_RUNTIME_DIR}, CLEANUP => 1);
	    return { other_fs_dir => $other_fs_dir };
	}
    }

    return { skip => "Mounting fs only implemented for linux" } if $^O ne 'linux';
    return { skip => "Cannot mount in linux containers" } if TestUtil::in_linux_container($doit);
    return { skip => "dd not available" } if !$doit->which("dd");
    return { skip => "mkfs not available" } if !-x "/sbin/mkfs";
    my $sudo = TestUtil::get_sudo($doit, info => \my %info);
    return { skip => $info{error} } if !$sudo;

    my $fs_file = "$tempdir/testfs";
    $doit->system(qw(dd if=/dev/zero), "of=$fs_file", qw(count=1 bs=1MB));
    $doit->system(qw(/sbin/mkfs -t ext3), $fs_file);
    my $mnt_point = "$tempdir/testmnt";
    $doit->mkdir($mnt_point);
    my $mount_scope = new_scope_cleanup {
	$sudo->system(qw(umount), $mnt_point);
    };
    $sudo->system(qw(mount -o loop), $fs_file, $mnt_point);
    $sudo->mkdir("$mnt_point/dir");
    $sudo->chown($<, undef, "$mnt_point/dir");

    return { other_fs_dir => "$mnt_point/dir", scope_cleanup => $mount_scope };
}
