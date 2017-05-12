#include "Session.h"
#include <ctime>

/** Constructor. */
Session::Session(IO2GSession *session)
{
    mSession = session;
    mSession->subscribeSessionStatus(this);
    mSession->addRef();
    mRefCount = 1;
    mError = "";
    mStatusCode = IO2GSessionStatus::Disconnected;
    mTimeout = 10.0;
}

/** Destructor. */
Session::~Session() {
    mSession->unsubscribeSessionStatus(this);
    mError.clear();
    mSession->release();
}

/** Increase reference counter. */
long Session::addRef()
{
    return InterlockedIncrement(&mRefCount);
}

/** Decrease reference counter. */
long Session::release()
{
    long rc = InterlockedDecrement(&mRefCount);
    if (rc == 0)
        delete this;
    return rc;
}

void  Session::onLoginFailed(const char *error) {
    mError = error;
}

void Session::onSessionStatusChanged(IO2GSessionStatus::O2GSessionStatus status) {
/*
    switch (status)
    {
    case    IO2GSessionStatus::Disconnected:
            printf("status::disconnected 2\n");
            break;
    case    IO2GSessionStatus::Connecting:
            printf("status::connecting\n");
            break;
    case    IO2GSessionStatus::TradingSessionRequested:
            printf("status::trading session requested\n");
            break;
    case    IO2GSessionStatus::Connected:
            printf("status::connected\n");
            break;
    case    IO2GSessionStatus::Reconnecting:
            printf("status::reconnecting\n");
            break;
    case    IO2GSessionStatus::Disconnecting:
            printf("status::disconnecting\n");
            break;
    case    IO2GSessionStatus::SessionLost:
            printf("status::session lost\n");
            break;
    }
*/
    mStatusCode = status;
}

bool Session::loginAndWait(const std::string user, const std::string password, const std::string url, const std::string accountType) {

    if (mStatusCode == IO2GSessionStatus::Connected) {
        return true;
    }


    if (mStatusCode != IO2GSessionStatus::Connecting) {
        mSession->useTableManager(::Yes, NULL);
        mSession->login(user.c_str(), password.c_str(), url.c_str(), accountType.c_str());
    }
    std::time_t started = time(NULL);

    while (1) {
        usleep(500000);

        if (difftime(time(NULL), started) > mTimeout) {
            mError = "Timeout";
            return false;
        }

        switch (mStatusCode) {
            case IO2GSessionStatus::Connected:
                return true;
            case IO2GSessionStatus::Disconnected:
            case IO2GSessionStatus::SessionLost:
                return false;
            case IO2GSessionStatus::Connecting:
            case IO2GSessionStatus::TradingSessionRequested:
            case IO2GSessionStatus::Reconnecting:
            case IO2GSessionStatus::Disconnecting:
            case IO2GSessionStatus::PriceSessionReconnecting:
                break;
        }
    }
}

bool Session::logoutAndWait() {

    if (mStatusCode == IO2GSessionStatus::Disconnected) {
        return true;
    }

    if (mStatusCode != IO2GSessionStatus::Disconnecting) {
        mSession->logout();
    }
    std::time_t started = time(NULL);

    while (1) {
        usleep(500000);

        if (difftime(time(NULL), started) > mTimeout) {
            mError = "Timeout";
            return false;
        }

        switch (mStatusCode) {
            case IO2GSessionStatus::Disconnected:
            case IO2GSessionStatus::SessionLost:
                return true;
            case IO2GSessionStatus::Connecting:
            case IO2GSessionStatus::TradingSessionRequested:
            case IO2GSessionStatus::Connected:
            case IO2GSessionStatus::Reconnecting:
            case IO2GSessionStatus::Disconnecting:
            case IO2GSessionStatus::PriceSessionReconnecting:
                break;
        }
    }
}

IO2GSessionStatus::O2GSessionStatus Session::getStatusCode() const {
    return mStatusCode;
}
