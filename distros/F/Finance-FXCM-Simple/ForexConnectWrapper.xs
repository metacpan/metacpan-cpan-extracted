#include "ForexConnectWrapper/ForexConnectWrapper.h"


#ifdef __cplusplus
extern "C" {
#endif


#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#ifdef __cplusplus
}
#endif

#define TRY try {
#define CATCH } catch (char const* error) {  Perl_croak(aTHX_ error); }


using namespace std;


MODULE = Finance::FXCM::Simple		PACKAGE = Finance::FXCM::Simple		

ForexConnectWrapper *
ForexConnectWrapper::new(const char *user, const char *password, const char *accountType, const char *url)
    INIT:
        TRY
    CLEANUP:
        CATCH

void
ForexConnectWrapper::DESTROY()

double
ForexConnectWrapper::getAsk(const char *symbol)
    INIT:
        TRY
    CLEANUP:
        CATCH

double
ForexConnectWrapper::getBid(const char *symbol)
    INIT:
        TRY
    CLEANUP:
        CATCH

void
ForexConnectWrapper::openMarket(const char *symbol, const char *direction, int amount)
    INIT:
        TRY
    CLEANUP:
        CATCH

void
ForexConnectWrapper::closeMarket(const char *tradeID, int amount)
    INIT:
        TRY
    CLEANUP:
        CATCH

string
ForexConnectWrapper::getTradesAsYAML()
    INIT:
        TRY
    CLEANUP:
        CATCH

double
ForexConnectWrapper::getBalance()
    INIT:
        TRY
    CLEANUP:
        CATCH

int
ForexConnectWrapper::getBaseUnitSize(const char *symbol)
    INIT:
        TRY
    CLEANUP:
        CATCH

void
ForexConnectWrapper::saveHistoricalDataToFile(const char *filename, const char *symbol, const char * tf, int totalItemsToDownload)
    INIT:
        TRY
    CLEANUP:
        CATCH

string
ForexConnectWrapper::getOffersHashAsYAML()
    INIT:
        TRY
    CLEANUP:
        CATCH

void
ForexConnectWrapper::setSubscriptionStatus(const char *symbol, const char *status)
    INIT:
        TRY
    CLEANUP:
        CATCH

