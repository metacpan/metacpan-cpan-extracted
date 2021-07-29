package Finance::IG;

# use 5.010000;  I cannot get this to work, trying to say it should run with perl 5.10 or greater and should be fine with 5.32 
# but get message ! Installing the dependencies failed: Your Perl (5.032001) is not in the range '5.10'
use strict;
no strict 'refs'; 
use warnings;

=encoding utf8

=head1 NAME

Finance::IG - - Module for doing useful stuff with IG Markets REST API.

=head1 DESCRIPTION

This is very much a first draft, but will enable you to get simple arrays of positions, print them out possily some simple trading.

Its proof of concept in perl beyond anything else, extend it as you need to.

I have only used it for spreadbet accounts, it would be simple to extend to CFD's but I dont have CFD data or an interest in CFD's so have not done this. 

You will need an API key to use this module, available free from IG Markets. 

=head1 VERSION

Version 0.101

=cut

our $VERSION = '0.101';


=head1 SYNOPSIS

   use Finance::IG;
   use strict;
   no strict 'refs';
   use warnings;

   my $ig=iFinance::IG->new(
                username=> "demome",
                password=> "mypassword",
                apikey=>   "4398232394029341776153276512736icab",
                isdemo=>0,
   );
 
   my $p=$ig->positions();    #  Get a list of positions
   $p=$ig->agg($p,$sortlist); #  Aggregate them, so one item per instrument. 

   my $format="%-41sinstrumentName %+6.2fsize %-9.2flevel ".
           "%-9.2fbid £%-8.2fprofit %5.1fprofitpc%% £%10.2fatrisk\n",

   $ig->printpos("stdout" , [], $format); 

   for my $position (@$p)
   { 
       $ig-> printpos("stdout" ,$position,$format); 
   } 

=head1 UTILITIES

The utility igdisp.pl is installed with this module and may be used to list your positions on IG.  A help message can be obtained with igdisp.pl -h 

=head1 SUBROUTINES/METHODS

This is a list of currently implemented methods

=head2 new
  
Normal parameters, as above.

col=>1

Causes Finance::IG to try to use Term::Chrome to do some simple coloration of output.
If Term::Chrome is not installed, it will be silently ignored. See printpos.

=head2 login

Originally needed to be called once after new and before other calls. Now this is done automatically, 
so you do not need to use this or be aware of it. Look for a 401 error if your password is 
wrong. 


No Parameters.

=head2 printpos print out a formatted hash as one line

Parameters
 
 file - can be a file handle or the string stdout or the glob *STDOUT 
 A position of other shallow hash, 
 A format string. The format string is similar to a printf format string, for example %s says print out a string
     however, the name of the item to be printed follows the letter, eg %sinstrumentName print the string instrument name. 
 optional up
 optional down 

A title line can be printed by either passing an array ref instead of a position, in which case the array ref can contain
the titles to print. If the array is empty then the titles will be generated from the format string.

up and down can be provided and represent negative and posite limits on dbid element by default. 
Alternatively, provide up only and make it a subroutine ref. 

The subroutime takes parameter a position, and should return escape characters (from Term::Chrome to colorise the line. 

=head2 transactions - retrieve transactions history 

transactions(++$page,Time::Piece->strptime("2020-01-01","%Y-%m-%d-%H.%M"),scalar localtime)

Parameters

Paging number, start at 1
Start time, can be a string or a Time::Piece
Endtime

return a reference to an array of transactions for that time span. Each transaction is a hash of data.

=cut 

use Moose;
use JSON;
use REST::Client;
#use Data::Dump qw(dump); # used in some commented out debug statements
#use Scalar::Util;
use Time::Piece;

BEGIN {
        if (eval("require Term::Chrome"))
        {
           Term::Chrome->import();
        }
        else
        {
           map { eval ("sub $_ {}") } qw(Red Blue Bold Reset Underline Green color); # need these to avoid compile time errors. 
        }
      }
has 'apikey' => (
                   is=>'ro',
                   isa=>'Str',
                   required=>1,
                );
has 'username' => (
                   is=>'ro',
                   isa=>'Str',
                   required=>1,
                );
has 'password' => (
                   is=>'ro',
                   isa=>'Str',
                   required=>1,
                );
has 'isdemo' => (
                   is=>'ro',
                   isa=>'Bool',
                   required=>1,
                );
has 'CST' => (
                   is=>'rw',
                   isa=>'Str',
                );
has 'XSECURITYTOKEN' => (
                   is=>'rw',
                   isa=>'Str',
                );

has 'XSTTIME' => (
                   is=>'rw',
                   isa=>'Int',
                );
has 'col' => (  # set to 1 to use Term::Chrome for coloration. 
                        is=>'rw',
                        isa=>'Bool',
                        default=>0,
                      );
has 'uds' => (
                        is=>'rw',
                        isa=>'Str',
                        default=>'',
                     );

around 'new' => sub {
    my $orig = shift;
    my $self = shift;
    my $r; 
 
    $r=$self->$orig(@_);
    $r->login; 
    return $r; 
};
sub _url
{
               my ($self) = @_;
               return 'https://demo-api.ig.com/gateway/deal' if ( $self->isdemo);
               return 'https://api.ig.com/gateway/deal';
}


##########################################################################
=head2 login - loginto the account. 

 Parameters - none 

login to the object, using the parameters provided to new. 

You should call this just once per object after calling new.  

=cut 
##########################################################################
sub login {
               my ($self) = @_;
               my $headers =
                        {
                            'Content-Type' => 'application/json; charset=UTF-8',
                            'Accept' =>  'application/json; charset=UTF-8',
                            VERSION => 2,
                            'X-IG-API-KEY'=> $self->apikey
                        };
                my $data =  {
                             identifier  => $self->username,
                             password  => $self->password,
                            };
                # my $jdata = encode_json($data);
                my $jdata=JSON->new->canonical->encode($data);

                my $client = REST::Client->new();
                $client->setHost($self->_url);


                $client->POST (
                               '/session',
                               $jdata,
                               $headers
                              );
                my $code=$client->responseCode();
                die "response code from login $code" if ($code!=200);
                $self->CST($client->responseHeader('CST')   // die "No CST header in login response");
                $self->XSECURITYTOKEN($client->responseHeader('X-SECURITY-TOKEN') // die "No X-SECURITY-TOKEN in login response header");
                $self->XSTTIME(time());
                return;
   }
##########################################################################

=head2 flatten 

Parameters 
  1 Ref to array of hashes to flatten or a ref to a hash to flatten
  2 ref to an array of items to flatten, or just a single item name.  

Typical use of this is for a position that as it comes back from IG contains a market and a position
byut we would prefer all items at the top level. This would moves all the keys of position and market up one level and 
would remove the keys market and position. 

$self->flatten($hash, [qw(market position)]);   

=cut 
##########################################################################
sub flatten
{
   my ($self)=shift;
   my ($hash)=shift;
   my ($toflatten)=shift;

   $hash=[$hash] if (ref($hash) ne  'ARRAY');
   $toflatten=[$toflatten] if (ref($toflatten) ne 'ARRAY');

   for my $h (@$hash)
   {
    for my $key (@$toflatten)
    {
      if (exists($h->{$key}))
      {
         if (defined($h->{$key}))
         {
            die "key $key to flatten is not a hash" if (ref($h->{$key}) ne 'HASH');
            for my $subkey (keys %{$h->{$key}})
            {
              die "subkey exists $subkey" if (exists($h->{$subkey}));
              $h->{$subkey}=$h->{$key}->{$subkey};
            }
         }
         delete $h->{$key};
      }
    }
   }
}
sub transactions
{

   my ($self) = shift;
   my ($pageNumber)=shift;
   my ($from) =shift;
   my ($to)=shift;

   my $pageSize=50;

   $from//='';
   $to//='';

   if (ref($to) eq 'Time::Piece')
   {
      $to=$to->strftime("%Y-%m-%dT%H:%M:%S");
   }
   if (ref($from) eq 'Time::Piece')
   {
      $from=$from->strftime("%Y-%m-%dT%H:%M:%S");
   }
   $to=~m/^[-0-9T:]*$/ or die "Invalid date format for 'to' $to, is a ".ref(\$to);
   $from=~m/^[-0-9T:]*$/ or die "Invalid date format for 'from' $from";

   my $headers =    {
                       'Content-Type' => 'application/json; charset=UTF-8',
                       'Accept' =>  'application/json; charset=UTF-8',
                       VERSION => 2,
                       CST=>$self->CST,
                       'X-SECURITY-TOKEN'=> $self->XSECURITYTOKEN,
                       'X-IG-API-KEY'=> $self->apikey,
                    };
    #my $jheaders = encode_json($headers);
    my $jheaders=JSON->new->canonical->encode($headers);

    my $client = REST::Client->new();
    $client->setHost($self->_url);

    $from and $from="from=$from";
    $to and $to="to=$to";
    my $rpage=$pageNumber; # requested page number as integer, 1 is first 
    $pageNumber and $pageNumber="pageNumber=$pageNumber";
    $pageSize and $pageSize="pageSize=$pageSize";

     my $url=join '', map { $_?'&'.$_:'' } ($from,$to,$pageNumber,$pageSize);
     $url=~s/^&//;
     $url='?'.$url if ($url);

     $url='/history/transactions'.$url;
    $client->GET (
                      $url,
                      $headers
                    );

     my $code=$client->responseCode();
     if ($code==200)
     {
        my $resp=decode_json($client->responseContent());
#         $resp=$self->flatten($resp,[qw/transactions metadata/]); 
         #die encode_json($resp); 

        my @activities=@{$resp->{transactions}};
        # pncerint encode_json( $resp->{metadata} ); 
        # {"pageData":{"totalPages":11,"pageNumber":11,"pageSize":50},"size":534}***** 34
        return undef if ($rpage > $resp->{metadata}->{pageData}->{pageNumber});
        # return undef if (@activities==0); 
        return \@activities;
     }
     else
     {
       print "failed $code: ".$client->responseContent()."\n";
       return undef;
     }
}

#  example from/ to sting format: 
#  2020-10-28
#  2020-10-28T15:30

# keys in retirn, when called with detailed=1
# type, goodTillDate, actions(ARRAY) , epic, direction, level, channel, marketName, date, dealReference, guaranteedStop, stopLevel, size, currency, stopDistance, trailingStep, status, trailingStopDistance, limitLevel, description, dealId, period, limitDistance
# without: 
# period, details, date, dealId, epic, description, channel, status, type

sub history
{
   my ($self) = shift;
   my ($detailed)=shift; ## undef, not detailed, 1 for detailed. 
   my ($pageNumber)=shift;


   my ($from) = shift;
   my ($to) = shift;

   $pageNumber//='';
   my $pageSize=50;

   $from//='';
   $to//='';

   if (ref($to) eq 'Time::Piece')
   {
      $to=$to->strftime("%Y-%m-%dT%H:%M:%S");
   }
   if (ref($from) eq 'Time::Piece')
   {
      $from=$from->strftime("%Y-%m-%dT%H:%M:%S");
   }

   $to=~m/^[-0-9T:]*$/ or die "Invalid date format for 'to' $to";
   $from=~m/^[-0-9T:]*$/ or die "Invalid date format for 'from' $from";

   my $headers =    {
                       'Content-Type' => 'application/json; charset=UTF-8',
                       'Accept' =>  'application/json; charset=UTF-8',
                       VERSION => 2,
                       CST=>$self->CST,
                       'X-SECURITY-TOKEN'=> $self->XSECURITYTOKEN,
                       'X-IG-API-KEY'=> $self->apikey,
                    };
    #my $jheaders = encode_json($headers);
    my $jheaders=JSON->new->canonical->encode($headers);

    my $client = REST::Client->new();
    $client->setHost($self->_url);
    $from="from=$from" if ($from ne '');
    $to="to=$to" if ($to ne '');
    if ($detailed)
    {
       $detailed="detailed=true"
    }
    else
    {
       $detailed='';
    }

    $pageNumber="pageNumber=$pageNumber" if ($pageNumber);
    $pageSize//='';
    $pageSize="pageSize=$pageSize" if ($pageSize);

#    my $sep='?'; 
#    map { $_ eq '' or $_=$sep.$_ and $sep='&'} ($from,$to,$detailed,$pageNumber,$pageSize); 

     my $url=join '', map { $_?'&'.$_:'' } ($from,$to,$detailed,$pageNumber,$pageSize);
     $url=~s/^&//;
     $url='?'.$url if ($url);

     $url='/history/activity'.$url;

    # die $url; 

    $client->GET (
                      $url,
                      $headers
                    );

     my $code=$client->responseCode();

     if ($code==200)
     {
        my $resp=decode_json($client->responseContent());
        my @activities=@{$resp->{activities}};
        return undef if (@activities==0);
        $self->flatten(\@activities,'details');
        return \@activities;
     }
     else
     {
       print "failed $code: ".$client->responseContent()."\n";
       return undef;
     }
}
# example response: 
#{"metadata":{"paging":{"size":50,"next":"/history/activity?version=3&from=2020-10-28T00:00:00&to=2020-10-29T16:41:45&detailed=false&pageSize=50"}}
#  "activities": [.... ] 
# }
# each activity looks like: 
#{
# details=>null,
# dealId=>"DIAAAAFRS39HJAK",
# period=>"DFB",
# type=>"POSITION",
# epic=>"UA.D.ATVI.DAILY.IP",
# description=>"Position partially closed=> J6GK8WA9",
# date=>"2020-10-29T17:47:46",
# status=>"ACCEPTED",
# channel=>"SYSTEM"
#
# or with detail 
# {"activities":
#      [
#      [
#        {"date":"2020-11-19T18:41:04",
#         "epic":"UC.D.MU.DAILY.IP",
#         "period":"DFB",
#         "dealId":"DIAAAAFVXZV5LA5",
#         "channel":"WEB",
#         "type":"POSITION",
#         "status":"ACCEPTED",
#         "description":"Position opened: VXZV5LA5",
#         "details":
#                    {
#                      "dealReference":"6XQESB1EQGWY4FR2",
#                      "actions":
#                           [
#                             {"actionType":"POSITION_OPENED",
#                              "affectedDealId":"DIAAAAFVXZV5LA5"
#                             }
#                           ],
#                        "marketName":"Micron Technology Inc (All Sessions)",
#                        "goodTillDate":null,
#                        "currency":"GBP",
#                        "size":0.4,
#                        "direction":"BUY",
#                        "level":6123,
#                        "stopLevel":null,
#                        "stopDistance":null,
#                        "guaranteedStop":false,
#                        "trailingStopDistance":null,
#                        "trailingStep":null,
#                        "limitLevel":null,
#                        "limitDistance":null
#                      }
#       },
#       {"date":"2020-11-17T11:33:52",
#"epic":"KA.D.FSTA.DAILY.IP",
#"period":"DFB",
#"dealId":"DIAAAAFVEFD4GAG",
#"channel":"WEB",
#"type":"POSITION",
#"status":"ACCEPTED",
#"description":"Position/s closed: HH93GXAZ",
#"details":{"dealReference":"6XQESB1EQAZNR6V3",
#"actions":[{"actionType":"POSITION_CLOSED",
#"affectedDealId":"DIAAAAFHH93GXAZ"}],
#"marketName":"Fuller Smith & Turner",
#"goodTillDate":null,
#"currency":"GBP",
#"size":1,
#"direction":"SELL",
#"level":726.2,
#"stopLevel":null,
#"stopDistance":null,
#"guaranteedStop":false,
#"trailingStopDistance":null,
#"trailingStep":null,
#"limitLevel":null,
#"limitDistance":null}},
#}

# with detailed=1

#{
#  "activities": [
#    {
#      "date": "2020-11-19T18:41:04",
#      "epic": "UC.D.MU.DAILY.IP",
#      "period": "DFB",
#      "dealId": "DIAAAAFVXZV5LA5",
#      "channel": "WEB",
#      "type": "POSITION",
#      "status": "ACCEPTED",
#      "description": "Position opened: VXZV5LA5",
#      "details": {
#        "dealReference": "6XQESB1EQGWY4FR2",
#        "actions": [
#          {
#            "actionType": "POSITION_OPENED",
#            "affectedDealId": "DIAAAAFVXZV5LA5"
#          }
#        ],
#        "marketName": "Micron Technology Inc (All Sessions)",
#        "goodTillDate": null,
#        "currency": "GBP",
#        "size": 0.4,
#        "direction": "BUY",
#        "level": 6123,
#        "stopLevel": null,
#        "stopDistance": null,
#        "guaranteedStop": false,
#        "trailingStopDistance": null,
#        "trailingStep": null,
#        "limitLevel": null,
#        "limitDistance": null
#      }
#    },
#    {
#      "date": "2020-11-17T11:33:52",
#      "epic": "KA.D.FSTA.DAILY.IP",
#      "period": "DFB",
#      "dealId": "DIAAAAFVEFD4GAG",
#      "channel": "WEB",
#      "type": "POSITION",
#      "status": "ACCEPTED",
#      "description": "Position/s closed: HH93GXAZ",
#      "details": {
#        "dealReference": "6XQESB1EQAZNR6V3",
#        "actions": [
#          {
#            "actionType": "POSITION_CLOSED",
#            "affectedDealId": "DIAAAAFHH93GXAZ"
#          }
#        ],
#        "marketName": "Fuller Smith & Turner",
#        "goodTillDate": null,
#        "currency": "GBP",
#        "size": 1,
#        "direction": "SELL",
#        "level": 726.2,
#        "stopLevel": null,
#        "stopDistance": null,
#        "guaranteedStop": false,
#        "trailingStopDistance": null,
#        "trailingStep": null,
#        "limitLevel": null,
#        "limitDistance": null
#      }
#    },
#    {
#      "date": "2020-11-17T11:33:09",
#      "epic": "KA.D.FSTA.DAILY.IP",
#      "period": "DFB",
#      "dealId": "DIAAAAFVEFBBKA4",
#      "channel": "WEB",
#      "type": "POSITION",
#      "status": "ACCEPTED",
#      "description": "Position opened: VEFBBKA4",
#      "details": {
#        "dealReference": "6XQESB1EQAZKR1V2",
#        "actions": [
#          {
#            "actionType": "POSITION_OPENED",
#            "affectedDealId": "DIAAAAFVEFBBKA4"
#          }
#        ],
#        "marketName": "Fuller Smith & Turner",
#        "goodTillDate": null,
#        "currency": "GBP",
#        "size": 2,
#        "direction": "BUY",
#        "level": 779.9,
#        "stopLevel": null,
#        "stopDistance": null,
#        "guaranteedStop": false,
#        "trailingStopDistance": null,
#        "trailingStep": null,
#        "limitLevel": null,
#        "limitDistance": null
#      }
#    },
#    {
#      "date": "2020-11-16T17:17:29",
#      "epic": "UD.D.WIXUS.DAILY.IP",
#      "period": "DFB",
#      "dealId": "DIAAAAFU94TQRAR",
#      "channel": "WEB",
#      "type": "POSITION",
#      "status": "ACCEPTED",
#      "description": "Position opened: U94TQRAR",
#      "details": {
#        "dealReference": "6XQESB1EQ90XNSR2",
#        "actions": [
#          {
#            "actionType": "POSITION_OPENED",
#            "affectedDealId": "DIAAAAFU94TQRAR"
#          }
#        ],
#        "marketName": "Wix.com Ltd",
#        "goodTillDate": null,
#        "currency": "GBP",
#        "size": 0.31,
#        "direction": "BUY",
#        "level": 24142,
#        "stopLevel": null,
#        "stopDistance": null,
#        "guaranteedStop": false,
#        "trailingStopDistance": null,
#        "trailingStep": null,
#        "limitLevel": null,
#        "limitDistance": null
#      }
#    },
#    {
#      "date": "2020-11-16T17:08:33",
#      "epic": "UD.D.ZMUS.DAILY.IP",
#      "period": "DFB",
#      "dealId": "DIAAAAFU924B7A3",
# etc.... 
##########################################################################
#

=head2 accounts - retrieve a list of accounts

 Parameters - none 

 Return value - Array ref containing hashes of accounts. 

=cut 
##########################################################################
sub accounts
{
   my ($self) = shift;

   my $headers =  {
                       'Content-Type' => 'application/json; charset=UTF-8',
                       'Accept' =>  'application/json; charset=UTF-8',
                       VERSION => 1,
                       CST=>$self->CST,
                       'X-SECURITY-TOKEN'=> $self->XSECURITYTOKEN,
                       'X-IG-API-KEY'=> $self->apikey,
                   };
    #my $jheaders = encode_json($headers);
    my $jheaders=JSON->new->canonical->encode($headers);

    my $client = REST::Client->new();
    $client->setHost($self->_url);
    my $r=$client->GET ( '/accounts', $headers);

    my $resp=decode_json($client->responseContent());

    my $accounts=[];
    @$accounts=@{$resp->{accounts}};

    return $accounts;

}

# Typical return data: 
#[
# {"accountId":"...",
#  "status":"ENABLED",
#  "canTransferFrom":true,
#  "preferred":true,
#  "accountAlias":null,
#  "accountType":"SPREADBET",
#  "accountName":"Spread bet",
#  "balance":{
#              "deposit":89051.36,
#              "balance":152475.8,
#              "available":85942.65,
#              "profitLoss":22518.21
#             },
#   "canTransferTo":true,
#   "currency":"GBP"
# },
# {"accountId":"...",
#  "status":"ENABLED",
#  "canTransferFrom":true,
#  "preferred":false,
#  "accountAlias":null,
#  "accountType":"CFD",
#  "accountName":"CFD",
#  "balance":{
#               "available":0,
#               "profitLoss":0,
#               "balance":0,
#               "deposit":0
#            },
#  "canTransferTo":true,
#  "currency":"GBP"
#  }
#]
##########################################################################
#
# Return a ref to an array of positions. Each position is  
# a variable structure deep hash 
#
##########################################################################
sub positions
{
   my ($self) = shift;

   my $headers =    {
                       'Content-Type' => 'application/json; charset=UTF-8',
                       'Accept' =>  'application/json; charset=UTF-8',
                       VERSION => 2,
                       #   'IG-ACCOUNT-ID'=> $accountid, 
                       CST=>$self->CST,
                       'X-SECURITY-TOKEN'=> $self->XSECURITYTOKEN,
                       'X-IG-API-KEY'=> $self->apikey,
                    };
    #my $jheaders=JSON->new->canonical->encode($headers); # for debug 

    my $client = REST::Client->new();
    $client->setHost($self->_url);
    #my $r;
#    $headers->{VERSION}=2;
    #$r=$client->GET (
    $client->GET (    '/positions',
                      $headers
                    );
    my $resp=decode_json($client->responseContent());

    my $positions=[];
    @$positions=@{$resp->{positions}};

    return $positions;
}
# example of the structure of a position
# Regeneron Pharmaceuticals Inc, 0.06
# {
#    "position" : {
#       "trailingStopDistance" : null,
#       "size" : 0.06,
#       "limitedRiskPremium" : null,
#       "stopLevel" : 50128,
#       "direction" : "BUY",
#       "level" : 50303,
#       "dealReference" : "6XQESB1E506WW334",
#       "controlledRisk" : false,
#       "currency" : "GBP",
#       "contractSize" : 1,
#       "createdDateUTC" : "2020-04-03T14:26:07",
#       "trailingStep" : null,
#       "createdDate" : "2020/04/03 15:26:07:000",
#       "limitLevel" : null,
#       "dealId" : "DIAAAAEL2T7AEAS"
#    },
#    "market" : {
#       "lotSize" : 1,
#       "marketStatus" : "EDITS_ONLY",
#       "instrumentType" : "SHARES",
#       "expiry" : "DFB",
#       "streamingPricesAvailable" : false,
#       "instrumentName" : "Regeneron Pharmaceuticals Inc",
#       "offer" : 60261,
#       "delayTime" : 0,
#       "updateTime" : "20:59:56",
#       "high" : 61455,
#       "percentageChange" : -2.01,
#       "netChange" : -1236,
#       "low" : 59886,
#       "bid" : 60261,
#       "updateTimeUTC" : "19:59:56",
#       "scalingFactor" : 1,
#       "epic" : "UC.D.REGN.DAILY.IP"
#    }
# }
#####################################################################
# Aggregate an array of positions into an array of unique 
# positions with 1 element per instrument, Items will be combined
# where more than one position is combined, in a field dependent way. 
# for exeample sizes will be added as will be profit
# a reference to an array is expected and a reference to a new array
# returned. 
#####################################################################

=head2 agg - aggregate positions into a flattened 1 element per instrument form. 

Parameters 

  1 Reference to an array of positions
  2 (Optional) Ref to an array of keys to sort on 

agg does three things actually. First, it joins together multiple positions of the same instrument, 
generating sensible values for things like profit/loss and size

Second, it performs some flattening of the deep structure for a position which comes from IG. 

Third it sorts the result. The default sort order I use is -profitpc instrumentName, but  
you can provide a 2rd parameter,  a reference to an array of items to sort by. 
Each item can optionally be preceeded by - to reverse the prder. If the first item equates equal, then 
the next item is used. 

=cut
#####################################################################
sub agg
{
  my ($self,$positions,$sortlist)=@_;
  my %totals;  # aggregated totals as arrays of individuals. 

  $self->flatten($positions, [qw/market position/]);
  for my $position (@$positions)
  {

   my $json = JSON->new;
#   $position->{size}= -abs($position->{size}) if ($position->{direction}//'' ne 'BUY'); 
   $position->{profit}=($self->fetch($position,'bid')-$self->fetch($position,'level'))*$self->fetch($position,'size');

   $position->{held}=Time::Piece->strptime($position->{createdDateUTC},"%Y-%m-%dT%H:%M:%S")  or die "strptime failed for ".$position->{createdDateOnly}; 
   $position->{held}=(gmtime()-$position->{held})/(24*3600); 

   my $ra=($totals{$position->{instrumentName}}||=[]);
   push(@$ra,$position);

  }

  # totals is a hash on instrument name each element is a pointer to an array of positions for the same instrument. 

  my $aggregated=[];
  for my $total (values %totals)
  {                                    # for one particular name 
     my $position={};                  # initialise the new aggregate position

     $position->{profit}=0;
     $position->{size}=0; 
     $position->{held}=0; 
     $position->{stopLevel}=[]; 
     $position->{createdDate}=[]; 
     $position->{createdDateUTC}=[]; 

     for my $subtotal ( @$total)         # go through all the positions for that one name
     {
      $position->{instrumentName}//=$subtotal->{instrumentName};
      $position->{size}+=$subtotal->{size};
      my $h; 
      $h=Time::Piece->strptime($subtotal->{createdDateUTC},"%Y-%m-%dT%H:%M:%S")  or die "strptime failed for ".$subtotal->{createdDateOnly}; 
      $h=(gmtime()-$h)/(24*3600); 
      $h=int($h*10)/10; 
      $subtotal->{held}=$h;
      $position->{held}+=$subtotal->{held}*$subtotal->{size}; # this is a size-weighted average. Needs division by total size.  
      $position->{bid}//=$subtotal->{bid};
      $position->{profit}+=$subtotal->{profit} ;
      $position->{epic}//=$subtotal->{epic};

      $position->{currency}//=$subtotal->{currency}; 
      $position->{marketStatus}//=$subtotal->{marketStatus}; 

      push(@{$position->{stopLevel}},$subtotal->{stopLevel}) if $subtotal->{stopLevel}; 
      push(@{$position->{createdDate}},$subtotal->{createdDate}); 
      push(@{$position->{createdDateUTC}},$subtotal->{createdDateUTC}); 
     }

     # now we have various housekeeping to do in some cases, eg where an average is calculated as a sum above, we divide by the number to get a true mean. 
     ###########

     $position->{held}=sprintf("%0.1f",$position->{held}/$position->{size});  $position->{held}.=" av" if (@$total>1); 


     $position->{level}=$position->{bid}-$position->{profit}/$position->{size}; # open level for multiple positions

     $position->{profitpc}=int(0.5+1000*$position->{profit}/($position->{level}*abs($position->{size})))/10 if ($position->{level}>0); 

     $position->{atrisk}=$position->{bid}*$position->{size};

     $position->{createdDate}=$self->sortrange($position->{createdDate}); 
     $position->{createdDateUTC}=$self->sortrange($position->{createdDateUTC}); 
     $position->{createdDateOnly}=$position->{createdDate}; 
     $position->{createdDateOnly}=~s/T[^-]+//g; 

     $position->{slpc}=join(',',map { $_?(int(1000.0*$_/$position->{bid})/10):''} @{$position->{stopLevel}});
     $position->{stopLevel}=join(',',@{$position->{stopLevel}}); 
     
     ########### 
     # end of aggregated operations 


     push(@$aggregated,$position);
   }

#  @$aggregated=sort { $b->{profitpc}<=>$a->{profitpc} }  @$aggregated;
   $sortlist//=[qw(-profitpc instrumentName)]; # default sort 
   $self->sorter($sortlist,$aggregated);
   return $aggregated;

}
# like agg, but do not do actual aggregation. 
# so we sort, add certain extra characteristics but thats all. 
##########################################################################
#

=head2 nonagg - like agg but do not do actual aggregation

Parameters 

  1 Reference to an array of positions
  2 (Optional) Ref to an array of keys to sort on 

 Return value - Array ref containing hashes of accounts. Should be the same size as the original. 

=cut 
##########################################################################
#sub nonagg
#{
#  my ($self,$positions,$sortlist)=@_;
#  my %totals;  # aggregated totals as arrays of individuals. 
#
#  $self->flatten($positions, [qw/market position/]);
#  for my $position (@$positions)
#  {
#
#   my $json = JSON->new;
#
#   $position->{profit}=($self->fetch($position,'bid')-$self->fetch($position,'level'))*$self->fetch($position,'size');
#   # create new profits element 
#
#     my $open=$position->{bid}-$position->{profit}/$position->{size};
#     $position->{level}=$open;
#     $position->{profitpc}=int(0.5+1000*$position->{profit}/($position->{level}*$position->{size}))/10;
#     $position->{atrisk}=$position->{bid}*$position->{size};
#     $position->{createdDateOnly}=$position->{createdDate};
#     $position->{createdDateOnly}=~s/ .*$//;
#   }
#
#   $sortlist//=[qw(-profitpc instrumentName)]; # default sort 
#   $self->sorter($sortlist,$positions);
#   return $positions;
#}
sub nonagg
{
  my ($self,$positions,$sortlist)=@_;
  my %totals;  # aggregated totals as arrays of individuals. 

  $self->flatten($positions, [qw/market position/]); 
  for my $position (@$positions)
  {

   my $json = JSON->new;

   $position->{size}=-abs($position->{size}) if ($position->{direction} eq 'SELL'); 
   $position->{profit}=($position->{bid}-$position->{level})*$position->{size};
   # create new profits element 

 #     my $open=$position->{bid}-$position->{profit}/$position->{size};
 #    $position->{level}=$open;
     $position->{profitpc}=int(0.5+1000*$position->{profit}/($position->{level}*abs($position->{size})))/10;
     $position->{atrisk}=$position->{bid}*$position->{size};
     $position->{createdDateOnly}=$position->{createdDate}; 
     $position->{createdDateOnly}=~s/ .*$//; 
     $position->{held}=Time::Piece->strptime($position->{createdDateUTC},"%Y-%m-%dT%H:%M:%S")  or die "strptime failed for ".$position->{createdDateOnly}; 
     $position->{held}=(gmtime()-$position->{held})/(24*3600); 
    $position->{held}=int($position->{held}*10+0.5)/10; 
     $position->{dailyp}=''; 
     $position->{dailyp}=((1+$position->{profitpc}/100.0)**(1/$position->{held})-1)*100 if ($position->{held}>0); 
    
   }

   $sortlist//=[qw(-profitpc instrumentName)]; # default sort 
   $self->sorter($sortlist,$positions); 
   return $positions;
}
####################################################################
# General array sort function. 
# Given an array of hash refs, and a sort key 
# considtying of an array of an array of keys to the hashes
# sort in place the array. 
# 
# sortkey, arrayref of keys. Sort order direction reversed 
# if key has - appended to start, eg -profitpc gives largest first 
# pos array eo be sorted, its an inplace sort. 
# uses the determinant $x eq $x+0 to determine if numeric or not. 
# improvements: may need to use a deep fetch to locate the items 
####################################################################

=head2 sorter - general array sort function for an array of hashes

Parameters 

  1 Ref to array of keys to sort. Each my be prefixed with a - to
    reverse the order on that key. If keys compare equal the next key is used. 
  2 Ref to an array of positions to sort. 

The array is sorted in-place. A numeric comparison is done if for 
both items $x == $x+0

Formatted datetimes are correctly sorted. 

=cut 
####################################################################
sub sorter
{
   my ($self,$sortkey,$pos)=@_;

   @$pos= sort {
                  my ($result)=0;
                  for my $fkey (@$sortkey)
                  {
                    my $key=$fkey;
                    my $dir=1;
                    $dir=-1 if ($key=~s/^-//);
                    # die "key=$key value=$b->{createdDateUTC} keys are ".join(', ',keys %$a); ; 
                    next if (!exists($a->{$key}) or !exists($b->{$key}));
                    my ($x1,$x2)=($a->{$key},$b->{$key});
                    map { s/[£%]//g } ($x1,$x2);

                    { no warnings qw(numeric);
                      my $warning;

                      if ($x1  eq  $x1+0 and $x2 eq $x2+0)
                      {
                          $result=$x1<=>$x2;
                      }
                      else
                      {   # note that this correctly handles a formatted date
                          $result=$x1 cmp $x2;
                      }
                    }
                    return $result*$dir if ($result);
                  }
                  return 0;
                }
                @$pos;

}
####################################################################
# The idea is this will close all the supplied positions, optionally returning a reference to 
# either/both an array of closed/non closed positions; 
# This is not quite working yet, needs more work, 
####################################################################

=head2 close  - close the supplied positions. 



Parameters 

  1 Ref to array of positions to close.  
    reverse the order on that key. 
  2/3 ref to done / notdone arrays to sort succesful / failed 
    closes in to. 

The idea is this will close all the supplied positions, optionally returning a reference to 


=head3 Status - very experimental. 

Contains die / print statements that you may wish to remove 

=cut 
####################################################################
sub close
{
   my $self=shift;
   my $positions=shift; # to close 
   my $done=shift;
   my $notdone=shift;

   my $verbose=0;

   my @done;
   my @notdone;

   my $headers =    {
                       'Content-Type' => 'application/json; charset=UTF-8',
                       'Accept' =>  'application/json; charset=UTF-8',
                       VERSION => 1,
                       #   'IG-ACCOUNT-ID'=> $accountid, 
                       CST=>$self->CST,
                       'X-SECURITY-TOKEN'=> $self->XSECURITYTOKEN,
                       'X-IG-API-KEY'=> $self->apikey,
                       '_method'=>'DELETE',
                    };

    my $data =      {
                       #encryptedPassword => "false",
                       #identifier  => $self->username,
                       #password  => $self->password
                       #direction => 'BUY', 
                       # epic=>
                       # expiry=> 
                       orderType=>'MARKET',
                       #size=>0.1 
                       ##guaranteedStop=>'false', 
                       forceOpen=>'true',
                       #timeInForce => "EXECUTE_AND_ELIMINATE", # "GOOD_TILL_CANCELLED"
                       timeInForce => "", # "GOOD_TILL_CANCELLED"
                    };
    my $client = REST::Client->new();

   $client->setHost($self->_url);


    my %existhash;
    map { $existhash{$self->fetch($_,'epic')}=$_ }   @$positions; # creat a hash on epic

for my $position (@$positions)
{
#    die dump($position); 

    my $existingsize=0;
    my $epic=$self->fetch($position,'epic');
    my $name=$self->fetch($position,'instrumentName');

    my $ms=$self->fetch($position,'marketStatus');

    if ($ms ne 'TRADEABLE')
    {
      push(@notdone,$position);
      print "$name, market status is $ms\n";
      next;
    }


    #$data->{epic}=$self->fetch($position,'epic'); 
    $data->{epic}=$epic;
    $data->{size}=$self->fetch($position,'size');
#    $data->{currencyCode}=$self->fetch($position,'currency');
    $data->{expiry}='DFB';
#    $data->{expiry}='-'; 
    $data->{direction}='SELL';

    #my $jdata = encode_json($data);
    my $jdata=JSON->new->canonical->encode($data);
    $client->PUT (
                      '/positions/otc',
                      $jdata,
                      $headers
                 );
     my $code=$client->responseCode();
     if ($code==200)
     {
        my $resp=decode_json($client->responseContent());
        my $dealReference=$resp->{dealReference};
        print "$name, dr=$dealReference\n";
        if (defined $dealReference  and length($dealReference)>5)
        {
           push(@done,$position);
           die;
           next;
           next;
        }
      }
      else
      {
        print "$name failed $code: ".$client->responseContent()."\n";
        push(@notdone,$position);
      }
}
      @$done=@done if ($done);
      @$notdone=@notdone if ($notdone);

printf "done=%d notdone=%d\n",0+@done,0+@notdone;
print "notdone:\n";

my $cpc='%%';
my $format="%-41sinstrumentName %+4.2fsize %-9.2flevel ".
           "%-8.2fbid £%-8.2fprofit %4.1fprofitpc%% £%10.2fatrisk %-9sstopLevel %-4sslpc$cpc\n";

$self->printpos("stdout" , ['Name','Size','Open','Latest','P/L','P/L%','Value','Stop','Stop'], $format);

map { $self->printpos("stdout" , $_, $format) } @notdone;

}
#####################################################################
# given a ref to an array of positions, attempt to buy the same 
# position in this object. 
# if the position already exists or is succesfully brought, count as success. 
# If the buy fails, include it in the returned list. 
# If all buys succesful then return an empty list. 
# done and notdone references may be supplied and if they are these should point to arrays 
# of the succesful and unsuccesful positions. 
# return value is NOT now used. 
# ignortradeable ... use this if the positionis an old one, so that tradeable status could 
#                    be out of date. 
#####################################################################

=head2 buy - attempt to buy a number of instruments. 

Parameters 

  1 Reference to an array of positions
  2 Optional ref to an array done, to be filled with succesful buys
  3 Optional ref to an array notdone, to be filled with the failed 
  4 ignore tradeable, one of the fields in a position relates to the market
    being open or closed (TRADEABLE) If this field is current, its a 
    good indication to skip this one (place it in the notdone array. 
    But if its out of date then setting this flag 1 attempts the trade 
    anyway. 

Attempt to buy positions. I have used this to move positions 
between a demo account and real account or vice-versa. 

=head3 Status - very experimental. 

Contains print statements that should 
probably be removed. 

=cut
#####################################################################
sub buy
{
   my $self=shift;
   my $positions=shift; # to buy
   my $done=shift;
   my $notdone=shift;
   my $ignoretradeable=shift;

   my $verbose=0;

   my @done;
   my @notdone;
   my $headers =    {
                       'Content-Type' => 'application/json; charset=UTF-8',
                       'Accept' =>  'application/json; charset=UTF-8',
                       VERSION => 2,
                       #   'IG-ACCOUNT-ID'=> $accountid, 
                       CST=>$self->CST,
                       'X-SECURITY-TOKEN'=> $self->XSECURITYTOKEN,
                       'X-IG-API-KEY'=> $self->apikey,
                    };

    my $data =      {
                       direction => 'BUY',
                       #epic=>
                       #size=>0.1 
                       orderType=>'MARKET',
                       guaranteedStop=>'false',
                       forceOpen=>'false',
                       timeInForce => "EXECUTE_AND_ELIMINATE", # "GOOD_TILL_CANCELLED"
                    };
    my $client = REST::Client->new();
    $client->setHost($self->_url);

    my $existing=$self->positions;
    my %existhash;
    map { $existhash{$self->fetch($_,'epic')}=$_ }   @$existing;

for my $position (@$positions)
{
#    die dump($position); 

    my $existingsize=0;
    my $epic=$self->fetch($position,'epic');
    my $name=$self->fetch($position,'instrumentName');

    my $ms=$self->fetch($position,'marketStatus');


    if (exists $existhash{$epic})
    {
     my $existingposition=$existhash{$epic};
     $existingsize=$self->fetch($existingposition,'size');
    }

    my $demandsize=$self->fetch($position,'size');
    my $wantedsize=$demandsize-$existingsize;

    print "existingsize=$existingsize wantedsize=$wantedsize, demandsize=$demandsize\n";
    if ($wantedsize<=0)
    {
      push(@done,$position);
      print "$name, not needed\n";
      next;
    }

    if ($ms ne 'TRADEABLE' and !$ignoretradeable)
    {
      push(@notdone,$position);
      print "$name, market status is $ms\n";
      next;
    }


    #$data->{epic}=$self->fetch($position,'epic'); 
    $data->{epic}=$epic;
    $data->{size}=$wantedsize;
    $data->{currencyCode}=$self->fetch($position,'currency');
    $data->{expiry}='DFB';

    #my $jdata = encode_json($data);
    my $jdata=JSON->new->canonical->encode($data);
    # die $jdata; 
    print "$data->{direction}: $position->{instrumentName} $position->{size}\n";
    $client->POST (
                      '/positions/otc',
                      $jdata,
                      $headers
                 );
     my $code=$client->responseCode();
     if ($code==200)
     {
      print "200: ".$client->responseContent()."\n";
        my $resp=decode_json($client->responseContent());
        my $dealReference=$resp->{dealReference};
        print "$name, dr=$dealReference\n";
        if (defined $dealReference  and length($dealReference)>5)
        {
           push(@done,$position);
           next;
        }
      }
      print "$name, failed code $code \n";
      push(@notdone,$position);
}
  @$done=@done if ($done);
  @$notdone=@notdone if ($notdone);
printf "done=%d notdone=%d\n",0+@done,0+@notdone;
print "notdone:\n";

return;

my $format="%-41sinstrumentName %+4.2fsize %-9.2flevel ".
           "%-8.2fbid £%-8.2fprofit %4.1fprofitpc%% £%10.2fatrisk\n";

$self->printpos("stdout" , ['Name','Size','Open','Latest','P/L','P/L%','Value','Stop','Stop'], $format);

map { $self->printpos("stdout" , $_, $format) } @notdone;

}

#####################################################################

=head2 prices - Obtain historical prices

Obtain historical price information on an instrument. 

=head3 Parameters 

    Unused parameters should be set as undef or ''. (either); 

    1 A aubstring to be searched for in the name. Eg "UB.D.FTNT.DAILY.IP"

    2 Resolution. Should be one of the IG defined strings (left) or (in my opinion more memorable) aliases (right)

      DAY       1d  
      HOUR      1h  
      HOUR_2    1h  
      HOUR_3    2h  
      HOUR_4    3h  
      MINUTE    1m  
      MINUTE_2  2m  
      MINUTE_3  3m  
      MINUTE_5  5m  
      MINUTE_10 10m  
      MINUTE_15 15m  
      MINUTE_30 30m  
      SECOND    1s  
      WEEK      1w  
      MONTH     1M  

    4, 5 pageNumber, pageSize What page to produce, and how many items on it. 

    6, 7 from , to (dates) can be a string of the form 2021-01-01T16:15:00  or a Time::Piece

    8 max Limits the number of price points (not applicable if a date range has been specified)

    



=cut

#####################################################################
# Historical prices
# epic, resolution , pagenum, pagessize, from.to max 
#####################################################################
sub prices
{ 

   my $self=shift;
   my $epic=shift; 
   my $resolution=shift; 
   my $pagenumber=shift; 
   my $pagesize=shift; 

   my $from=shift; 
   my $to=shift; 
   my $max=shift; 

   
   if (ref($to) eq 'Time::Piece')
   {
      $to=$to->strftime("%Y-%m-%dT%H:%M:%S");
   }
   if (ref($from) eq 'Time::Piece')
   {
      $from=$from->strftime("%Y-%m-%dT%H:%M:%S");
   }

   $pagesize//=1;  # set a default of 1 item per page 
   # $pagenumber=1;  # set a default of page 1, not needed as already set as defult 

   my $headers =    {
                       'Content-Type' => 'application/json; charset=UTF-8',
                       'Accept' =>  'application/json; charset=UTF-8',
                       VERSION => 3,
                       #   'IG-ACCOUNT-ID'=> $accountid, 
                       CST=>$self->CST,
                       'X-SECURITY-TOKEN'=> $self->XSECURITYTOKEN,
                       'X-IG-API-KEY'=> $self->apikey,
                    };

    $resolution="MINUTE_10"; 
    $resolution="HOUR_4"; 

# An alternative and more memorable resolution constants. IG values can also be used.
    $resolution="DAY" if ($resolution eq '1d');  
    $resolution="HOUR" if ($resolution eq'1h');  
    $resolution="HOUR_2" if ($resolution eq '1h');  
    $resolution="HOUR_3" if ($resolution eq '2h');  
    $resolution="HOUR_4" if ($resolution eq '3h');  
    $resolution="MINUTE" if ($resolution eq '1m');  
    $resolution="MINUTE_2" if ($resolution eq '2m');  
    $resolution="MINUTE_3" if ($resolution eq '3m');  
    $resolution="MINUTE_5" if ($resolution eq '5m');  
    $resolution="MINUTE_10" if ($resolution eq '10m');  
    $resolution="MINUTE_15" if ($resolution eq '15m');  
    $resolution="MINUTE_30" if ($resolution eq '30m');  
    $resolution="SECOND" if ($resolution eq '1s');  
    $resolution="WEEK" if ($resolution eq '1w');  
    $resolution="MONTH" if ($resolution eq '1M');  

    defined $resolution and 
    (0==grep { $resolution eq $_} qw(DAY HOUR HOUR_2 HOUR_3 HOUR_4 MINUTE MINUTE_10 MINUTE_15 MINUTE_2 MINUTE_3 MINUTE_30 MINUTE_5 MONTH SECOND WEEK)) and 
       die "Resolution is '$resolution', not recognised"; 

    #my $jheaders=JSON->new->canonical->encode($headers);

    my $client = REST::Client->new();
    $client->setHost($self->_url);
    #my $r;

    my $values={
                 pageNumber=>$pagenumber, 
                 pageSize=>$pagesize, 
                 resolution=>$resolution, 
                 from=>$from,
                 to=>$to,
                 max=>$max, 
               } ; 

    delete @$values{ grep {!$values->{$_}  } keys %$values} ;        # delete all empty or undef values 
    map { $values->{$_}=$_."=".$values->{$_} } keys %$values ;
 
    my $url;  
    $url=join('&',sort values(%$values)); 
    $url='?'.$url if ($url);  
    $url="prices/$epic".$url; 


    $client->GET (    $url,
                      $headers
                    );

    
    my $resp=decode_json($client->responseContent());



    $self->flatten_withunder($resp); 
    # print JSON->new->canonical->pretty->encode($resp); exit; 

    return $resp; 
}
#####################################################################
# flatten_withunder
# flattens a deep hash, 3 levels max, where complex hashes are 
# removed and replace with _ joined shallow hash values
# for exapmple: 
#   { 
#     "metadata" : {
#      "allowance" : {
#         "allowanceExpiry" : 530567,
#         "remainingAllowance" : 9557,
#         "totalAllowance" : 10000
#      },
#      ...
# 
# becomes 
#      {
#        "metadata_allowance_allowanceExpiry" : 530473,
#        "metadata_allowance_remainingAllowance" : 9556,
#        "metadata_allowance_totalAllowance" : 10000,
#         ...
# The advantage of a flattened structure is its easier to print. 

#####################################################################

=head2 flatten_withunder 

Flatten a deep structure, up to 3 layers deep using underscores to create new keys by concatenating deeper keys. 
Deep keys are removed. More than 3 layers can be removed by calling multiply. 

=head3 Parameters 
 
  One or more scalers to opperate on or an array. Each will be flattened 
  where there are hashes or hashes or hashes of hashes of hashes  
  to a single depth, with elements joined by underscores 

=head3 Example

   { 
     "metadata" : {
      "allowance" : {
         "allowanceExpiry" : 530567,
         "remainingAllowance" : 9557,
         "totalAllowance" : 10000
      },
      ...
 
 becomes 
      {
        "metadata_allowance_allowanceExpiry" : 530473,
        "metadata_allowance_remainingAllowance" : 9556,
        "metadata_allowance_totalAllowance" : 10000,
         ...

The advantage of a flattened structure is its easier to print with existing fuunctions like printpos

=cut 

#####################################################################
sub flatten_withunder
{ 
  my ($self)=shift; 
  my (@items)=@_; 
  my $fudebug=0; 
  $fudebug and printf "%d items to process\n",0+@items; 
  for my $item (@items) 
  { 
     $fudebug and print "item is a ".ref($item)."\n"; 
     return if (ref($item)eq ''); 
     if (ref($item) eq 'HASH')
     { 
        $fudebug and print "is a hash\n"; 
        for my $key (keys %$item)
        { 
         $fudebug and print "key1 $key\n"; 
         if (ref($item->{$key}) eq 'HASH')
         { 
           for my $key2 (keys %{$item->{$key}}) 
           { 
              $fudebug and print "keyr2 $key2\n"; 
              $item->{$key."_".$key2}=$item->{$key}->{$key2}; 
              $fudebug and printf "creating $key"."_"."$key2 as a %s\n",ref($item->{$key}->{$key2}); 
              
              # $self->flatten_withunder($item->{$key}) if (ref($item->{$key}->{$key2}) eq 'HASH'); 
              if (ref($item->{$key}->{$key2}) eq 'HASH')
              { 
                 for my $key3 (keys %{$item->{$key}->{$key2}}) 
                 { 
                   $fudebug and print "key3 $key3\n"; 
                   $item->{$key."_".$key2."_".$key3}=$item->{$key}->{$key2}->{$key3}; 
                   $fudebug and printf "creating $key"."_$key2"."_$key3 as a %s\n",ref($item->{$key}->{$key2}->{$key3}); 
                 } 
                 $fudebug and print "deleting $key->$key2 and $key _$key2\n"; 
                 delete $item->{$key}->{$key2}; 
                 delete $item->{$key."_".$key2}; 
              } 
           } 
           $fudebug and print "deleting: $key\n"; 
           delete $item->{$key}; 
         }
         if (ref($item->{$key}) eq 'ARRAY')
         { 
           $fudebug and print "$key is array ref\n"; 
           for (@{$item->{$key}})
           { 
              $self->flatten_withunder($_); 
           } 
         } 
        }
     } 
     if (ref($item) eq 'ARRAY')
     { 
       $fudebug and print "is an array\n"; 
       for (@$item) 
       { 
          $self->flatten_withunder($_); 
       } 
     }
   }    
   $fudebug and print "processed\n"; 
} 


#####################################################################
# uses known structure of supplied deep hash to search for item
# should probably replace with a more generalised deep fetch function. 
#####################################################################

=head2 fetch

This function is a way to hide the various structures a position may have

Obsolete but still used sometimes. 

Parameters 

   1 A position hash ref, $h  
   2 The name of the item to be retrieved. 

Returns undef if not found, or the value of item if it is. 

The function looks first in $h->{item} then 
in $h->{position}=>{item} and then in $h->{market}->{item} 

Its only useful with positions, not hashes in general. 

=cut 
#####################################################################
sub fetch
{
 my ($self,$position,$item)=@_;

  # return "NOT A HASREF $position"if (ref($position) ne 'HASH'); 
  die "supplied position $position to fetch() is not a HASHREF" if (ref($position) ne 'HASH');
  defined $item or die "fetch, item undefined";
  my $p=$position->{position};
  my $m=$position->{market};

     if (exists $position->{$item}) { return $position->{$item}; }
     elsif (exists $p->{$item}) { return $p->{$item}; }
     elsif (exists $m->{$item}) { return $m->{$item}; }
     else {
            return undef;
          }

}

#####################################################################
# given an instrument name in search, look for it inside the instrumentName, and return 
# the epic. Fail if result is not 1 item. 
# used for filling in the epic (a unique identifier) in old data files 
# where I forgot to store it. 
#####################################################################

=head2 epicsearch 

Find the epic (unique identifier) for an instrument from the underlying share. 

This function calls IG's search API looking for a match to the name. If found 
the value of the epic is returned. 

=head3 Status - very experimental. Seems to work well. 

Contains print and die statements. Useful if you forgot to record the epic. 

=cut 

#####################################################################
sub epicsearch
{
  my ($self,$search)=@_;
  my $headers =
  {
   'Content-Type' => 'application/json; charset=UTF-8',
   'Accept' =>  'application/json; charset=UTF-8',
    VERSION => 1,
    CST=>$self->CST,
    'X-SECURITY-TOKEN'=> $self->XSECURITYTOKEN,
    'X-IG-API-KEY'=> $self->apikey,
  };
  #my $jheaders = encode_json($headers);
  my $jheaders=JSON->new->canonical->encode($headers);
  my $client = REST::Client->new();
  $client->setHost($self->_url);
  $search=~s#/#%2F#g;
  my $url="/markets?searchTerm=$search";
  $search=~s#%2F#/#g;
  $url=~s/ /%20/g;
 my $r=$client->GET ( $url, $headers);

# my $resp=decode_json($client->responseContent()); 


  #print "url=$url\n"; 
  my $code;

  $code=$client->responseCode();

  my $retried=0;
  while ($code==403 and $retried<4)
  {
     sleep 10;
     $retried++;
     $r=$client->GET ( $url, $headers);
     $code=$client->responseCode();
#     print "search retried\n"; 
  }

  die "response code from  url='$url' code=$code retried $retried times" if ($code!=200);

  my $markets=decode_json($client->responseContent);
#   print JSON->new->ascii->pretty->encode($markets)."\n"; 

  my @wantedmarkets=grep { $_->{expiry} eq 'DFB' } @{$markets->{markets}};
    @wantedmarkets=grep { $self->_nothe($self->fetch($_,'instrumentName') , $search) } @wantedmarkets;

  @wantedmarkets=map { $_->{epic} } @wantedmarkets;
  die "Zero epics found for search $search" if (@wantedmarkets==0);
  die "Multiple epics found @wantedmarkets for search $search" if (@wantedmarkets!=1);

  return $wantedmarkets[0];

}
#####################################################
# remove a trailing 'the' 
#####################################################
sub _nothe
{
  my ($self,$x,$y)=@_;

  # print "comparing $x $y \n"; 
  $x=~s#/.*$##;
  $y=~s#/.*$##;

  return $x eq $y;
}
# so this is used to read one of my old data files. 
##################################################################################
# Reads am ascii file - older format and returns a list of positions, 
# a hashref keyed on epic. 
##################################################################################

=head2 readfile_oldformat 


Parameters

    1 Path to a file to read 

A file readable by this function may be generated by using printpos with  format as follows: 
           "%-41sinstrumentName %+6.2fsize %-9.2flevel ".
           "%-9.2fbid £%-8.2fprofit %5.1fprofitpc%% £%10.2fatrisk\n", 

This file was originally generated to be human readable so reading by machine is a stretch. 

=head3 Status - downright broken (for you). Sorry! 

May contains print and die statements. Contaions hardcoded paths that will need to be 
changed. 

=cut 
##################################################################################
sub readfile_oldformat
{
  my ($self, $f,$writenewfile)=@_;
  my $positions={};
  my $totalline;
  $f="/home/mark/igrec/results/$f";
  open(F,$f) or die "cannot open $f";
#Roku Inc                                   +0.38 16501.00   21842.0 £2029.58  32.4% £   8299.96
  my @fieldhashnames=qw(epic instrumentName size level bid profit profitpc atrisk);
  while (<F>)
  {
    my @fields;
    my @names=@fieldhashnames;
    my $position={};

    chomp;
    if (m/\|/)
    {
      die;
    }
    elsif (m/^Name/)
    {
      s/[£%]//g;
      @fields=split(/ +/);
      unshift(@fields,'Epic');
#      print "#".join("\|",@fields)."\n";
    }
    elsif (m/^Total/)
    {
      $totalline=$_;
    }
    else
    {
      my $name=substr($_,0,42);
      my $line=substr($_,43);
      $name=~s/ +$//;
      $line=~s/[\$£%]//g;
      @fields=split(/ +/,$line);
      my $epic=$self->epicsearch($name);
      unshift(@fields,$epic,$name);
      #die "$line\n@fields\n@names"; 
      while (@names)
      {
        $position->{shift(@names)}=shift(@fields);
      }
      $positions->{$epic}=$position;
    }
 }
 # close F; 
 if ($writenewfile)
 {
   $f=~s/results/r2/;
   if (! -e $f)
   {
     open(my $g,">" , $f) or die "Cannot open $f for write";
     my $format=    "%sepic|%sinstrumentName|%0.2fsize|%-0.2flevel|".
                    "%-0.2fbid|£%-0.2fprofit|%0.1fprofitpc%%|£%0.2fatrisk\n",
     print $g "Epic|Instrumentname|Size|Level|Bid|Profit£|Profitpc%|Atrisk£\n";
     my $a=$self->agg([values %$positions]);
     for (@$a)
     {
        $self->printpos($g,$_,$format);
     }
     print $g $totalline."\n";
   }
 }
 return $positions;
}
##################################################################################
# Reads am ascii file and returns a list of positions, 
# a hashref keyed on epic. 
##################################################################################

=head2 readfile


Parameters

    1 Path to a file to read 

A file readable by this function may be generated by using printpos with  format as follows: 
           "%sepic|%sinstrumentName|%0.2fsize|%-0.2flevel|".
           "%-0.2fbid|£%-0.2fprofit|%0.1fprofitpc%%|£%0.2fatrisk|%smarketStatus\n", 

=head3 Status - downright broken (for you). Sorry! 

The function contains a hardcoded path for reading the files.  You would need a 
crontab entry to generate them.   

May contain print and die statements. Contains hardcoded paths that will need to be 
changed. 

=cut 
##################################################################################
sub readfile
{
  my ($self,$f)=@_;

  my $positions={};
  $f="/home/mark/igrec/r2/$f";
  open(F,$f) or die "cannot open $f";
  my @fieldhashnames=qw(epic instrumentName size level bid profit profitpc atrisk tradeable);
  my $ln=0;
  while (<F>)
  {
    my @fields;
    my @names=@fieldhashnames;
    my $position={};

    $ln++;
    chomp;
    if (m/^Total/)
    {
      next;
    }
    elsif (m/ Positions$/)
    {
      next;
    }
    elsif (m/^ *$/)
    {
      next;
    }
    elsif (m/#/)
    {
      next;
    }
    elsif (!m/\|/)
    {
      die "No | lin line $ln file $f";
    }
    elsif (m/Epic/)
    {
      next;
    }
    else
    {
      s/[£&]//g;
      @fields=split(/\|/);
      for my $fieldname (@fieldhashnames)
      {
        die if (!defined $names[0]);
        #print "names[0]=$names[0]\n"; 
        $position->{$fieldname}=shift(@fields);
      }
      $positions->{$position->{epic}}=$position;
      $position->{marketStatus}//='';  # older files do not record this. 
    }
 }
 return $positions;
}
#####################################################################
# format strings contained embedded printf specifiers followed by 
# a hash element name . 
#
# eg "%sdate %sdescription %sepic %sstatus\n"; 
# eg "%-20sdate %-30sdescription %-20sepic %-15sstatus\n"; 
# eg 
#           "%sepic|%sinstrumentName|%6.2fsize|%-9.2flevel|".
#           "%-9.2fbid|£%-8.2fprofit|%5.1fprofitpc%%|£%10.2fatrisk\n", 
#eg 
#           "%-41sinstrumentName %+6.2fsize %-9.2flevel ".
#           "%-9.2fbid £%-8.2fprofit %5.1fprofitpc%% £%10.2fatrisk\n", 
# Arguments:
# 1) An IG object ref. (self) Is not really used. 
# 2) Either "stdout" or an open writable file handle. 
# 3) A hash possibly deep, with items. Ig the item is not found directly in the hash, 
# the $self->fetch function is used for access. If still not found
# then "UNDEF" is printed.
# CHANGED to $self->uds 
# OR: If this is an array ref, then a title line is ptinted using the format string 
#     and the referenced array of titles
# OR: If empty dtring ort undef, derive titles from the format 
#     string and print a title line.  
# 4) A formatting string. Can contain text, containing embedded 
#    format instructions like %6.2fsize here %6.2f is a print f 
#    specifier and size is the name of the item to retrieve from the hash. 
#  5,6)  up /down  can be percent gives green if > up, bold green if > 5*up. 
#        can be a coloration function of position. 
#        just one function, so no down ever. 
#        function takes argument position, and returns optional colors 
#####################################################################

=head2 printpos 

=head3 Parmeters

A file handle or the word stdout, all output sent here. 

A hashref  of items to print 
OR: If this is an array ref, then a title line is ptinted using the format string 
and the referenced array of titles
OR: If empty string or undef, derive titles from the format 
string and print a title line.  

A formatting string. Can contain text, containing embedded 
format instructions like %6.2fsize here %6.2f is a print f 
specifier and size is the name of the item to retrieve from the hash. 

OPTIONAL up     can be percent gives green if > up, bold green if > 5*up. 
can be a coloration function of position.  Just one function, so no down ever if a function is given 
function takes argument position, and returns optional colors 

OPTIONAL down   can be percent gives red if <down , bold red if < 5*down. 

=head3 Description

This is a very general function will work with any hash. 

=cut
#####################################################################
sub printpos
{

   my ($self,$out,$position,$format,$up,$down)=@_;

  my $colsub;

  $out=*STDOUT if ($out eq "stdout");

  $down=-$up if (defined $up and ref($up) eq '' and !defined $down) ;

  if (defined $up and  ref($up) ne 'CODE')
  {
    $colsub=sub 
        {
          my ($position)=shift;
          my $v1=$position->{dbid};
          my $col='';
          $v1=~s/%//;
          $col=Green if (defined $up and $v1>$up);
          $col=Red if (defined $down and $v1<$down);
          $col=Green+Bold if (defined $up and $v1>$up*5);
          $col=Red+Bold if (defined $down and $v1<5*$down);
          return $col;
        };
  }
  $colsub=$up if (defined $up and ref($up) eq 'CODE');
  $colsub=sub {''} if (!defined $up);


  my $titles=$format;
  if (ref($position) eq 'ARRAY') # its titles to print!
  {
     #$format=~s/%[-+]/%/g; 
     #print "$format\n"; 
     while ($format=~m/[-+]?([0-9]+)\.([0-9]+)/)
     {
       my $x;
       $x=$1;
       abs($2)>abs($x) and $x=$2;
       $format=~s/%([-+]?)([0-9]+)\.([0-9]+)/%$1$x/;
     }
     #print "#1 $format\n"; 
     $format=~s/%\+\+/%+/g;
     #print "#2 $format\n"; 
     $format=~s/%([-\+]?[0-9]+)\.[0-9]+/%$1/g;
     #print "#3 $format\n"; 
     $format=~s/%([-\+]?[0-9]+)[fd]/%$1s/g;
     #print "#4 $format\n"; 
     $format=~s/%([-\+]?[0-9]*)([a-zA-Z_][a-zA-Z0-9_]*)/%$1s/g;
     #die $format; 
     # print "$format\n"; exit; 
     #$"=":"; print "@$position\n"; 
  

    $format=~s/[\x82\x83\xc3]//g;   # so we get some strange characters like ÃÂ occuring in pairs. Not sure why. This removes them.   
     #$format="%-41s %+7s %11s %-10s £%-10s %5s%% £%12s %-9s %-4s"; 
     #print "$format\n"; #exit; 
    print $out Bold if ($self->col and defined $INC{'Term/Chrome.pm'});
    # print "format='$format' @$position\n"; 
    printf $out $format,@$position;
    print $out Reset if ($self->col and defined $INC{'Term/Chrome.pm'});
    return;
  }

  # auto generated title list from the names  
  if (!defined $position or $position eq '')
  {
    $titles=~s/\n//g;
    $titles=~s/%([-+0-9.]*)([sfd])/%/g;
    $titles=~s/%%/__PC__/g;
    $titles=~s/%//; # just one 
    $titles=~s/£%([a-zA-Z]+)/%$1£/g;
    my @titles=split(/%/,$titles);
    map {s/[|,]//g } @titles;
    map {s/  +//g } @titles;
    map { s/__PC__//g; } @titles;
    map { s/([\w']+)/\u\L$1/g; } @titles;
    while ($format=~m/%[-+]?([0-9]+)\.([0-9]+)/)
     {
       my $x;
       #my $x=$1+$2; 
       $x=$1;
       $2>$x and $x=$2;
       $format=~s/%([-+]?)([0-9]+)\.([0-9]+)/%$1$x/;
     }
    $format=~s/(%[-+0-9.]*)[a-zA-Z]+/$1s/g;
    #$format=~s/(%[-+0-9]+)\.[0-9]+/$1/g; 
    $format=~s/£//g;
    #die "format=$format titles=@titles"; 
    $format=~s/[\x82\x83\xc3]//g;   # so we get some strange characters like ÃÂ occuring in pairs. Not sure why. This removes them.   
    print $out Bold  if ($self->col and defined $INC{'Term/Chrome.pm'});
    printf $out $format, @titles;
    print $out Reset if ($self->col and defined $INC{'Term/Chrome.pm'});
    return;
  }



#  $p=$position->{position};
#  $m=$position->{market};

  $format=~s/%%/##/g;


#  while (($format=~s/%([-+0-9]+\.[0-9]+)([a-z][a-zA-Z0-9]*)/%$1__S__/) || ($format=~s/%([-+0-9]*)([a-z][a-zA-Z0-9]*)/%$1__F__/))
#  { 
#     my $s; 
#     $s=$activity->{$2}; 
#     my $pos=$1; 
#     $pos=~s/-//; 
#     $s=substr($s,0,$pos) if (defined(pos) and $pos ne '' and $pos<length($s));
#     push(@args,$s); 
#  } 

  my $col='';
  while ($format=~s/%([-+0-9.]*[dsf])([a-zA-Z_][a-zA-Z0-9_]*)/%s/)
  {
     my $s;

     my $item=$2;
     my $len=$1//"";
#     die "item is UNDEF" if ($item eq 'UNDEF'); 
#     die "len is UNDEF" if ($len eq 'UNDEF'); 
#     $len='' if ($len eq 'UNDEF'); 
     $len="%".$len if ($len);
     if (defined $item and $item ne '' and exists $position->{$item} and defined $position->{$item})
     {
       $position->{$item}=~s/%//g;
       #$position->{$item}='0' if ($position->{$item} eq 'UNDEF'); 
       $s=sprintf($len,$position->{$item});
       if ($item eq 'dbid'  and exists $INC{'Term/Chrome.pm'} and $self->col)
       {
          ##my $v1=$position->{dbid}; 
          ##$v1=~s/%//; 
          ##$col=Green if (defined $up and $v1>$up); 
          ##$col=Red if (defined $down and $v1<$down); 
          ##$col=Green+Bold if (defined $up and $v1>$up*5); 
          ##$col=Red+Bold if (defined $down and $v1<5*$down); 

          # $col=&$colsub($position); 
       }
       # $col=Yellow if (defined $up); 
          # $col=&$colsub($position); 
     }
     elsif (defined $self->fetch($position,$item))
     {
       #$s=sprintf($len,$self->fetch($position,$2)//"UNDEF");
       $s=sprintf($len,$self->fetch($position,$item)//$self->uds);
       if ($item eq 'dbid'  and defined $INC{'Term/Chrome.pm'} and $self->col)
       {
          #my $v1; 

          #$v1=$self->fetch($position,'dbid'); 
          #$v1=~s/%//; 
          #$v1=100*$v1/$self->fetch($position,'bid'); 
          ###$col=Green if (defined $up and $self->col and $self->fetch($position,'dbid')/$self->fetch($position,'bid')>$up/100); 
          ###$col=Red if (defined $down and $self->col and $self->fetch($position,'dbid')/$self->fetch($position,'bid')<$down/100); 
          #$col=Green if (defined $up and $self->col and $v1>$up); 
          #$col=Red if (defined $down and $self->col and $v1<$down); 
          #$col=Green+Bold if (defined $up and $self->col and $v1>$up*5); 
          #$col=Red+Bold if (defined $down and $self->col and $v1<5*$down); 
          #$col=&$colsub($position); 
       }
          #$col=&$colsub($position); 

     }
     else
     {
       $len=~s/[df]/s/;
       $len=~s/\.[0-9]+//;
       #$s=sprintf($len,"UNDEF");
       $s=sprintf($len,$self->uds);
     }

          $col=&$colsub($position);
     $len=~s/[dsf]$//;
     if ($len ne '') # len can be something like 0.2
     {
       $len=~s/%//;
       $len=abs($len) if ($len ne '');
       $s=substr($s,0,$len) if ($len and $len<length($s) and $len>=1);
     }

     $format=~s/%s/$s/;
  }

  $col=&$colsub($position)//'' if ($self->col and defined $INC{'Term/Chrome.pm'});
  $format=~s/##/%/g;
  $format=~s/£-/-£/g;
  $format=~s/[\x82\x83\xc3]//g;   # so we get some strange characters like ÃÂ occuring in pairs. Not sure why. This removes them.   
  print $out $col, $format;
  if (ref($col) ne '')
  { print $out Reset;
  }

}



=head2 sortrange 

=head3 Parameters
   
  Ref to an array containing dates in printed ascii format. 

If there are no dates or an empty array, an empty string is returned. 

If there is one date, then that date is returned

If there is more than one then the first and last after sorting is returned, with a dash between them. 

This is used in aggregation of positions and relates to creation dates with multiple positions
in the same security purchased at different times. 

=cut 

sub sortrange
{ 
   my ($self,$ar)=@_; 

   my @dates=sort @$ar; 
    
   return '' if (@dates==0); 
   return $dates[0] if (@dates==1); 
   return $dates[0] . "-".$dates[-1]; 
} 

=head1 DEPENDENCIES

 Moose
 Term::Chrom if available. 

=head1 UTILITIES

A more complete position lister is given as igdisp.pl

=head1 AUTHOR

Mark Winder, C<< <markwin at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-finance-ig at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Finance-IG>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Finance::IG


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Finance-IG>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Finance-IG>

=item * Search CPAN

L<https://metacpan.org/release/Finance-IG>

=back


=head1 ACKNOWLEDGEMENTS

=head1 FURTHER READING

IG REST API Reference https://labs.ig.com/rest-trading-api-reference

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2020 by Mark Winder.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1; # End of Finance::IG
