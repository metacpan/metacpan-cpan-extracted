#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ip-tools.h"
#include "block-china-data.h"

MODULE=IP::China PACKAGE=IP::China

PROTOTYPES: ENABLE

int
chinese_ip (char * ip)
CODE:
        unsigned long ipAddr;
        int found;

        ipAddr = ip_tools_ip_to_int (ip);
        found = ip_tools_ip_range (china_ips, n_china_ips, ipAddr);
        if (found != NOTFOUND) {
		RETVAL = -1;
        }
        else {
		RETVAL = 0;
        }
        OUTPUT:
        RETVAL
