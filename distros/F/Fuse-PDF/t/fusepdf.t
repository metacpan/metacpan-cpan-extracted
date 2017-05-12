use warnings;
use strict;
use File::Spec;
use File::Temp qw();
use File::Copy qw();
use POSIX qw(WEXITSTATUS);
use English qw(-no_match_vars);
use Time::HiRes qw();
use Test::Virtual::Filesystem;
use Test::More;
use Fuse::PDF;

plan tests => Test::Virtual::Filesystem->expected_tests(+1);

my $tmpdir = $ENV{PWD} && $ENV{PWD} eq '/Users/chris/Work/chrisdolan/Fuse-PDF'
    ? '/tmp/fusepdf_test' 
    : File::Temp::tempdir(CLEANUP => 1);
mkdir $tmpdir if !-d $tmpdir;
my $pdffile = File::Spec->catfile($tmpdir, 'mnt.pdf');
my $mntdir = File::Spec->catfile($tmpdir, 'mnt');
my $logfile = File::Spec->catfile($tmpdir, 'mnt.log');

File::Copy::copy(File::Spec->catfile('t', 'test.pdf'), $pdffile);
mkdir $mntdir;

use Net::Server::Daemonize qw();
my $fs = Fuse::PDF->new($pdffile);
if (0 == Net::Server::Daemonize::safe_fork()) {
   Net::Server::Daemonize::daemonize($EFFECTIVE_USER_ID, $EFFECTIVE_GROUP_ID, undef);
   open STDOUT, '>', $logfile;
   open STDERR, '>&', \*STDOUT;
   $fs->mount($mntdir, {debug => 1});
   exit 0;
}

sub is_mounted {
   my $diag = -d '/proc' ? `cat /proc/mounts` : `mount`;
   return $diag =~ m{ (?:/private)?$mntdir };
}

my $success;
for (1..50) {
   Time::HiRes::usleep(100_000); # == 100 milliseconeds == 0.1 seconds
   if (is_mounted()) {
      $success = 1;
      last;
   }
}
die 'Failed to mount the filesystem' if !$success;

my $test = Test::Virtual::Filesystem->new({mountdir => $mntdir, compatible => '0.08'});
# Leave symlink default alone.  Test::Virtual::Filesystem knows best.
$test->enable_test_xattr(1);
$test->enable_test_chown(0);
$test->enable_test_permissions(0);
$test->enable_test_special(0);
$test->enable_test_nlink(0);
$test->enable_test_hardlink(0);
$test->runtests;

eval {
   require Test::Memory::Cycle;
};
SKIP: {
   if ($EVAL_ERROR) {
      skip 1, 'Optional Test::Memory::Cycle not available';
   }
   Test::Memory::Cycle::memory_cycle_ok($fs);
}

#<STDIN>;  # pause to let me fiddle with the fs manually before unmounting

system 'umount', $mntdir;
if (POSIX::WEXITSTATUS($?) != 0) {
   system 'fusermount', '-u', $mntdir;
   if (POSIX::WEXITSTATUS($?) != 0) {
      die 'Failed to unmount the filesystem';
   }
}

__END__

# Local Variables:
#   mode: perl
#   perl-indent-level: 3
#   cperl-indent-level: 3
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab :
