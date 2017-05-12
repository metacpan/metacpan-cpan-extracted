#pragma once
#include "ForexConnect.h"
#include "Interlocked.h"
#include "ILog.h"

class Listener : public IO2GResponseListener, ILog {
    private:
        long mRefCount;
        IO2GSession *mSession;
        bool mRequestInProgress;
        bool mWaitingForUpdateEvent;
        double mTimeout;
        IO2GResponse *mResponse;
        std::string mWaitingRequestId;
        std::string mFailReason;
    public:
        Listener(IO2GSession *);
        ~Listener();
        virtual long addRef();
        virtual long release();
        IO2GResponse* sendRequest(IO2GRequest *);
        IO2GResponse* sendRequestAndWaitForUpdateEvent(IO2GRequest *request);
        virtual void onRequestCompleted(const char *requestId, IO2GResponse  *response = 0);
        virtual void onRequestFailed(const char *requestId , const char *error);
        virtual void onTablesUpdates(IO2GResponse *data);
        const std::string getFailReason();
};
