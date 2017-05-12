#!/usr/bin/perl -w
use warnings;

=head1 DESCRIPTION

Test those bits of the functionality of test-link that can be done
safely without any network connection or servers..  Unfortunately this
mostly means behavior where it doesn't do anything.

We mostly don't want to test things which require a working network
connection (unscalable and unreliable)

We don't want much external configuration because this could cause
confusion.

We don't want to take too long becuase this should be run by every
single person trying to install the software.

=head1 TESTS

first we test normal http

then we try to test other protocols

=cut

use Cwd;

$ENV{HOME}=cwd() . "/t/homedir";
$config=$ENV{HOME} . "/.link-control.pl";
die "LinkController test config file, $config missing." unless -e $config;

BEGIN {print "1..15\n"}

@start = qw(perl -Iblib/lib);

#$verbose=255;
$verbose=0;
$fail=0;
sub nogo {print "not "; $fail=1;}
sub ok {my $t=shift; print "ok $t\n"; $fail=0}

do "t/config/files.pl" or die "files.pl script not read: " . ($@ ? $@ :$!);
#die "files.pl script failed $@" if $@;

-e $_ and die "file $_ exists" foreach ($lonp, $phasl, $linkdb);

# create a "urllist" file from the directories

nogo if system @start, qw(blib/script/extract-links http://www.test.nowhere/
			  test-data/sample-infostruc/),
                          "--config-file=$conf", 
                          ($::verbose ? '--verbose' : '--silent');

ok(1);

#nogo unless ( -e $lonp and -e $phasl and -e $urls);

ok(2);

#FIXME: delete this test

#nogo if system @start, 'blib/script/links-from-listfile', 'test-links.bdbm',
#		'urllist';

ok(3);

nogo unless ( -e $lonp and -e $phasl and -e $linkdb );

ok(4);

unlink $sched;

die "failed to delete schedule" if -e $sched;
#check we can tell the schedule doesn't exist.
$command= (join (" ", @start, 'blib/script/test-link',"--config-file=$conf",
		 ($::verbose ? '--verbose' : '--silent')) );
nogo unless system "$command 2> /dev/null";

ok(5);

nogo if system @start, 'blib/script/build-schedule', '--spread-time=100',
  "--config-file=$conf", ($::verbose ? '--verbose' : ('--silent', '--no-warn'));

ok(6);

die "failed to create schedule" unless -e $sched;

#check we can run and do no links; the schedule has just been built, so
#when we set the halt time in the past none of the links should match.
nogo if system @start, 'blib/script/test-link', '--halt-time=-1000',
  "--config-file=$conf", '--sequential', ($::verbose ? '--verbose' : '--silent');

ok(7);

unlink $sched;
die "failed to delete schedule" if -e $sched;

unlink $linkdb;
die "failed to delete schedule" if -e $linkdb;

ok(8);


nogo if system @start, qw(blib/script/extract-links http://www.test.nowhere/
			  test-data/multi-protocol-infostruc/),
                          "--config-file=$conf", ($::verbose ? '--verbose' : '--silent');

ok(9);


#FIXME: delete this test

#nogo if system @start, 'blib/script/links-from-listfile', 'test-links.bdbm',
#		'urllist';

ok(10);


nogo if system @start, 'blib/script/build-schedule', '--spread-time=100',
  "--config-file=$conf", ($::verbose ? '--verbose' : ('--silent', '--no-warn'));

die "failed to create schedule" unless -e $sched;

ok(11);

#rebuilding a schedule
nogo if system @start, 'blib/script/build-schedule', '--spread-time=100',
  "--config-file=$conf", ($::verbose ? '--verbose' : ('--silent', '--no-warn'));


die "failed to create schedule" unless -e $sched;

ok(12);

#push @start, '-d';

#check we can run and do nothing to unsupported protocols
nogo if system @start, ( 'blib/script/test-link', '--test-now', '--never-stop',
			 '--max-links=10',
			 ($::verbose ? '--verbose' : ('--silent', '--no-warn')),
			 '--no-waitre=127.0.0.1', "--config-file=$conf", '--sequential' );

ok(13);

#push @start, '-d';

#check that --untested works (should do nothing)
nogo if system @start, ( 'blib/script/test-link', '--test-now', '--never-stop',
			 '--max-links=10',
			 ($::verbose ? '--verbose' : ('--silent', '--no-warn')),
			 '--no-waitre=127.0.0.1', "--config-file=$conf", '--untested' );

ok(14);

use WWW::Link_Controller::Lock;
$WWW::Link_Controller::Lock::silent = 1;
WWW::Link_Controller::Lock::lock($linkdb);
#check we throw an error if lock file exists
$command= join (" ", @start, 'blib/script/test-link', "--config-file=$conf",
		 ($::verbose ? '--verbose' : ('--silent', '--no-warn')));
#FIXME: check the database modtime isn't altered
nogo unless system "$command 2> /dev/null";

ok(15);

