#pragma once
#include "ForexConnect.h"
#include "Interlocked.h"
//#include "ILog.h"

class TableListener : public IO2GTableListener {
    private:
        volatile long mRefCount;
        std::string mRequestID;
        bool mTableUpdated;
        double mTimeout;
    public:
        TableListener();
        ~TableListener();
        virtual long addRef();
        virtual long release();
        void onAdded(const char *, IO2GRow *);
        void onChanged(const char *, IO2GRow *);
        void onDeleted(const char *, IO2GRow *);
        void onEachRow(const char *, IO2GRow *);
        void onStatusChanged(O2GTableStatus );

        void setRequestID(std::string requestID);
        bool isTableUpdated();
        void waitForTableUpdate();
};

void subscribeTableListener(IO2GTableManager *, IO2GTableListener *);
void unsubscribeTableListener(IO2GTableManager *, IO2GTableListener *);
