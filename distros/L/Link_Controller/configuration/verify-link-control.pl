#!/usr/bin/perl -w

=head1 NAME

verify-link-control - check that linkcontroller setup is correct

=head1 DESCRIPTION

This program simply loads the configuration for LinkController and
then carries out some simple tests to see if all is as it should be.

If any problems are detected then it suggests corrective action,
either a variable which should be added to the configuration file
(.link-control in the users home directory) or a program which should
be run.

=head1 BUGS

This program needs to have lots of things added

=over 4

=item *

Check that the filenames make sense.

=item *

Check that the files are the correct type.

=item *

Check that the files interact correctly

=item *

Check permissions

=back

=head1 SEE ALSO

L<verify-link-control(1)>; L<extract-links(1)>; L<build-schedule>
L<link-report(1)>; L<fix-link(1)>; L<link-report.cgi(1)>; L<fix-link.cgi>
L<suggest(1)>; L<link-report.cgi(1)>; L<configure-link-control>

The LinkController manual in the distribution in HTML, info, or
postscript formats, included in the distribution.

http://scotclimb.org.uk/software/linkcont/ - the
LinkController homepage.

=cut

use strict;
use warnings;

use Fcntl;
use DB_File;
use MLDBM qw(DB_File);

use WWW::Link_Controller::ReadConf;
use WWW::Link_Controller::Version;
use Data::Dumper;
use WWW::Link;
use Schedule::SoftTime;

use Getopt::Function; #don't need yet qw(maketrue makevalue);

$::opthandler = new Getopt::Function 
  [ "version V>version",
    "usage h>usage help>usage",
    "help-opt=s",
    "verbose:i v>verbose",
  ],  {};

$::opthandler->std_opts;

$::opthandler->check_opts;

die "can't accept any arguments" if @ARGV;

sub usage() {
  print <<EOF;
verify-link-control [options] page-url...

EOF
  $::opthandler->list_opts;
  print <<EOF;

Check that link controller is set up correctly and suggest corrective
action for any problems
EOF
}

sub version() {
  print <<'EOF';
verify-link-control version 
$Id: verify-link-control.pl,v 1.9 2002/01/18 20:32:35 mikedlr Exp $
EOF
}

$::now=time;

my $revision='$Revision: 1.9 $';
use WWW::Link_Controller::Version;
my $version = $WWW::Link_Controller::Version::VERSION;


  print STDOUT <<EOF;
verify-link-control: $revision   LinkController version $version

checking through your configuration.

EOF

unless ($::user_address) {
  print STDOUT <<EOF;

User Email address needs to be defined (\$::user_address) if you want
to test links.  You will be able to make reports from other people's
data though
EOF
}

unless ($::page_index) {
  print STDOUT <<EOF;

Page index variable needs to be defined (\$::page_index) to allow
rebuilding of link index.
EOF
} elsif (! -e $::page_index) {
  print STDOUT <<EOF;

The file $::page_index should exist but
doesn't you may want to build it with extract-links The \$::page_index
variable controls its location.
EOF
}

unless ($::link_index) {
  print STDOUT <<EOF;

Page index variable needs to be defined (\$::link_index) to allow
rebuilding of link index.  It's a filename.
EOF
} elsif (! -e $::link_index) {
  print STDOUT <<EOF;

The file $::link_index should exist but
doesn't.  You need this to generate reports identifying which resource
has a broken link.  You can build it with extract-links The
\$::link_index variable controls its location.
EOF
}

unless ($::links) {
  print STDOUT <<EOF;

Links database variable needs to be defined (\$::links)
to allow reports on the status of links and link checking.
EOF
} elsif (! -e $::links) {
  print STDOUT <<EOF

The file $::links should exist but
doesn't.  You will have to rebuild it using extract-links.  The
\$::links variable controls its location
EOF
}

unless ($::infostrucs) {
  print STDOUT <<EOF;

The \$::infostrucs variable should be defined.  This variable gives
the name of a configuration file which allows extract links to know
where you keep your infostructure(s) (web pages).
EOF
} elsif (! -e $::infostrucs) {
  print STDOUT <<EOF;

The file $::infostrucs should exist but
doesn't you should put configuration of your web pages in it, like so

  directory http://my.webserver.somewhere/ /var/www/html
  www http://dynamic.my.webserver.somewhere
EOF
}

unless ($::base_dir) {
  print STDOUT <<EOF;

Base directory variable should be defined (\$::base_dir) this will
give default definitions for many other variables.  It should be a
directory where LinkController can keep various data files.
EOF
}

#verify index
  #is it in order
  #do keys match in reverse
#verify database
  #are all indexed forms included

defined $::links or do {
  print STDOUT <<EOF;

Can't check databases due to previous configuration errors.  Giving up.
EOF
  exit 1;
};


print STDOUT <<EOF;

Checking through entire schedule and link database; this may take time
EOF

#$::linkdbm =
tie %::links, "MLDBM", $::links, O_RDONLY, 0666, $::DB_HASH
  or die $!;

SCHED: {

  $::check_inverted=0;

  $::schedule or do {
    print STDOUT <<EOF;

Schedule file variable needs to be defined (\$::schedule) to allow the
link testing software to know what to do.  This won't affect your
ability to make reports from other people's data
EOF
    last SCHED;
  };
  -e $::schedule or do {
    print STDOUT <<EOF;

The file $::schedule should exist but
doesn't.  You may want to consider using the program 
build-schedule to create it.  The \$::schedule variable controls its
location.
EOF
    last SCHED;
  };
  my $sched;

  eval { $sched=new Schedule::SoftTime $::schedule; };

  $@ && do {
    if ( $@ =~ m/Permission denied/ ) {
      print STDOUT <<EOF;

You don't seem to have access to the schedule file
  $::schedule
If you want to test links yourself, you need to get access to it.
EOF
      last SCHED;
    } else {
      print STDOUT <<EOF;

If you want to test links, you need to get access to it.
Unknown error trying to access schedule file  $::schedule
$@
EOF
    }
    last SCHED;
  };

  my ($count, $past, $future);

  my ($time,$url) = $sched->first_item();

  defined $time or do {
    print STDOUT <<EOF;

The schedule is empty.  Please try rebuilding it with Build Schedule;
EOF
    last SCHED;
  };

  $::check_inverted=1;
  %::inverted=();

 ENTRY: while ( defined $time ) {
    $time =~ m/^(?:\d+(?:\.\d*)?|\.\d+)$/ or $time < 1 or do {
      print STDOUT <<EOF;

Internal application error; illegal time value $time in schedule.  Try
deleting the schedule and rebuilding with build-schedule.
EOF
      last SCHED;
    };

    exists $::links{$url} or do {
      print STDOUT <<EOF;

Minor application error; non existent link $url
scheduled for testing.  If this recurs over a long period, please
investigate.
EOF
      next ENTRY;
    };

    $::inverted{$url}=$time;

    $time > ( $::now + 3 * 30 * 24 * 60 * 60 ) and do {
      print STDOUT <<EOF;

Link $url scheduled to be tested 
more than three months into the future (now $::now sched $time)
which seems to be unreasonable.  If you didn't do this using
build-schedule, then please investigate
EOF
    };

    $count++;
    $time > $::now ? $future++ : $past++;

  } continue {
    ($time,$url) = $sched->next_item();
  }

  $count < 10 and $past > $future * 0.3 and do {
    print STDOUT <<EOF;

A large proportion of the links in the database are scheduled in the
past.  This may mean that you aren't running test-links often enough.  You
may want to rebuild the schedule with build-schedule.  If you have
very many links to check then you may need to adjust some
parameters... FIXME: which??

Before running test-link again, you probably want to try running
build-schedule in order to avoid getting a pulst of activity.

If you find test-link is running and testing continuously, and still
isn't testing all of your links often enough, then you have reached
the limit of the current design.  You will have to look for ways to
improve it.  Consider contributing (or paying a programmer to
contribute) a parallelised link checking routine.
EOF
  };

}



while ( my ($url,$link) = each %::links ) {
  $url =~ m/\%\+\+refresh_time/ and do {
    $link =~ m/^(?:\d+(?:\.\d*)?|\.\d+)$/ or do {
      print STDOUT <<EOF;

Refresh time on database is invalid.  Try running extract-links and if
it doesn't fix the problem then follow the bug reporting procedure
EOF
    }
  };
  $url =~ m/\%\+\+/ && next; #unknown option maybe we should warn?

  ref $link or do {
    print STDOUT <<EOF;
Database record for $url is $link,
not the reference expected.
EOF
    next;
  };

  my $ref=ref $link;
  #accept subclasses too..
  $ref =~ m/WWW::Link/ or do {
    print STDOUT <<EOF;
Unexpected package $ref for link $url in database.
Expected WWW::Link.
EOF
    next;
  };

  my $lurl;
  eval {
    $lurl = $link->url();
  };

  $@ && do {
    print STDOUT <<EOF;
Something's wrong with the link for $url. \$link->url() doesn't work
EOF
    next;
  };

  $lurl eq $url or do {
    print STDOUT <<EOF;
Link url $lurl does not match database key $url
EOF
  };

  next unless $::check_inverted;

  exists $::inverted{$url} or do {
    print STDOUT <<EOF;
Link url $url is not scheduled for testing.  Use build-schedule to
rebuild the schedule.  If the link should be scheduled, then please
investigate how it stopped being scheduled
EOF
  };
}


