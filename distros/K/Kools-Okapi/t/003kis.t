#
#   This file is part of the Kools::Okapi package
#   a Perl C wrapper for the Thomson Reuters Kondor+ OKAPI api.
#
#   Copyright (C) 2009 Gabriel Galibourg
#
#   The Kools::Okapi package is free software; you can redistribute it and/or
#   modify it under the terms of the Artistic License 2.0 as published by
#   The Perl Foundation; either version 2.0 of the License, or
#   (at your option) any later version.
#
#   The Kools::Okapi package is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   Perl Artistic License for more details.
#
#   You should have received a copy of the Artistic License along with
#   this package.  If not, see <http://www.perlfoundation.org/legal/>.
# 
#

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 001Kools-Okapi.t'

#########################

use strict;
use Test::More tests => 1;
BEGIN { use_ok('Kools::Okapi') };


my $retval;
my $icc;


sub selectTimeout_callBack($)
{
    print "In select_timeout_callback  ";
    my $io=shift;
    print "  $io\n";

my $message=
"Table:ImportTable\027" .
"Action:I\027" .
"TableName:SpotDeals\027" .
"Table:SpotDeals\027" .
"DealStatus:V\027" .
"CaptureDate:30/06/2007\027" .
"TradeDate:30/06/2007\027" .
"ValueDate:30/06/2007\027" .
"TypeOfEvent:O\027" .
"Comments:Example of Spot Deals\027" .
"Amount1:1000000.0\027" .
"SpotRate:1.5421\027" .
"CapturedAmount:1\027" .
"Table:Pairs\027" .
"Pairs_ShortName:EUR/USD\027" .
"Table:Users\027" .
"Users_ShortName:KPLUS\027" .
"Table:Folders\027" .
"Folders_ShortName:FOLDER1\027" ;

print $message . "\n";
    ICC_DataMsg_init(Kools::Okapi::ICC_DATA_MSG_TABLE,"SpotDeals_123");
    ICC_DataMsg_Integer_set(Kools::Okapi::DATA_KEY_TRANSID,"0");
    ICC_DataMsg_Buffer_set($message);
    my $buf=ICC_get($io,Kools::Okapi::ICC_GET_SENT_DATA_MSG_FOR_DISPLAY);
    print "\nBUFFER=$buf\n\n";
    print ICC_DataMsg_Buffer_get() . "\n";
    ICC_DataMsg_send_to_server($io);
    print ICC_DataMsg_Buffer_get() . "\n";
    
    return Kools::Okapi::ICC_OK;
#    return ICC_set($io,Kools::Okapi::ICC_SEND_DATA,"0",
#                       Kools::Okapi::ICC_DATA_MSG_TABLE,$message);

#    my $buf=ICC_get($io,Kools::Okapi::ICC_GET_SENT_DATA_MSG_FOR_DISPLAY);
#    print "\nBUFFER=$buf\n\n";

}

sub dataMsg_callBack($$$)
{
    print "In data_msg_callback  ";
    my $io=shift;
    my $key=shift;
    my $type=shift;
    print "  $io:$key:$type\n";
    
    SWITCH: # (type)
    {
        if (Kools::Okapi::ICC_DATA_MSG_TABLE_ACK==$type) {
            print "Got a ICC_DATA_MSG_TABLE_ACK: " . ICC_DataMsg_Buffer_get() . "\n";
            my $tableId=ICC_DataMsg_get(Kools::Okapi::DATA_KEY_KPLUS_TABLE_ID);
            my $warnMsg=ICC_DataMsg_get(Kools::Okapi::DATA_KEY_WARNING_MESSAGE);
            print "The deal $key (K+ deal id $tableId ) has been inserted. Warning message: $warnMsg\n";
            
            last SWITCH;
        }
        if (Kools::Okapi::ICC_DATA_MSG_ERROR==$type) {
            print "Got a ICC_DATA_MSG_ERROR: " . ICC_DataMsg_Buffer_get() . "\n";
            my $errClass=ICC_DataMsg_get(Kools::Okapi::DATA_KEY_ERROR_CLASS);
            my $errType =ICC_DataMsg_get(Kools::Okapi::DATA_KEY_ERROR_TYPE);
            my $errMsg  =ICC_DataMsg_get(Kools::Okapi::DATA_KEY_ERROR_MESSAGE);
            print "KIS error:: class=$errClass, Type=$errType, Key=$key, Msg=$errMsg\n";
            last SWITCH;
        }

        printf "Unknown message type: %d\n",$type;
    }
    
    return Kools::Okapi::ICC_OK;
}

sub disconnect_callBack($)
{
    print "In disconnect callBack  ";
    my $io=shift;
    print "  $io\n";
    
    return Kools::Okapi::ICC_OK;
}

sub reconnect_callBack($)
{
    print "In reconnect callBack  ";
    my $io=shift;
    print "  $io\n";
    
    return Kools::Okapi::ICC_OK;
}


print "ICC_create:\n";
$icc = ICC_create(
                  Kools::Okapi::ICC_CLIENT_NAME,               'KPLUSIMPORT',
                  Kools::Okapi::ICC_KIS_HOST_NAMES,            'localhost',
                  Kools::Okapi::ICC_PORT_NAME,                 'kis_port',

                  Kools::Okapi::ICC_SELECT_TIMEOUT,             15,
                  Kools::Okapi::ICC_SELECT_TIMEOUT_CALLBACK,    \&selectTimeout_callBack,
                  Kools::Okapi::ICC_DATA_MSG_CALLBACK,          \&dataMsg_callBack,
                  Kools::Okapi::ICC_DISCONNECT_CALLBACK,        \&disconnect_callBack,
                  Kools::Okapi::ICC_RECONNECT_CALLBACK,         \&reconnect_callBack);
                  
print "icc=$icc\n";
print "ok 1\n";
#ICC_set($icc,Kools::Okapi::ICC_CLIENT_READY, 1);
print "ok 2\n";
ICC_main_loop($icc);
print "ok 3\n";
ICC_main_loop($icc);

