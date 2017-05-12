#include "ForexConnectWrapper.h"
#include "TableListener.h"
#include <ctime>
#include <iostream>
#include <unistd.h>

TableListener::TableListener()
{
    mRefCount = 1;
    mRequestID  = "";
    mTableUpdated = false;
    mTimeout = 10.0;
}

TableListener::~TableListener() {
}

void TableListener::onAdded(const char *rowID, IO2GRow *rowData) {
    O2GTable type = rowData->getTableType();

    IO2GTradeTableRow *trade = (IO2GTradeTableRow *)(rowData);
    std::string openOrderReqID = trade->getOpenOrderReqID();

    if (type != Trades) {
        return;
    }

    if (openOrderReqID != mRequestID) {
        return;
    }

    mTableUpdated = true;
}

void TableListener::onChanged(const char *rowID, IO2GRow *rowData) {
   IO2GTradeTableRow *trade = (IO2GTradeTableRow *)(rowData);
   std::cout << "Trade information changed " << rowID << std::endl;
   std::cout << "TradeID: " << trade->getTradeID() <<
                " Close = " << trade->getClose() << std::endl;
}

void TableListener::onDeleted(const char *rowID, IO2GRow *rowData) {
    O2GTable type = rowData->getTableType();

    IO2GOrderRow *orderRow = static_cast<IO2GOrderRow *>(rowData);
    std::string requestID = orderRow->getRequestID();

    if (type != Orders) {
        return;
    }

    if (strncmp(orderRow->getType(), "CM", 2)) {
        return;
    }

    if (requestID != mRequestID) {
        return;
    }

    mTableUpdated = true;

}

void TableListener::onEachRow(const char *rowID, IO2GRow *rowData) {
    std::cout << "Implementation of IO2GTableListener interface public method onEachRow" << std::endl;
}


void TableListener::onStatusChanged(O2GTableStatus status) {
    std::cout << "Implementation of IO2GTableListener interface public method onStatus" << std::endl;
}

/** Increase reference counter. */
long TableListener::addRef() {
    return InterlockedIncrement(&mRefCount);
}

/** Decrease reference counter. */
long TableListener::release()
{
    long rc = InterlockedDecrement(&mRefCount);
    if (rc == 0)
        delete this;
    return rc;
}


void TableListener::setRequestID(std::string requestID) {
    mTableUpdated = false;
    mRequestID = requestID;
}

bool TableListener::isTableUpdated() {
    return mTableUpdated;
}

void TableListener::waitForTableUpdate() {
    std::time_t started = time(NULL);
    while (!mTableUpdated) {
        usleep(100000);
        if (difftime(time(NULL), started) > mTimeout) {
            throw "Timeout waiting for table update";
            break;
        }
    }
}

void subscribeTableListener(IO2GTableManager *manager, IO2GTableListener *listener) {
    O2G2Ptr<IO2GAccountsTable> accountsTable = (IO2GAccountsTable*)manager->getTable(Messages);
    O2G2Ptr<IO2GOrdersTable> ordersTable = (IO2GOrdersTable *)manager->getTable(Orders);
    O2G2Ptr<IO2GTradesTable> tradesTable = (IO2GTradesTable*)manager->getTable(Trades);
    O2G2Ptr<IO2GMessagesTable> messageTable = (IO2GMessagesTable*)manager->getTable(Messages);
    O2G2Ptr<IO2GClosedTradesTable> closeTradesTable = (IO2GClosedTradesTable*)manager->getTable(ClosedTrades);

    accountsTable->subscribeUpdate(Update, listener);
    ordersTable->subscribeUpdate(Insert, listener);
    ordersTable->subscribeUpdate(Delete, listener);
    tradesTable->subscribeUpdate(Insert, listener);
    closeTradesTable->subscribeUpdate(Insert, listener);
    messageTable->subscribeUpdate(Insert, listener);
}

void unsubscribeTableListener(IO2GTableManager *manager, IO2GTableListener *listener) {
    O2G2Ptr<IO2GAccountsTable> accountsTable = (IO2GAccountsTable*)manager->getTable(Messages);
    O2G2Ptr<IO2GTradesTable> tradesTable = (IO2GTradesTable*)manager->getTable(Trades);
    O2G2Ptr<IO2GOrdersTable> ordersTable = (IO2GOrdersTable *)manager->getTable(Orders);
    O2G2Ptr<IO2GMessagesTable> messageTable = (IO2GMessagesTable*)manager->getTable(Messages);
    O2G2Ptr<IO2GClosedTradesTable> closeTradesTable = (IO2GClosedTradesTable*)manager->getTable(ClosedTrades);
    accountsTable->subscribeUpdate(Update, listener);
    ordersTable->unsubscribeUpdate(Insert, listener);
    ordersTable->unsubscribeUpdate(Delete, listener);
    tradesTable->unsubscribeUpdate(Insert, listener);
    closeTradesTable->unsubscribeUpdate(Insert, listener);
    messageTable->unsubscribeUpdate(Insert, listener);
}
