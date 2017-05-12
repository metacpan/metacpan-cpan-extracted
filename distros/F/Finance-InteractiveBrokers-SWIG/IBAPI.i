/* 
 * Finance::InteractiveBrokers::SWIG - SWIG interface file for IBAPI 9.64
 * 
 * Copyright (c) 2010-2014 Jason McManus
 */

#ifndef IB_API_VERSION
# error IB_API_VERSION must be defined.
#endif

#ifndef IB_API_INTVER
# error IB_API_INTVER must be defined.
#endif

/*************************************************************************
 * Resulting full (base) module name for main .pm file
 */

%module "Finance::InteractiveBrokers::SWIG::IBAPI"


/*************************************************************************
 * %perlcode will be embedded as-is in the output .pm file
 */

%perlcode {

# --- From SWIG perlcode section

use vars qw( $VERSION $API_VERSION $BUILD_TIME );
BEGIN {
    $VERSION = '0.13';
}

$API_VERSION = IB_API_VERSION;  # IB API version
$API_INTVER  = IB_API_INTVER;   # IB API integral version
#ifdef BUILD_TIME
$BUILD_TIME  = BUILD_TIME;      # Build time for this library
#else
$BUILD_TIME  = 0;               # Default build time
#endif

sub api_version
{
    return $API_VERSION;
}

sub api_intver
{
    return $API_INTVER;
}

sub build_time
{
    return $BUILD_TIME;
}

}


/*************************************************************************
 * These declarations will be included as-is into IBAPI_wrap.cxx
 */

%{
#undef USE_PERL_ATOF
#define USE_PERL_ATOF 0
#undef Atof
#define Atof Atof

#include "Contract.h"
#include "Order.h"
#include "OrderState.h"
#include "Execution.h"
#include "ScannerSubscription.h"

#if IB_API_INTVER >= 967
#include "CommissionReport.h"
#endif

#include "IBAPI.h"
%}


/*************************************************************************
 * This section includes our perl_call_va() as-is into the wrapper file
 */

%inline %{
/* BEGIN include ezembed.c */
#include "ezembed.c"
/* END include ezembed.c */
%}


/*************************************************************************
 * This section defines the interface seen by Perl in ::IBAPI.pm
 */

/* Include the SWIG declaration files to handle std::string, std::vector, and time_t */
%include "std_vector.i"
%include "std_string.i"

/* time_t typemaps for perl */
%typemap(typecheck) time_t {
    $1 = SvIOK($input) ? 1 : 0;
}
%typemap(in) time_t {
    $1 = SvIV($input);
}
%typemap(out) time_t {
    sv_setiv($result, $input);
}

/* Make sure setSelectTimeout refuses anything but a time_t */
void IBAPIClient::setSelectTimeout(time_t);

/* Make sure IBString is treated like std::string by SWIG */
%apply std::string { IBString }
typedef std::string IBString;

/* typedef some other junk */
typedef long TickerId;
typedef long OrderId;

/* Include (and build code for) some of our types */
%include "Contract.h"
%include "Order.h"
%include "OrderState.h"
%include "Execution.h"
%include "ScannerSubscription.h"

#if IB_API_INTVER >= 967
%include "CommissionReport.h"
#endif

/* Import, but dont include, some needed header declarations */
%import "EWrapper.h"

/* Set some ignored names; don't expose the callbacks as methods */
%ignore State;
%ignore "IBAPIClient::winError";
%ignore "IBAPIClient::error";
%ignore "IBAPIClient::connectionClosed";
%ignore "IBAPIClient::currentTime";

%ignore "IBAPIClient::tickPrice";
%ignore "IBAPIClient::tickSize";
%ignore "IBAPIClient::tickOptionComputation";
%ignore "IBAPIClient::tickGeneric";
%ignore "IBAPIClient::tickString";
%ignore "IBAPIClient::tickEFP";
%ignore "IBAPIClient::tickSnapshotEnd";

%ignore "IBAPIClient::orderStatus";
%ignore "IBAPIClient::openOrder";
%ignore "IBAPIClient::openOrderEnd";

%ignore "IBAPIClient::updateAccountValue";
%ignore "IBAPIClient::updatePortfolio";
%ignore "IBAPIClient::updateAccountTime";

%ignore "IBAPIClient::updateNewsBulletin";

%ignore "IBAPIClient::contractDetails";
%ignore "IBAPIClient::bondContractDetails";
%ignore "IBAPIClient::contractDetailsEnd";

%ignore "IBAPIClient::execDetails";
%ignore "IBAPIClient::execDetailsEnd";

%ignore "IBAPIClient::updateMktDepth";
%ignore "IBAPIClient::updateMktDepthL2";

%ignore "IBAPIClient::managedAccounts";
%ignore "IBAPIClient::receiveFA";

%ignore "IBAPIClient::historicalData";

%ignore "IBAPIClient::scannerParameters";
%ignore "IBAPIClient::scannerData";
%ignore "IBAPIClient::scannerDataEnd";

%ignore "IBAPIClient::realtimeBar";

%ignore "IBAPIClient::fundamentalData";

%ignore "IBAPIClient::deltaNeutralValidation";
%ignore "IBAPIClient::accountDownloadEnd";
%ignore "IBAPIClient::nextValidId";

#if IB_API_INTVER >= 966
%ignore "IBAPIClient::marketDataType";
#endif

#if IB_API_INTVER >= 967
%ignore "IBAPIClient::commissionReport";
#endif

/* Finally, just suck in our own header file */
%include "IBAPI.h"


/* END */
