#include <stdlib.h>
#include <net/if.h>
#include <linux/ethtool.h>
#include <linux/sockios.h>
#include <string.h>

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"
#include "ethtool.h"

MODULE = Linux::Ethtool::WOL		PACKAGE = Linux::Ethtool::WOL

int
_ethtool_gwol(href, dev)
	SV *href
	const char *dev
	
	CODE:
		if(!(SvROK(href) && SvTYPE(SvRV(href)) == SVt_PVHV))
		{
			croak("First argument must be a hashref");
		}
		else if(strlen(dev) >= IFNAMSIZ)
		{
			errno  = ENAMETOOLONG;
			RETVAL = 0;
		}
		else{
			HV *hash = (HV*)(SvRV(href));
			
			struct ethtool_wolinfo wol;
			wol.cmd = ETHTOOL_GWOL;
			
			if(_do_ioctl(dev, &wol))
			{
				hv_store(hash, "supported", 9, newSVuv(wol.supported), 0);
				hv_store(hash, "wolopts",   7, newSVuv(wol.wolopts), 0);
				hv_store(hash, "sopass",    6, newSVpvn(wol.sopass, 6), 0);
				
				RETVAL = 1;
			}
			else{
				RETVAL = 0;
			}
		}
	OUTPUT:
		RETVAL

int
_ethtool_swol(dev, wolopts, sopass)
	const char *dev
	unsigned int wolopts
	const char *sopass
	
	CODE:
		if(strlen(dev) >= IFNAMSIZ)
		{
			errno  = ENAMETOOLONG;
			RETVAL = 0;
		}
		else{
			struct ethtool_wolinfo wol;
			wol.cmd = ETHTOOL_SWOL;
			
			wol.wolopts = wolopts;
			memcpy(wol.sopass, sopass, 6);
			
			if(_do_ioctl(dev, &wol))
			{
				RETVAL = 1;
			}
			else{
				RETVAL = 0;
			}
		}
	OUTPUT:
		RETVAL
