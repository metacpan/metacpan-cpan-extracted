#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "qmailrem/qmailrem.h"

MODULE = Mail::QmailRemoteXS		PACKAGE = Mail::QmailRemoteXS		


char  *
mail(addrhost,mailfrom,mailto,data,helo,tout,toutconnect)
	char *		addrhost
	char *		mailfrom
	char *		mailto
	char *		data
	char *		helo
        int             tout
        int             toutconnect

