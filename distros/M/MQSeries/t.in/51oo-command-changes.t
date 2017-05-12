#
# $Id: 51oo-command-changes.t,v 36.9 2012/09/26 16:15:34 jettisu Exp $
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
use Test::More tests => 102;
BEGIN {
    our $VERSION = '1.34';
    use_ok('__APITYPE__::MQSeries' => $VERSION);
    use_ok('MQSeries::QueueManager' => $VERSION);
    use_ok('MQSeries::Command' => $VERSION);
}

SKIP: {
    if ( "__APITYPE__" eq "MQServer" && ! -d $systemdir ) {
        skip("Cannot test server API on client host", 99);
    }

    #
    # We'll only test MQSeries::Command if we run as user 'mqm'
    #
    my $username = ($^O =~ /^MSWin/ ? $ENV{USERNAME} : getpwuid($<));
    unless (lc $username eq 'mqm') {
        skip("Not testing MQSeries::Command unless running as user 'mqm', not '$username'", 99);
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
             $qmgr_obj->Reason() . ")", 99);
    }
    ok($qmgr_obj, "MQSeries::QueueManager - Connect");

    #
    # Inquire the platform.  Skip the tests if we're not on Unix.
    #
    my $rc = $qmgr_obj->Open();
    unless ($rc) {
        skip("Could not open queue manager", 98);
    }
    ok($rc, "MQSeries::QueueManager - Open");
    my %qmgr_attr = $qmgr_obj->Inquire('Platform');
    ok((keys %qmgr_attr), "MQSeries::QueueManager - Inquire");
    $rc = $qmgr_obj->Close();
    ok($rc, "MQSeries::QueueManager - Close");

    unless ($qmgr_attr{Platform} eq 'UNIX') {
        skip("Not testing MQSeries::Command on non-Unix platform $qmgr_attr{Platform}", 95);
    }

    #
    # Create MQSeries::Command object
    #
    my $cmd = MQSeries::Command::->new('QueueManager' => $qmgr_obj,
                                       'Type'         => 'PCF');
    unless (defined $cmd) {
        skip("MQSeries::Command constructor failed", 95);
    }
    ok($cmd, "MQSeries::Command constructor");

    #
    # Use 'InquireQueueManager' to get queue manager information.  We
    # retain this, as we need the command level later to test MQ v6
    # and MQ v7 specific commands.
    #
    my $qmgr_info = $cmd->InquireQueueManager();
    ok($qmgr_info, "InquireQueueManager");

    #
    # For multiple object types, go through the following cycle
    # that works out most of of the MQSeries::Command functionality
    #
    # - Delete object, should it exist
    # - Create object
    # - Inquire it back & verify
    # - Change object
    # - Inquire it back & verify
    # - Copy object
    # - Inquire it back & verify
    # - Delete object and copy
    # - Use 'CreateObject' to create object
    # - Inquire it back & verify
    # - Use 'CreateObject' to make changes
    # - Inquire it back & verify
    # - For queue/channel, use 'CreateObject' to change object type
    #   (which requires a delete & create)
    # - Inquire it back & verify
    # - Delete object
    #
    my $object_name = 'PERL.MQSERIES.TEST';
    my $object_copy = 'PERL.MQSERIES.COPY';
    my $objects =
      { AuthInfo     => { LDAPUserName     => 'foo',
                          AuthInfoType     => 'CRLLDAP',
                          AuthInfoConnName => 'hostname(1234)',
                        },
        Channel      => { ChannelType    => 'Sender',
                          ConnectionName => 'hostname(port)',
                          XmitQName      => 'PERL.MQSERIES.XMITQ',
                        },
        Namelist     => { Names => [ qw(foo bar baz) ],
                        },
        Process      => { EnvData => "LD_LIBRARY_PATH=/usr/lib",
                        },
        Queue        => { QType        => 'Local',
                          MaxMsgLength => '123456',
                        },
        Subscription => { Destination => "SYSTEM.DEAD.LETTER.QUEUE",
                          UserData    => 'Sample user data',
                          TopicString => '/perl/MQseries/test/topic',
                        },
        Topic        => { TopicString => '/perl/MQseries/test/topic',
                          DefPriority => 5,
                        },
      };

    foreach my $type (qw(Queue Channel Process
                         AuthInfo Namelist
                         Subscription Topic)) {
        #next unless ($type eq 'Topic');

      SKIP: {
            my $info = $objects->{$type} ||
              die "Missing information for object type '$type'";
            if ($qmgr_info->{CommandLevel} < 600 &&
                ($type eq 'AuthInfo' || $type eq 'Namelist')) {
                skip("Commands for $type - not supported for MQ < v6", 13);
            }
            if ($qmgr_info->{CommandLevel} < 700 &&
                ($type eq 'Subscription' || $type eq 'Topic')) {
                skip("Commands for $type - not supported for MQ < v7", 13);
            }

            #
            # Method names
            #
            my ($delete_method, $create_method, $change_method, $copy_method, $inq_method) =
              ("Delete$type", "Create$type", "Change$type", "Copy$type", "Inquire$type");
            my $prefix = ($type eq 'Queue' ? 'Q' : $type);
            my $key = $prefix . 'Name';
            $key = 'SubName' if ($type eq 'Subscription');
            my $desc_key = $prefix . 'Desc';
            $desc_key = 'UserData' if ($type eq 'Subscription');
            $info->{$desc_key} = "Test of MQSeries::Command";
            my @required;
            if ($type eq 'Queue') {
                @required = ('QType' => $info->{QType});
            } elsif ($type eq 'Channel') {
                @required = ('ChannelType' => $info->{ChannelType});
            } elsif ($type eq 'AuthInfo') {
                @required = ('AuthInfoType'     => $info->{AuthInfoType},
                             'AuthInfoConnName' => $info->{AuthInfoConnName},
                            );
            } elsif ($type eq 'Topic') {
                @required = ('TopicString' => $info->{TopicString});
            }

            #
            # Delete object if it exists
            #
            print "Delete $type, should it exist\n";
            my $attrs = $cmd->$inq_method($key => $object_name);
            if (keys %$attrs) {
                $cmd->$delete_method($key => $object_name);
            }

            #
            # Create object
            #
            print "Create $type\n";
            my $rc = $cmd->$create_method($key => $object_name, %$info);
            ok($rc, $create_method);

            #
            # Inquire it back & verify
            #
            print "Inquire $type\n";
            $attrs = $cmd->$inq_method($key => $object_name);
            my @slice = keys %$info;
            my $compare = {};
            @{$compare}{@slice} = @{$attrs}{@slice};
            is_deeply($compare, $info, "$inq_method - after $create_method");

            #
            # Change object
            #
            # NB: this is icky...v7 "requires" AuthInfoType with
            # ChangeAuthInfo, and v6 will throw an error if you do.
            #
            @required =
                $cmd->{QueueManager}->{QMgrConfig}->{CommandLevel} >= 700 ?
                ('AuthInfoType' => $info->{AuthInfoType}) :
                () if ($type eq 'AuthInfo');
            @required = () if ($type eq 'Topic');
            $info->{$desc_key} = "Updated description";
            $rc = $cmd->$change_method($key      => $object_name,
                                       $desc_key => $info->{$desc_key},
                                       @required);
            ok($rc, $change_method);

            #
            # Inquire it back & verify
            #
            print "Inquire $type\n";
            $attrs = $cmd->$inq_method($key => $object_name);
            $compare = {};
            @{$compare}{@slice} = @{$attrs}{@slice};
            is_deeply($compare, $info, "$inq_method - after $change_method");

            #
            # Copy object
            #
            # - AuthInfo requires type on create/copy, not change
            # - Topic requires TopicString on create/copy, and the topic
            #   string must change on copy.
            #
            print "Copy $type\n";
            @required = ('AuthInfoType' => $info->{AuthInfoType},
                         'AuthInfoConnName' => $info->{AuthInfoConnName})
              if ($type eq 'AuthInfo');
            if ($type eq 'Topic') {
                $info->{TopicString} .= '/more';
                @required = ('TopicString' => $info->{TopicString});
            }
            my ($from, $to) = ("From$key", "To$key");
            ($from, $to) = ('FromSubscriptionName', 'ToSubscriptionName')
              if ($type eq 'Subscription');
            $rc = $cmd->$copy_method($from => $object_name,
                                     $to   => $object_copy,
                                     @required);
            ok($rc, $copy_method);

            #
            # Inquire it back & verify
            #
            print "Inquire $type\n";
            $attrs = $cmd->$inq_method($key => $object_copy);
            $compare = {};
            @{$compare}{@slice} = @{$attrs}{@slice};
            is_deeply($compare, $info, "$inq_method - after $copy_method");

            #
            # Delete object and copy
            #
            $rc = $cmd->$delete_method($key => $object_name);
            ok($rc, "$delete_method - $object_name");
            $rc = $cmd->$delete_method($key => $object_copy);
            ok($rc, "$delete_method - $object_copy");

            #
            # Use 'CreateObject' to create object
            #
            $info->{$desc_key} = "$type created using CreateObject";
            $rc = $cmd->CreateObject(Attrs => { $key => $object_name, %$info },
                                     Quiet => 1,
                                    );
            ok($rc, "CreateObject - create $type");

            #
            # Inquire it back & verify
            #
            print "Inquire $type\n";
            $attrs = $cmd->$inq_method($key => $object_name);
            $compare = {};
            @{$compare}{@slice} = @{$attrs}{@slice};
            is_deeply($compare, $info, "$inq_method - after CreateObject creation");

            #
            # Use 'CreateObject' to make changes
            #
            @required = ('AuthInfoType' => $info->{AuthInfoType}) if ($type eq 'AuthInfo');
            $info->{$desc_key} = "$type modified using CreateObject";
            $rc = $cmd->CreateObject(Attrs => { $key      => $object_name,
                                                $desc_key => $info->{$desc_key},
                                                @required,
                                              },
                                     Quiet => 1,
                                    );
            ok($rc, "CreateObject - change $type description");

            #
            # Inquire it back & verify
            #
            print "Inquire $type\n";
            $attrs = $cmd->$inq_method($key => $object_name);
            $compare = {};
            @{$compare}{@slice} = @{$attrs}{@slice};
            is_deeply($compare, $info, "$inq_method - after CreateObject description change");

            if ($type eq 'Queue') {
                $info->{QType} = 'Alias';
                $info->{BaseQName} = 'PERL.MQSERIES.BASEQ';
                delete $info->{MaxMsgLength};
                #
                # For queue, use 'CreateObject' to change object
                # type (which requires a delete & create)
                #
                $rc = $cmd->CreateObject(Attrs => { $key => $object_name, %$info },
                                         Quiet => 1,
                                        );
                ok($rc, "CreateObject - Change type for $type");

                #
                # Inquire it back & verify
                #
                print "Inquire $type\n";
                $attrs = $cmd->$inq_method($key => $object_name);
                @slice = keys %$info;
                $compare = {};
                @{$compare}{@slice} = @{$attrs}{@slice};
                is_deeply($compare, $info, "$inq_method - after CreateObject type change");
            }                       # End if: chaneg queue type

            #
            # Delete object
            #
            $rc = $cmd->$delete_method($key => $object_name);
            ok($rc, "$delete_method - $object_name");
        }                       # SKIP block inside 'foreach type'
    }                           # End foreach: type
}                               #  SKIP block
