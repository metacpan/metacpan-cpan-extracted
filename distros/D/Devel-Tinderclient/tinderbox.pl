#!/usr/bin/perl -w

# Version: MPL 1.1/GPL 2.0/LGPL 2.1
#
# The contents of this file are subject to the Mozilla Public License Version
# 1.1 (the "License"); you may not use this file except in compliance with
# the License. You may obtain a copy of the License at
# http://www.mozilla.org/MPL/
#
# Software distributed under the License is distributed on an "AS IS" basis,
# WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
# for the specific language governing rights and limitations under the
# License.
#
# The Original Code is The Tinderbox Client.
#
# The Initial Developer of the Original Code is
# Zach Lipton.
# Portions created by the Initial Developer are Copyright (C) 2002
# the Initial Developer. All Rights Reserved.
#
# Contributor(s): Zach Lipton <zach@zachlipton.com>
#
# Alternatively, the contents of this file may be used under the terms of
# either the GNU General Public License Version 2 or later (the "GPL"), or
# the GNU Lesser General Public License Version 2.1 or later (the "LGPL"),
# in which case the provisions of the GPL or the LGPL are applicable instead
# of those above. If you wish to allow use of your version of this file only
# under the terms of either the GPL or the LGPL, and not to allow others to
# use your version of this file under the terms of the MPL, indicate your
# decision by deleting the provisions above and replace them with the notice
# and other provisions required by the GPL or the LGPL. If you do not delete
# the provisions above, a recipient may use your version of this file under
# the terms of any one of the MPL, the GPL or the LGPL.

# This script developed August 2001 for Abisource and perl.


use Tinderconfig;
eval "use $Tinderconfig::mailsystem";
if ($@) {
	die "Error loading mail backend: $@";
}
use strict;

use subs qw( checkerrors restart sendstartmail );


sendstartmail(); #send the mail that says we are underway
my $starttime = time();
my $testfailed = 0;
my $log = "";

sub Log(\$$) { # pass a ref to a string, and a string, string gets concatonated to the referenced string, and output to stdout.
  my $log = shift;
  my $str = shift;
  $$log .= $str;
  print "$str";
  return;
}

if ($Tinderconfig::cvs) { $ENV{CVSROOT} = $Tinderconfig::cvsroot; } # set the CVSROOT env var.
Log($log,"Starting tinderbox session...\n\n");
Log($log,"machine administrator is $Tinderconfig::admin\n");
Log($log,"tinderbox version is 1.4 modelevel: Devel::Tinderclient\n");

Log($log,"perl cvs mode enabled\n") if $Tinderconfig::cvs eq '1';
Log($log,"perl rsync mode enabled\n") if $Tinderconfig::rsync eq '1';
Log($log,"rsync info = $Tinderconfig::rsynccommand\n");

Log($log,"please address all issues with this client to zach\@zachlipton.com\n");
Log($log,"Dumping env vars...\n");

foreach my $key (keys(%ENV))
{
  Log($log,"$key = $ENV{$key}\n");
}

Log($log,"env vars dumped...\n\n");

if ($Tinderconfig::cvs) {
  Log($log,"about to cvs checkout $Tinderconfig::cvsmodule:\n");
  Log($log,`cvs -z3 co $Tinderconfig::cvsmodule 2>&1`); # do the checkout
  Log($log,"cvs checkout complete\n\n");
}
if ($Tinderconfig::rsync) { #handle the rsync pull
    unless ($Tinderconfig::pulldir) {
        failure('$pulldir unset!\n'); # yell! ASSERT! BAD BAD BAD!
    }
    unlink($Tinderconfig::pulldir); # get rid of it
    system("mkdir $Tinderconfig::pulldir");
    chdir("$Tinderconfig::pulldir"); # move into place
    system("$Tinderconfig::rsynccommand"); # do the actual pull
}

checkerrors($log); # see if we had any issues pulling

my $dir = `pwd` || failure($!);
chomp($dir);

if ($Tinderconfig::cvs) {
        chdir("$Tinderconfig::pulldir") || failure($!); # move into place
}

if ($Tinderconfig::prebuild) {
        Log($log,"about to run prebuild task $Tinderconfig::prebuild:\n");
        Log($log,`$Tinderconfig::prebuild 2>&1`);  # do any prebuild tasks we have
        Log($log,"Prebuild tasks complete\n\n");
}

checkerrors($log); # and did anything go wrong?

foreach my $command (@Tinderconfig::buildcommands) { # do the build
        Log($log,"About to run build command: $command\n");
        Log($log,`$command 2>&1`);
        checkerrors($log); # yes, all this error checking is REALLY going to have a 
                                   # perf impact. I'll look into fixing this soon.
# Basically, we need to cache the log output into a temp var and just 
# check that, dumping the temp var into the full log.
        Log($log,"$command complete\n\n");
}

foreach my $test (keys(%Tinderconfig::tests)) {
        Log($log,"About to run test: $test:\n");
        my $successregexp = ${$Tinderconfig::tests{$test}}[0];
        my $builderrorregexp = ${$Tinderconfig::tests{$test}}[1];
        open TEST,"$test 2>&1 |";
        my $tmp = "";
        while (<TEST>) {       # we'll do it this way so we can get the
                $tmp .= $_;    # output as it comes in if you're watching console
                Log($log,$_);
        }
        close TEST;
        if (!$tmp) {
                $testfailed = 1;
                Log($log,"test did not have any output\n\n");
        } elsif ($builderrorregexp && ($tmp =~ m/$builderrorregexp/i)) { # compile error
                Log($log,"$test complete\n");
                Log($log,"$test found FATAL compile errors\n\n");
                failure("Fatal compile errors found");
        } elsif ($tmp =~ m/$successregexp/i) { # success!
                Log($log,"$test complete\n");
                Log($log,"$test passed\n\n");
        } else { # it failed
                $testfailed = 1;
                Log($log,"$test complete\n");
                Log($log,"$test FAILED!\n\n");
        }
}

if (@Tinderconfig::postbuild) {
        foreach my $command (@Tinderconfig::postbuild) {
                Log($log,"about to do postbuild command: $command\n");
                Log($log,`$command 2>&1`);
                checkerrors($log); # here we go again...
                Log($log,"$command complete.\n\n");
        }
} else {
        Log($log,"No postbuild steps defined\n\n");
}

checkerrors($log); # one last time, just to be safe...

if ($testfailed) {
        sendendmail($log, "testfailed");
} else {
        sendendmail($log, "pass");
}
restart();

sub failure {
        Log($log,$_[0]); # add the latest info to the log (if any)
        sendendmail($log,'fail'); # send the failure email
        restart(); # and give it another go
}

sub checkerrors {
        my $log = shift;
        foreach my $currentstate (@Tinderconfig::failurestates) { # go through the failurestates
                if ($log =~ m/$currentstate/i) { # if we hit one
                        failure("fatal error: The following error trigger was found: ".$currentstate."\n"); # go away
                }
        }
}

sub restart {
        sleep(1); #give things a little time to process through the mail system
        chdir($dir); # it doesn't matter if this fails, all the same.
        my $timetaken = (time() - $starttime);
        if ($timetaken < $Tinderconfig::mincycletime) { # wait for cycle time to expire
                my $sleeptime = $Tinderconfig::mincycletime - $timetaken;
                print "Sleeping $sleeptime seconds...\n";
                sleep($sleeptime);
        }
        exec("$0");
        exit();
}
exec("$0");
exit();