# -*-perl-*- i/o

use Config;
BEGIN {
    if ($^O eq 'MSWin32') {
	print "1..0 # skipped; Win32 supports select() only on sockets\n";
	exit;
    }
}

use Test; plan tests => 8;
use Event qw(loop unloop);
use Event::Watcher qw(R W);
use Symbol;

#$Event::DebugLevel = 3;

eval { Event->io };
ok $@, "/nothing to watch/";

eval { Event->io(fd => \*STDIN, cb => \&die, poll => 0) };
ok $@, "/nothing to watch/";

my $cannot_detect_bogus_fd;
if ($Config{osname} eq 'darwin' or $Config{osname} eq 'gnu' or
    $Config{archname} =~ m/^armv5tejl/) {
    # GNU/Hurd's poll returns with -EBADF which is accurate
    # but we cannot determine which fd is bad.
    $cannot_detect_bogus_fd = 'Cannot detect bogus file descriptors';
}

my $noticed_bogus_fd=0;
my $bogus_timeout=0;
my $bogus;
if (!$cannot_detect_bogus_fd) {
    $bogus = Event->io(desc => 'oops', poll => 'r', fd => 123,
		      timeout => .1, cb => sub {
			  ++$bogus_timeout;
		      });
}

$SIG{__WARN__} = sub {
    my $is_it = $_[0] =~ m/\'oops\' was unexpectedly/;
    if ($is_it) {
	++$noticed_bogus_fd;
    } else {
	warn $_[0]
    }
};

sub new_pipe {
    my ($cnt) = @_;
    my ($r,$w) = (gensym, gensym);
    pipe($r,$w);

    Event->io(desc => "r", poll => 'r', fd => $r, cb => sub {
		  my $e = shift;
		  my $w=$e->w;
		  if ($e->got & R) {
		      my $buf;
		      my $got = sysread $w->fd, $buf, 1;
		      die "sysread: $!"
			  if !defined $got;
		      die "sysread: pipe closed?"
			  if $got == 0;
		      ++$$cnt;
		  }
	      });
    Event->io(desc => 'w', poll => 'w', fd => $w, cb => sub {
		  my $e = shift;
		  my $w=$e->w;
		  if ($e->got & W) {
		      my $got = syswrite $w->fd, '.', 1;
		      die "syswrite: $!"
			  if !defined $got;
		      die "syswrite: pipe closed?"
			  if $got == 0;
		  }
	      });
}

my $count = 0;
new_pipe(\$count);

my $hit=0;
my $once = Event->io(timeout => .01, repeat => 0, cb => sub { ++$hit });

Event->io(timeout => 2, repeat => 0,
	  cb => sub {
	      ok $count > 0;
	      ok $hit, 1;
	      ok $once->timeout, 0;
	      unloop;
	  });

loop();

skip $cannot_detect_bogus_fd, $noticed_bogus_fd, 1;
skip $cannot_detect_bogus_fd, $bogus && !defined $bogus->fd;
skip $cannot_detect_bogus_fd, $bogus_timeout > 0;
