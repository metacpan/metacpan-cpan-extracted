# This script generates Ethtool.xs at build-time since it contains a ton of
# almost identical subroutines. Macros can't be used as the XS section of the
# file isn't processed by cpp.

use strict;
use warnings;

open(my $out, ">", $ARGV[0]) or die($!);

print {$out} <<"EOF";
#include <stdlib.h>
#include <net/if.h>
#include <linux/ethtool.h>
#include <string.h>

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"
#include "ethtool.h"

MODULE = Linux::Ethtool		PACKAGE = Linux::Ethtool

EOF

bool_get_func("get_link", "ETHTOOL_GLINK");

bool_get_func("get_rx_csum", "ETHTOOL_GRXCSUM");
bool_set_func("set_rx_csum", "ETHTOOL_SRXCSUM");
bool_get_func("get_tx_csum", "ETHTOOL_GTXCSUM");
bool_set_func("set_tx_csum", "ETHTOOL_STXCSUM");

bool_get_func("get_sg", "ETHTOOL_GSG");
bool_set_func("set_sg", "ETHTOOL_SSG");

bool_get_func("get_tso", "ETHTOOL_GTSO");
bool_set_func("set_tso", "ETHTOOL_STSO");
bool_get_func("get_ufo", "ETHTOOL_GUFO");
bool_set_func("set_ufo", "ETHTOOL_SUFO");
bool_get_func("get_gso", "ETHTOOL_GGSO");
bool_set_func("set_gso", "ETHTOOL_SGSO");
bool_get_func("get_gro", "ETHTOOL_GGRO");
bool_set_func("set_gro", "ETHTOOL_SGRO");

sub bool_get_func
{
	my ($name, $cmd) = @_;
	
	print {$out} <<"EOF";
unsigned int
$name(dev)
	const char *dev
	
	CODE:
		if(strlen(dev) >= IFNAMSIZ)
		{
			errno = ENAMETOOLONG;
			XSRETURN_UNDEF;
		}
		
		struct ethtool_value value;
		value.cmd = $cmd;
		
		if(_do_ioctl(dev, &value))
		{
			RETVAL = (value.data ? 1 : 0);
		}
		else{
			XSRETURN_UNDEF;
		}
	OUTPUT:
		RETVAL

EOF
}

sub bool_set_func
{
	my ($name, $cmd) = @_;
	
	print {$out} <<"EOF";
unsigned int
$name(dev, enable)
	const char *dev
	unsigned int enable
	
	CODE:
		if(strlen(dev) >= IFNAMSIZ)
		{
			errno = ENAMETOOLONG;
			XSRETURN_UNDEF;
		}
		
		struct ethtool_value value;
		value.cmd  = $cmd;
		value.data = (enable ? 1 : 0);
		
		if(_do_ioctl(dev, &value))
		{
			RETVAL = 1;
		}
		else{
			RETVAL = 0;
		}
	OUTPUT:
		RETVAL

EOF
}

close($out);
