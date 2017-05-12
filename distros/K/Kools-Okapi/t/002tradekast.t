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

sub dataMsg_callBack($$$)
{
    print "In data_msg callBack  ";
    my $io=shift;
    my $key=shift;
    my $type=shift;
    print "  $io:$key:$type\n";
    my $cd=ICC_get($io,Kools::Okapi::ICC_CLIENT_DATA);
    print "  cd=$cd\n";
    
    SWITCH: # (type)
    {
        if (Kools::Okapi::ICC_DATA_MSG_SIGNON==$type) {
            print "Got a ICC_DATA_MSG_SIGNON\n";
            last SWITCH;
        }
        if (Kools::Okapi::ICC_DATA_MSG_SIGNOFF==$type) {
            print "Got a ICC_DATA_MSG_SIGNOFF\n";
            last SWITCH;
        }
        if (Kools::Okapi::ICC_DATA_MSG_RELOAD_END==$type) {
            print "Got a ICC_DATA_MSG_RELOAD_END\n";
            last SWITCH;
        }
        if (Kools::Okapi::ICC_DATA_MSG_REQUEST==$type) {
            print "Got a ICC_DATA_MSG_REQUEST\n";
            last SWITCH;
        }
        if (Kools::Okapi::ICC_DATA_MSG_TABLE==$type) {
            print "Got a ICC_DATA_MSG_TABLE\n";
            print ICC_DataMsg_Buffer_get() . "\n\n";
            my $transId=ICC_DataMsg_get(Kools::Okapi::DATA_KEY_TRANSID);
            ICC_DataMsg_init(Kools::Okapi::ICC_DATA_MSG_TABLE_ACK,$key);
            ICC_DataMsg_Integer_set(Kools::Okapi::DATA_KEY_TRANSID,$transId);
            ICC_DataMsg_send_to_server($io);
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
                  Kools::Okapi::ICC_CLIENT_NAME,           'EXPORT',
                  Kools::Okapi::ICC_KIS_HOST_NAMES,        'localhost',
                  Kools::Okapi::ICC_PORT_NAME,             'tradekast',
                  
                  Kools::Okapi::ICC_CLIENT_RECEIVE_ARRAY,  [ "SpotDeals", "FxSwapDeals", "ForwardDeals", "NeverCheckUserCode" ],
                  Kools::Okapi::ICC_DATA_MSG_CALLBACK,     \&dataMsg_callBack,
                  Kools::Okapi::ICC_DISCONNECT_CALLBACK,   \&disconnect_callBack,
                  Kools::Okapi::ICC_RECONNECT_CALLBACK,    \&reconnect_callBack);

my $cd="Hello world";
ICC_set($icc,Kools::Okapi::ICC_CLIENT_DATA,$cd);

print "ok 1\n";
ICC_set($icc,Kools::Okapi::ICC_CLIENT_READY, 1);
print "ok 2\n";
ICC_main_loop($icc);
print "ok 3\n";
ICC_main_loop($icc);

