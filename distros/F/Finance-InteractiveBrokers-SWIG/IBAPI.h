/*
 *  Finance::InteractiveBrokers::SWIG - IB API concrete class header
 *
 *  Copyright (c) 2010-2014 Jason McManus
 */

#ifndef IB_API_VERSION
# error IB_API_VERSION must be defined.
#endif

#ifndef IB_API_INTVER
# error IB_API_INTVER must be defined.
#endif

#ifndef IBAPI_H
#define IBAPI_H

// Some needed types
#include "Contract.h"
#include "Order.h"
#include "OrderState.h"
#include "Execution.h"
#include "ScannerSubscription.h"

#if IB_API_INTVER >= 967
#include "CommissionReport.h"
#endif

// Better patch for RT#94880: gcc >4.7 stopped including <unistd.h>
#include <unistd.h>
#include <ctime>

// Our base class, from the IB API
#include "EWrapper.h"

#include <iostream>
#include <memory>

class EPosixClientSocket;

enum State {
    ST_DISCONNECTED,
    ST_CONNECTING,
    ST_IDLE,
    ST_PING
/*
    ST_PLACEORDER,
    ST_PLACEORDER_ACK,
    ST_CANCELORDER,
    ST_CANCELORDER_ACK,
    ST_PING_ACK,
*/
};

class IBAPIClient : public EWrapper
{
public:
    // ctor, dtor
    IBAPIClient();
    ~IBAPIClient();

public:
    ////////////////////////////////////////////////////////////////////////
    // OUR EXTENSIONS

    // loop message-receiver function
    void processMessages();
    // set the select(2) timeout (integer)
    void setSelectTimeout(time_t timeout);
    // get the API version
    double version();
    // get an integral API version
    int version_int();
    // get the build time of this library
    int build_time();

public:
    ////////////////////////////////////////////////////////////////////////
    // METHODS

    // Connection and server
    bool eConnect( const char * host, unsigned int port, int clientId = 0 );
    void eDisconnect();
    bool isConnected();
    void reqCurrentTime();
    int serverVersion();
    void setServerLogLevel( int logLevel );
    void checkMessages();
    IBString TwsConnectionTime();

    // Market Data
    void reqMktData( TickerId id, const Contract &contract,
                     const IBString& genericTicks, bool snapshot );
    void cancelMktData( TickerId id );
    void calculateImpliedVolatility( TickerId reqId, const Contract &contract,
                                     double optionPrice, double underPrice );
    void cancelCalculateImpliedVolatility( TickerId reqId );
    void calculateOptionPrice( TickerId reqId, const Contract &contract,
                               double volatility, double underPrice );
    void cancelCalculateOptionPrice( TickerId reqId );

#if IB_API_INTVER >= 966
    void reqMarketDataType( int marketDataType );
#endif

    // Orders    
    void placeOrder( OrderId id, const Contract &contract, const Order &order );
    void cancelOrder( OrderId id );
    void reqOpenOrders();
    void reqAllOpenOrders();
    void reqAutoOpenOrders( bool bAutoBind );
    void reqIds( int numIds );
    void exerciseOptions( TickerId id, const Contract &contract,
                          int exerciseAction, int exerciseQuantity,
                          const IBString &account, int override );
#if IB_API_INTVER >= 966
    // UNDOCUMENTED
    void reqGlobalCancel();
#endif

    // Account
    void reqAccountUpdates( bool subscribe, const IBString& acctCode );

    // Executions
    void reqExecutions( int reqId, const ExecutionFilter& filter );

    // Contract Details
    void reqContractDetails( int reqId, const Contract &contract );

    // Market Depth
    void reqMktDepth( TickerId id, const Contract &contract, int numRows );
    void cancelMktDepth( TickerId id );

    // News Bulletins
    void reqNewsBulletins( bool allMsgs );
    void cancelNewsBulletins();

    // Financial Advisors
    void reqManagedAccts();
    void requestFA( faDataType pFaDataType );
    void replaceFA( faDataType pFaDataType, const IBString& cxml );

    // Historical Data
    void reqHistoricalData( TickerId id, const Contract &contract,
                            const IBString &endDateTime,
                            const IBString &durationStr,
                            const IBString &barSizeSetting,
                            const IBString &whatToShow, int useRTH,
                            int formatDate );
    void cancelHistoricalData( TickerId tickerId );

    // Market Scanners
    void reqScannerParameters();
    void reqScannerSubscription( int tickerId,
                                 const ScannerSubscription &subscription);
    void cancelScannerSubscription( int tickerId );

    // Real Time Bars
    void reqRealTimeBars( TickerId id, const Contract &contract, int barSize,
                          const IBString &whatToShow, bool useRTH );
    void cancelRealTimeBars( TickerId tickerId );

    // Fundamental Data
    void reqFundamentalData( TickerId reqId, const Contract& contract,
                             const IBString& reportType );
    void cancelFundamentalData( TickerId reqId );

public:
    ////////////////////////////////////////////////////////////////////////
    // EVENTS

    // meta-events
    void winError( const IBString &str, int lastError );
    void error( const int id, const int errorCode, const IBString errorString );
    void connectionClosed();
    void currentTime( long time );

    // Market Data events
    void tickPrice( TickerId tickerId, TickType field, double price,
                    int canAutoExecute );
    void tickSize( TickerId tickerId, TickType field, int size );
    void tickOptionComputation( TickerId tickerId, TickType tickType,
                                double impliedVol, double delta,
                                double optPrice, double pvDividend,
                                double gamma, double vega,
                                double theta, double undPrice );
    void tickGeneric( TickerId tickerId, TickType tickType, double value );
    void tickString( TickerId tickerId, TickType tickType,
                     const IBString& value );
    void tickEFP( TickerId tickerId, TickType tickType,
                  double basisPoints, const IBString& formattedBasisPoints,
                  double totalDividends, int holdDays,
                  const IBString& futureExpiry, double dividendImpact,
                  double dividendsToExpiry );
    void tickSnapshotEnd( int reqId );
#if IB_API_INTVER >= 966
    void marketDataType( TickerId reqId, int marketDataType );
#endif

    // Order events
    void orderStatus( OrderId orderId, const IBString& status,
                      int filled, int remaining, double avgFillPrice,
                      int permId, int parentId, double lastFillPrice,
                      int clientId, const IBString& whyHeld );
    void openOrder( OrderId orderId, const Contract& contract,
                    const Order& order, const OrderState& ostate );
    void openOrderEnd();

    // Account and Portfolio events
    void updateAccountValue( const IBString &key, const IBString& val,
                             const IBString& currency,
                             const IBString& accountName);
    void updatePortfolio( const Contract& contract, int position,
                          double marketPrice, double marketValue,
                          double averageCost, double unrealizedPNL,
                          double realizedPNL, const IBString& accountName );
    void updateAccountTime( const IBString& timeStamp );

    // News Bulletin events
    void updateNewsBulletin( int msgId, int msgType,
                             const IBString& newsMessage,
                             const IBString& originExch );

    // Contract Details events
    void contractDetails( int reqId, const ContractDetails& contractDetails );
    void bondContractDetails( int reqId,
                              const ContractDetails& contractDetails );
    void contractDetailsEnd( int reqId );

    // Execution events
    void execDetails( int reqId, const Contract& contract,
                      const Execution& execution );
    void execDetailsEnd( int reqId );
#if IB_API_INTVER >= 967
    void commissionReport( const CommissionReport &commissionReport );
#endif

    // Market Depth events
    void updateMktDepth( TickerId id, int position, int operation, int side,
                         double price, int size);
    void updateMktDepthL2( TickerId id, int position, IBString marketMaker,
                           int operation, int side, double price, int size );

    // Financial Advisors events
    void managedAccounts( const IBString& accountsList );
    void receiveFA( faDataType pFaDataType, const IBString& cxml );

    // Historical Data events
    void historicalData( TickerId reqId, const IBString& date,
                         double open, double high, double low, double close,
                         int volume, int barCount, double WAP, int hasGaps );

    // Market Scanners events
    void scannerParameters( const IBString &xml );
    void scannerData( int reqId, int rank,
                      const ContractDetails &contractDetails,
                      const IBString &distance, const IBString &benchmark,
                      const IBString &projection, const IBString &legsStr );
    void scannerDataEnd( int reqId );

    // Real Time bars events
    void realtimeBar( TickerId reqId, long time,
                      double open, double high, double low, double close,
                      long volume, double wap, int count );

    // Fundamental Data events
    void fundamentalData( TickerId reqId, const IBString& data );

    // Undocumented events
    void deltaNeutralValidation( int reqId, const UnderComp& underComp );
    void accountDownloadEnd( const IBString& accountName );
    void nextValidId( OrderId orderId );

private:
    // member variables
    std::auto_ptr<EPosixClientSocket> m_pClient;
    State m_state;
    time_t m_sleepDeadline;
    time_t m_selectTimeout;

    OrderId m_orderId;
};

#endif // ifdef IBAPI_H

/* END */
