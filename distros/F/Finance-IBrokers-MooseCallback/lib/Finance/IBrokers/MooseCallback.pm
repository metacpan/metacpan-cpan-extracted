package Finance::IBrokers::MooseCallback;

use 5.006;
use strict;

#use warnings FATAL => 'all';
use warnings;

=head1 NAME

Finance::IBrokers::MooseCallback - Moose implemention of the Interactive Brokers callback.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

This is a Perl Moose implementation of the sample callback described at 
http://search.cpan.org/~jstrauss/Finance-InteractiveBrokers-TWS-0.1.1/lib/Finance/InteractiveBrokers/TWS.pm#EXAMPLE

It provides variable names that are descriptive of what gets passed to each method. It is a generalization of code 
I wrote for my own purposes. You will likely want to override it with your own methods. Updates are welcome.

Using this module is very similar to the sample described within Finance::InteractiveBrokers::TWS

    use Finance::InteractiveBrokers;
    use Finance::IBrokers::MooseCallback;

    my $callback = Finance::IBrokers::MooseCallback->new(debug => 1);
    my $tws = Finance::InteractiveBrokers::TWS->new($callback);

    my $tick_type = $tws->TickType->new();
    $callback->{tickType} = $tick_type;

    #                           Host         Port    Client_ID
    #                           ----         ----    ---------
    my @tws_GUI_location = qw/  127.0.0.1    7496       15     /;

    $tws->eclient->eConnect(@tws_GUI_location);

    do { $tws->read_messages_for_x_sec() } until $tws->eclient->isConnected();
 
    my $orderid = $callback->getNextID; # For the next ID available 

    #  Create a contract
    #
    my $contract = $tws->Contract->new();

    ... 

    $tws->eclient->reqContractDetails( '1', $contract );


    do {
    $tws->read_messages_for_x_sec();
    } until ( defined $callback->get_contractDetailsRequest() && $callback->get_contractDetailsRequest('1')->{Status} eq 'Complete'  );

    warn Dumper( $callback->contractDetailsRequest);
    
=head1 SUBROUTINES/METHODS
=cut 

use MooseX::Declare;

class Finance::IBrokers::MooseCallback {
    use MooseX::Types::Moose qw( Int Any Num HashRef ArrayRef Any);
    use Data::Dumper;
    use Time::HiRes::Value;
    use Date::Manip;

    #use Storable;

    use Finance::IBrokers::Types
      qw(Contract Order OrderState ContractDetails Execution boolean long UnderComp);

=head2 NextID
   - Stores the NextID value to use when placing an order. It is initialized by TWS at startup, then incremented with getNextID.

=cut

    has 'NextID' => ( is => 'rw', isa => Int, default => -1 );

=head2 contracts
    - Stores the an array of Finance::InteractiveBrokers::TWS::com::ib::client::ContractDetails objects in the contractDetails method.

=cut

    has 'contracts' => (
        is => 'rw',
        isa =>
'ArrayRef[Finance::InteractiveBrokers::TWS::com::ib::client::ContractDetails]',
        traits  => ['Array'],
        default => sub { [] },
        handles => {
            all_contracts    => 'elements',
            add_contract     => 'push',
            map_contracts    => 'map',
            filter_contracts => 'grep',
            find_contract    => 'first',
            get_contract     => 'get',
            join_contracts   => 'join',
            count_contracts  => 'count',
            has_contracts    => 'count',
            has_no_contracts => 'is_empty',
            sorted_contracts => 'sort',
        },
    );

    #has 'contracts' => ( is => 'rw', isa => ArrayRef );
    #has 'accountinfo' => ( is => 'rw', isa => HashRef );

=head2 debug
    Set debug to 1 to enable more warn output 

=cut

    has 'debug' => ( is => 'rw', isa => boolean, default => 0 );

=head2 contractDetailsRequest
    - Stores a hash of values describing the contract details request status.

=cut

    has 'contractDetailsRequest' => (
        is      => 'rw',
        isa     => HashRef,
        traits  => ['Hash'],
        default => sub { {} },
        handles => {
            set_contractDetailsRequest     => 'set',
            get_contractDetailsRequest     => 'get',
            has_no_contractDetailsRequests => 'is_empty',
            num_contractDetailsRequests    => 'count',
            delete_contractDetailsRequest  => 'delete',
            contractDetailsRequest_pairs   => 'kv',
        },
    );

=head2 accountinfo
    - Stores the a hash of account information key=>value pairs.

=cut

    has 'accountinfo' => (
        is      => 'rw',
        isa     => HashRef,
        traits  => ['Hash'],
        default => sub { {} },
        handles => {
            set_accountinfo    => 'set',
            get_accountinfo    => 'get',
            has_no_accountinfo => 'is_empty',
            num_accountinfo    => 'count',
            delete_accountinfo => 'delete',
            accountinfo_pairs  => 'kv',
        },
    );

=head2 DataReq
    - Storage for data requests to be made.

=cut

    has 'DataReq' => (
        is      => 'rw',
        isa     => HashRef,
        traits  => ['Hash'],
        default => sub { {} },
        handles => {
            set_DataReq    => 'set',
            get_DataReq    => 'get',
            has_no_DataReq => 'is_empty',
            num_DataReq    => 'count',
            delete_DataReq => 'delete',
            DataReq_pairs  => 'kv',
        },
    );

=head2 candles
    - Storage for OHLC candles

=cut

    has 'candles' => (
        is      => 'rw',
        isa     => 'HashRef',
        traits  => ['Hash'],
        default => sub { {} },
        handles => {
            set_candle    => 'set',
            get_candle    => 'get',
            has_no_candle => 'is_empty',
            num_candle    => 'count',
            delete_candle => 'delete',
            candle_pairs  => 'kv',
        },

    );

=head2 nextValidId
    - Called at startup, then when getNextID is used. Sets the next ID for TWS orders.

=cut

    method nextValidId( Int $orderId) {
        $self->NextID($orderId);
          warn "nextValidId initialized with: $orderId\n" if ( $self->debug );
      }

=head2 getNextID
    - Return the next order ID currently set NextID and increments the value.

=cut

      method getNextID {
        my $nextid = $self->NextID;
        my $addid  = $nextid;
        $self->NextID( ++$addid );
        return $nextid;
    }

    #method error( Exception e ) {}

=head2 error
    - Two error methods, since it can be called two different ways.
    method error( Str $str ) { warn $str if ( $self->debug ); }
      method error( Int $id, Int $errorCode, Any $errorMsg )

=cut

    method error( Str $str ) { warn $str if ( $self->debug ); }

      method error( Int $id, Int $errorCode, Any $errorMsg )
      { warn "ERROR: $id, EC: $errorCode, Msg: $errorMsg\n" }

=head2 connectionClosed
    - Called with the TWS connection is closed. 

=cut

      method connectionClosed() { warn "Connection Closed\n" }

=head2 tickPrice
    - Called when tickPrice changes

=cut

      method tickPrice( Int $tickerId, Int $field, Num $price,
        Int $canAutoExecute) {

        my $type   = $self->{tickType}->getField($field);
          my $time = Time::HiRes::Value->now();
          my $ae   = $canAutoExecute ? 'canAutoExecute' : 'NoAutoExecute';

          warn "TickPrice: $tickerId, $type: $price, $ae, $time \n"
          if ( $self->debug );

        }

=head2 tickSize
    - Called when tickSize changes

=cut

      method tickSize( Int $tickerId, Int $field, Int $size ) {

        my $type   = $self->{tickType}->getField($field);
          my $time = Time::HiRes::Value->now();

          warn "tickSize: $tickerId, Type: $type, Size: $size, Time: $time\n"
          if ( $self->debug );

      }

=head2 tickGeneric
    - Called when market data changes

=cut

      method tickGeneric( Int $tickerId, Int $tickType, Num $value ) {
        my $type = $self->{tickType}->getField($tickType);
          warn "tickGeneric: $tickerId, $tickType, $type, $value \n"
          if ( $self->debug );
      }

=head2 Other methods
    - See the Interactive Brokers API documentation at https://www.interactivebrokers.com/en/software/api/apiguide/java/java_ewrapper_methods.htm for other methods.

=cut

      method tickString( Int $tickerId, Int $tickType, Any $value ) {
        my $type = $self->{tickType}->getField($tickType);
          warn "tickString: $tickerId, $tickType, $type, $value \n"
          if ( $self->debug );

      }

      method tickSnapshotEnd( Int $tickerId) {
        warn "tickSnapshotEnd called with Ticker ID: $tickerId\n"
          if ( $self->debug );
      }

      method tickOptionComputation(
        Int $tickerId,
        Int $field,
        Num $impliedVol,
        Num $delta,
        Num $optPrice,
        Num $pvDividend,
        Num $gamma,
        Num $vega,
        Num $theta,
        Num $undPrice
      ) {

        my $fieldtype = $self->{tickType}->getField($field);
          warn
"tickOptionComputation:  ticker: $tickerId, field: $field, F: $fieldtype, IV: $impliedVol, Dt: $delta, OptPrice: $optPrice, pvDiv: $pvDividend, gamma: $gamma, vega: $vega, theta: $theta, undPrice: $undPrice \n"
          if ( $self->debug );

      }

      method tickEFP(
        Int $tickerId,
        Int $tickType,
        Num $basisPoints,
        Any $formattedBasisPoints,
        Num $impliedFuture,
        Int $holdDays,
        Any $futureExpiry,
        Num $dividendImpact,
        Num $dividendsToExpiry
      ) {
        my $type = $self->{tickType}->getField($tickType);
          warn
"EFP: $tickerId, $tickType, $type, $basisPoints, $formattedBasisPoints, $impliedFuture, $holdDays, $futureExpiry, $dividendImpact, $dividendsToExpiry \n"
          if ( $self->debug );

      }

      method orderStatus(
        Int $orderId,
        Any $status,
        Int $filled,
        Int $remaining,
        Num $avgFillPrice,
        Int $permId,
        Int $parentId,
        Num $lastFillPrice,
        Int $clientId,
        Any $whyHeld) {
        warn
"orderStatus: ID: $orderId, Stat: $status, Fill: $filled, Remain: $remaining, AvgFP: $avgFillPrice, PermID: $permId, ParentID: $parentId, LastFillPrice: $lastFillPrice, ClientID: $clientId, WhyHeld: $whyHeld\n"
          if ( $self->debug );

        }

      method openOrder(
        Int $orderId,
        Contract $contract,
        Order $order,
        OrderState $orderState
      ) {
        warn "openOrder: "
          . Dumper($orderId) . ' '
          . Dumper($contract) . ' '
          . Dumper($order) . ' '
          . Dumper($orderState) . "\n"
          if ( $self->debug );

      }

      method openOrderEnd() {}

      method updateAccountValue(
        Any $key, Any $value,
        Any $currency,
        Any $accountName
      ) {
        #$self->accountinfo({$accountName->{$key} = $value}});
        $self->set_accountinfo( ${key} => { $accountName => $value } );

          warn "Account Value: $key, $value, $currency, $accountName\n"
          if ( $self->debug );
      }

      method updatePortfolio(
        Contract $contract,
        Int $position,
        Num $marketPrice,
        Num $marketValue,
        Num $averageCost,
        Num $unrealizedPNL,
        Num $realizedPNL,
        Any $accountName
      ) {

        warn "updatePortfolio, "
          . $contract->{m_conId}
          . ", $position, $marketPrice, $marketValue, $averageCost, $unrealizedPNL, $realizedPNL, $accountName\n"
          if ( $self->debug );

          warn "Portfolio Contract info: "
          . $contract->{m_conId} . ", "
          . $contract->{m_symbol} . ", "
          . $contract->{m_secType} . ", "
          . $contract->{m_expiry} . ", "
          . $contract->{m_strike} . ", "
          . $contract->{m_right} . ", "
          . $contract->{m_multiplier} . ", "
          . $contract->{m_exchange} . ", "
          . $contract->{m_currency} . ", "
          . $contract->{m_localSymbol} . ", "
          . $contract->{m_primaryExch} . ", "
          . $contract->{m_includeExpired} . ", "
          . $contract->{m_secIdType} . ", "
          . $contract->{m_secId} . ", "
          . $contract->{m_comboLegsDescrip} . ", "
          . $contract->{m_underComp} . "\n\n"
          if ( $self->debug );

      }

      method updateAccountTime( Any $timeStamp )
      { warn "Timestamp: $timeStamp\n"; }

      method accountDownloadEnd( Any $accountName ) {
        warn "accountDownloadEnd called with account name $accountName\n"
          if ( $self->debug );

      }

      method contractDetails( Int $reqId, ContractDetails $contractDetails ) {

        #print Dumper($contractDetails);
        $self->add_contract($contractDetails)
          ;    # Add this contract to the ContractDetails array

          warn "contractDetails Request ID: $reqId, \n" if ( $self->debug );

          #store [\$contractDetails], 'some_file';
          warn "\nContract summary: m_conId: "
          . $contractDetails->{m_summary}->{m_conId}
          . " m_symbol: "
          . $contractDetails->{m_summary}->{m_symbol}
          . " m_secType: "
          . $contractDetails->{m_summary}->{m_secType}
          . " m_expiry: "
          . $contractDetails->{m_summary}->{m_expiry}
          . " m_strike: "
          . $contractDetails->{m_summary}->{m_strike}
          . " m_right: "
          . $contractDetails->{m_summary}->{m_right}
          . " m_multiplier: "
          . $contractDetails->{m_summary}->{m_multiplier}
          . " m_exchange: "
          . $contractDetails->{m_summary}->{m_exchange}
          . " m_currency: "
          . $contractDetails->{m_summary}->{m_currency}
          . " m_localSymbol: "
          . $contractDetails->{m_summary}->{m_localSymbol}
          . " m_primaryExch: "
          . $contractDetails->{m_summary}->{m_primaryExch}
          . " m_includeExpired: "
          . $contractDetails->{m_summary}->{m_includeExpired}
          . " m_secIdType: "
          . $contractDetails->{m_summary}->{m_secIdType}
          . " m_secId: "
          . $contractDetails->{m_summary}->{m_secId}
          . " m_comboLegsDescrip: "
          . $contractDetails->{m_summary}->{m_comboLegsDescrip}
          . " m_underComp: "
          . $contractDetails->{m_summary}->{m_underComp} . "\n"
          if ( $self->debug );

          warn "Contract Details:\n" if ( $self->debug );

          warn "m_summary: "
          . $contractDetails->{m_summary} . ", "
          . Dumper( $contractDetails->{m_summary} ) . ", "
          . "m_marketName: "
          . $contractDetails->{m_marketName} . ", "
          . "m_minTick: "
          . $contractDetails->{m_minTick} . ", "
          . "m_priceMagnifier: "
          . $contractDetails->{m_priceMagnifier} . ", "
          . "m_orderTypes: "
          . $contractDetails->{m_orderTypes} . ", "
          . "m_validExchanges: "
          . $contractDetails->{m_validExchanges} . ", "
          . "m_underConId: "
          . $contractDetails->{m_underConId} . ", "
          . "m_longName: "
          . $contractDetails->{m_longName} . ", "
          . "m_contractMonth: "
          . $contractDetails->{m_contractMonth} . ", "
          . "m_industry: "
          . $contractDetails->{m_industry} . ", "
          . "m_category: "
          . $contractDetails->{m_category} . ", "
          . "m_subcategory: "
          . $contractDetails->{m_subcategory} . ", "
          . "m_timeZoneId: "
          . $contractDetails->{m_timeZoneId} . ", "
          . "m_tradingHours: "
          . $contractDetails->{m_tradingHours} . ", "
          . "m_liquidHours: "
          . $contractDetails->{m_liquidHours} . ", "
          . "m_evRule: "
          . $contractDetails->{m_evRule} . ", "
          . "m_evMultiplier: "
          . $contractDetails->{m_evMultiplier} . ", "
          . "m_secIdList: "
          . $contractDetails->{m_secIdList} . ", "
          . "m_cusip: "
          . $contractDetails->{m_cusip} . ", "
          . "m_ratings: "
          . $contractDetails->{m_ratings} . ", "
          . "m_descAppend: "
          . $contractDetails->{m_descAppend} . ", "
          . "m_bondType: "
          . $contractDetails->{m_bondType} . ", "
          . "m_couponType: "
          . $contractDetails->{m_couponType} . ", "
          . "m_maturity: "
          . $contractDetails->{m_maturity} . ", "
          . "m_issueDate: "
          . $contractDetails->{m_issueDate} . ", "
          . "m_nextOptionDate: "
          . $contractDetails->{m_nextOptionDate} . ", "
          . "m_nextOptionType: "
          . $contractDetails->{m_nextOptionType} . ", "
          . "m_notes: "
          . $contractDetails->{m_notes} . "\n"
          if ( $self->debug );

      }

      method contractDetailsEnd( Int $reqId ) {
        $self->set_contractDetailsRequest(
            $reqId => { 'Status' => 'Complete' }
        );
          if ( $self->debug ) {

            my $d = Data::Dumper->new( [ $self->all_contracts ] );
            $d->Purity(1)->Terse(1)->Deepcopy(1);
            warn "Contract Details request complete for ID $reqId\n";
            warn "Contracts: " . $d->Dump;

            #warn "Sample contract details: "
            #. $self->get_contract(1)->{m_orderTypes} . "\n\n";
        }
      }

      method bondContractDetails( Int $reqId, ContractDetails $contractDetails )
      {}

      method execDetails( Int $reqId, Contract $contract, Execution $execution )
      {
        warn "execDetails: $reqId, $contract, $execution \n"
          if ( $self->debug );
          warn "Contract: " . Dumper($contract)   if ( $self->debug );
          warn "Execution: " . Dumper($execution) if ( $self->debug );

      }

      method execDetailsEnd( Int $reqId ) {}

      method updateMktDepth(
        Int $tickerId,
        Int $position,
        Int $operation,
        Int $side,
        Num $price,
        Int $size
      ) {

        my %op;
          my %s;
          $op{0} = 'Insert';
          $op{1} = 'Update';
          $op{2} = 'Delete';
          $s{0}  = 'Ask';
          $s{1}  = 'Bid';

          my $time = Time::HiRes::Value->now();

#print "Ticker: $tickerid, pos: $position Op: $op{$operation}, $s{$side}, $price, $size\n";
          warn
"ID: $tickerId,Pos: $position,Op: $op{$operation},Side: $s{$side},Price: $price,Size: $size, Time: $time\n"
          if ( $self->debug );
      }

      method updateMktDepthL2(
        Int $tickerId,
        Int $position,
        Any $marketMaker,
        Int $operation,
        Int $side,
        Num $price,
        Int $size
      ) {

        my %op;
          my %s;
          $op{0} = 'Insert';
          $op{1} = 'Update';
          $op{2} = 'Delete';
          $s{0}  = 'Ask';
          $s{1}  = 'Bid';

          my $time = Time::HiRes::Value->now();

          warn
"L2ID: $tickerId,Pos: $position,Op: $op{$operation},Side: $s{$side},Price: $price,Size: $size, Time: $time\n"
          if ( $self->debug );
      }

      method updateNewsBulletin( Int $msgId, Int $msgType, Any $message,
        Any $origExchange ) {}

      method managedAccounts( Any $accountsList ) {}

      method receiveFA( Int $faDataType, Any $xml ) {}

      method historicalData(
        Int $reqId,
        Any $date,
        Num $open,
        Num $high,
        Num $low,
        Num $close,
        Int $volume,
        Int $count,
        Num $WAP,
        boolean $hasGaps
      ) {
        warn
"ID: $reqId, Date: $date, O: $open, H: $high, L: $low, C: $close, V: $volume, Count: $count, WAP: $WAP, HasGaps: $hasGaps \n"
          if ( $self->debug );

      }

      method scannerParameters( Any $xml ) {
        warn $xml
          if ( $self->debug );
      }

      method commissionReport( Any $commissionreport ) {
        warn Dumper($commissionreport)
          if ( $self->debug );

      }

      method scannerData(
        Int $reqId, Int $rank,
        ContractDetails $contractDetails,
        Any $distance,
        Any $benchmark,
        Any $projection,
        Any $legsStr
      ) {}

      method scannerDataEnd( Int $reqId ) {}

      method realtimeBar(
        Int $reqId,
        long $time,
        Num $open,
        Num $high,
        Num $low,
        Num $close,
        long $volume,
        Num $wap,
        Int $count
      ) {
        warn
"RTB: $reqId, $time, $open, $high, $low, $close, $volume, $wap, $count\n"
          if ( $self->debug );

          return 1;

      }

      method currentTime( long $millis )
      { warn "CurrentTime: $millis\n" if ( $self->debug ); }

      method fundamentalData( Int $reqId, Any $data ) {}

      method deltaNeutralValidation( Int $reqId, UnderComp $underComp ) {}

      sub AUTOLOAD {    # catch all for other events
        my ( $self, @args ) = @_;
        our $AUTOLOAD;
        warn "$AUTOLOAD called with: ", join '^', @args, "\n"
          if ( $self->debug );
        return 0;
    }

}

=head1 AUTHOR

Doug Spencer, C<< <forhire99 at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-finance-ibrokers-moosecallback at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Finance-IBrokers-MooseCallback>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Finance::IBrokers::MooseCallback


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Finance-IBrokers-MooseCallback>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Finance-IBrokers-MooseCallback>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Finance-IBrokers-MooseCallback>

=item * Search CPAN

L<http://search.cpan.org/dist/Finance-IBrokers-MooseCallback/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2014 Doug Spencer.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1;    # End of Finance::IBrokers::MooseCallback
