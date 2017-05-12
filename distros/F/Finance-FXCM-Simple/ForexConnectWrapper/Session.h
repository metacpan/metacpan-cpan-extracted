#pragma once
#include "ForexConnect.h"
#include <string>
#include <unistd.h>
#include "Interlocked.h"

class Session : public IO2GSessionStatus {
    private:
        long mRefCount;
        IO2GSession *mSession;
        IO2GSessionStatus::O2GSessionStatus mStatusCode;
        std::string mError;
        double mTimeout;
    public:
        Session(IO2GSession *);
        ~Session();

        /** Increase reference counter. */
        virtual long addRef();

        /** Decrease reference counter. */
        virtual long release();

        /** Callback called when login has been failed. */
        virtual void  onLoginFailed (const char *error);

        /** Callback called when session status has been changed. */
        virtual void  onSessionStatusChanged(IO2GSessionStatus::O2GSessionStatus status);

        bool loginAndWait(const std::string, const std::string, const std::string, const std::string);
        bool logoutAndWait();
        IO2GSessionStatus::O2GSessionStatus getStatusCode() const;
};
