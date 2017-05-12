#include "ForexConnectWrapper.h"
#include <string>
#include <ctime>
#include <iostream>
#include <fstream>
#include <sstream>
#include "ForexConnect.h"
#include "Listener.h"
#include "TableListener.h"
#include "Session.h"

ForexConnectWrapper::ForexConnectWrapper(const std::string user, const std::string password, const std::string accountType, const std::string url) {

    session = CO2GTransport::createSession();
    session->useTableManager(::Yes, NULL);
    listener = new Session(session);

    if (!listener->loginAndWait(user, password, url, accountType)) {
        log("Failed to login");
        throw "Failed to login";
    }

    connected = true;

    loginRules = session->getLoginRules();
    if (!loginRules->isTableLoadedByDefault(::Accounts)) {
        log("Accounts table not loaded");
        throw "Accounts table not loaded";
    }

    IO2GResponse *response = loginRules->getTableRefreshResponse(::Accounts);
    if(!response) {
        log("No response to refresh accounts table request");
        throw "No response to refresh accounts table request";
    }

    mResponseReaderFactory = session->getResponseReaderFactory();
    IO2GAccountsTableResponseReader *accountsTableResponseReader = mResponseReaderFactory->createAccountsTableReader(response);
    response->release();
    accountRow = accountsTableResponseReader->getRow(0);
    accountsTableResponseReader->release();
    sAccountID = accountRow->getAccountID();
    mRequestFactory = session->getRequestFactory();
}

ForexConnectWrapper::~ForexConnectWrapper() {
    mRequestFactory->release();
    accountRow->release();
    mResponseReaderFactory->release();

    listener->logoutAndWait();

    listener->release();
    session->release();
}

std::string ForexConnectWrapper::getOffersHashAsYAML() {
    std::string rv;
    IO2GTableManager *tableManager = getLoadedTableManager();
    IO2GOffersTable *offersTable = (IO2GOffersTable *)tableManager->getTable(::Offers);
    tableManager->release();

    IO2GOfferTableRow *offerRow = NULL;
    IO2GTableIterator tableIterator;

    while (offersTable->getNextRow(tableIterator, offerRow)) {
        rv.append(offerRow->getInstrument()).append(": ").append(offerRow->getSubscriptionStatus()).append("\n");
        //std::cout << offerRow->getInstrument() << "\t" << offerRow->getSubscriptionStatus()[0] << std::endl;
        if (offerRow)
            offerRow->release();
    }
    offersTable->release();
    return rv;
}

void ForexConnectWrapper::setSubscriptionStatus(std::string instrument, std::string status) {
    IO2GTableManager *tableManager = getLoadedTableManager();
    IO2GOffersTable *offersTable = (IO2GOffersTable *)tableManager->getTable(::Offers);
    tableManager->release();

    IO2GOfferTableRow *offerRow = NULL;
    IO2GTableIterator tableIterator;
    bool instrumentFound = false;

    while (offersTable->getNextRow(tableIterator, offerRow)) {
        if ( instrument == offerRow->getInstrument() ) {
            instrumentFound = true;
            IO2GRequestFactory *factory = session->getRequestFactory();

            IO2GValueMap *valueMap = factory->createValueMap();
            valueMap->setString(::Command, O2G2::Commands::SetSubscriptionStatus);
            valueMap->setString(::SubscriptionStatus, status.c_str());
            valueMap->setString(::OfferID, offerRow->getOfferID());

            IO2GRequest *request = factory->createOrderRequest(valueMap);
            valueMap->release();

            Listener *ll = new Listener(session);
            IO2GResponse *response = ll->sendRequest(request);
            response->release();
            request->release();
            ll->release();
            factory->release();

            break;
        }
    }
    offerRow->release();
    offersTable->release();

    if (!instrumentFound) {
        std::stringstream ss;
        ss << "Could not find offer row for instrument " << instrument;
        log(ss.str());
        throw ss.str().c_str();
    }
}

std::string ForexConnectWrapper::getOfferID(std::string instrument) {
        IO2GTableManager *tableManager = getLoadedTableManager();
        IO2GOffersTable *offersTable = (IO2GOffersTable *)tableManager->getTable(::Offers);
        tableManager->release();

        IO2GOfferTableRow *offerRow = NULL;
        IO2GTableIterator tableIterator;

        std::string sOfferID;

        while (offersTable->getNextRow(tableIterator, offerRow)) {
            if (instrument == offerRow->getInstrument()) {
                break;
            }
        }
        offersTable->release();

        if (offerRow) {
            sOfferID = offerRow->getOfferID();
            offerRow->release();
        } else {
            std::stringstream ss;
            ss << "Could not find offer row for instrument " << instrument;
            log(ss.str());
            throw ss.str().c_str();
        }

        return sOfferID;
}

void ForexConnectWrapper::openMarket(const std::string symbol, const std::string direction, int amount) {
    if (direction != O2G2::Sell && direction != O2G2::Buy) {
        log("Direction must be 'B' or 'S'");
        throw "Direction must be 'B' or 'S'";
    }

    std::string sOfferID = getOfferID(symbol);

    IO2GValueMap *valuemap = mRequestFactory->createValueMap();
    valuemap->setString(Command, O2G2::Commands::CreateOrder);
    valuemap->setString(OrderType, O2G2::Orders::TrueMarketOpen);
    valuemap->setString(AccountID, sAccountID.c_str());
    valuemap->setString(OfferID, sOfferID.c_str());
    valuemap->setString(BuySell, direction.c_str());
    valuemap->setInt(Amount, amount);
    valuemap->setString(TimeInForce, O2G2::TIF::IOC);

    IO2GRequest *orderRequest = mRequestFactory->createOrderRequest(valuemap);
    valuemap->release();

    TableListener *tableListener = new TableListener();
    tableListener->setRequestID(orderRequest->getRequestID());

    IO2GTableManager *tableManager = getLoadedTableManager();
    subscribeTableListener(tableManager, tableListener);

    Listener *ll = new Listener(session);
    IO2GResponse *response = ll->sendRequest(orderRequest);
    orderRequest->release();
    ll->release();

    if (!response) {
        std::stringstream ss;
        ss << "Failed to send openMarket request " << symbol << " " << direction << " " << amount;
        log(ss.str());
        throw ss.str().c_str();
    }

    tableListener->waitForTableUpdate();

    response->release();
    unsubscribeTableListener(tableManager, tableListener);
    tableListener->release();
    tableManager->release();
}

double ForexConnectWrapper::getBid(const std::string symbol) {
    IO2GOfferRow *offer = getTableRow<IO2GOfferRow, IO2GOffersTableResponseReader>(Offers, symbol, &findOfferRowBySymbol, &getOffersReader);
    double rv = offer->getBid();
    offer->release();

    return rv;
}

double ForexConnectWrapper::getAsk(const std::string symbol) {
    IO2GOfferRow *offer = getTableRow<IO2GOfferRow, IO2GOffersTableResponseReader>(Offers, symbol, &findOfferRowBySymbol, &getOffersReader);
    double rv = offer->getAsk();
    offer->release();

    return rv;
}

IO2GTradeTableRow* ForexConnectWrapper::getTradeTableRow(std::string tradeID) {
        IO2GTableManager *tableManager = getLoadedTableManager();
        IO2GTradesTable *tradesTable = (IO2GTradesTable *)tableManager->getTable(::Trades);
        tableManager->release();

        IO2GTradeTableRow *tradeRow = NULL;
        IO2GTableIterator tableIterator;

        std::string sOfferID;

        while (tradesTable->getNextRow(tableIterator, tradeRow)) {
            if (tradeID == tradeRow->getTradeID()) {
                break;
            }
        }
        tradesTable->release();

        return tradeRow;
}

void ForexConnectWrapper::closeMarket(const std::string tradeID, int amount) {
    IO2GTradeTableRow *trade = getTradeTableRow(tradeID);
    if (!trade) {
        std::stringstream ss;
        ss << "Could not find trade with ID = " << tradeID;
        log(ss.str());
        throw ss.str().c_str();
    }

    IO2GValueMap *valuemap = mRequestFactory->createValueMap();
    valuemap->setString(Command, O2G2::Commands::CreateOrder);
    valuemap->setString(OrderType, O2G2::Orders::TrueMarketClose);
    valuemap->setString(AccountID, sAccountID.c_str());
    valuemap->setString(OfferID, trade->getOfferID());
    valuemap->setString(TradeID, tradeID.c_str());
    valuemap->setString(BuySell, ( strncmp(trade->getBuySell(), "B", 1) == 0 ? O2G2::Sell : O2G2::Buy ) );
    trade->release();
    valuemap->setInt(Amount, amount);
    //valuemap->setString(CustomID, "Custom");

    IO2GRequest *request = mRequestFactory->createOrderRequest(valuemap);
    valuemap->release();

    TableListener *tableListener = new TableListener();
    tableListener->setRequestID(request->getRequestID());

    IO2GTableManager *tableManager = getLoadedTableManager();
    subscribeTableListener(tableManager, tableListener);

    Listener *ll = new Listener(session);
    IO2GResponse *response = ll->sendRequest(request);
    request->release();
    ll->release();

    if (!response) {
        std::stringstream ss;
        ss << "Failed to get response to closeMarket request " << tradeID << " " << amount;
        log(ss.str());
        throw ss.str().c_str();
    }

    tableListener->waitForTableUpdate();

    response->release();
    unsubscribeTableListener(tableManager, tableListener);
    tableListener->release();
    tableManager->release();
}

IO2GTableManager* ForexConnectWrapper::getLoadedTableManager() {
    IO2GTableManager *tableManager = session->getTableManager();

    while (tableManager->getStatus() != TablesLoaded) {
        usleep(50);
        if (tableManager->getStatus() == TablesLoadFailed)
            throw "Failed to load tables";
    }

    return tableManager;
}

std::string ForexConnectWrapper::getTradesAsYAML() {
    std::string rv;
    IO2GTableManager *tableManager = getLoadedTableManager();

    IO2GTradesTable *tradesTable = (IO2GTradesTable *)tableManager->getTable(Trades);
    IO2GTradeTableRow *tradeRow = NULL;
    IO2GTableIterator tableIterator;
    while (tradesTable->getNextRow(tableIterator, tradeRow)) {
        bool isLong = (strncmp(tradeRow->getBuySell(), "B", 1) == 0);
        double d = tradeRow->getOpenTime();
        std::string openDateTime;
        formatDate(d, openDateTime);

        IO2GOfferRow *offer = getTableRow<IO2GOfferRow, IO2GOffersTableResponseReader>(Offers, tradeRow->getOfferID(), &findOfferRowByOfferId, &getOffersReader);

        rv.append("- symbol: ").append(offer->getInstrument()).append("\n");
        offer->release();
        rv.append("  id: ").append(tradeRow->getTradeID()).append("\n");
        rv.append("  direction: ").append(isLong ? "long" : "short").append("\n");
        rv.append("  openPrice: ").append(double2str(tradeRow->getOpenRate())).append("\n");
        rv.append("  size: ").append(int2str(tradeRow->getAmount())).append("\n");
        rv.append("  openDate: ").append(openDateTime).append("\n");
        rv.append("  pl: ").append(double2str(tradeRow->getGrossPL())).append("\n");

        tradeRow->release();
    }

    tradesTable->release();
    tableManager->release();

    return rv;
}

double ForexConnectWrapper::getBalance() {
    return accountRow->getBalance();
}

int ForexConnectWrapper::getBaseUnitSize(const std::string symbol) {
    IO2GTradingSettingsProvider *tradingSettingsProvider = loginRules->getTradingSettingsProvider();

    int rv = tradingSettingsProvider->getBaseUnitSize(symbol.c_str(), accountRow);
    tradingSettingsProvider->release();
    return rv;
}


template <class RowType, class ReaderType>
RowType* ForexConnectWrapper::getTableRow(O2GTable table, std::string key, bool (*finderFunc)(RowType *, std::string), ReaderType* (*readerCreateFunc)(IO2GResponseReaderFactory* , IO2GResponse *)) {

    IO2GResponse *response;

    if( !loginRules->isTableLoadedByDefault(table) ) {
        IO2GRequest *request = mRequestFactory->createRefreshTableRequestByAccount(Trades, sAccountID.c_str());

        Listener *ll = new Listener(session);
        response = ll->sendRequest(request);
        request->release();
        ll->release();
        if (!response) {
            log("No response to manual table refresh request");
            throw "No response to manual table refresh request";
        }
    } else {
        response = loginRules->getTableRefreshResponse(table);
        if (!response) {
            log("No response to automatic table refresh request");
            throw "No response to automatic table refresh request";
        }
    }

    ReaderType *reader = readerCreateFunc(mResponseReaderFactory, response);
    response->release();

    RowType *row = NULL;

    for ( int i = 0; i < reader->size(); ++i ) {
        row = reader->getRow(i);
        if ( finderFunc(row, key) ) {
                break;
        }
        row->release();
        row = NULL;
    }
    reader->release();

    if (row == NULL) {
        std::stringstream ss;
        ss << "Could not find row for key " << key;
        log(ss.str());
        throw ss.str().c_str();
    }

    return row;
}

void ForexConnectWrapper::saveHistoricalDataToFile(const std::string filename, const std::string symbol, const std::string tf, int totalItemsToDownload) {
        IO2GTimeframeCollection *timeframeCollection = mRequestFactory->getTimeFrameCollection();
        IO2GTimeframe *timeframeObject = NULL;
        int timeframeCollectionSize = timeframeCollection->size();
        for (int i = 0; i < timeframeCollectionSize; i++) {
            IO2GTimeframe *searchTimeframeObject = timeframeCollection->get(i);
            if ( tf == searchTimeframeObject->getID() ) {
                timeframeObject = searchTimeframeObject;
                break;
            } else {
                searchTimeframeObject->release();
            }
        }
        timeframeCollection->release();

        if (!timeframeObject) {
            log("Could not find timeframe");
            throw "Could not find timeframe";
        }


        double timeFrom = 0, timeTo = 0;

        time_t rawtime = time(NULL);
        struct tm timeinfo = *localtime(&rawtime);
        timeinfo.tm_year = 50;
        timeinfo.tm_mon = 0;
        timeinfo.tm_mday = 1;
        timeinfo.tm_hour = 0;
        timeinfo.tm_min = 0;
        timeinfo.tm_sec = 0;

        CO2GDateUtils::CTimeToOleTime(&timeinfo, &timeFrom);
        std::string dd;
        formatDate(timeFrom, dd);

        std::ofstream outputFile;
        outputFile.open(filename.c_str());
        Listener *ll = new Listener(session);
        while (totalItemsToDownload > 0) {
            IO2GRequest *marketDataRequest = mRequestFactory->createMarketDataSnapshotRequestInstrument(symbol.c_str(), timeframeObject, totalItemsToDownload > 300 ? 300 : totalItemsToDownload);
            mRequestFactory->fillMarketDataSnapshotRequestTime(marketDataRequest, timeFrom, timeTo, false);
            IO2GResponse *marketDataResponse = ll->sendRequest(marketDataRequest);
            if (!marketDataResponse) {
                throw "no response to marketDataRequest";
            }

            IO2GMarketDataSnapshotResponseReader *marketSnapshotReader = mResponseReaderFactory->createMarketDataSnapshotReader(marketDataResponse);
            if (!marketSnapshotReader) {
                throw "Failed to create marketSnapshotReader";
            }
            int snapshotSize = marketSnapshotReader->size();
            for (int i = snapshotSize - 1; i >= 0; i--) {
                double date = marketSnapshotReader->getDate(i);
                std::string dateTimeStr;
                formatDate(date, dateTimeStr);
                outputFile << dateTimeStr << "\t" << double2str(marketSnapshotReader->getAskOpen(i)) << "\t" << double2str(marketSnapshotReader->getAskHigh(i)) << "\t" << double2str(marketSnapshotReader->getAskLow(i)) << "\t" << double2str(marketSnapshotReader->getAskClose(i)) << "\t" << std::endl;

            }

            totalItemsToDownload -= snapshotSize;
            if (totalItemsToDownload > 0) {
                timeTo = marketSnapshotReader->getDate(0);
            }
            marketSnapshotReader->release();
        }
        timeframeObject->release();
        ll->release();
        outputFile.close();
}
