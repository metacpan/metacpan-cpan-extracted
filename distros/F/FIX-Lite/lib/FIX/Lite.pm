package FIX::Lite;

use vars qw($VERSION @ISA);
use warnings;
use strict;

use IO::Socket;
use POSIX qw(strftime);
#use Net::Cmd;
use FIX::Lite::Dictionary;
use IO::Select;
use Time::HiRes qw(gettimeofday);

#@ISA = qw(Net::Cmd IO::Socket::INET);
@ISA = qw(IO::Socket::INET);
$VERSION = "0.04";

my $fixDict;
my $MsgSeqNum = 0;
my %fieldDefaults = (
        EncryptMethod => 0,
        HeartBtInt    => 30,
        );
my $sel;

sub new {
    my $self = shift;
    my $type = ref($self) || $self;
    my %arg = @_;
    my $obj;
    $obj = $type->SUPER::new(
            PeerHost => defined $arg{Host} ? $arg{Host} : '127.0.0.1',
            PeerPort => defined $arg{Port} ? $arg{Port} : '5201',
            Timeout  => defined $arg{Timeout} ? $arg{Timeout} : 60,
            Proto => 'tcp',
            );
    $sel = IO::Select->new( $obj );

    return undef
        unless defined $obj;

    $obj->autoflush(1);

    #$obj->debug(exists $arg{Debug} ? $arg{Debug} : undef);

    # Initialize $fixDict

    if ( defined $arg{version} ) {
        FIX::Lite::Dictionary::load( $arg{version} );
    }
    else {
        FIX::Lite::Dictionary::load('FIX44');
    }
    $fixDict = FIX::Lite::Dictionary->new();

    $obj;
}

sub logon {
    my $self = shift;
    my %arg = @_;

    $arg{ResetSeqNumFlag} = 'Y';
    $MsgSeqNum=0;

    my $msgBody = constructMessage('Logon',\%arg);
    print "----\nPrepared Logon FIX Message:\n".readableFix($msgBody)."\n" if ($arg{Debug});

    my $size = $self->send($msgBody);
    print "  Sent data of length $size\n" if ($arg{Debug});

    # receive a response of up to 1024 characters from server
    my $response = "";
    $self->recv($response, 1024);
    print "----\nReceived Logon response:\n".readableFix($response)."\n" if ($arg{Debug});
    my $parsedResp;
    $parsedResp = parseFixMessage($response) if ($response);
    ${*$self}->{logon}=$parsedResp;
    ${*$self}->{args}=\%arg;
    return $parsedResp;
}

sub request {
    my $self = shift;
    my %arg = @_;

    $arg{SenderCompID} ||= ${*$self}->{args}->{SenderCompID};
    $arg{TargetCompID} ||= ${*$self}->{args}->{TargetCompID};
    $arg{TargetSubID} ||= (${*$self}->{args}->{TargetSubID}) ? ${*$self}->{args}->{TargetSubID} : undef;

    my $msgBody = constructMessage($arg{MsgType},\%arg);
    print "----\nPrepared FIX Message:\n".readableFix($msgBody)."\n" if ($arg{Debug});

    my $size = $self->send($msgBody);
    print "  Sent data of length $size\n" if ($arg{Debug});

    my $response = "";

    $self->recv($response, 4096);

    print "----\nReceived response:\n".readableFix($response)."\n" if ($arg{Debug});
    my $parsedResp;
    $parsedResp = parseFixMessage($response) if ($response);
    ${*$self}->{request}=$parsedResp;

    return $parsedResp;
}

sub heartbeat {
    my $self = shift;
    my %arg = @_;

    $arg{SenderCompID} ||= ${*$self}->{args}->{SenderCompID};
    $arg{TargetCompID} ||= ${*$self}->{args}->{TargetCompID};
    $arg{TargetSubID} ||= (${*$self}->{args}->{TargetSubID}) ? ${*$self}->{args}->{TargetSubID} : undef;

    my $msgBody = constructMessage('Heartbeat',\%arg);
    print "----\nPrepared FIX Heartbeat:\n".readableFix($msgBody)."\n" if ($arg{Debug});
    my $size = $self->send($msgBody);
    print "  Sent data of length $size\n" if ($arg{Debug});
}

sub listen {
    my $self = shift;
    my $handler = shift;
    my %arg = @_;

    my $HeartBtInt = $arg{HeartBtInt} || $fieldDefaults{HeartBtInt};
    my $response;
    my $lastHbTime = time;
    while (1) {
        my @ready = $sel->can_read(0);
        if (scalar(@ready)) {
            my $sock = $ready[0];
            if (! sysread($ready[0], $response, 4096)) {
                print "recv failed :$!\n";
                return 1;
            } else {
                print "----\nReceived FIX message:\n".readableFix($response)."\n" if ($arg{Debug});

                #Split into each single msg
                for my $fixMsg ( split /8=FIX.4.4\x{01}/, $response ) { # Split on FIX version
                    next if (length($fixMsg)<=0);

                    print "  Splitted FIX message:\n".readableFix($fixMsg)."\n" if ($arg{Debug}); 
    
			my $parsedResp = parseFixMessage($fixMsg);

                	if ( ! defined $parsedResp->{MsgType} ) {
                    		print "   Cannot parse message\n" if ($arg{Debug});
                	}
                	elsif ( $parsedResp->{MsgType} eq '0' ) {
                    		print "   This is heartbeat. Will not pass it to handler\n" if ($arg{Debug});
                	}
                	elsif ( $parsedResp->{MsgType} eq '1' ) {
                    		my $TestReqID = (defined $parsedResp->{TestReqID})?$parsedResp->{TestReqID}:'TEST';
                    		print "   This is TestRequest. Will send heartbeat with TestReqID $TestReqID\n" if ($arg{Debug});
                    		$self->heartbeat( 
                        		TestReqID => $TestReqID,
                        		Debug => $arg{Debug}
                    			);
                	}
                	else {
		    		$handler->($parsedResp);
                	}

		}
            }
        }

        if ( time - $lastHbTime > $HeartBtInt ) {
            $lastHbTime = time;
            $self->heartbeat( Debug => $arg{Debug} );
        }
        select(undef, undef, undef, 0.002);

    }
}

sub loggedIn {
    my $self = shift;
    return 1 if (defined ${*$self}->{logon}->{'MsgType'} && ${*$self}->{logon}->{'MsgType'} eq getMessageType('Logon'));
    return 0;
}

sub lastRequest {
    my $self = shift;
    my $field = shift;
    return getFieldDescription($field, ${*$self}->{request}->{$field});
}

sub constructMessage($$) {

    my $msgtype = shift; 
    my $arg = shift; 
    my @fields;
    undef $arg->{MsgType};
    $MsgSeqNum++;

    my $time = strftime "%Y%m%d-%H:%M:%S.".getMilliseconds(), gmtime;
    push @fields, getFieldNumber('MsgType')."=".getMessageType($msgtype);
    push @fields, getFieldNumber('SendingTime')."=".$time;
    push @fields, getFieldNumber('MsgSeqNum')."=".$MsgSeqNum;

    my @allFields = ( @{getMessageHeader()}, @{getMessageFields($msgtype)} );

    foreach my $field ( @allFields ) {
        if ( defined $arg->{$field->{name}} ) {
            if (ref($arg->{$field->{name}}) eq "HASH") {
                my @tmpFields;
                my $count=0;
                foreach my $component ( keys %{$arg->{$field->{name}}} ) {
                   if (isComponent($component)) {
                    my @componentFields = @{getComponentFields($component)};
                    foreach ( @componentFields ) {
                        if ( defined $arg->{$field->{name}}->{$component}->{$_->{name}} ){
                            my $componentField = $arg->{$field->{name}}->{$component}->{$_->{name}};
                            if ( ref($componentField) eq "ARRAY" ) {
                                foreach my $entry ( @{$componentField} ) {
                                    push @tmpFields, getFieldNumber($_->{name})."=".getFieldValue($_->{name},$entry);
                                    $count++
                                }
                            } else {
                                push @tmpFields, getFieldNumber($_->{name})."=".getFieldValue($_->{name},$componentField);
                                $count++;
                            }
                        }
                    }
                    } else {
                    my $componentField = $arg->{$field->{name}}->{$component};
                    if ( ref($componentField) eq "ARRAY" ) {
                        foreach my $entry ( @{$componentField} ) {
                            push @tmpFields, getFieldNumber($component)."=".getFieldValue($component,$entry);
                            $count++
                        }
                    } else {
                        push @tmpFields, getFieldNumber($component)."=".getFieldValue($component,$componentField);
                    }
                    }
    
                }
                push @fields, getFieldNumber($field->{name})."=".$count;
                @fields = ( @fields, @tmpFields );
            }

            next if (ref($arg->{$field->{name}}) eq "HASH");
            push @fields, getFieldNumber($field->{name})."=".getFieldValue($field->{name},$arg->{$field->{name}});
        }
        elsif ( $field->{required} eq 'Y' && defined $fieldDefaults{$field->{name}} ) {
            push @fields, getFieldNumber($field->{name})."=".$fieldDefaults{$field->{name}}
        }
        elsif ( $field->{required} eq 'Y' && $field->{name} ne 'BeginString' and $field->{name} ne 'BodyLength' 
                and $field->{name} ne 'MsgType' and $field->{name} ne 'MsgSeqNum' and $field->{name} ne 'SendingTime') {
            if ($field->{name} eq "MDReqID") {
                push @fields, getFieldNumber($field->{name})."=".randomString();
            } else {
                print "ERROR: $field->{name}\n";
            }
        }
    }

    my $req = join "\x01",@fields;
    $req .= "\x01";
    $req = getFieldNumber('BeginString')."=FIX.4.4\x01".getFieldNumber('BodyLength')."=".length($req)."\x01".$req;
    my $checksum = unpack("%8C*", $req) % 256;
    $checksum = sprintf( "%03d", $checksum );
    $req .= getFieldNumber('CheckSum')."=$checksum\x01";
    return $req."\n";
}

sub getField($) {
    my $f = shift;
    return $fixDict->{hFields}->{$f};
}

# returns 1 if given field is a group header field
# isGroup('NoAllocs')  -> returns 1
# isGroup('Symbol')    -> returns 0
sub isGroup($) {
    my $f  = shift;
    my $ff = getField($f);
    return defined $ff ? $ff->{type} eq 'NUMINGROUP' : 0;
}

# returns true if given field is a member of the given group of given message.
sub isFieldInGroup($$$) {
    my ( $m, $g, $f ) = @_;

    my $gn = getFieldName($g);
    return 0 if ! defined $gn;
    return 0 if ! isGroup($gn);

    my $msg = getGroupInMessage($m, $g);
    return 0 if ! defined $msg;
    return _isFieldInStructure($msg, $f);
}

# return a ref on group of a message, this then allows us to work on the group elements.
# $d->getGroupInMessage('D','NoAllocs')
# will return a ref on the NoAllocs group allowing us to then parse it
#
# Looks recursively into groups of groups if needed.
sub getGroupInMessage($$) {
    my ( $m, $g ) = @_;
    my $s = getMessageFields($m);
    return undef if ! defined $s;
    my $gn = getFieldName($g);
    return undef if ! defined($gn);

    return undef if ! isGroup($g);

    return _getGroupInStructure( $s, $gn );
}

# returns true if given field is found in the structure.
sub _isFieldInStructure($$);

sub _isFieldInStructure($$) {
    my ( $m, $f ) = @_;
    return 0 unless ( defined $m && defined $f );
    my $fn = getFieldName($f);
    return 0 if ! defined $fn;

    for my $f2 ( @{$m} ) {
        # found the field? return 1. Beware that if the element is a component then we don't accept
        # it as a valid field of the structure.
        return 1 if ( $f2->{name} eq $fn && !defined $f2->{component} );

        # if the field is a group then scan all elements of the group
        if ( defined $f2->{group} ) {
            return 1 if _isFieldInStructure( $f2->{group}, $fn ) == 1;
        }

        # if the field is a component, we need to go to the component hash and check out its
        # composition.
        if ( defined $f2->{component} ) {
            return 1 if _isFieldInStructure( getComponentFields($f2->{name}), $fn ) == 1;
        }
    }
    return 0;
}

sub _getGroupInStructure($$);

sub _getGroupInStructure($$) {
    my ($s, $gn) = @_;

    my $ret;
    # parse each field in the structure, and ....
    for my $e ( @{$s} ) {
        # we found the group name
        return $e->{group} if ($e->{name} eq $gn && defined $e->{group});

        # stop at each group header
        if (defined $e->{group}) {
             # and research recursively
             $ret = _getGroupInStructure($e->{group},$gn);
             return $ret if defined $ret;
        }

        # if we run into a component we need to check that out too
        if (defined $e->{component}) {
             $ret = _getGroupInStructure(getComponentFields($e->{name}), $gn);
             return $ret if defined $ret;
        }
    }
    undef;
}


sub getFieldName($) {
    my $f = shift;
    my $fh = getField($f);
    return defined $fh ? $fh->{name} : undef;
}

sub getTagById {
    my ($self, $f) = @_;
    return getFieldName($f);
}

sub getFieldNumber($) {
    my $f = shift;
    return $f if ( $f =~ /^[0-9]+$/ );
    my $fh = getField($f);
    warn("getFieldNumber($f) returning undef") if !defined $fh;
    return defined $fh ? $fh->{number} : undef;
}

sub getFieldValue($$) {
    my $f = shift;
    my $v = shift;
    return $v if ( $v =~ /^[0-9]+$/ );
    my $fh = getField($f);
    warn("getField($f) returning undef") if !defined $fh;
    if ($fh->{enum}) {
        foreach ( @{$fh->{enum}} ) {
            if ($_->{description} eq $v) {
                return $_->{name};
            }
        }
    }
    return $v;
}

sub getFieldDescription($$) {
    my $f = shift;
    my $v = shift; 
    my $fh = getField($f);
    warn("getField($f) returning undef") if !defined $fh;
    if ($fh->{enum}) {
        foreach ( @{$fh->{enum}} ) {
            if ($_->{name} eq $v) {
                return $_->{description};
            }
        }
    }
    return $v;
}

sub getMessage($) {
    my $f = shift;
    return $fixDict->{hMessages}->{$f};
}

sub getMessageType($) {
    my $f = shift;
    return $f if ( $f =~ /^[0-9]+$/ );
    my $fh = getMessage($f);
    warn("getMessage($f) returning undef") if !defined $fh;
    return defined $fh ? $fh->{msgtype} : undef;
}

sub getMessageName($) {
    my $f = shift;
    my $fh = getMessage($f);
    warn("getMessage($f) returning undef") if !defined $fh;
    return defined $fh ? $fh->{name} : undef;
}

sub getMsgByType {
    my ($self, $f) = @_;
    return getMessageName($f);
}

sub getMessageFields($) {
    my $f = shift;
    my $fh = getMessage($f);
    warn("getMessage($f) returning undef") if !defined $fh;
    return defined $fh ? $fh->{fields} : undef;
}

sub getMessageHeader {
    return $fixDict->{header};
}

sub getComponent($) {
    my $f = shift;
    return $fixDict->{hComponents}->{$f};
}

sub isComponent($) {
    my $f = shift;
    return defined $fixDict->{hComponents}->{$f};
}

sub getComponentFields($) {
    my $f = shift;
    my $fh = getComponent($f);
    warn("getComponent($f) returning undef") if !defined $fh;
    return defined $fh ? $fh->{fields} : undef;
}

sub parseFixMessage {
    my $message = shift;
    return unless defined $message;
    my $parsedMsg;

    my @fields = split /\x01/, $message; # Split on "SOH" 
    _parseFixArray( \$parsedMsg, undef, undef, 0, \@fields );

    return $parsedMsg;
}

sub _parseFixArray($$$$$);

sub _parseFixArray($$$$$) {
    my ( $result, $msgType, $groupTag, $iField, $fields ) = @_;
    my $i = $iField;

    while ( $i < scalar(@$fields) ) {
        my $field = $fields->[$i];
        my ( $k, $v ) = ( $field =~ /^([^=]+)=(.*)$/ );

        if ( defined $$result->{$k} ) {
             return $i if defined $groupTag;
             warn("Field $k is already in hash!");
        }
        if ( defined $groupTag ) {
             return $i if !isFieldInGroup( $msgType, $groupTag, $k );
        }
        # Store both using Tag and FieldName.
        $$result->{$k} = $v;
        my $fieldName = getFieldName($k);
        if ( defined $fieldName ) {
            $$result->{$fieldName} = $v;
        } else {
            warn("Haven't found field $k in dictionary");
        }
       
        if ( $fieldName eq 'MsgType' ) {
            $msgType = $v;
        }
        elsif ( isGroup($k) ) {
            my @elems;
            $i++;
            for ( 1 .. $v ) {
                my $localResult;
                $i = _parseFixArray( \$localResult, $msgType, $k, $i, $fields );
                push( @elems, $localResult );
            }
            # Store both using Tag and FieldName.
            $$result->{$k} = \@elems;
            $$result->{$fieldName} = \@elems;
            $i--;
        }
    $i++;
    }
}

sub randomString {
    my @chars = ("A".."Z", "a".."z");
    my $string;
    $string .= $chars[rand @chars] for 1..6;
    return $string;
}

sub readableFix {
    my $fixMsg = shift;
    $fixMsg =~ s/\x01/\|/g;
    return $fixMsg;
}

sub quit {
    my $self = shift;

    $self->close;
}

sub getMilliseconds {
    my $time = gettimeofday;
    return sprintf("%03d",int(($time-int($time))*1000));
}
1; # End of FIX::Lite
__END__

=head1 NAME

FIX::Lite - Simple FIX (Financial Information eXchange) protocol module

=head1 VERSION

Version 0.04

=head1 SYNOPSIS

  use FIX::Lite;
  my $fix = FIX::Lite->new(
      Host         => 'somefixserver.com',
      Port         => 5201,
      Debug        => 0,
      Timeout      => 60
  ) or die "Cannot connect to server: $!";

  # Then we usually need to login

  $fix->logon( 
      SenderCompID => 'somevalue1',
      TargetCompID => 'somevalue2',
      TargetSubID  => 'somevalue3',
      Username     => 'somevalue4',
      Password     => 'somevalue5',
      Debug        => 0
  ); 

  # To check the login results we can use method loggedIn()

  die "Cannot logon: $!" unless $fix->loggedIn()

  # After logon we can make some market request

  $fix->request( 
      MsgType => 'MarketDataRequest',
      SubscriptionRequestType => 'SNAPSHOT_PLUS_UPDATES',
      MarketDepth => 1,
      MDUpdateType => 'INCREMENTAL_REFRESH',
      NoRelatedSym => {
         Instrument => {
            Symbol => [
               'EUR/USD',
               'GBP/CHF'
            ]
         },
      },
      NoMDEntryTypes => {
         MDEntryType => [
           'BID',
           'OFFER'
         ]
      },
      Debug => $debug
  ) or die "Cannot send request: $!";

  # We then use lastRequest() method to get the parsed answer

  if ( $fix->lastRequest('MsgType') eq "REJECT" ) {
      print "Request was rejected\n";
      print "Reason: ".$fix->lastRequest('SessionRejectReason')."\n";
      print "RefTag: ".FIX::Lite->getTagById($fix->lastRequest('RefTagID'))."\n"; 
  }

  # And yup, we can use FIX::Lite->getTagById() method to resolve tag codes into 
  # human-readable values
  # After sending some subscriptions we can relax and wait for the quotes

  $fix->listen( \&handler,
        HeartBtInt => 30,
        Debug => 0
  );

  # Every incoming message (except Heartbeats and TestRequests) will call some handler function,
  # we need to just pass its reference as an argument. As for the hearbeats then
  # module will send them every HeartBtInt seconds (default is 30). And also the module will automatically answer
  # the test requests

  # To explicitly close the connection we can use quit() method  

  $fix->quit();

  # And a simple example of the handler function:

  sub handler {
     my $resp = shift;
     print "Received message ".$resp->{MsgType}."\n";
     if ( $resp->{MsgType} eq 'W' ) {
        if ( defined $resp->{NoMDEntries} ) {
            print "Received Prices for symbol ".$resp->{Symbol}."\n";
            foreach ( @{$resp->{NoMDEntries}} ) {
                print "Price ".$_->{MDEntryPx}.", type ".$_->{MDEntryType}."\n";
            } 
        } else {
            print "Received Price ".$resp->{MDEntryPx}." for symbol ".$resp->{Symbol}."\n";
        }
     }
     return 1;
  }

=head1 INSTANCE METHODS

=head2 new

Open a socket to the FIX server

=head2 logon

Send the logon (35=A) message and wait for the response

=head2 heartbeat

Send the heartbeat (35=0) message and get back

=head2 request

Send the FIX request of any type and wait for the response

=head2 listen

Wait for the incoming messages. This method will return after the socket is closed. Heartbeats are sent automatically.

=head2 loggedIn

Returns true if FIX server has answered with Logon message

=head2 lastRequest

Returns hash with parsed response for the last request sent.

=head2 getTagById

Resolve tag name by its code

=head2 getMsgByType

Resolve message name by its type code

=head2 quit

Explicitly close the socket to the FIX server.


=head1 AUTHOR

Vitaly Agapov, E<lt>agapov.vitaly@gmail.comE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright 2015 "Vitaly Agapov".

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
