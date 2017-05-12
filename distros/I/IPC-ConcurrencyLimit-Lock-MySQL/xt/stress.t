use strict;
use warnings;
use File::Temp;
use IPC::ConcurrencyLimit;
use IPC::ConcurrencyLimit::Lock::MySQL;
use DBI;
use DBD::mysql;
use Time::HiRes qw(sleep);

$| = 1;

our($db, $usr, $pwd, $host, $port);
my $conf_file = 'mysql.dat';
if (-e $conf_file) {
  # eval connection parameters into existance
  my $ok = do $conf_file;
  defined $ok or die "Error loading $conf_file: ", $@||$!;

  unless (defined $db) {
    die "Need mysql credentials for this";
  }
}

my %args = (
  type => 'MySQL',
  lock_name => 'testlock',
  make_new_dbh => sub {
    my $dbh = DBI->connect("DBI:mysql:database=$db;host=$host;port=$port", $usr, $pwd);
    $dbh or die "Could not connect to database '$db'";
    return $dbh;
  },
);


my $nprocs = 10;
my @pids;
PARENT_ONLY: {
  foreach my $child (1..$nprocs) {
    my $pid = fork();
    if ($pid) {
      push @pids, $pid;
    }
    else {
      last PARENT_ONLY;
    }
  }
}

use POSIX ":sys_wait_h";
if (@pids == $nprocs) {
  my $kid;
  do {
    $kid = waitpid(-1, 0);
  } while $kid > 0;
  exit;
}

SCOPE: {
  my $max = 11;
  my @limits = map {
    IPC::ConcurrencyLimit->new(%args, max_procs => $max)
  } (1..$max);

  my @locks_done = ((0) x $max);

  my $work = sub {my $id= shift; sleep 0.001; $locks_done[$id-1] = 1;};

  while ($max != (grep $_, @locks_done)) {
    print "$$ has done " . (scalar(grep $_, @locks_done)) . " out of $max\n";
    my @todo = grep !$locks_done[$_], (0..$max-1);
    my @l = map $limits[$_], @todo;
    my @ids = map $_->get_lock, @l;
    foreach my $id (@ids) {
      print "$$ got lock id " . (defined($id) ? $id : "<undef>") . "\n";
      $work->($id) if defined $id;
    }
    $_->release_lock for @l;
  }
}


