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

static int _do_sset(const char *dev, unsigned int advertising, unsigned int speed, unsigned int duplex, unsigned int port, unsigned int transceiver, unsigned int autoneg)
{
	struct ethtool_cmd cmd;
	cmd.cmd = ETHTOOL_GSET;
	
	if(!_do_ioctl(dev, &cmd))
	{
		return 0;
	}
	
	cmd.advertising = advertising;
	ethtool_cmd_speed_set(&cmd, speed);
	cmd.duplex      = duplex;
	cmd.port        = port;
	cmd.transceiver = transceiver;
	cmd.autoneg     = autoneg;
	
	cmd.cmd = ETHTOOL_SSET;
	
	if(!_do_ioctl(dev, &cmd))
	{
		return 0;
	}
	
	return 1;
}

static int _do_gset(HV *hash, const char *dev)
{
	struct ethtool_cmd cmd;
	cmd.cmd = ETHTOOL_GSET;
	
	if(!_do_ioctl(dev, &cmd))
	{
		return 0;
	}
	
	unsigned int speed = ethtool_cmd_speed(&cmd);
	
	hv_store(hash, "supported",      9,  newSVuv(cmd.supported), 0);
	hv_store(hash, "advertising",    11, newSVuv(cmd.advertising), 0);
	hv_store(hash, "speed",          5,  newSVuv(speed), 0);
	hv_store(hash, "duplex",         6,  newSVuv(cmd.duplex), 0);
	hv_store(hash, "port",           4,  newSVuv(cmd.port), 0);
	hv_store(hash, "transceiver",    11, newSVuv(cmd.transceiver), 0);
	hv_store(hash, "autoneg",        7,  newSVuv(cmd.autoneg), 0);
	hv_store(hash, "lp_advertising", 14, newSVuv(cmd.lp_advertising), 0);
	
	return 1;
}

MODULE = Linux::Ethtool::Settings		PACKAGE = Linux::Ethtool::Settings

int
_ethtool_gset(buf, dev)
	SV *buf
	const char *dev
	
	CODE:
		if(!(SvROK(buf) && SvTYPE(SvRV(buf)) == SVt_PVHV))
		{
			croak("First argument must be a hashref");
		}
		else if(strlen(dev) >= IFNAMSIZ)
		{
			errno  = ENAMETOOLONG;
			RETVAL = 0;
		}
		else{
			RETVAL = _do_gset((HV*)(SvRV(buf)), dev);
		}
	OUTPUT:
		RETVAL

int
_ethtool_sset(dev, advertising, speed, duplex, port, transceiver, autoneg)
	const char *dev
	unsigned int advertising
	unsigned int speed
	unsigned int duplex
	unsigned int port
	unsigned int transceiver
	unsigned int autoneg
	
	CODE:
		if(strlen(dev) >= IFNAMSIZ)
		{
			errno  = ENAMETOOLONG;
			RETVAL = 0;
		}
		else{
			RETVAL = _do_sset(dev, advertising, speed, duplex, port, transceiver, autoneg);
		}
	OUTPUT:
		RETVAL
