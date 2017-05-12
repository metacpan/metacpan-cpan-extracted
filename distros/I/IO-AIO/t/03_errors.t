#!/usr/bin/perl

use Fcntl;
use Test;
use POSIX qw(ENOENT EACCES EBADF);
use FindBin;
use lib "$FindBin::Bin";
use aio_test_common;

BEGIN { plan tests => 12 }

IO::AIO::min_parallel 2;

my $tempdir = tempdir();

my $some_dir  = "$tempdir/some_dir";
my $some_file = "$some_dir/some_file";
my $some_link = "$some_dir/some_link";

# create a file in a non-existent directory
aio_open $some_file, O_RDWR|O_CREAT|O_TRUNC, 0, sub {
    ok((!defined $_[0]) && $! == ENOENT);
};
pcb;

# now actually make that file
ok(mkdir $some_dir);
aio_open $some_file, O_RDWR|O_CREAT|O_TRUNC, 0644, sub {
    my $fh = shift;
    ok(defined $fh);
    print $fh "contents.";
    ok(-e $some_file);
    close $fh;
};
pcb;

# test error on unlinking nonexistent file
aio_unlink "$some_dir/notfound.txt", sub {
    ok($_[0] < 0);
    ok($! == ENOENT);
};
pcb;

# write to file open for reading
ok(open(F, $some_file)) or die $!;
eval { aio_write *F, 0, 10, "foobarbaz.", 0, sub { ok (0) } };
ok ($@ =~ /mode mismatch/);
pcb;

close F;

aio_symlink "\\test\\", $some_link, sub {
   if ($^O eq "cygwin" or $^O eq "MSWin32") {
      ok (1);
      ok (1);
   } else {
      ok (!$_[0]);
      ok ("\\test\\" eq readlink $some_link);
   }
};
pcb;
unlink $some_link;

# test unlinking and rmdir
aio_unlink $some_file, sub {
   ok (!shift);
};
pcb;
aio_rmdir $some_dir, sub {
   ok (!shift);
};
pcb;



