#!/usr/bin/perl -w

=head1 NAME

test-link - test links and update the link database

=head1 SYNOPSIS

 test-link [arguments]

  -V --version            Give version information for this program
  -h --help --usage       Describe usage of this program.
     --help-opt=OPTION    Give help information for a given option
  -v --verbose[=VERBOSITY] Give information about what the program is doing.  
                           Set value to control what information is given.
  --quite -q --silent     Program should generate no output except in case of
			  error.

     --config-file=FILENAME Load in an additional configuration file
  -u --user-address=STRING Email address for user running link testing.
  -H --halt-time=MINUTES  stop after given number of minutes

     --never-stop         keep running without stopping
     --no-robot           Don't follow robot rules.  Dangerous!!!
  -w --no-waitre=NETLOC-REGEX Home HOST regex: no robot rules.. (danger?)!!!
     --test-now           Test links now not when scheduled (testing only)
     --untested           Test all links which have not been tested.
     --sequential         Put links into schedule in order tested (for testing)
  -H --halt-time=MINUTES  stop after given number of minutes
  -L --latest-time=MINUTES  latest time from schedule to stop
  -m --max-links=INTEGER  Maximum number of links to test (-1=no limit)

=head1 DESCRIPTION

This program tests links and stores the information about what it
found into the Link database.

Needs:-

  * link database
  * schedule database

=head1 CONFIGURATION

Configuration is done using the WWW::Link_Controller::ReadConf (3) module.

You may want to explicitly set the user name.

=head1 ROBOT BEHAVIOR

This program is designed to be a well behaved netizen..  That means
that it will try not to put alot of load on a single site.  However,
the program also attempts to work efficeiently through all of the
links it has to check.

In order to achieve these goals the test-link will wait for a delay
period between checks to the same site, but it will try to re-order
it's work so that it always has some link to check.  It looks ahead
up to 100 links.

Making this queue longer will probably not help with efficiency since
an overload is probably a sign that you have many links from the same
site.  If that site is your own to check or you can get an arrangement
with them then you could use a regular expression to allow faster
checking.

=head1 SCHEDULING

Most of the scheduling is handled by Schedule::Softtime which provides
an `I'll get round to you when I can be bothered' scheduler.  We
guarantee that we will never schedule a link earlier than I<min-time>
(defaults to a day) from now.

The suggested time is created by the link (see WWW::Link) for details.
We then check that it's at least a certain amount (hard wired to be
one day at present) into the future.

=cut

use strict;
use English;
use vars qw($now $no_links_so_far);

use Fcntl;
use DB_File;
use Data::Dumper;
use MLDBM qw(DB_File);

#use LinkIndex;
use WWW::Link;
use Schedule::SoftTime;
use WWW::Link::Tester::Adaptive;
use WWW::RobotRules::AnyDBM_File; #we must cache the robots file
use LWP::NoStopRobot;

use LWP::Debug;

#Configuration - we go through %ENV, so you'd better not be running SUID
#eval to ignore if a file doesn't exist.. e.g. the system config

use WWW::Link_Controller;
use WWW::Link_Controller::Lock;
use WWW::Link_Controller::ReadConf;

use Getopt::Function qw(maketrue makevalue);

use WWW::Link_Controller::Version;

sub status_change ($);

#signal handling

#basically, we sync the database and then do what was asked for..
#this is wrong cos we should be setting these with sigaction so that
#we don't get screwed by old SYSV signals.

$::suspend=0;
$::abort=0;
$::all_links_read=0;
$::latest_time_read=0;
@::link_queue=();


$::suspfunc=sub {my $signal=shift; $::suspend=1; $SIG{$signal}=$::abortfunc; };
$SIG{TSTP}=$::suspfunc;

#external termination signals
$::abortfunc=sub {my $signal=shift; $::abort=1;  $SIG{$signal}=$::abortfunc; };
my $signame;
foreach $signame (("INT", "QUIT", "HUP", "USR1", "USR2", "TERM", "PWR")) {
  $SIG{$signame}=$::abortfunc;
}

#internal error condition signals...
#BUS SEGV ILL TRAP IOT FPE
#used for other things
#ALRM PIPE CHLD IO
#irrelevant
#KILL STOP CONT PROF WINCH
#dunno
# TTIN TTOU URG XCPU XFSZ VTALRM

sub check_sigs ();
sub get_first_link();
sub get_next_link(;$);

$no_links_so_far = 0;
$::last_queue_time = 0;
$::lookforward=100; #how many links we check forward if the first in the
                    #queue can't run yet because we are protecting
		    #that host

$::min_delay=60 * 60 * 1; #minimum scheduling delay is 1 hour
#FIXME: configurable parameter??

$::no_waitre="";
$::verbose=0;
$::never_stop=0;
$::start_time = time();
$::next_sched=$::start_time + 1000;
$::halt_time=undef;
$::test_now=0;
$::max_links = 1000 unless defined $::max_links;
$::max_links =~ m/^\d+$/ or die "$::max_links must be a natural number";
$::robot=1;
$::sequential=undef;

$::opthandler = new Getopt::Function
  [ "version V>version",
    "usage h>usage help>usage",
    "help-opt=s",
    "verbose:i v>verbose",
    "silent quite>silent q>silent",
    "no-warn",
#the following info comes from the config file, but overriding it on the 
#command line would be nice
#    "link-file=s l>link-file", #do we need this???
#    "schedule-file=s s>schedule-file", #do we need this???
    "",
    "config-file=s c>config-file",
    "user-address=s u>user-address",
    "halt-time=i H>halt-time",
    "",
    "never-stop",
    "no-robot",  #no short form.. don't want to encourage this much
    "no-waitre=s w>no-waitre",
    "test-now", #also don't encourage
    "untested", #also don't encourage
    "sequential", 
    "halt-time=i H>halt-time",
    "max-links=i m>max-links",
  ],  {
       "no-warn" => [ sub { $::no_warn = 1; },
		      "Avoid issuing warnings about non-fatal problems." ],
       "user-address" => [ \&makevalue,
			   "Email address for user running link testing.",
			   "STRING" ],
       "never-stop" => [ \&maketrue,
		       "keep running without stopping" ],
       "halt-time" => [ sub { $::halt_time=$::start_time + $::value * 60;},
		      "stop after given number of minutes",
		      "MINUTES" ],
       "no-robot" => [ \&maketrue,
		       "Don't follow robot rules.  Dangerous!!!" ],
       #FIXME no-wait
       "no-waitre" => [ \&makevalue,
		     "Home HOST regex: no robot rules.. (danger?)!!!",
		     "NETLOC-REGEX" ],
       "test-now" => [ \&maketrue,
		      "Test links now not when scheduled (testing only)" ],
       "untested" => [ \&maketrue,
		      "Test all links which have not been tested." ],
       "sequential" => [ \&maketrue,
			 "Put links into schedule in order tested "
			 . "(for testing)" ],
       "max-links" => [ \&makevalue,
		      "Maximum number of links to test (-1=no limit)",
		      "INTEGER" ],
       "config-file" => [ sub {
			    eval {require $::value};
			    die "Additional config failed: $@"
			      if $@;
			    #if it's not there die anyway.
			    # compare ReadConf.pm
			  },
			  "Load in an additional configuration file",
			  "FILENAME" ]
      };

$::opthandler->std_opts;

$::opthandler->check_opts;

$::halt_time=$::start_time unless defined $::halt_time;

sub usage() {
  print <<EOF;
test-link [arguments]

EOF
  $::opthandler->list_opts;
  print <<EOF;

Read the link database and test those links which are due to have been
tested, exiting when the next link to be tested is due after the program
start time.

Don't use --no-robot, except for when you are doing local
testing (that is, you aren't connected to the internet proper).

Don't use --never-stop or --test-now except when you are watching what
is happening.
EOF
}

sub version() {
  print <<'EOF';
test-link version
$Id: test-link.pl,v 1.19 2002/01/18 20:32:48 mikedlr Exp $
EOF
}

$Schedule::SoftTime::no_warn=1 if $::no_warn;
$WWW::Link_Controller::Lock::silent=1 if $::silent;

LWP::Debug::level("+trace") if $::verbose;
LWP::Debug::level("+debug") if $::verbose & 1024;


#command-line-end

die "don't accept arguments, giving up\n" if @ARGV;

die 'you must define the $::links configuration variable'
    unless $::links;

print STDERR "locking link database file $::links\n" unless $::silent;

WWW::Link_Controller::Lock::lock($::links);
$::linkdbm = tie %::links, "MLDBM", $::links, O_RDWR, 0666, $DB_HASH
  or die $!;

$::refresh_time=$::linkdbm{$WWW::Link_Controller::refresh_key};
defined $::refresh_time 
    and ( not $::refresh_time =~ m/^(?:\d+(?:\.\d*)?|\.\d+)$/) and do {
  warn "invalid update time on database $::refresh_time";
  $::refresh_time=undef;
};

die 'you must define the $::schedule configuration variable'
    unless $::schedule;
die "there is no schedule file $::schedule" unless -e $::schedule;
#FIXME: this call should not create a schedule database.  Only use an
#existing one.  At time of writing Schedule.pm doesn't support that.
$::sched=new Schedule::SoftTime $::schedule;

print STDERR "test-link begins @ time:$::start_time testing with " unless $::silent;

my $ua;
if ($::robot) {
  print STDERR "a robot ua\n" unless $::silent;
  my $rules = new WWW::RobotRules::AnyDBM_File 'my-robot/1.0', '.robot.cache';
  $ua = new LWP::NoStopRobot 'LinkControllerBot/'
    . $WWW::Link_Controller::Version::VERSION, $::user_address;
  $ua->delay(1);
  unless ($::no_waitre eq "") {
    print STDERR "NoWaitre is $::no_waitre\n" unless $::silent;
    $ua->no_wait($::no_waitre);
  }
} else {
  print STDERR "a normal ua\n" unless $::silent;
  $ua = new LWP::Auth_UA 'No_Robot_Link_Controller/'
    . $WWW::Link_Controller::Version::VERSION, $::user_address;
}


my $tester = new WWW::Link::Tester::Adaptive $ua;

my ($link, $check_time);

END {
  if ($no_links_so_far) {
    print "test link exited at ", $now,
      " having checked $no_links_so_far links\n" unless $::silent;
  }
}

#main loop; reading the next link which is ready to check then
#checking it.

for ( ($link, $check_time)=get_first_link();
      defined $link ;
      ($link, $check_time)=get_next_link() ) {
  my $now=time();
  check_sigs();
#    unless ($::never_stop) {
#      if ($check_time > $::halt_time) {
#        print STDERR "exiting because finished links up to halt time\n";
#        exit 0;
#      }
#    }
#    #FIXME database locking...

  my $url=$link->url();
  my $host_wait = $ua->host_wait_url($url);
  $host_wait=0 unless defined $host_wait;
  my $sched_wait=$check_time - $now + 1;
  my $wait = $sched_wait;
  ($host_wait > $sched_wait) and ( $wait = $host_wait );

  if ($::test_now) {
    print STDERR "going ahead with link.. " .
      "should have waited $wait secs.\n" unless $::silent;
  } else {
    while ($now < $check_time) {
      my $wait=$check_time - $now + 1;
      print STDERR "waiting for $wait seconds to test link\n" if $::verbose;
      sleep ($wait);
      check_sigs();
      my $now=time();
    }
  }

  #for one link only testing. should do maxlinks.
  $::verbose and do {
    print STDERR "testing link $link ";
    ( $now < $check_time )
      and print STDERR ( $check_time - $now ) . " seconds early\n";
    ( $now == $check_time )
      and print STDERR " on time\n";
    ( $now > $check_time )
      and print STDERR ( $now - $check_time ) .	" seconds late\n";
  };

  print STDERR "url is ",$url,"\n" if $::verbose;

  my $was_broken=$link->is_broken();

  $tester->test_link($link);

  status_change($link) if ($link->is_broken() and not $was_broken);

  print STDERR "updating link\n" if $::verbose;;
  update_link($link);
  print STDERR "rescheduling $link\n" if $::verbose;
  $::sched->unschedule($check_time);
  auto_schedule_link($link);
  $no_links_so_far++;

  if ($::max_links and $no_links_so_far == $::max_links) {
    print STDERR "Checked maximum number of links.  Exiting\n"
      unless $::silent;
    exit 0;
  }
}

print STDERR "No more links to check.  Exiting\n" unless $::silent;
exit 0;

exit;

sub check_sigs () {

  #FIXME we aren't syncing the schedule.. this isn't critical as it
  #can always be rebuilt

  if ($::abort==1) {
    #perhaps we should destroy it?
    $::linkdbm->sync();
    die "Aborted due to signal; databases updated\n";
  }
  if ($::suspend==1) {
    $::linkdbm->sync();
    $::suspend=0;
    print STDERR "Stopped due to user generated signal; databases updated\n";
    kill STOP => $$;
    #at this stage we need to reinstall the signal handler.. what
    #happens if we miss the opportunity?  Fortunately nothing, we just
    #get stopped, but we've already synced the database..
  }
}


#=head1 get_first_link ()

sub get_first_link() {
  get_next_link(1);
}

#=head2 get_next_link
#
#This function looks forward in the queue of links and decides which
#one should be checked next.  It needs to know about the UserAgent so
#that it can work out how long it will take before the link can
#actually be scheduled.
#
#note that if there is a large chunk of links in a row from one host
#then we can't share round hits amoung various hosts and slow down
#alot.  That's one reason why the schedule building process should
#randomly spread links into the future.
#
#=cut

sub get_next_link(;$) {
  my $first=shift; #should we load the first link from the queue
  my ($link, $time);
  #loop checks queue is empty and then reads from database to queue if needed
 CASE:  {
    $::verbose && ($#::link_queue > -1) and do {
      print STDERR "link queue looks as follows\n";
      for (my $index=0; $index <= $#::link_queue; $index++) {
	print STDERR $index . ") Link: " . $::link_queue[$index]->[0]
	  . " time " . $::link_queue[$index]->[1] . "\n"
	    . " URL: " . $::link_queue[$index]->[0]->url() . "\n";
      }
      last CASE;
    };
    $::verbose && print STDERR "link queue is empty\n";
  }

  my $index=-1; #a counter for looking through the queue
 DBREAD: while () {
    #loop reads through the remainder of the queue.
  QUEUER: while ($#::link_queue > $index) {
      $index++;
      print STDERR "index in queue is $index\n"
	if $::verbose;
      ($link, $time)=@{$::link_queue[$index]};
      print STDERR "considering link $link from queue\n" if $::verbose;;
      if (skip_for_time($link)) {
	print STDERR "link $link on queue is still waiting around\n"
	  if $::verbose;
	next QUEUER;
      }
      #link from queue is ready to be checked
      print STDERR "link $link on queue now ready to go\n"
	if $::verbose;
      splice @::link_queue, $index, 1;
      return $link, $time;
    }

    print STDERR "none of links in queue are ready\n" if $::verbose;

    $now=time();
    last DBREAD if ( $::all_links_read
		     or ($#::link_queue > $::lookforward)
		     or ($::latest_time_read > $now and (not $::never_stop))
		   );

    if ($first) {
      print STDERR "find first link from the schedule\n" if $::verbose;
      ($link, $time)=first_link();
      $first=0;
    } else {
      print STDERR "find another link from the schedule\n" if $::verbose;
      ($link, $time)=next_link();
    }

    defined $time and do {
      if ( $time < $::last_queue_time) {
	warn "Queue gave out of order link";
      } else {
	$::last_queue_time = $time;
      }
    };

    ( defined ( $link ) ) or do {
      print STDERR "no more links in the schedule\n" if $::verbose;
      $::all_links_read=1;
      last DBREAD;
    };
    $::latest_time_read=$time;
    ($::latest_time_read > $now and (not $::never_stop)) and do  {
      print STDERR "no ready links on the queue\n" if $::verbose;
      $::all_links_read=1;
      last DBREAD;
    };
    (($time < $::halt_time)  || $::never_stop ) or do {
      print STDERR "link is after halt time; not reading\n" if $::verbose;
      $::all_links_read=1;
      last DBREAD;
    };
    #a link for the queue

    #FIXME: load robot rules for this link now so we can then see schedule

    push @::link_queue, [$link, $time];
    print STDERR "added\n" . $#::link_queue . ") Link: " . $link
	 . " time " . $time . "\n" . " URL: " . $link->url() . "\n"
	   if $::verbose;
  }

  my $ref=shift @::link_queue;
  defined $ref or do {
    print STDERR "no links in queue; finished working\n"
      if $::verbose;
    return undef;
  };
  print STDERR "we will just wait for the first link from the queue..\n"
    if $::verbose;
  ($link, $time)=@$ref;
  return $link, $time;
}

sub skip_for_time () {
  $::robot or return 0;
  my $link=shift;
  my $url;
  $url = URI->new($link->url);
  #sometimes this accesses the robots.txt so slow and difficult
  check_sigs();
  print STDERR "about to check for robots access\n" if $::verbose;
  my $scheme = $url->scheme();
  ($scheme eq "http" or $scheme eq "ftp") or return 0;
  $ua->robot_check($url);
  check_sigs();
  my $host_wait = $ua->host_wait_url($url);
  $host_wait=0 unless defined $host_wait;
  print STDERR "host_wait gives  ", $host_wait, " seconds.\n";
 CASE: {
    ( $host_wait > 5) && do {
      #the link is going to have to wait a while anyway
      print STDERR "Link ", $link->url(), " is waiting for net access.\n";
      return 1;
    };
    ( $host_wait > 0) && do {
      print STDERR "Link ", $link->url(), 
	" is ready to go in $host_wait secs.\n";
      return 0;
    };
    print STDERR "Link ", $link->url(), " is ready to go.\n";
    return 0;
  }
}

# =head2 first_link

# Returns the first link that needs to be checked.

# =cut

sub first_link {
  my $time;
  my $name;
  my $link;
  ($time, $name)=$::sched->first_item();
  return undef unless defined $time; # out of items
  $link=$::links{$name};
 CASE: {
    ! (defined $link) && do {
      #the link has probably been deleted from the database
      warn "non existant link scheduled for checking";
      #what happens if you remove the cursor item?? oh well
      ($link, $time)=next_link();
      last CASE;
    };
     $::untested && $link->is_not_checked() and do {
      ($link, $time)=next_link();
      last CASE;
    }
  }
  return $link, $time; #can be undefined..
}

# =head2 next_link

# Returns the next link that needs to be checked.

# =cut

sub DAY () {60*60*24;}

sub next_link {
  my $self=shift;
  my $time;
  my $name;
  my $link;
  while () {
    ($time, $name)=$::sched->next_item();
    return undef unless defined $time; # out of items
    $link=$::links{$name};
    $::untested && (! $link->is_not_checked() ) and do {
      print STDERR "link " . $link->url() . " already tested.. skipping\n"
	if $::verbose;
      next;
    };
    defined $::refresh_time and
      $link->last_refresh() < ( $::refresh_time -  $::max_link_age * DAY)
	and do {
      print STDERR "deleting old link " . $link->url() . " from database";
      delete $::links{$name};
      next;
    };

    last if defined $link;
    #the link has probably been deleted from the database
    warn "non existant link " . $link->url() . " scheduled for checking";
    #what happens if you remove the cursor item?? oh well
  }
  print STDERR "Next link: " . $link . " URL: " . $link->url() . " for time " .
    $time . "\n" if $::verbose;
  return $link, $time;
}

# =head2 update_link

# Updates the link in the database.

# =cut

sub update_link {
  my $link=shift;
  # here be danger.. this could cause multiplication of links in
  # the database if the url function returns variable values..
  # it `shouldn´t´
  print STDERR "New link is " , $link,  Dumper ( $link )
    if $::verbose & 16;
  print STDERR "Before " , Dumper( $::links{$link->url()} ), "\n"
    if $::verbose & 256;
  WWW::Link_Controller::Lock::checklock();
  $::links{$link->url()} = $link;
  print STDERR "After  " , Dumper( $::links{$link->url()} ), "\n"
    if $::verbose & 128;
  #FIXME Fsync???
}

# =head2 auto_schedule_link

# Schedules a link according to when it wants to be scheduled.  We actually
# schedule the URI which should be a unique identifier.

# N.B. this is for use after a link has been tested and checks that
# the link wants to be tested in the future.

# =cut

sub auto_schedule_link {
  my $link=shift;
  die "usage auto_schedule_link(<link>)" unless ref $link;
  my ($sched_time,$vary)=$link->time_want_test();
  die "link failed to return sched time" unless $sched_time;
  my $time=time;
  if ( $::sequential ) {
    $sched_time=$::next_sched;
  } else {
    warn "time logic wrong; just tested ($time) but wants tested at $sched_time"
      if $sched_time < $time;
    print STDERR "Link wants test between $sched_time and "
	. ( $sched_time + $vary ) . "\n" if $::verbose;

    my $earliest=time() + $::min_delay;
    if ( $sched_time < $earliest ) {
      $sched_time = $earliest ;
      print STDERR "forcing link to test at $earliest for minimum delay\n";
    }

    $sched_time += rand($vary);
    if ( $sched_time < $::last_queue_time ) {
      $sched_time=$::last_queue_time+1 ;
      print STDERR "forcing link after end of queue at $::last_queue_time\n";
    }
    print STDERR " will schedule at $sched_time\n" if $::verbose;
  }
  $::sched->schedule(int($sched_time) , $link->url() );
}

=head2 status log handling

During it's operation, test-link can write a log file (to a file given
in the $::link_stat_log configuration variable).  This can be used to
alerts to the webmaster about newly broken links.

=cut

sub status_change ($) {
  my $link=shift;
  defined $::link_stat_log or return undef;
  open STAT, ">$::link_stat_log" or die "couldn't open status log";
  print STAT $link->url(), "\n";
  close STAT or die "couldn't open status log";
}

=head1 LOCKING

test-link uses a very simple application level lock to protect the
links database.  If you bypass this locking it could corrupt the
database.  Only other runs of test-link will follow this locking.

During a run you can run link-report, but there is in principle no
guarantee that it works properly at all.  However it shouldn't
normally do any damage since it has read only access to the database.

Note that the lock is done on the links database filename.

Other programs such as build-schedule and link creation programs should not 

=head1 BUGS

The locking used in the current design could be considered a bug..

There should be a mechanism for detecting that the computer is not
connected to the network at all and aborting the run completely.  This
would avoid false positive broken links.

There is a problem with redirects.  The second request has to wait for
the robot rules to permit it after the first.  We should allow a
number of levels of redirects without waiting...  Maybe this is fixed
best with a parallel agent.

=head1 SEE ALSO

L<verify-link-control(1)>; L<extract-links(1)>; L<build-schedule>
L<link-report(1)>; L<fix-link(1)>; L<link-report.cgi(1)>; L<fix-link.cgi>
L<suggest(1)>; L<link-report.cgi(1)>; L<configure-link-control>

The LinkController manual in the distribution in HTML, info, or
postscript formats, included in the distribution.

http://scotclimb.org.uk/software/linkcont/ - the
LinkController homepage.

=cut
