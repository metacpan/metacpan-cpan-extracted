#!/usr/bin/perl

#
# mainloop stuff.
#

use strict;
use warnings;
use Config;

print "1..30\n";

use Glib qw/:constants/;

my $have_fork = 0;
my $fork_excuse;
{
  my $pid = fork();
  if (! defined $pid) {
    $fork_excuse = "error $!";
  } elsif ($pid == 0) {
    # child
    exit (0);
  } elsif ($pid < 0) {
    # parent, perlfork
    $fork_excuse = "perlfork fakery";
    waitpid ($pid, 0);
  } else {
    # parent, real fork
    $have_fork = 1;
    waitpid ($pid, 0);
  }
}


print "ok 1\n";

=out

GPerlClosures are used for Timeouts, Idle and IO watch handlers in addition
to GSignal stuff.

=cut

my $timeout = undef;

print "ok 2\n";
Glib::Idle->add (sub {print "ok 4 - idle one-shot\n"; 0});
Glib::Idle->add (sub {
		 print "ok 5 - another idle, but this one dies\n";
		 die "killer";
		 print "not ok - after die, shouldn't get here!\n";
		 1 # return true from idle to be called again; we
		   # should never get here, though
	});
$timeout = Glib::Timeout->add (1000, sub {
		    warn "!!!! should never get called";
		    die "oops" });
# timeouts and idles only get executed when there's a mainloop.
{
my $loop = Glib::MainLoop->new;
# the die will simply jump to the eval, leaving side effects in place.
# we have to kill the mainloop ourselves.
local $SIG{__DIE__} = sub {
		print "ok 6 - in __DIE__ handler\n";
		$loop->quit;
	};
local $SIG{__WARN__} = sub {
		print ""
		    . ($_[0] =~ /unhandled exception in callback/
		       ? "ok 7"
		       : "not ok - got something unexpected in __WARN__"
		      )
		    . "\n";
	};
print "ok 3 - running in eval\n";
$loop->run;
# remove this timeout to avoid confusing the next test.
Glib::Source->remove ($timeout);
}

# again, without dying in an idle this time
print "ok 8\n";
Glib::Timeout->add (100, sub { 
		    print "ok 10 - dying with 'waugh'\n";
		    die "waugh"
		    });
my $loop = Glib::MainLoop->new;
print "ok 9 - running in eval\n";
Glib->install_exception_handler (sub {
		print "ok 11 - killing loop from exception handler\n";
		$loop->quit;
		0});
$loop->run;


# this time with IO watchers
use Data::Dumper;

# There's a bug in glib which prevents io channels from marshalling
# properly here.  we don't have versioning API in Glib (yet), so
# we can't do much but just skip this.

if ($Config{archname} =~ m/^(x86_64|mipsel|mips|alpha)/
    && (!Glib->CHECK_VERSION (2,2,4))) {
	print "ok 12 # skip bug in glib\n";
	print "ok 13 # skip bug in glib\n";
	print "ok 14 # skip bug in glib\n";

} elsif ($^O eq "MSWin32") {
	print "ok 12 # skip add_watch on win32\n";
	print "ok 13 # skip add_watch on win32\n";
	print "ok 14 # skip add_watch on win32\n";
} else {
	print "ok 12\n";
	open IN, $0 or die "can't open file\n";
	Glib::IO->add_watch (fileno IN,
		     [qw/in err hup nval/], 
		     sub {
		     	local $/ = undef;
			#print Dumper(\@_);
			$_ = <IN>;
			#print "'$_'";
			#print "eof - ".eof ($_[0])."\n";
			if (eof $_[0]) {
				print "ok 14 - eof, dying with 'done\\n'\n";
				die "done\n";
			}
			1;
		     });
	$loop = Glib::MainLoop->new;
	print "ok 13 - running in eval\n";
	Glib->install_exception_handler (sub {$loop->quit; 0});
	$loop->run;
}


# 1.072 fixes the long-standing "bug" that perl's safe signal handling
# caused asynchronous signals not to be delivered while a main loop is
# running (because control stays in C).  let's make sure that we can
# get a 1 second alarm before a 5 second timeout has a chance to fire.
if ($^O eq 'MSWin32') {
	# XXX Win32 doesn't do SIGALRM the way unix does; either the alarm
	# doesn't interrupt the poll, or alarm just doesn't work.
	my $reason = "async signals don't work on win32 like they do on unix";
	print "ok 15 # skip $reason\n";
	print "ok 16 # skip $reason\n";
} else {
	$loop = Glib::MainLoop->new;
	$SIG{ALRM} = sub {
		print "ok 15 - ALRM handler\n";
		$loop->quit;
	};
	my $timeout_fired = 0;
	Glib::Timeout->add (5000, sub {
		$timeout_fired++;
		$loop->quit;
		0;
	});
	alarm 1;
	$loop->run;
	print ""
	    . ($timeout_fired ? "not ok" : "ok")
	    . " 16 - 1 sec alarm handler fires before 5 sec timeout\n";
}

if (Glib->CHECK_VERSION (2, 4, 0)) {
	print Glib::main_depth() == 0 ?
	  "ok 17\n" : "not ok 17\n";
} else {
	print "ok 17 # skip main_depth\n";
}

print $loop->is_running ?
  "not ok 18\n" : "ok 18\n";

print Glib::MainContext->new ?
  "ok 19\n" : "not ok 19\n";

print Glib::MainContext->default ?
  "ok 20\n" : "not ok 20\n";

print $loop->get_context ?
  "ok 21\n" : "not ok 21\n";

print Glib::MainContext->new->pending ?
  "not ok 22\n" : "ok 22\n";

if (Glib->CHECK_VERSION (2, 12, 0)) {
  print Glib::MainContext->new->is_owner ?
    "not ok 23\n" : "ok 23\n";
  print Glib::MainContext::is_owner(undef) ?
    "not ok 24\n" : "ok 24\n";
} else {
  print "ok 23 # skip\n";
  print "ok 24 # skip\n";
}

if (Glib->CHECK_VERSION (2, 14, 0)) {
  my $loop = Glib::MainLoop->new;
  Glib::Timeout->add_seconds (1, sub {
    print "ok 25 - in timeout handler\n";
    $loop->quit;
    return FALSE;
  });
  $loop->run;
} else {
  print "ok 25 # skip\n";
}


{
  my $skip_reason = undef;
  if (! $have_fork) {
    $skip_reason = "no fork: $fork_excuse";
  }
  if (! Glib->CHECK_VERSION (2, 4, 0)) {
    $skip_reason = 'need glib >= 2.4';
  }
  if ($^O eq 'freebsd' || $^O eq 'netbsd') {
    if ($Config{ldflags} !~ m/-pthread\b/) {
      $skip_reason = 'need a perl built with "-pthread" on freebsd/netbsd';
    }
  }
  if (defined $skip_reason) {
    print "ok 26 # skip: $skip_reason\n";
    print "ok 27 # skip\n";
    print "ok 28 # skip\n";
    print "ok 29 # skip\n";
    print "ok 30 # skip\n";
    goto SKIP_CHILD_TESTS;
  }
  my $pid = fork();
  if (! defined $pid) {
    die "oops, cannot fork: $!";
  }
  if ($pid == 0) {
    # child
    require POSIX;
    POSIX::_exit(42); # no END etc cleanups
  }
  # parent
  my $loop = Glib::MainLoop->new;
  my $userdata = [ 'hello' ];
  my $id = Glib::Child->watch_add ($pid, sub { die; }, $userdata);
  require Scalar::Util;
  Scalar::Util::weaken ($userdata);
  print '', (defined $userdata ? 'ok' : 'not ok'),
    " 26 - child userdata kept alive\n";
  print '', (Glib::Source->remove($id) ? 'ok' : 'not ok'),
    " 27 - child source removal\n";
  print '', (! defined $userdata ? 'ok' : 'not ok'),
    " 28 - child userdata now gone\n";

  # No test of $status here, yet, since it may be a raw number on ms-dos,
  # instead of a waitpid() style "code*256".  Believe there's no
  # POSIX::WIFEXITED() etc on dos either to help examining the value.
  my $timer_id;
  Glib::Child->watch_add ($pid,
                          sub {
                            my ($pid, $status, $userdata) = @_;
                            print '', ($userdata eq 'hello' ? 'ok' : 'not ok'),
                              " 29 - child callback userdata value\n";
                            print "ok 30 - child callback\n";
                            $loop->quit;
                          },
                          'hello');
  $timer_id = Glib::Timeout->add
    (30_000, # 30 seconds should be more than enough for child exit
     sub {
       warn "*** Oops, child watch callback didn't run\n";
       print "not ok 29\n";
       print "not ok 30\n";
       $loop->quit;
       return Glib::SOURCE_CONTINUE;
     });
  $loop->run;
  Glib::Source->remove ($timer_id);
}
SKIP_CHILD_TESTS:


__END__

Copyright (C) 2003-2005 by the gtk2-perl team (see the file AUTHORS for the
full list)

This library is free software; you can redistribute it and/or modify it under
the terms of the GNU Library General Public License as published by the Free
Software Foundation; either version 2.1 of the License, or (at your option) any
later version.

This library is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.  See the GNU Library General Public License for more
details.

You should have received a copy of the GNU Library General Public License along
with this library; if not, write to the Free Software Foundation, Inc.,
51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
