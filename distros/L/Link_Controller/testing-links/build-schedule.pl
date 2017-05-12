#!/usr/bin/perl -w

=head1 NAME

build-schedule - build a schedule for link checking.

=head1 SYNOPSIS

  build-schedule [options]

   -V --version            Give version information for this program
   -h --help --usage       Describe usage of this program.
      --help-opt=OPTION    Give help information for a given option
   -v --verbose[=VERBOSITY] Give information about what the program is doing.
                            Set value to control what information is given.
   -l --url-list=FILENAME  File with complete list of URLs to schedule
   -s --schedule=FILENAME  Override location of the schedule
   -t --spread-time=SECONDS Time over which to spread checking; default 10 days

      --config-file=FILENAME Load in an additional configuration file

=head1 DESCRIPTION

This program takes a links database and builds an entire schedule from
scratch for them.  This can then be later used by daily-check-links to
check all of the links.

By default C<build-schedule> builds a schedule for all of the links in
your links database but you can give it a list of URLs in a file in
which case the schedule built will only contain those links.

The schedule tries to spread link checking into the future with more
links being checked soon and fewer later.  As links are scheduled for
repeat checking this should work out to a reasonably even rate of
checking.

If there is an already a schedule file in existance, it will be read
and the times in the old database will be reused.  The old database
will be renamed with a .bak extension.

=head1 EXAMPLES

   build-schedule

If everything is set up correctly and you don't have any special needs
then you don't have to give any arguments.

   build-schedule --ignore-links --spread-time=7200

Causes an immediate pulse of activity which tests all of the links in
the database within the next two hours.  Needless to say, this will
cause considerable amounts of network traffic and is a bad idea in
most normal situations.

=head1 BUGS

The program doesn't check the validity of its output database, so if
the output filesystem fills up things can go horrible.  Check afterwards.

=head1 SEE ALSO

L<verify-link-control(1)>; L<extract-links(1)>; L<build-schedule>
L<link-report(1)>; L<fix-link(1)>; L<link-report.cgi(1)>; L<fix-link.cgi>
L<suggest(1)>; L<link-report.cgi(1)>; L<configure-link-control>

The LinkController manual in the distribution in HTML, info, or
postscript formats, included in the distribution.

http://scotclimb.org.uk/software/linkcont/ - the
LinkController homepage.

=cut

use vars qw($sched_margin);
sub check_time ($$;\%) ;

$sched_margin=10; #earliest time we schedule a link to run

use Carp;

use Fcntl;
use DB_File;
use Data::Dumper;
use MLDBM qw(DB_File);

use WWW::Link;
use Schedule::SoftTime;

#Configuration - we go through %ENV, so you'd better not be running SUID
#eval to ignore if a file doesn't exist.. e.g. the system config

use WWW::Link_Controller;
use WWW::Link_Controller::ReadConf;

use Getopt::Function qw(maketrue makevalue);

$::verbose=0;
$::spread_time=60.0 * 60.0 * 24.0 * 10.0;
$::start_offset=0;
$::ignore_link=0;
$::ignore_db=0;

$::opthandler = new Getopt::Function
  [ "version V>version",
    "usage h>usage help>usage",
    "help-opt=s",
    "verbose:i v>verbose",
    "silent quite>silent q>silent",
    "no-warn",
    "",
    "url-list=s l>url-list",
    "schedule=s s>schedule",
    "spread-time=i t>spread-time",
    "start-offset=i S>start-offset",
    "ignore-db d>ignore-db",
    "ignore-link i>ignore-link",
    "no-warn",
    "config-file=s",
#    "old-schedule=s o>old-schedlue",
  ],  {
       "no-warn" => [ sub { $::no_warn = 1; },
		      "Avoid issuing warnings about non-fatal problems." ],
       "url-list" => [ \&makevalue,
		       "File with complete list of URLs to schedule",
		       "FILENAME" ],
#       "old-schedule" => [ \&makevalue, "Location of the old schedule",
#			   "FILENAME" ],
       "schedule" => [ \&makevalue, "Override location of the schedule",
			   "FILENAME" ],
       "config-file" => [ sub {
			    eval {require $::value};
			    die "Additional config failed: $@"
			      if $@;
			    #if it's not there die anyway.
			    # compare ReadConf.pm
			  },
			  "Load in an additional configuration file",
			  "FILENAME" ],
       "spread-time" => [ \&makevalue,
			  "Time over which to spread checking; default 10 " 
			  . "days",
			  "SECONDS" ],
       "ignore-link" => [ \&maketrue,
			  "Set the time with no regard to link status" ],
       "ignore-db" => [ \&maketrue,
			  "Set the time with no regard to curent setting" ],
       "start-offset" => [ \&makevalue,
			   "Time offset from now for starting work (can be "
			   . "negative)",
			   "SECONDS" ],
#       "clear" => [ \&maketrue, "Clear out old entries."]
      };


$::opthandler->std_opts;

$::opthandler->check_opts;

sub usage() {
  print <<EOF;
build-schedule [options]

EOF
  $::opthandler->list_opts;
print <<EOF;

Examine a database of link objects and build a schedule to check those links
which can be used by test-link.
EOF
}
sub version() {
  print <<'EOF';
build-schedule version 
$Id: build-schedule.pl,v 1.14 2002/01/18 20:32:48 mikedlr Exp $
EOF
}

$Schedule::SoftTime::silent = 1 if $::silent;
#command-line-end

die 'you must define the $::links configuration variable'
    unless $::links;
tie %::links, MLDBM, $::links, O_RDONLY, 0666, $DB_HASH
  or die $!;

die 'you must define the $::schedule configuration variable'
    unless $::schedule;

-e $::schedule && do {
  rename($::schedule, $::schedule . ".bak")
    or die "could not rename old schedule";
  $::old_file=$::schedule . ".bak" unless $::old_file;
};

defined $::url_list and not -e $::url_list and
    die "url list file doesn't exist";

#FIXME. This is bad; we must read the entire old schedule into memory in 
#order to invert it.  We could use a temp file?  Still seems ugly..

my $oldsched=new Schedule::SoftTime $::old_file;
my %old_inverted=();
my ($key,$value);
print STDERR "Loading old database\n" if $::verbose;
($key,$value)=$oldsched->first_item;
$count=0;
while ($key){
  $count++;
  die "link name not defined for scheduled time??" unless defined $value;
  print STDERR "$count " if ($::verbose & 32 ) && ($count % 100)==0;
  warn "Link $value scheduled twice. At $key and at "
    . $old_inverted{$value} . " that's wrong."
      if defined $old_inverted{$value};
  $old_inverted{$value}=$key;
} continue {
  ($key,$value)=$oldsched->next_item;
}

print STDERR "Old database loaded\n" if $::verbose;

my $sched=new Schedule::SoftTime $::schedule;
my $now = time + $::start_offset;
my $daystart;
my $name;
my $link;

  #FIXME: full check for valid URLs at this stage.  Has to select all
  #possible valid absoloute urls.


if ($::url_list) {
  #shedule links from a file
  open URLS, "sort $::url_list | uniq |";
 URL: while (my $url=<URLS>) {
    chomp $url;
    $url =~ m/\w{3,}:.*\w{3,}/ or do {
      warn "link $url not sensible??";
    };
    my $link=$::links{$url};
    unless ($link) {
      print STDERR "URL $url doesn't have a link in the database\n"
	if $::verbose;
      next URL;
    }
    my $check_time=check_time($link, $url, %old_inverted);
    print STDERR "Scheduling $url at $check_time\n" if $::verbose;
    $sched->schedule($check_time, $link->url);
  }
} else {
  #shedule all links which are available.

  while (my ($url, $link)=each %::links) {

    $url =~ m/${WWW::Link_Controller::special_regex}/ && do {
      print STDERR "ignoring special key $url\n" if $::verbose;
      next;
    };

    $url =~ m,[a-z][a-z0-9]*:, or do {
      warn "ignoring database key $url - not absolute url";
      next;
    };

    defined $link or do {
      warn "key $url had undefined link" unless $::no_warn;
      next;
    };

    $url =~ m/\w{3,}:.*\w{3,}/ or do {
      warn "link $url not sensible??" unless $::no_warn;
    };
    print STDERR "Scheduling URL $url\n" if $::verbose;
    my $check_time=check_time($link, $url, %old_inverted);
    print STDERR "check $url at $check_time\n" unless $::silent;
    $sched->schedule($check_time, $link->url);
  }
}

exit;

#what should we really do if a link is in the old database but has been 
#scheduled to run prior to now?   I think leave it and just let it queue?

sub check_time ($$;\%) {
  my $link=shift;
  my $url=shift;
  my $inverted=shift;
  my $old_time=$old_inverted{$url};

  confess "usage check_time(<link>,<url>,<invert>) not ($link,$url,$inverted)"
      unless ref $link and defined $url and ((ref $inverted) =~ m/HASH/);

  defined $old_time and not $::ignore_db and do {
    print STDERR "Time found for $url in old database: $old_time\n"
      if $::verbose;
    return $old_time;
  };
  my $check_time=$link->time_want_test();
  print STDERR "New link in schedule.  Time suggested: $check_time\n"
    if $::verbose;
  if ( ( $check_time < ($now + $sched_margin)) or ($::ignore_link) ) {
    $check_time = $now + randsecs ();
    print STDERR "Overriding too old time and using instead $check_time\n"
      if $::verbose;
  }
  return $check_time;
}

# =head3 randsecs

# This function gives a number of seconds between zero and ten days
# spread into the future.

# =cut

sub randsecs {
  my $number = int ( logrand() * $spread_time ) ;
  print STDERR "randsecs generated $number\n" if $::verbose;
  die "should generate positive number" unless $number >= 0;
  return $number;
}

# =head3 logrand

# logrand gives a number which is random, but distributed sort of
# logaritmically between 0 and 1

# =cut

sub logrand {
  my $return=log ( rand(1) +1);
  print STDERR "logrand generated $return\n" if $::verbose;
  return $return;
}


# =head3 add_days

# given a time, this function adds a number of days to that time.  I
# can't see any clean way of doing this.  You cannot guarantee that
# adding twenty four hours worth of seconds will get the same day can
# you?  Leap seconds?  For now we just do it.  

# A (neat?) hack would be to convert the time forward, run daystart and
# see that the difference of the two times was indeed approximately X
# times 24 hours.

# =cut

sub add_days {
  my $time=shift;
  my $days=shift;
  $days=$days * 24 * 60 * 60;
  return $time + $days;
}
