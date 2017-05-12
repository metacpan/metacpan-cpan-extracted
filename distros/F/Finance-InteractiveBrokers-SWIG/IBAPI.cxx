/*
 *  Finance::InteractiveBrokers::SWIG - IB API concrete class implementation
 *
 *  Copyright (c) 2010-2014 Jason McManus
 */

#ifndef IB_API_VERSION
# error IB_API_VERSION must be defined.
#endif

#ifndef IB_API_INTVER
# error IB_API_INTVER must be defined.
#endif

// Include a default build time for this library, if not externally defined
#ifndef BUILD_TIME
#define BUILD_TIME 0
#endif

// Header for F::IB::SWIG embedding library
#include "ezembed.h"

// Headers for F::IB::SWIG concrete class declarations
#include "IBAPI.h"

// Headers for the IB API
#include "EWrapper.h"
#include "EPosixClientSocket.h"
#include "EPosixClientSocketPlatform.h"

// IB API data classes
#include "Contract.h"
#include "Order.h"
#include "OrderState.h"
#include "Execution.h"
#include "ScannerSubscription.h"

#if IB_API_INTVER >= 967
#include "CommissionReport.h"
#endif

const int PING_DEADLINE       = 5;  // seconds
const int SLEEP_BETWEEN_PINGS = 30; // seconds

///////////////////////////////////////////////////////////
// Constructor
// DONE
IBAPIClient::IBAPIClient()
    : m_pClient( new EPosixClientSocket(this) )
    , m_state(ST_DISCONNECTED)
    , m_sleepDeadline(0)
    , m_orderId(0)
    , m_selectTimeout(-1)
{
#ifdef DEBUG
    std::cout << "C++ constructor" << std::endl;
#endif
}

///////////////////////////////////////////////////////////
// Destructor
// DONE
IBAPIClient::~IBAPIClient()
{
#ifdef DEBUG
    std::cout << "C++ destructor" << std::endl;
#endif
}

///////////////////////////////////////////////////////////
// Our extensions

// get the API version
// DONE
double IBAPIClient::version()
{
    return IB_API_VERSION;
}

// get an integral API version
// DONE
int IBAPIClient::version_int()
{
    return IB_API_INTVER;
}

// get the build time for this library
// DONE
int IBAPIClient::build_time()
{
    return BUILD_TIME;
}

// Set select timeout
// DONE
void IBAPIClient::setSelectTimeout(time_t timeout)
{
    m_selectTimeout = timeout;
}

// Message processing loop
// DONE
void IBAPIClient::processMessages()
{
    fd_set readSet, writeSet, errorSet;

    struct timeval tval;
    tval.tv_usec = 0;
    tval.tv_sec = 0;

    time_t now = time(NULL);

    switch( m_state ) {
        case ST_PING:
            if( m_sleepDeadline < now ) {
                std::cerr << "Warning: Server ping timeout" << std::endl;
                eDisconnect();
                return;
            }
            break;
        case ST_IDLE:
            if( m_sleepDeadline < now ) {
                m_state = ST_PING;
                reqCurrentTime();
                // keep going and process this outgoing ping
                //return;
            }
            break;
        default:
            ;
    }

    // initialize select() timeout with m_sleepDeadline - now
    if( m_sleepDeadline > 0 )
    {
        if( m_selectTimeout >= 0 )
            tval.tv_sec = m_selectTimeout;
        else
            tval.tv_sec = m_sleepDeadline - now;
    }

    if( m_pClient->fd() >= 0 )
    {
        FD_ZERO( &readSet );
        errorSet = writeSet = readSet;

        FD_SET( m_pClient->fd(), &readSet );

        if( !m_pClient->isOutBufferEmpty() )
            FD_SET( m_pClient->fd(), &writeSet );

        FD_CLR( m_pClient->fd(), &errorSet );

        errno = 0;      // bug fix: RT:88097
        int ret = select( m_pClient->fd() + 1,
                          &readSet, &writeSet, &errorSet, &tval );

        if( ret == 0 ) { // timeout
            return;
        }

        if( ret < 0 ) {    // error
            eDisconnect();
            return;
        }

        if( m_pClient->fd() < 0 )
            return;

        if( FD_ISSET( m_pClient->fd(), &errorSet ) ) {
            // error on socket
            m_pClient->onError();
        }

        if( m_pClient->fd() < 0 )
            return;

        if( FD_ISSET( m_pClient->fd(), &writeSet ) ) {
            // socket is ready for writing
            m_pClient->onSend();
        }

        if( m_pClient->fd() < 0 )
            return;

        if( FD_ISSET( m_pClient->fd(), &readSet ) ) {
            // socket is ready for reading
            m_pClient->onReceive();
        }
    }
}

//////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////

///////////////////////////////////////////////
// Connection and Server

// DONE
bool IBAPIClient::eConnect( const char *host, unsigned int port, int clientId )
{
    bool connectOk = false;

#ifdef DEBUG
    std::cout << "C++ eConnect()" << std::endl;
#endif
    m_state = ST_CONNECTING;
    connectOk = m_pClient->eConnect( host, port, clientId );
    if( connectOk )
        m_state = ST_IDLE;
    else
        m_state = ST_DISCONNECTED;

    return connectOk;
}

// DONE
void IBAPIClient::eDisconnect()
{
#ifdef DEBUG
    std::cout << "C++ eDisconnect()" << std::endl;
#endif
    m_pClient->eDisconnect();
    m_state = ST_DISCONNECTED;
}

// DONE
bool IBAPIClient::isConnected()
{
#ifdef DEBUG
    std::cout << "C++ isConnected()" << std::endl;
#endif
    return m_pClient->isConnected();
}

// DONE
void IBAPIClient::reqCurrentTime()
{
#ifdef DEBUG
    std::cout << "C++ reqCurrentTime()" << std::endl;
#endif
    // reset ping deadline to "now + n seconds"
    m_sleepDeadline = time( NULL) + PING_DEADLINE;

    m_pClient->reqCurrentTime();
}

// DONE
int IBAPIClient::serverVersion()
{
#ifdef DEBUG
    std::cout << "C++ reqCurrentTime()" << std::endl;
#endif
    return m_pClient->serverVersion();
}

// DONE
void IBAPIClient::setServerLogLevel( int logLevel )
{
#ifdef DEBUG
    std::cout << "C++ setServerLogLevel()" << std::endl;
#endif
    m_pClient->setServerLogLevel( logLevel );
}

// DONE
void IBAPIClient::checkMessages()
{
#ifdef DEBUG
    std::cout << "C++ checkMessages()" << std::endl;
#endif
    std::cerr << "Warning: Use processMessages() instead." << std::endl;
    processMessages();
}

// DONE
IBString IBAPIClient::TwsConnectionTime()
{
#ifdef DEBUG
    std::cout << "C++ TwsConnectionTime()" << std::endl;
#endif
    return m_pClient->TwsConnectionTime();
}


///////////////////////////////////////////////
// Market Data

// DONE
void IBAPIClient::reqMktData( TickerId id, const Contract &contract,
                              const IBString& genericTicks, bool snapshot )
{
#ifdef DEBUG
    std::cout << "C++ reqMktData()" << std::endl;
#endif
    m_pClient->reqMktData( id, contract, genericTicks, snapshot );
}

// DONE
void IBAPIClient::cancelMktData( TickerId id )
{
#ifdef DEBUG
    std::cout << "C++ cancelMktData()" << std::endl;
#endif
    m_pClient->cancelMktData( id );
}

// DONE
void IBAPIClient::calculateImpliedVolatility( TickerId reqId,
                                              const Contract &contract,
                                              double optionPrice,
                                              double underPrice )
{
#ifdef DEBUG
    std::cout << "C++ calculateImpliedVolatility()" << std::endl;
#endif
    m_pClient->calculateImpliedVolatility( reqId, contract,
                                           optionPrice, underPrice );
}

// DONE
void IBAPIClient::cancelCalculateImpliedVolatility( TickerId reqId )
{
#ifdef DEBUG
    std::cout << "C++ cancelCalculateImpliedVolatility()" << std::endl;
#endif
    m_pClient->cancelCalculateImpliedVolatility( reqId );
}

#if IB_API_INTVER >= 966
// DONE
void IBAPIClient::reqMarketDataType( int marketDataType )
{
#ifdef DEBUG
    std::cout << "C++ reqMarketDataType()" << std::endl;
#endif
    m_pClient->reqMarketDataType( marketDataType );
}
#endif


// DONE
void IBAPIClient::calculateOptionPrice( TickerId reqId,
                                        const Contract &contract,
                                        double volatility,
                                        double underPrice )
{
#ifdef DEBUG
    std::cout << "C++ calculateOptionPrice()" << std::endl;
#endif
    m_pClient->calculateOptionPrice( reqId, contract, volatility, underPrice );
}

// DONE
void IBAPIClient::cancelCalculateOptionPrice( TickerId reqId )
{
#ifdef DEBUG
    std::cout << "C++ cancelCalculateOptionPrice()" << std::endl;
#endif
    m_pClient->cancelCalculateOptionPrice( reqId );
}


///////////////////////////////////////////////
// Orders

// DONE
void IBAPIClient::placeOrder( OrderId id, const Contract &contract,
                              const Order &order )
{
#ifdef DEBUG
    std::cout << "C++ placeOrder()" << std::endl;
#endif
    m_pClient->placeOrder( id, contract, order );
}

// DONE
void IBAPIClient::cancelOrder( OrderId id )
{
#ifdef DEBUG
    std::cout << "C++ cancelOrder()" << std::endl;
#endif
    m_pClient->cancelOrder( id );
}

// DONE
void IBAPIClient::reqOpenOrders()
{
#ifdef DEBUG
    std::cout << "C++ reqOpenOrders()" << std::endl;
#endif
    m_pClient->reqOpenOrders();
}

// DONE
void IBAPIClient::reqAllOpenOrders()
{
#ifdef DEBUG
    std::cout << "C++ reqAllOpenOrders()" << std::endl;
#endif
    m_pClient->reqAllOpenOrders();

}

// DONE
void IBAPIClient::reqAutoOpenOrders( bool bAutoBind )
{
#ifdef DEBUG
    std::cout << "C++ reqAutoOpenOrders()" << std::endl;
#endif
    m_pClient->reqAutoOpenOrders( bAutoBind );
}

// DONE
void IBAPIClient::reqIds( int numIds )
{
#ifdef DEBUG
    std::cout << "C++ reqIds()" << std::endl;
#endif
    m_pClient->reqIds( numIds );
}

// DONE
void IBAPIClient::exerciseOptions( TickerId id, const Contract &contract,
                                   int exerciseAction, int exerciseQuantity,
                                   const IBString &account, int override )
{
#ifdef DEBUG
    std::cout << "C++ exerciseOptions()" << std::endl;
#endif
    m_pClient->exerciseOptions( id, contract,
                                exerciseAction, exerciseQuantity,
                                account, override );
}

#if IB_API_INTVER >= 966
// UNDOCUMENTED
void IBAPIClient::reqGlobalCancel()
{
#ifdef DEBUG
    std::cout << "C++ reqGlobalCancel()" << std::endl;
#endif
    m_pClient->reqGlobalCancel();
}
#endif


///////////////////////////////////////////////
// Account

// DONE
void IBAPIClient::reqAccountUpdates( bool subscribe, const IBString& acctCode )
{
#ifdef DEBUG
    std::cout << "C++ reqAccountUpdates()" << std::endl;
#endif
    m_pClient->reqAccountUpdates( subscribe, acctCode );
}


///////////////////////////////////////////////
// Executions

// DONE
void IBAPIClient::reqExecutions( int reqId, const ExecutionFilter& filter )
{
#ifdef DEBUG
    std::cout << "C++ reqExecutions()" << std::endl;
#endif
    m_pClient->reqExecutions( reqId, filter );
}


///////////////////////////////////////////////
// Contract Details

// DONE
void IBAPIClient::reqContractDetails( int reqId, const Contract &contract )
{
#ifdef DEBUG
    std::cout << "C++ reqContractDetails()" << std::endl;
#endif
    m_pClient->reqContractDetails( reqId, contract );
}


///////////////////////////////////////////////
// Market Depth

// DONE
void IBAPIClient::reqMktDepth( TickerId id, const Contract &contract,
                               int numRows )
{
#ifdef DEBUG
    std::cout << "C++ reqMktDepth()" << std::endl;
#endif
    m_pClient->reqMktDepth( id, contract, numRows );
}

// DONE
void IBAPIClient::cancelMktDepth( TickerId id )
{
#ifdef DEBUG
    std::cout << "C++ cancelMktDepth()" << std::endl;
#endif
    m_pClient->cancelMktDepth( id );
}


///////////////////////////////////////////////
// News Bulletins

// DONE
void IBAPIClient::reqNewsBulletins( bool allMsgs )
{
#ifdef DEBUG
    std::cout << "C++ reqNewsBulletins()" << std::endl;
#endif
    m_pClient->reqNewsBulletins( allMsgs );
}

// DONE
void IBAPIClient::cancelNewsBulletins()
{
#ifdef DEBUG
    std::cout << "C++ cancelNewsBulletins()" << std::endl;
#endif
    m_pClient->cancelNewsBulletins();
}


///////////////////////////////////////////////
// Financial Advisors

// DONE
void IBAPIClient::reqManagedAccts()
{
#ifdef DEBUG
    std::cout << "C++ reqManagedAccts()" << std::endl;
#endif
    m_pClient->reqManagedAccts();
}

// DONE
void IBAPIClient::requestFA( faDataType pFaDataType )
{
#ifdef DEBUG
    std::cout << "C++ requestFA()" << std::endl;
#endif
    m_pClient->requestFA( pFaDataType );
}

// DONE
void IBAPIClient::replaceFA( faDataType pFaDataType, const IBString& cxml )
{
#ifdef DEBUG
    std::cout << "C++ replaceFA()" << std::endl;
#endif
    m_pClient->replaceFA( pFaDataType, cxml );
}


///////////////////////////////////////////////
// Historical Data

// DONE
void IBAPIClient::reqHistoricalData( TickerId id, const Contract &contract,
                                     const IBString &endDateTime,
                                     const IBString &durationStr,
                                     const IBString &barSizeSetting,
                                     const IBString &whatToShow,
                                     int useRTH, int formatDate )
{
#ifdef DEBUG
    std::cout << "C++ reqHistoricalData()" << std::endl;
#endif
    m_pClient->reqHistoricalData( id, contract,
                                  endDateTime, durationStr,
                                  barSizeSetting, whatToShow,
                                  useRTH, formatDate );
}

// DONE
void IBAPIClient::cancelHistoricalData( TickerId tickerId )
{
#ifdef DEBUG
    std::cout << "C++ cancelHistoricalData()" << std::endl;
#endif
    m_pClient->cancelHistoricalData( tickerId );
}


///////////////////////////////////////////////
// Market Scanners

// DONE
void IBAPIClient::reqScannerParameters()
{
#ifdef DEBUG
    std::cout << "C++ reqScannerParameters()" << std::endl;
#endif
    m_pClient->reqScannerParameters();
}

// DONE
void IBAPIClient::reqScannerSubscription( int tickerId,
                                     const ScannerSubscription &subscription )
{
#ifdef DEBUG
    std::cout << "C++ reqScannerSubscription()" << std::endl;
#endif
    m_pClient->reqScannerSubscription( tickerId, subscription );
}

// DONE
void IBAPIClient::cancelScannerSubscription( int tickerId )
{
#ifdef DEBUG
    std::cout << "C++ cancelScannerSubscription()" << std::endl;
#endif
    m_pClient->cancelScannerSubscription( tickerId );
}


///////////////////////////////////////////////
// Real Time Bars

// DONE
void IBAPIClient::reqRealTimeBars( TickerId id, const Contract &contract,
                                   int barSize, const IBString &whatToShow,
                                   bool useRTH )
{
#ifdef DEBUG
    std::cout << "C++ reqRealTimeBars()" << std::endl;
#endif
    m_pClient->reqRealTimeBars( id, contract, barSize, whatToShow, useRTH );
}

// DONE
void IBAPIClient::cancelRealTimeBars( TickerId tickerId )
{
#ifdef DEBUG
    std::cout << "C++ cancelRealTimeBars()" << std::endl;
#endif
    m_pClient->cancelRealTimeBars( tickerId );
}


///////////////////////////////////////////////
// Fundamental Data

// DONE
void IBAPIClient::reqFundamentalData( TickerId reqId, const Contract& contract,
                                      const IBString& reportType )
{
#ifdef DEBUG
    std::cout << "C++ reqFundamentalData()" << std::endl;
#endif
    m_pClient->reqFundamentalData( reqId, contract, reportType );
}

// DONE
void IBAPIClient::cancelFundamentalData( TickerId reqId )
{
#ifdef DEBUG
    std::cout << "C++ cancelFundamentalData()" << std::endl;
#endif
    m_pClient->cancelFundamentalData( reqId );
}


///////////////////////////////////////////////////////////////////
// Event handler callbacks
///////////////////////////////////////////////////////////////////

///////////////////////////////////////////////
// Connection and Server

// DONE
void IBAPIClient::winError( const IBString &str, int lastError )
{
#ifdef DEBUG
    std::cout << "C++ winError()" << std::endl;
#endif
    perl_call_va( "Finance::InteractiveBrokers::SWIG::_event_dispatcher",
                  "s", "winError",
                  "s", str.c_str(),
                  "i", lastError,
                  NULL );
}

// DONE
void IBAPIClient::error( const int id, const int errorCode,
                         const IBString errorString )
{
#ifdef DEBUG
    std::cout << "C++ error()" << std::endl;
#endif

    perl_call_va( "Finance::InteractiveBrokers::SWIG::_event_dispatcher",
                  "s", "error",
                  "i", id,
                  "i", errorCode,
                  "s", errorString.c_str(),
                  NULL );

    // Connectivity between IB and TWS has been lost
    if( id == -1 && errorCode == 1100 )
        eDisconnect();
}

// DONE
void IBAPIClient::connectionClosed()
{
#ifdef DEBUG
    std::cout << "C++ connectionClosed()" << std::endl;
#endif
    perl_call_va( "Finance::InteractiveBrokers::SWIG::_event_dispatcher",
                  "s", "connectionClosed",
                  NULL );
}

// DONE
void IBAPIClient::currentTime( long time )
{
#ifdef DEBUG
    std::cout << "C++ currentTime()" << std::endl;
#endif
    if ( m_state == ST_PING ) {
        // hidden ping communication; don't bother Perl

        // Reset the sleep deadline; ignore what we received, set from local
        time_t now = ::time(NULL);
        m_sleepDeadline = now + SLEEP_BETWEEN_PINGS;
        m_state = ST_IDLE;
    }
    else
    {
        // Not a hidden ping response; pass off to perl
        perl_call_va( "Finance::InteractiveBrokers::SWIG::_event_dispatcher",
                      "s", "currentTime",
                      "i", time,
                      NULL );
    }
}


///////////////////////////////////////////////
// Market Data

// DONE
void IBAPIClient::tickPrice( TickerId tickerId, TickType field,
                             double price, int canAutoExecute)
{
#ifdef DEBUG
    std::cout << "C++ tickPrice()" << std::endl;
#endif
    perl_call_va( "Finance::InteractiveBrokers::SWIG::_event_dispatcher",
                  "s", "tickPrice",
                  "i", tickerId,
                  "i", field,
                  "f", price,
                  "i", canAutoExecute,
                  NULL );
}

// DONE
void IBAPIClient::tickSize( TickerId tickerId, TickType field, int size )
{
#ifdef DEBUG
    std::cout << "C++ tickPrice()" << std::endl;
#endif
    perl_call_va( "Finance::InteractiveBrokers::SWIG::_event_dispatcher",
                  "s", "tickSize",
                  "i", tickerId,
                  "i", field,
                  "i", size,
                  NULL );
}

// DONE
void IBAPIClient::tickOptionComputation( TickerId tickerId, TickType tickType,
                                         double impliedVol, double delta,
                                         double optPrice, double pvDividend,
                                         double gamma, double vega,
                                         double theta, double undPrice )
{
#ifdef DEBUG
    std::cout << "C++ tickOptionComputation()" << std::endl;
#endif
    perl_call_va( "Finance::InteractiveBrokers::SWIG::_event_dispatcher",
                  "s", "tickOptionComputation",
                  "i", tickerId,
                  "i", tickType,
                  "f", impliedVol,
                  "f", delta,
                  "f", optPrice,
                  "f", pvDividend,
                  "f", gamma,
                  "f", vega,
                  "f", theta,
                  "f", undPrice,
                  NULL );
}

// DONE
void IBAPIClient::tickGeneric( TickerId tickerId, TickType tickType,
                               double value )
{
#ifdef DEBUG
    std::cout << "C++ tickGeneric()" << std::endl;
#endif
    perl_call_va( "Finance::InteractiveBrokers::SWIG::_event_dispatcher",
                  "s", "tickGeneric",
                  "i", tickerId,
                  "i", tickType,
                  "f", value,
                  NULL );
}

// DONE
void IBAPIClient::tickString( TickerId tickerId, TickType tickType,
                              const IBString& value )
{
#ifdef DEBUG
    std::cout << "C++ tickString()" << std::endl;
#endif
    perl_call_va( "Finance::InteractiveBrokers::SWIG::_event_dispatcher",
                  "s", "tickString",
                  "i", tickerId,
                  "i", tickType,
                  "s", value.c_str(),
                  NULL );
}

// DONE
void IBAPIClient::tickEFP( TickerId tickerId, TickType tickType,
                           double basisPoints,
                           const IBString& formattedBasisPoints,
                           double totalDividends, int holdDays,
                           const IBString& futureExpiry,
                           double dividendImpact, double dividendsToExpiry )
{
#ifdef DEBUG
    std::cout << "C++ tickEFP()" << std::endl;
#endif
    perl_call_va( "Finance::InteractiveBrokers::SWIG::_event_dispatcher",
                  "s", "tickEFP",
                  "i", tickerId,
                  "i", tickType,
                  "f", basisPoints,
                  "s", formattedBasisPoints.c_str(),
                  "f", totalDividends,
                  "i", holdDays,
                  "s", futureExpiry.c_str(),
                  "f", dividendImpact,
                  "f", dividendsToExpiry,
                  NULL );
}

// DONE
void IBAPIClient::tickSnapshotEnd( int reqId )
{
#ifdef DEBUG
    std::cout << "C++ tickPrice()" << std::endl;
#endif
    perl_call_va( "Finance::InteractiveBrokers::SWIG::_event_dispatcher",
                  "s", "tickSnapshotEnd",
                  "i", reqId,
                  NULL );
}

#if IB_API_INTVER >= 966
// DONE
void IBAPIClient::marketDataType( TickerId reqId, int marketDataType )
{
#ifdef DEBUG
    std::cout << "C++ marketDataType()" << std::endl;
#endif
    perl_call_va( "Finance::InteractiveBrokers::SWIG::_event_dispatcher",
                  "s", "marketDataType",
                  "i", reqId,
                  "i", marketDataType,
                  NULL );
}
#endif


///////////////////////////////////////////////
// Orders

// DONE
void IBAPIClient::orderStatus( OrderId orderId, const IBString &status,
                               int filled, int remaining, double avgFillPrice,
                               int permId, int parentId, double lastFillPrice,
                               int clientId, const IBString& whyHeld )
{
#ifdef DEBUG
    std::cout << "C++ orderStatus()" << std::endl;
#endif
    perl_call_va( "Finance::InteractiveBrokers::SWIG::_event_dispatcher",
                  "s", "orderStatus",
                  "i", orderId,
                  "s", status.c_str(),
                  "i", filled,
                  "i", remaining,
                  "f", avgFillPrice,
                  "i", permId,
                  "i", parentId,
                  "f", lastFillPrice,
                  "i", clientId,
                  "s", whyHeld.c_str(),
                  NULL );
}

// DONE
void IBAPIClient::openOrder( OrderId orderId, const Contract& contract,
                             const Order& order, const OrderState& ostate )
{
#ifdef DEBUG
    std::cout << "C++ openOrder()" << std::endl;
#endif
    perl_call_va( "Finance::InteractiveBrokers::SWIG::_event_dispatcher",
                  "s", "openOrder",
                  "i", orderId,
                  "c", &contract,
                  "o", &order,
                  "r", &ostate,
                  NULL );
}

// DONE
void IBAPIClient::nextValidId( OrderId orderId )
{
#ifdef DEBUG
    std::cout << "C++ nextValidId()" << std::endl;
#endif
    perl_call_va( "Finance::InteractiveBrokers::SWIG::_event_dispatcher",
                  "s", "nextValidId",
                  "i", orderId,
                  NULL );
}


///////////////////////////////////////////////
// Account and Portfolio

// DONE
void IBAPIClient::updateAccountValue( const IBString& key, const IBString& val,
                                      const IBString& currency,
                                      const IBString& accountName )
{
#ifdef DEBUG
    std::cout << "C++ updateAccountValue()" << std::endl;
#endif
    perl_call_va( "Finance::InteractiveBrokers::SWIG::_event_dispatcher",
                  "s", "updateAccountValue",
                  "s", key.c_str(),
                  "s", val.c_str(),
                  "s", currency.c_str(),
                  "s", accountName.c_str(),
                  NULL );
}

// DONE
void IBAPIClient::updatePortfolio( const Contract& contract, int position,
                                   double marketPrice, double marketValue,
                                   double averageCost, double unrealizedPNL,
                                   double realizedPNL,
                                   const IBString& accountName )
{
#ifdef DEBUG
    std::cout << "C++ updatePortfolio()" << std::endl;
#endif
    perl_call_va( "Finance::InteractiveBrokers::SWIG::_event_dispatcher",
                  "s", "updatePortfolio",
                  "c", &contract,
                  "i", position,
                  "f", marketPrice,
                  "f", marketValue,
                  "f", averageCost,
                  "f", unrealizedPNL,
                  "f", realizedPNL,
                  "s", accountName.c_str(),
                  NULL );
}

// DONE
void IBAPIClient::updateAccountTime( const IBString& timeStamp )
{
#ifdef DEBUG
    std::cout << "C++ updatePortfolio()" << std::endl;
#endif
    perl_call_va( "Finance::InteractiveBrokers::SWIG::_event_dispatcher",
                  "s", "updateAccountTime",
                  "s", timeStamp.c_str(),
                  NULL );
}


///////////////////////////////////////////////
// News Bulletins

// DONE
void IBAPIClient::updateNewsBulletin( int msgId, int msgType,
                                      const IBString& newsMessage,
                                      const IBString& originExch )
{
#ifdef DEBUG
    std::cout << "C++ updateNewsBulletin()" << std::endl;
#endif
    perl_call_va( "Finance::InteractiveBrokers::SWIG::_event_dispatcher",
                  "s", "updateNewsBulletin",
                  "i", msgId,
                  "i", msgType,
                  "s", newsMessage.c_str(),
                  "s", originExch.c_str(),
                  NULL );
}


///////////////////////////////////////////////
// Contract Details

// DONE
void IBAPIClient::contractDetails( int reqId,
                                   const ContractDetails& contractDetails )
{
#ifdef DEBUG
    std::cout << "C++ contractDetails()" << std::endl;
#endif
    perl_call_va( "Finance::InteractiveBrokers::SWIG::_event_dispatcher",
                  "s", "contractDetails",
                  "i", reqId,
                  "d", &contractDetails,
                  NULL );
}

// DONE
void IBAPIClient::contractDetailsEnd( int reqId )
{
#ifdef DEBUG
    std::cout << "C++ contractDetailsEnd()" << std::endl;
#endif
    perl_call_va( "Finance::InteractiveBrokers::SWIG::_event_dispatcher",
                  "s", "contractDetailsEnd",
                  "i", reqId,
                  NULL );
}

// DONE
void IBAPIClient::bondContractDetails( int reqId,
                                       const ContractDetails& contractDetails )
{
#ifdef DEBUG
    std::cout << "C++ bondContractDetails()" << std::endl;
#endif
    perl_call_va( "Finance::InteractiveBrokers::SWIG::_event_dispatcher",
                  "s", "bondContractDetails",
                  "i", reqId,
                  "d", &contractDetails,
                  NULL );
}


///////////////////////////////////////////////
// Executions

// DONE
void IBAPIClient::execDetails( int reqId, const Contract& contract,
                               const Execution& execution )
{
#ifdef DEBUG
    std::cout << "C++ execDetails()" << std::endl;
#endif
    perl_call_va( "Finance::InteractiveBrokers::SWIG::_event_dispatcher",
                  "s", "execDetails",
                  "i", reqId,
                  "c", &contract,
                  "x", &execution,
                  NULL );
}

// DONE
void IBAPIClient::execDetailsEnd( int reqId )
{
#ifdef DEBUG
    std::cout << "C++ execDetailsEnd()" << std::endl;
#endif
    perl_call_va( "Finance::InteractiveBrokers::SWIG::_event_dispatcher",
                  "s", "execDetailsEnd",
                  "i", reqId,
                  NULL );
}

#if IB_API_INTVER >= 967
// DONE
void IBAPIClient::commissionReport( const CommissionReport &commissionReport )
{
#ifdef DEBUG
    std::cout << "C++ commissionReport()" << std::endl;
#endif
    perl_call_va( "Finance::InteractiveBrokers::SWIG::_event_dispatcher",
                  "s", "commissionReport",
                  "m", &commissionReport,
                  NULL );
}
#endif


///////////////////////////////////////////////
// Market Depth

// DONE
void IBAPIClient::updateMktDepth( TickerId id, int position, int operation,
                                  int side, double price, int size )
{
#ifdef DEBUG
    std::cout << "C++ updateMktDepth()" << std::endl;
#endif
    perl_call_va( "Finance::InteractiveBrokers::SWIG::_event_dispatcher",
                  "s", "updateMktDepth",
                  "i", position,
                  "i", operation,
                  "i", side,
                  "f", price,
                  "i", size,
                  NULL );
}

// DONE
void IBAPIClient::updateMktDepthL2( TickerId id, int position,
                                    IBString marketMaker, int operation,
                                    int side, double price, int size )
{
#ifdef DEBUG
    std::cout << "C++ updateMktDepthL2()" << std::endl;
#endif
    perl_call_va( "Finance::InteractiveBrokers::SWIG::_event_dispatcher",
                  "s", "updateMktDepthL2",
                  "i", id,
                  "i", position,
                  "s", marketMaker.c_str(),
                  "i", operation,
                  "i", side,
                  "f", price,
                  "i", size,
                  NULL );
}


///////////////////////////////////////////////
// Financial Advisors

// DONE
void IBAPIClient::managedAccounts( const IBString& accountsList )
{
#ifdef DEBUG
    std::cout << "C++ managedAccounts()" << std::endl;
#endif
    perl_call_va( "Finance::InteractiveBrokers::SWIG::_event_dispatcher",
                  "s", "managedAccounts",
                  "s", accountsList.c_str(),
                  NULL );
}

// DONE
void IBAPIClient::receiveFA( faDataType pFaDataType, const IBString& cxml )
{
#ifdef DEBUG
    std::cout << "C++ receiveFA()" << std::endl;
#endif
    perl_call_va( "Finance::InteractiveBrokers::SWIG::_event_dispatcher",
                  "s", "receiveFA",
                  "i", pFaDataType,
                  "s", cxml.c_str(),
                  NULL );
}


///////////////////////////////////////////////
// Historical Data

// DONE
void IBAPIClient::historicalData( TickerId reqId, const IBString& date,
                                  double open, double high, double low,
                                  double close, int volume, int barCount,
                                  double WAP, int hasGaps )
{
#ifdef DEBUG
    std::cout << "C++ historicalData()" << std::endl;
#endif
    perl_call_va( "Finance::InteractiveBrokers::SWIG::_event_dispatcher",
                  "s", "historicalData",
                  "i", reqId,
                  "s", date.c_str(),
                  "f", open,
                  "f", high,
                  "f", low,
                  "f", close,
                  "i", volume,
                  "i", barCount,
                  "f", WAP,
                  "i", hasGaps,
                  NULL );
}


///////////////////////////////////////////////
// Market Scanners

// DONE
void IBAPIClient::scannerParameters( const IBString &xml )
{
#ifdef DEBUG
    std::cout << "C++ scannerParameters()" << std::endl;
#endif
    perl_call_va( "Finance::InteractiveBrokers::SWIG::_event_dispatcher",
                  "s", "scannerParameters",
                  "s", xml.c_str(),
                  NULL );
}

// DONE
void IBAPIClient::scannerData( int reqId, int rank,
                               const ContractDetails &contractDetails,
                               const IBString &distance,
                               const IBString &benchmark,
                               const IBString &projection,
                               const IBString &legsStr )
{
#ifdef DEBUG
    std::cout << "C++ scannerData()" << std::endl;
#endif
    perl_call_va( "Finance::InteractiveBrokers::SWIG::_event_dispatcher",
                  "s", "scannerData",
                  "i", reqId,
                  "i", rank,
                  "d", &contractDetails,
                  "s", distance.c_str(),
                  "s", benchmark.c_str(),
                  "s", projection.c_str(),
                  "s", legsStr.c_str(),
                  NULL );
}

// DONE
void IBAPIClient::scannerDataEnd( int reqId )
{
#ifdef DEBUG
    std::cout << "C++ scannerDataEnd()" << std::endl;
#endif
    perl_call_va( "Finance::InteractiveBrokers::SWIG::_event_dispatcher",
                  "s", "scannerDataEnd",
                  "i", reqId,
                  NULL );
}


///////////////////////////////////////////////
// Real Time Bars

// DONE
void IBAPIClient::realtimeBar( TickerId reqId, long time, double open,
                               double high, double low, double close,
                               long volume, double wap, int count )
{
#ifdef DEBUG
    std::cout << "C++ realtimeBar()" << std::endl;
#endif
    perl_call_va( "Finance::InteractiveBrokers::SWIG::_event_dispatcher",
                  "s", "realtimeBar",
                  "i", reqId,
                  "i", time,
                  "f", open,
                  "f", high,
                  "f", low,
                  "f", close,
                  "i", volume,
                  "f", wap,
                  "i", count,
                  NULL );
}


///////////////////////////////////////////////
// Fundamental Data

// DONE
void IBAPIClient::fundamentalData( TickerId reqId, const IBString& data )
{
#ifdef DEBUG
    std::cout << "C++ fundamentalData()" << std::endl;
#endif
    perl_call_va( "Finance::InteractiveBrokers::SWIG::_event_dispatcher",
                  "s", "fundamentalData",
                  "i", reqId,
                  "s", data.c_str(),
                  NULL );
}


///////////////////////////////////////////////
// Undocumented

// DONE
void IBAPIClient::deltaNeutralValidation( int reqId,
                                          const UnderComp& underComp )
{
#ifdef DEBUG
    std::cout << "C++ deltaNeutralValidation()" << std::endl;
#endif
    perl_call_va( "Finance::InteractiveBrokers::SWIG::_event_dispatcher",
                  "s", "deltaNeutralValidation",
                  "i", reqId,
                  "u", &underComp,
                  NULL );
}

// DONE
void IBAPIClient::openOrderEnd()
{
#ifdef DEBUG
    std::cout << "C++ openOrderEnd()" << std::endl;
#endif
    perl_call_va( "Finance::InteractiveBrokers::SWIG::_event_dispatcher",
                  "s", "openOrderEnd",
                  NULL );
}

// DONE
void IBAPIClient::accountDownloadEnd( const IBString& accountName )
{
#ifdef DEBUG
    std::cout << "C++ accountDownloadEnd()" << std::endl;
#endif
    perl_call_va( "Finance::InteractiveBrokers::SWIG::_event_dispatcher",
                  "s", "accountDownloadEnd",
                  "s", accountName.c_str(),
                  NULL );
}

/* END */
