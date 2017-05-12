=head1 NAME

Finance::OATS - Stub of a Perl extension to support generating OATS records

=head1 SYNOPSIS

  use Finance::OATS qw(:all);

  $MPID = "TEST";
  $OSOID= 9999;

  # all variables must be set before first call to AddNewAndRoute and
  # friends

  # call AddNewAndRoute and AddCancel a bunch of times

  # closes last FORE file
  CloseFOREFile();


=head1 DESCRIPTION

Simple module to generate ROE records for OATS and package them up
into FORE files.

=head1 SEE ALSO

The NASDR OATS website, at L<http://www.nasd.com/web/idcplg?IdcService=SS_GET_PAGE&nodeId=377>

=head1 EXPORT

None by default.

AddNewAndRoute
AddCancel

CloseFOREFile

And a bunch of variables which can be used to tweak settings; settings must be tweaked before
first call to AddNewAndRoute or AddCancel.

=head1 AUTHOR

Mike Giroux, rmgiroux@acm.org

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Mike Giroux and Wang Trading, LLC

This library is free software; you can redistribute it and/or modify
it under the terms of the General Public License version 2, a.k.a. GPLv2.

See L<LICENSE> file for details.

=head1 CREDITS AND DISCLAIMER

This library is released under the GPL with the kind permission of
Dr. Meng-Yuan Wang, the Managing Partner of Wang Trading, LLC.

This library is a STUB.  It's the beginnings of an OATS implementation,
but it is far from complete.  Many of the ROE fields contain hard-coded
values which may not be appropriate to your case; please check them
carefully!

Neither Wang Trading, M-Y Wang, nor Mike Giroux is responsible nor
liable for any problems which may arise through the use of this library.

YOU are RESPONSIBLE for any files you upload to NASDR.  _YOU_ are liable
for fines if they are wrong.  Please be very careful!

At a minimum, use the NASDR OATS test site and make sure everything looks
good.

See the TBD comments.

=cut

package Finance::OATS;

require 5.005_62;
use strict;
use warnings;

use Carp qw(cluck confess);

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Finance::OATS ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
    $MPID
    $OSOID
    $UserID
    $Password
    $FOREByteLimit
    $sep
    $FOREPrefix
    AddNewAndRoute
    AddCancel
    AddCancelReplace
    GenerateFOREFiles
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(

);

our $VERSION = '0.11';

our $MPID = 'TEST';
our $OSOID = 999;

our $UserID = "user";
our $Password = "pass";
#our $Password = "";

our $FOREByteLimit = 1_450_000;

# NASDR allows many different field separators,
# so choose the one you like.
our $sep=',';

# fore files will have names starting with this prefix
our $FOREPrefix = "fore";


sub GetDateStamp {
    my ($yr, $mn, $dy) = (localtime)[5,4,3];
    $yr+=1900;
    $mn++;

    sprintf("%04d%02d%02d",$yr,$mn,$dy);
}

my $dateStamp = GetDateStamp();

my $lastROEIdNo = 1;
my $roePrefix   = 'WA';

sub GetNextROEID {
    my $id = sprintf("%2s%010d",$roePrefix, $lastROEIdNo);

    ++$lastROEIdNo;


    if($lastROEIdNo > 9_999_999_999) {
        $lastROEIdNo = 1;
        $roePrefix++;
    }

    return $id;
}

my $lastFOREIdNo = 1;

sub GetNextFOREId {
    sprintf("${FOREPrefix}.${dateStamp}_%04d",$lastFOREIdNo++);
}

=head2 sub AddNewAndRoute

Generates New Order and Route events for a new order

Arguments:
    Symbol => 'MSFT',
    Side   => 'B',          # or 'S', or 'SS', or 'SX'
    OrderID=> 'AISL-123',   # our order ID
    Time   => 'HHMMSS',     # order timestamp
    Price  => '12.12345',   # price, in dollars, to 7 decimal places if need be
    Shares => 1200,         # size, in shares
    MPID   => 'ISLD',       # sent-to MPID (opt., def ISLD)
    OtherID=> '123432',     # exchange order ID
    Date   => 'yyyymmdd',   # optional, defaults to today
    IOC    => 'IOC',        # optional, specified if order is IOC
    Visible=> 'Y',          # optional, 'Y' or 'N'
                            #   ******* TBD: LIST OUT OF DATE!!!! ***********
    RouteType=> 'C',        # 38) Routing method code (defaults to 'C')
                            #     E routed elec to member firm
                            #     C routed to ECN
                            #     L routed to SelectNet
                            #     N routed non-electronic to memb firm
                            #     M routed to non-member firm
                            #     O routed to SuprtSOES
                            #     P routed to Primex
                            #     S routed to SOES
                            #     X routed to exchange
    ProgramTradingCode=>'Y',# optional, 'Y' or 'N'
    IndexArbCode=>'N',      # optional, 'Y' or 'N'
    PriceType=>'LIM',       # optional, 'LIM' or 'MKT'

=cut

sub AddNewAndRoute {
    my %defaults = (
                        MPID    => 'ISLD',
                        RecvMPID=> '',
                        Visible => 'Y',
                        Date    => $dateStamp,
                        IOC     => '',
                        RouteType => 'C',
                        ProgramTradingCode => 'Y',
                        IndexArbCode => 'N',
                        PriceType => 'LIM',
                        CancelTimeStamp => '',
                        CancelledBy => ''
                   );
    my %args = (%defaults, @_);

    foreach my $key (qw(Symbol Side OrderID Time Price Shares)) {
        cluck "Missing argument '$key'" unless exists $args{$key};
    }

    my $ROE;
    my $ROEId=GetNextROEID();

    # Combined order/route record spec in Oats Technical Reporting ,
    # Specifications Appendix C, pages C-19 to C-22.
    $ROE="#OE#${sep}";                   # 1) Order event record (OE)
    $ROE.="OR${sep}";                    # 2) Order event type (OR)
    $ROE.="N${sep}";                     # 3) Action type code (N/C/D/R)
    $ROE.="$ROEId${sep}";                # 4) Firm ROE ID
    $ROE.="${sep}";                      # 5) corr/del TS
    $ROE.="${sep}";                      # 6) Rej ROE resub flag
    #$ROE.="$MPID${sep}";                 # 7) Receiving firm MPID
    #$ROE.="${sep}";                      # 7) Receiving firm MPID (blank if same)
    $ROE.="$args{RecvMPID}${sep}";       # 7) Receiving firm MPID (blank if same)
    $ROE.=sprintf("%08d000000${sep}",$args{Date});     # 8) Order received date
    $ROE.="$args{OrderID}${sep}";        # 9) receiving firm order ID
    $ROE.="${sep}";                      # 10) Routing firm MPID
    $ROE.="${sep}";                      # 11) Routed order ID
    $ROE.=sprintf("%08d%06s${sep}",$args{Date},$args{Time}); #12)Order received time
    $ROE.="E${sep}";                     # 13) received method code
    $ROE.="$args{Symbol}${sep}";         # 14) Symbol
    $ROE.="$args{Side}${sep}";           # 15) Buy/Sell code, B|S|SS|SX
    if($args{PriceType} eq "LIM") {
        $ROE.="$args{Price}${sep}";      # 16) Limit price
    }
    else {
        $ROE.="${sep}";                  # 16) Limit price
    }
    $ROE.="$args{Visible}${sep}";        # 17) Limit order display indicator
    $ROE.="${sep}";                      # 18) Stop price
    if($args{PriceType} eq "LIM") {
        $ROE.="DAY${sep}";               # 19) TIF
    }
    else {
        $ROE.="${sep}";                  # 19) TIF
    }
    $ROE.="${sep}";                      # 20) Expiration date
    $ROE.="${sep}";                      # 21) Expiration time
    $ROE.="${sep}";                      # 22) Do not reduce/do not increase code
    $ROE.="$args{IOC}${sep}";        # 23) First special handling code
    $ROE.="${sep}";                  # 24) 2nd special handling code
    $ROE.="${sep}";                  # 25) 3rd special handling code
    $ROE.="${sep}";                  # 26) 4th special handling code
    $ROE.="${sep}";                  # 27) 5th special handling code
    $ROE.="${sep}";                  # 28) receiving terminal ID
    $ROE.="${sep}";                  # 29) receiving dept ID
    $ROE.="${sep}";                  # 30) originating dept ID
    $ROE.="W${sep}";                 # 31) acct type code (Wholesale)
    $ROE.="$args{ProgramTradingCode}${sep}"; # 32) program trading code
    $ROE.="$args{IndexArbCode}${sep}"; # 33) arbitrage code
    $ROE.="$args{OrderID}${sep}";    # 34) Sent to routed order ID
    $ROE.="$args{MPID}${sep}";       # 35) Sent to firm MPID
    $ROE.=sprintf("%08d%06s${sep}",$args{Date},$args{Time}); # 36)Order sent time
    $ROE.="$args{Shares}${sep}";         # 37) Routed Shares Quantity
    $ROE.="E${sep}";                 # 38) Route type
                                    #     E Electronic
                                    #     M Manual
    #$ROE.="${sep}";                  # 39: bunched order indicator
    $ROE.="${sep}";                  # 39: bunched order indicator
    $ROE.="N${sep}";                 # 40: Member type code (N Non-Member Firm)
			             # TBD: LIST POSSIBLY OUT OF DATE!
    $ROE.="$args{RouteType}${sep}";  # 41: Destination code
                                #        E ecn
                                #        L selectnet
                                #        M Member firm
                                #        N non member firm
                                #        P Primex
                                #        U Supermontage
                                #        X Exchange
    $ROE.="${sep}";                  # 42: ECN flag
    $ROE.="$args{CancelTimeStamp}${sep}";
                                # 43: Cancel time stamp, if order fully cancelled
    $ROE.="$args{CancelledBy}"; # 44: Cancelled by flag, C or F
    $ROE.="\n";                 # 45: end of record marker (LF or CRLF)

    WriteROE($ROE);
}

=head2 sub AddCancel

Generates New Order and Route events for a new order

Arguments:
    Symbol => 'MSFT',
    OrderID=> 'AISL-123',   # our order ID
    Time   => 'HHMMSS',     # order timestamp
    CancelType=> 'F',       # 'F'ull or 'P'artial, defaults to F
    SharesCanceled => 1200, # shares canceled
    SharesRemaining => 100, # shares canceled
    MPID   => 'ISLD',       # sent-to MPID (opt., def ISLD)
    Date   => 'yyyymmdd',   # optional, defaults to today

=cut

sub AddCancel {
    my %defaults = (
                        MPID    => 'ISLD',
                        RecvMPID=> '',
                        Date    => $dateStamp,
                        CancelType => 'F',
                        SharesCanceled => '',
                        SharesRemaining => '',
                   );
    my %args = (%defaults, @_);

    foreach my $key (qw(Symbol OrderID Time)) {
        cluck "Missing argument '$key'" unless exists $args{$key};
    }

    # 2004-12-08, this is wrong interpretation of "P"artial
    # 2004-12-09, if partial, sharesCanceled must be present
    if($args{CancelType} eq 'P') {
        if(!exists $args{SharesCanceled}) {
            $args{SharesCanceled}=0;
        }
    }

    my $ROE;
    my $ROEId=GetNextROEID();

    # Cancel order record spec in Oats Technical Reporting Specifications,
    # Appendix C, page C-14
    $ROE="#OE#${sep}";                   # 1) Order event record (OE)
    $ROE.="CL${sep}";                    # 2) Order event type (CL)
    $ROE.="N${sep}";                     # 3) Action type code (N/C/D/R)
    $ROE.="$ROEId${sep}";                # 4) Firm ROE ID
    $ROE.="${sep}";                      # 5) corr/del TS
    $ROE.="${sep}";                      # 6) Rej ROE resub flag
    #$ROE.="$MPID${sep}";                 # 7) Receiving firm MPID
    #$ROE.="${sep}";                      # 7) Receiving firm MPID (blank if same)
    $ROE.="$args{RecvMPID}${sep}";       # 7) Receiving firm MPID (blank if same)
    $ROE.=sprintf("%08d000000${sep}",$args{Date});     # 8) Order received date
    $ROE.="$args{OrderID}${sep}";        # 9) receiving firm order ID
    $ROE.="$args{Symbol}${sep}";         # 10) Symbol
    $ROE.=sprintf("%08d%06s${sep}",$args{Date},$args{Time}); #11)Order received time
    $ROE.="$args{CancelType}${sep}";     # 12) Shares quantity
    $ROE.="$args{SharesCanceled}${sep}"; # 13) Cancel Quantity
    $ROE.="$args{SharesRemaining}${sep}"; # 14) Cancel leaves qty
    $ROE.="C${sep}";                      # 15) Canceled by flag 'C'ust or 'F'irm
    $ROE.="";                       # 16) Originating MPID (as of 20021213)
    $ROE.="\n";                     # 17) end of record marker (LF or CRLF)

    WriteROE($ROE);
}

sub AddNew {
    my %defaults = (
                        MPID    => 'ISLD',
                        RecvMPID=> '',
                        Visible => 'Y',
                        Date    => $dateStamp,
                        IOC     => ''
                   );
    my %args = (%defaults, @_);

    foreach my $key (qw(Symbol Side OrderID Time Price Shares OtherID)) {
        cluck "Missing argument '$key'" unless exists $args{$key};
    }

    my $ROE;
    my $ROEId=GetNextROEID();

    # New order record spec in Oats Technical Reporting Specifications,
    # Appendix C, pages C-6 to C-9.
    $ROE="#OE#${sep}";                   # 1) Order event record (OE)
    $ROE.="NW${sep}";                    # 2) Order event type (NW)
    $ROE.="N${sep}";                     # 3) Action type code (N/C/D/R)
    $ROE.="$ROEId${sep}";                # 4) Firm ROE ID
    $ROE.="${sep}";                      # 5) corr/del TS
    $ROE.="${sep}";                      # 6) Rej ROE resub flag
    #$ROE.="$MPID${sep}";                 # 7) Receiving firm MPID
    #$ROE.="${sep}";                      # 7) Receiving firm MPID (blank if same)
    $ROE.="$args{RecvMPID}${sep}";       # 7) Receiving firm MPID (blank if same)
    $ROE.=sprintf("%08d000000${sep}",$args{Date});     # 8) Order received date
    $ROE.="$args{OrderID}${sep}";        # 9) receiving firm order ID
    $ROE.="${sep}";                      # 10) Routing firm MPID
    $ROE.="${sep}";                      # 11) Routed order ID
    $ROE.=sprintf("%08d%06s${sep}",$args{Date},$args{Time}); #12)Order received time
    $ROE.="E${sep}";                     # 13) received method code
    $ROE.="$args{Symbol}${sep}";         # 14) Symbol
    $ROE.="$args{Side}${sep}";           # 15) Buy/Sell code, B|S|SS|SX
    $ROE.="$args{Shares}${sep}";         # 16) Shares quantity
    $ROE.="$args{Price}${sep}";          # 17) Limit price
    $ROE.="$args{Visible}${sep}";        # 18) Limit order display indicator
    $ROE.="${sep}";                      # 19) Stop price
    $ROE.="DAY${sep}";                   # 20) TIF
    $ROE.="${sep}";                      # 21) Expiration date
    $ROE.="${sep}";                      # 22) Expiration time
    $ROE.="${sep}";                      # 23) Do not reduce/do not increase code

    $ROE.="$args{IOC}${sep}";        # 24) First special handling code

    $ROE.="${sep}";                  # 25) 2nd special handling code
    $ROE.="${sep}";                  # 26) 3rd special handling code
    $ROE.="${sep}";                  # 27) 4th special handling code
    $ROE.="${sep}";                  # 28) 5th special handling code
    $ROE.="${sep}";                  # 29) receiving terminal ID
    $ROE.="${sep}";                  # 30) receiving dept ID
    $ROE.="${sep}";                  # 31) originating dept ID
    $ROE.="W${sep}";                 # 32) acct type code (Wholesale)
    $ROE.="N${sep}";                 # 33) program trading code
    $ROE.="N${sep}";                 # 34) arbitrage code
    #$ROE.="${sep}";                  # 35) reserved for future use
    $ROE.="";                   # 35) reserved for future use
    $ROE.="\n";                 # 36) end of record marker (LF or CRLF)

    WriteROE($ROE);
}

=head2 sub AddCancelReplace

Generates Cancel/Replace report

Arguments:
    Symbol => 'MSFT',
    Side   => 'B',          # or 'S', or 'SS', or 'SX'
    OrderID=> 'AISL-123',   # new order ID
    OrigOrderID=> 'AISL-122',   # original order ID
    Time   => 'HHMMSS',     # new order timestamp
    OrigTime=> 'HHMMSS',     # new order timestamp
    Price  => '12.12345',   # price, in dollars, to 7 decimal places if need be
    Shares => 1200,         # size, in shares
    MPID   => 'ISLD',       # sent-to MPID (opt., def ISLD)
    OtherID=> '123432',     # exchange order ID
    Date   => 'yyyymmdd',   # optional, defaults to today
    IOC    => 'IOC',        # optional, specified if order is IOC
    Visible=> 'Y',          # optional, 'Y' or 'N'
    RouteType=> 'C',        # 38) Routing method code (defaults to 'C')
                            #     E routed elec to member firm
                            #     C routed to ECN
                            #     L routed to SelectNet
                            #     N routed non-electronic to memb firm
                            #     M routed to non-member firm
                            #     O routed to SuprtSOES
                            #     P routed to Primex
                            #     S routed to SOES
    ProgramTradingCode=>'Y',# optional, 'Y' or 'N'
    IndexArbCode=>'N',      # optional, 'Y' or 'N'
    PriceType=>'LIM',       # optional, 'LIM' or 'MKT'

=cut

sub AddCancelReplace {
    my %defaults = (
                        MPID    => 'ISLD',
                        RecvMPID=> '',
                        Visible => 'Y',
                        Date    => $dateStamp,
                        IOC     => '',
                        RouteType => 'C',
                        ProgramTradingCode => 'Y',
                        IndexArbCode => 'N',
                        PriceType => 'LIM',
                   );
    my %args = (%defaults, @_);

    foreach my $key (qw(Symbol Side OrderID OrigOrderID Time OrigTime
                        Price Shares)) {
        cluck "Missing argument '$key'" unless exists $args{$key};
    }

    my $ROE;
    my $ROEId=GetNextROEID();

    # Cancel/Replace report
    # Specifications Appendix C, pages C-15 to C-17.
    $ROE="#OE#${sep}";                   # 1) Order event record (OE)
    $ROE.="CR${sep}";                    # 2) Order event type (CR)
    $ROE.="N${sep}";                     # 3) Action type code (N/C/D/R)
    $ROE.="$ROEId${sep}";                # 4) Firm ROE ID
    $ROE.="${sep}";                      # 5) corr/del TS
    $ROE.="${sep}";                      # 6) Rej ROE resub flag
    #$ROE.="$MPID${sep}";                 # 7) Receiving firm MPID
    #$ROE.="${sep}";                      # 7) Receiving firm MPID (blank if same)
    $ROE.="$args{RecvMPID}${sep}";       # 7) Receiving firm MPID (blank if same)
    $ROE.=sprintf("%08d000000${sep}",$args{Date});
                                    # 8) Orig Order received date
    $ROE.="$args{OrigOrderID}${sep}";    # 9) receiving firm orig order ID
    die "AddCancelReplace not yet implemented!";
#TBD Finish coding this report!
#TBD Finish coding this report!
#TBD Finish coding this report!
#TBD Finish coding this report!
#TBD Finish coding this report!
#TBD Finish coding this report!
#TBD Finish coding this report!
#TBD Finish coding this report!
#TBD Finish coding this report!
    $ROE.="${sep}";                      # 10) Routing firm MPID
    $ROE.="${sep}";                      # 11) Routed order ID
    $ROE.=sprintf("%08d%06s${sep}",$args{Date},$args{Time}); #12)Order received time
    $ROE.="E${sep}";                     # 13) received method code
    $ROE.="$args{Symbol}${sep}";         # 14) Symbol
    $ROE.="$args{Side}${sep}";           # 15) Buy/Sell code, B|S|SS|SX
    if($args{PriceType} eq "LIM") {
        $ROE.="$args{Price}${sep}";      # 16) Limit price
    }
    else {
        $ROE.="${sep}";                  # 16) Limit price
    }
    $ROE.="$args{Visible}${sep}";        # 17) Limit order display indicator
    $ROE.="${sep}";                      # 18) Stop price
    if($args{PriceType} eq "LIM") {
        $ROE.="DAY${sep}";               # 19) TIF
    }
    else {
        $ROE.="${sep}";                  # 19) TIF
    }
    $ROE.="${sep}";                      # 20) Expiration date
    $ROE.="${sep}";                      # 21) Expiration time
    $ROE.="${sep}";                      # 22) Do not reduce/do not increase code
    $ROE.="$args{IOC}${sep}";        # 23) First special handling code
    $ROE.="${sep}";                  # 24) 2nd special handling code
    $ROE.="${sep}";                  # 25) 3rd special handling code
    $ROE.="${sep}";                  # 26) 4th special handling code
    $ROE.="${sep}";                  # 27) 5th special handling code
    $ROE.="${sep}";                  # 28) receiving terminal ID
    $ROE.="${sep}";                  # 29) receiving dept ID
    $ROE.="${sep}";                  # 30) originating dept ID
    $ROE.="W${sep}";                 # 31) acct type code (Wholesale)
    $ROE.="$args{ProgramTradingCode}${sep}"; # 32) program trading code
    $ROE.="$args{IndexArbCode}${sep}"; # 33) arbitrage code
    $ROE.="$args{OrderID}${sep}";    # 34) Sent to routed order ID
    $ROE.="$args{MPID}${sep}";       # 35) Sent to firm MPID
    $ROE.=sprintf("%08d%06s${sep}",$args{Date},$args{Time}); # 36)Order sent time
    $ROE.="$args{Shares}${sep}";         # 37) Routed Shares Quantity
    $ROE.="$args{RouteType}${sep}";      # 38) Routing method code (routed to ECN)
                                    #     E routed elec to member firm
                                    #     C routed to ECN
                                    #     L routed to SelectNet
                                    #     N routed non-electronic to memb firm
                                    #     M routed to non-member firm
                                    #     O routed to SuprtSOES
                                    #     P routed to Primex
                                    #     S routed to SOES
    $ROE.="${sep}";                  # 39: bunched order indicator
    $ROE.="";                   # 40: Original MPID (as of 20021213)
    $ROE.="\n";                 # 41: end of record marker (LF or CRLF)

    WriteROE($ROE);
}



sub GetHeaderRecord
{
    my $foreID = shift;
    my $hdr;

    # Header record spec at page C-6 of OATS R.T.S.
    $hdr.="#HD#${sep}";              # 1: Record type code #HD# (header)
    $hdr.="OATS D1999-01${sep}";     # 2: Version description
    $hdr.="$dateStamp${sep}";        # 3: Generation date
    $hdr.="$foreID${sep}";           # 4: Firm FORE ID
    $hdr.="$OSOID${sep}";            # 5: Reporting/transmitting OSO ID
    $hdr.="$UserID${sep}";           # 6: USer ID
    $hdr.="$Password${sep}";         # 7: User password
    $hdr.="$MPID";              # 8: Order receiving firm MPID
    $hdr.="\n";                 # 9: End of record marker (LF or CRLF)
}

my $FOREFileOpen = 0;
my $FOREPath;
my $FOREBytes = 0;
my $FORERecords = 0;

my ($foreID, $forePath);

sub OpenFOREFile {
    $FOREPath = shift || ".";
    $FOREPath.="/" unless $FOREPath=~/\/$/;


    do {
        $foreID = GetNextFOREId();
        $forePath = "$FOREPath$foreID";
    } while (-e $forePath);

    my $hdr = GetHeaderRecord($foreID);

    open(FORE, ">$forePath") or confess "Can't open $forePath, error $!";

    $FOREBytes=length $hdr;

    print FORE $hdr;

    $FORERecords = 0;

    $FOREFileOpen = 1;
}

sub WriteROE {
    my $roe = shift;

    OpenFOREFile() unless $FOREFileOpen;

    if($FOREBytes>=$FOREByteLimit) {
        CloseFOREFile();
        OpenFOREFile();
    }

    print FORE $roe;

    $FOREBytes+=length $roe;
    ++$FORERecords;
}

sub CloseFOREFile {
    OpenFOREFile() unless $FOREFileOpen;

    print FORE "#TR#,$FORERecords,\n";
    close(FORE);
}

END {
    CloseFOREFile();
}


1;
__END__



