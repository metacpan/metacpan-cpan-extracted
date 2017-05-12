#
# $Id: 52oo-command-filter.t,v 38.2 2012/09/26 16:15:34 jettisu Exp $
#
# (c) 2009-2012 Morgan Stanley & Co. Incorporated
# See ..../src/LICENSE for terms of distribution.
#
# Additional MQSeries::Command test to create, copy, change and delete
# objects.
#

use strict;
use warnings;

our %myconfig;
our $systemdir;
BEGIN {
    require "../util/parse_config";
}

use Data::Dumper;
use Test::More tests => 86;
BEGIN {
    our $VERSION = '1.34';
    use_ok('__APITYPE__::MQSeries' => $VERSION);
    use_ok('MQSeries::QueueManager' => $VERSION);
    use_ok('MQSeries::Command' => $VERSION);
}

SKIP: {
    if ( "__APITYPE__" eq "MQServer" && ! -d $systemdir ) {
        skip("Cannot test server API on client host", 83);
    }

    if ($MQSeries::MQ_VERSION < 6) {
        skip("Module not compiled for MQSeries version 6", 83);
    }

    #
    # We'll only test MQSeries::Command if we run as user 'mqm'
    #
    my $username = ($^O =~ /^MSWin/ ? $ENV{USERNAME} : getpwuid($<));
    unless (lc $username eq 'mqm') {
        skip("Not testing MQSeries::Command unless running as user 'mqm', not '$username'", 83);
    }

    my $QMgrName = $myconfig{"QUEUEMGR"};

    #
    # Create QueueManager object and connect
    #
    my $qmgr_obj = MQSeries::QueueManager->
      new('QueueManager' => $QMgrName,
          'AutoConnect'  => 0);
    unless ($qmgr_obj->Connect()) {
        skip("MQSeries::QueueManager Connect failed (Reason=" .
             $qmgr_obj->Reason() . ")", 83);
    }
    ok($qmgr_obj, "MQSeries::QueueManager - Connect");

    #
    # Inquire the platform.  Skip the tests if we're not on Unix.
    #
    my $rc = $qmgr_obj->Open();
    unless ($rc) {
        skip("Could not open queue manager", 82);
    }
    ok($rc, "MQSeries::QueueManager - Open");
    my %qmgr_attr = $qmgr_obj->Inquire(qw(CommandLevel Platform));
    ok((keys %qmgr_attr), "MQSeries::QueueManager - Inquire");
    $rc = $qmgr_obj->Close();
    ok($rc, "MQSeries::QueueManager - Close");

    unless ($qmgr_attr{Platform} eq 'UNIX') {
        skip("Not testing MQSeries::Command on non-Unix platform $qmgr_attr{Platform}", 79);
    }
    if ($qmgr_attr{CommandLevel} < 600) {
        skip("Not testing MQSeries::Command filter options on MQ v5", 79);
    }

    #
    # Create MQSeries::Command object
    #
    my $cmd = MQSeries::Command::->
      new('QueueManager'   => $qmgr_obj,
          'Type'           => 'PCF',
          'CommandVersion' => MQSeries::MQCFH_VERSION_3,
         );
    unless (defined $cmd) {
        skip("MQSeries::Command constructor failed", 79);
    }
    ok($cmd, "MQSeries::Command constructor");

    #
    # For each command that support filetrs, try integer and string
    # filters with all the various options
    #
    my %tests =
      (
       'InquireAuthInfo' => {},
       'InquireChannel' => {},
       'InquireChannelListener' => {},
       'InquireChannelListenerStatus' => {},
       'InquireChannelStatus' => {},
       'InquireConnection' => {},
       'InquireNamelist' => {},
       'InquireProcess' => {},
       'InquireQueue' => {},
       'InquireQueueStatus' => {},
       'InquireService' => {},
       'InquireServiceStatus' => {},
       'InquireTopicStatus' => {},
      );

    foreach my $method (sort keys %tests) {
      SKIP: {
            if ($method eq 'InquireTopicStatus' &&
                $qmgr_attr{CommandLevel} < 700) {
                skip("Not testing $method on MQ v6", 6);
            }

            print "Invoking $method (without filter)\n";
            my @params = %{ $tests{$method} };
            my @retval = $cmd->$method(@params);
            #print "Have ", scalar(@retval), " results\n";
            unless (@retval) {
                skip("No results for $method", 6);
            }
            ok(@retval, "$method - no filter");
            my ($entry) = @retval;

            #
            # Two methods require a key taken from a previous
            # (different) method invocation
            #
            if ($method eq 'InquireChannelListener') {
                $tests{InquireChannelListenerStatus} = { ListenerName => $entry->{ListenerName} };
            } elsif ($method eq 'InquireService') {
                $tests{InquireServiceStatus} = { ServiceName => $entry->{ServiceName} };
            }

            #
            # Find elements of up to five types:
            # - enumerated
            # - integer and integer list
            # - string and string list
            # We cheat by looking at the value, rather than the
            # table of request/response parameters
            #
            my ($enum, $int, $int_list, $string, $string_list);
            while (my ($k, $v) = each %$entry) {
                # "InquireNamelist" may yield a "Names" value which is
                # empty (and therefore useless), so just skip that
                next if ($method eq "InquireNamelist" &&
                         $k eq "Names" && ref($v) && !@{$v});
                if (!defined $enum && $v =~ /^[A-Z]\w+$/) {
                    $enum = $k;
                } elsif (!defined $int && $v =~ /^\d+$/) {
                    $int = $k;
                } elsif (!defined $int_list && ref($v) && $v->[0] =~ /^-?\d+$/) {
                    $int_list = $k;
                } elsif (!defined $string && $v =~ /[\.\s]/ && $v =~ /\w/) {
                    $string = $k;
                } elsif (!defined $string_list && ref($v) && $v->[0] =~ /[\.\s]/ && $v->[0] =~ /\w/) {
                    $string_list = $k;
                }
            }

          SKIP: {
                unless (defined $enum) {
                    skip("No enumerated element available for $method", 1);
                }

                #
                # Test for equal and non-equal
                #
                foreach my $op (qw(== != <>)) {
                    foreach my $space ('', ' ') {
                        #print "Testing $method enum filter: $enum $op <value>, spacing='$space'\n";
                        my @filtered = $cmd->$method("FilterCommand" => "$enum$space$op$space$entry->{$enum}");
                        #print "Have ", scalar(@filtered), " filtered results\n";
                    }
                }
                ok(1, "$method - FilterCommand for enumerated types");
            }
          SKIP: {
                unless (defined $int) {
                    skip("No integer element available for $method", 1);
                }
                #
                # Test for equal, non-equal and numeric comparisons
                #
                foreach my $op (qw(== != <> > < <= >=)) {
                    foreach my $space ('', ' ') {
                        #print "Testing $method int filter: $int $op <value>, spacing='$space'\n";
                        my @filtered = $cmd->$method("FilterCommand" => "$int$space$op$space$entry->{$int}");
                        #print "Have ", scalar(@filtered), " filtered results\n";
                    }
                }
                ok(1, "$method - FilterCommand for integer types");
            }
          SKIP: {
                unless (defined $int_list) {
                    skip("No integer list element available for $method", 1);
                }

                #
                # Test for equal and non-equal
                #
                foreach my $op (qw(== != contains excludes)) {
                    my $value = $entry->{$int_list}->[0];
                    #print "Testing $method int list filter: $int_list $op $value\n";
                    my @filtered = $cmd->$method("FilterCommand" => "$int_list $op $value");
                    #print "Have ", scalar(@filtered), " filtered results\n";
                }
                ok(1, "$method - FilterCommand for integer list types");
            }
          SKIP: {
                unless (defined $string) {
                    skip("No string element available for $method", 1);
                }

                #
                # Test for equal, non-equal, comparison, like, not like
                #
                foreach my $op (qw(== != <> > < <= >=), 'like', 'not like') {
                    my $value = $entry->{$string};
                    $value =~ s/\.[^.]+$/.*/ if ($op =~ /like/);
                    #print "Testing $method string filter: $string $op $value\n";
                    my @filtered = $cmd->$method("FilterCommand" => "$string $op '$value'");
                    #print "Have ", scalar(@filtered), " filtered results\n";
                }
                ok(1, "$method - FilterCommand for string types");
            }
          SKIP: {
                unless (defined $string_list) {
                    skip("No string list element available for $method", 1);
                }

                #
                # Test for contains, excludes, contains_gen, excludes_gen
                #
                foreach my $op (qw(contains excludes contains_gen excludes_gen)) {
                    my $value = $entry->{$string_list}->[0];
                    $value =~ s/\.[^.]+$/.*/ if ($op =~ /_gen$/);
                    #print "Testing $method string list filter: $string_list $op $value\n";
                    my @filtered = $cmd->$method("FilterCommand" => "$string_list $op '$value'");
                    #print "Have ", scalar(@filtered), " filtered results\n";
                }
                ok(1, "$method - FilterCommand for string list types");
            }
        }                       # End SKIP in "foreach method"
    }                           # End foreach: method
}                               # End SKIP: MQ v6 or above
