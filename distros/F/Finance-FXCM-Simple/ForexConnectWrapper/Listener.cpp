#include "ForexConnectWrapper.h"
#include "Listener.h"
#include <ctime>
#include <unistd.h>

Listener::Listener(IO2GSession *session)
{
    mSession = session;
    mSession->addRef();
    mRequestInProgress = false;
    mWaitingForUpdateEvent = false;
    mTimeout = 10.0;
    mRefCount = 1;
    mResponse = NULL;
    mWaitingRequestId = "";
    mFailReason = "";
}

Listener::~Listener()
{
    mSession->release();
}

void Listener::onRequestCompleted(const char *requestId, IO2GResponse  *response) {
    if (strcmp(requestId, mWaitingRequestId.c_str())) {
        return;
    }
    mResponse = response;
    mResponse->addRef();
    mFailReason = "";
    mRequestInProgress = false;
    mWaitingRequestId = "";
}

void Listener::onRequestFailed(const char *requestId , const char *error) {
    if (strcmp(requestId, mWaitingRequestId.c_str())) {
        return;
    }
    mResponse = NULL;
    mFailReason = error;
    mRequestInProgress = false;
    mWaitingForUpdateEvent = false;
}

void Listener::onTablesUpdates(IO2GResponse *data) {
    if (data == NULL) {
        log("onTablesUpdates called with NULL data");
        throw "onTablesUpdates called with NULL data";
    }

    if (!mWaitingForUpdateEvent) {
        return;
    }
}

IO2GResponse* Listener::sendRequestAndWaitForUpdateEvent(IO2GRequest *request) {
    mWaitingRequestId = request->getRequestID();
    mRequestInProgress = true;
    mWaitingForUpdateEvent = true;
    mSession->subscribeResponse(this);
    mSession->sendRequest(request);
    std::time_t started = time(NULL);
    while (mRequestInProgress) {
        usleep(500000);

        if (difftime(time(NULL), started) > mTimeout) {
            mFailReason = "Timeout";
            break;
        }
    }
    mSession->unsubscribeResponse(this);

    return mResponse;

}

IO2GResponse* Listener::sendRequest(IO2GRequest *request) {
    mWaitingRequestId = request->getRequestID();
    mRequestInProgress = true;
    mSession->subscribeResponse(this);
    mSession->sendRequest(request);
    std::time_t started = time(NULL);
    while (mRequestInProgress) {
        usleep(500000);

        if (difftime(time(NULL), started) > mTimeout) {
            mFailReason = "Timeout";
            break;
        }
    }
    mSession->unsubscribeResponse(this);

    return mResponse;
}

const std::string Listener::getFailReason() {
    return mFailReason;
}

/** Increase reference counter. */
long Listener::addRef()
{
    return InterlockedIncrement(&mRefCount);
}

/** Decrease reference counter. */
long Listener::release()
{
    long rc = InterlockedDecrement(&mRefCount);
    if (rc == 0)
        delete this;
    return rc;
}

