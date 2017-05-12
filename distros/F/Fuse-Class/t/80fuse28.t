#
# test filesystem using test::fuse28.pm test mudule
#

use strict;
use POSIX ":sys_wait_h";
use Test::Class;
use Test::More;
use Fuse;

use test::fuse28;

my $mount_point = "/tmp/fuse-class-test-$<-$$";

my $reason = "no reason (test error?)";

sub start_check {
  #
  # Fuse version must be 2.8 or later for this test.
  #
  my $version = Fuse::fuse_version;
  if ($version < 2.6) {
    $reason = "Fuse version is lower than 2.6.";
    return 0;
  }

  #
  # fusermount command is available?
  #
  my $res = `fusermount -V 2>&1`;
  unless ($res =~ /version/) {
    $reason = "fusermount command is not available.";
    return 0;
  }

  #
  # Test::Virtual::Filesystem
  #
  eval "use Test::Virtual::Filesystem;";
  if ($@) {
    $reason = "Test::Virtual::Filesystem is not available.";
    return 0;
  }

  return 1;
}

#
# start Fuse main loop in child process
#
sub child_process {
  mkdir $mount_point, 0777;
  diag $mount_point;
  die "$mount_point: cannot create directoy: $!" unless (-d $mount_point);

  my $fs = new test::fuse28;
  $fs->main(mountpoint => $mount_point);
}

sub cleanup {
  my $child_pid = shift;

  my $kid = 0;
  my $n = 0;
  do {
    system("fusermount", "-u", $mount_point);
    sleep(1);
    $kid = waitpid $child_pid, WNOHANG;
  } while($kid != $child_pid && $n++ < 10);

  rmdir $mount_point;
}

#
# test start
#
unless (start_check) {
  plan skip_all => $reason;
}
else {
  eval "use Test::Virtual::Filesystem;";
  my $child_pid = -1;

  eval {
    plan tests => 165;

    $child_pid = fork();
    die $! if ($child_pid < 0);

    if ($child_pid == 0) {
      child_process;
      exit 0;
    }

    sleep(3);

    my $test = Test::Virtual::Filesystem->new({mountdir => $mount_point,
					       compatible => '0.08'});
    $test->enable_test_xattr(0);
    $test->enable_test_time(1);
    # $test->enable_test_atime(1);
    # $test->enable_test_mtime(1);
    # $test->enable_test_ctime(1);
    $test->enable_test_permissions(0);
    $test->enable_test_special(0);
    # $test->enable_test_fifo(0);
    $test->enable_test_symlink(1);
    # $test->enable_test_hardlink(0);
    # $test->enable_test_nlink(0);
    # $test->enable_test_chown(0);

    $test->runtests;

    # unlink
    {
	my $fname = "$mount_point/unlink-test";
	unlink $fname;
	open(my $fh, "> $fname");
	close($fh);

	ok(-f $fname);
	unlink $fname;
	ok(!-f $fname);
    }

    # chmod
    {
	my $fname = "$mount_point/chmod-test";
	unlink $fname;
	open(my $fh, "> $fname");
	close($fh);
	chmod(0642, $fname);
	my $perm = (stat $fname)[2] & 0777;
	ok($perm == 0642);
    }

    # ftrunate
    {
	my $fname = "$mount_point/ftruncate-test";
	unlink $fname;
	open(my $fh1, "> $fname");
	print $fh1 "12345";
	close($fh1);

	open(my $fh2, "+< $fname");
	truncate($fh2, 3);
	close($fh2);

	my $size = (stat $fname)[7];
	ok($size == 3);
    }

    # readdir (1)
    {
	my $test_dir = "$mount_point/test";
	my $test_dir_1 = "$test_dir/readdir-type-1";
	mkdir $test_dir, 0777;
	mkdir $test_dir_1, 0777;

	opendir(my $dh, $test_dir_1);

	my @entries;
	while(readdir $dh) {
	    push(@entries, $_);
	}
	is(scalar @entries, 2);
	is(scalar(grep { $_ eq '..' } @entries), 1);
	is(scalar(grep { $_ eq '.' } @entries), 1);
    }

    # readdir (2)
    {
	my $test_dir = "$mount_point/test";
	my $test_dir_2 = "$test_dir/readdir-type-2";
	mkdir $test_dir, 0777;
	mkdir $test_dir_2, 0777;

	opendir(my $dh, $test_dir_2);

	my @entries;
	while(readdir $dh) {
	    push(@entries, $_);
	}

	is(scalar @entries, 2);
	is(scalar(grep { $_ eq '..' } @entries), 1);
	is(scalar(grep { $_ eq '.' } @entries), 1);
    }

    # access
    {
	use POSIX;

	my $test_dir = "$mount_point/test";
	mkdir $test_dir, 0777;

	my $test_dir_bad = "$test_dir/access_no_perm";
	mkdir $test_dir_bad, 0777;
	my $test_dir_ok = "$test_dir/access_with_perm";
	mkdir $test_dir_ok, 0777;

	ok(!POSIX::access($test_dir_bad, &POSIX::R_OK));
	ok(POSIX::access($test_dir_ok, &POSIX::R_OK));
    }

    # ftruncate & fgetattr
    {
	my $test_dir = "$mount_point/test";
	mkdir $test_dir, 0777;

	my $file = "$test_dir/ftruncate_test";
	open(my $fh1, ">", $file);
	print $fh1 "hello world\n";
	close($fh1);

	open(my $fh2, "+<", $file);
	truncate($fh2, 3);

	my @st = stat($fh2);
	is($st[7], 3);

	close($fh2);

	@st = stat($file);
	is($st[7], 3);
    }
  };

  my $err = $@;
  cleanup($child_pid);

  die $err if ($err);
}
