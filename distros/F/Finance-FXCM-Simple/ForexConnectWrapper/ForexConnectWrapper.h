#pragma once
#include <string>
#include <cmath>
#include <cstring>
#include <ctime>
#include <iomanip>
#include <sstream>
#include <unistd.h>
#include "ForexConnect.h"
#include "Session.h"
#include "ILog.h"

inline tm *uni_gmtime(time_t *t)
{
#ifdef WIN32
    static struct tm _tm;
    gmtime_s(&_tm, t);
    return &_tm;
#else
    return gmtime(t);
#endif
}

class ForexConnectWrapper : public ILog {
    private:

        static bool findTradeRowByTradeId(IO2GTradeRow *row, std::string tradeID) {
            return tradeID == row->getTradeID();
        }

        static bool findOfferRowBySymbol(IO2GOfferRow *row, std::string symbol) {
            return (symbol == row->getInstrument() && row->getSubscriptionStatus()[0] == 'T');
        }

        static bool findOfferRowByOfferId(IO2GOfferRow *row, std::string offerId) {
            return (offerId == row->getOfferID());
        }

        static IO2GOffersTableResponseReader* getOffersReader(IO2GResponseReaderFactory* readerFactory, IO2GResponse *response) {
            return readerFactory->createOffersTableReader(response);
        }

        static IO2GTradesTableResponseReader* getTradesReader(IO2GResponseReaderFactory* readerFactory, IO2GResponse *response) {
            return readerFactory->createTradesTableReader(response);
        }

        static std::string double2str(double d) {
            std::stringstream oss;
            oss << d;
            return oss.str();
        }

        std::string getOfferID(std::string);

        static std::string int2str(int i) {
            std::stringstream oss;
            oss << i;
            return oss.str();
        }

        static void formatDate(double d, std::string &buf) {
            double d_int, d_frac;
            d_frac = modf(d, &d_int);
            time_t t = time_t(d_int - 25569.0) * 86400 + time_t(floor((d_frac * 86400) + 0.5));
            struct tm *t1 = uni_gmtime(&t);

            using namespace std;
            stringstream sstream;
            sstream << setw(4) << t1->tm_year + 1900 << "-" \
                    << setw(2) << setfill('0') << t1->tm_mon + 1 << "-" \
                    << setw(2) << setfill('0') << t1->tm_mday << " " \
                    << setw(2) << setfill('0') << t1->tm_hour << ":" \
                    << setw(2) << setfill('0') << t1->tm_min << ":" \
                    << setw(2) << setfill('0') << t1->tm_sec;
            buf = sstream.str();
        }

        IO2GSession* session;
        Session* listener;
        IO2GLoginRules* loginRules;
        IO2GAccountRow* accountRow;
        IO2GResponseReaderFactory* mResponseReaderFactory;
        IO2GRequestFactory* mRequestFactory;
        std::string sAccountID;
        bool connected;
        IO2GTradeTableRow* getTradeTableRow(std::string);
        IO2GOfferRow* getOfferRow(std::string);
        template <class RowType, class ReaderType>
            RowType* getTableRow(O2GTable, std::string, bool (*finderFunc)(RowType *, std::string), ReaderType* (*readerCreateFunc)(IO2GResponseReaderFactory* , IO2GResponse *));
        IO2GTableManager* getLoadedTableManager();

    public:
        ForexConnectWrapper(const std::string, const std::string, const std::string, const std::string);
        ~ForexConnectWrapper();
        double getAsk(const std::string);
        double getBid(const std::string);
        double getBalance();
        void openMarket(const std::string, const std::string, int);
        void closeMarket(const std::string, int);
        std::string getTradesAsYAML();
        int getBaseUnitSize(const std::string);
        void saveHistoricalDataToFile(const std::string, const std::string, const std::string, int);
        std::string getOffersHashAsYAML();
        void setSubscriptionStatus(std::string, std::string);
};
