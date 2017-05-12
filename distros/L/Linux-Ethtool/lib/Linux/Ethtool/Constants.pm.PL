use ExtUtils::H2PM;

module "Linux::Ethtool::Constants";

include "linux/ethtool.h";

constant "SUPPORTED_10baseT_Half";
constant "SUPPORTED_10baseT_Full";
constant "SUPPORTED_100baseT_Half";
constant "SUPPORTED_100baseT_Full";
constant "SUPPORTED_1000baseT_Half";
constant "SUPPORTED_1000baseT_Full";
constant "SUPPORTED_Autoneg";
constant "SUPPORTED_TP";
constant "SUPPORTED_AUI";
constant "SUPPORTED_MII";
constant "SUPPORTED_FIBRE";
constant "SUPPORTED_BNC";
constant "SUPPORTED_10000baseT_Full";
constant "SUPPORTED_Pause";
constant "SUPPORTED_Asym_Pause";
constant "SUPPORTED_2500baseX_Full";
constant "SUPPORTED_Backplane";
constant "SUPPORTED_1000baseKX_Full";
constant "SUPPORTED_10000baseKX4_Full";
constant "SUPPORTED_10000baseKR_Full";
constant "SUPPORTED_10000baseR_FEC";

constant "ADVERTISED_10baseT_Half";
constant "ADVERTISED_10baseT_Full";
constant "ADVERTISED_100baseT_Half";
constant "ADVERTISED_100baseT_Full";
constant "ADVERTISED_1000baseT_Half";
constant "ADVERTISED_1000baseT_Full";
constant "ADVERTISED_Autoneg";
constant "ADVERTISED_TP";
constant "ADVERTISED_AUI";
constant "ADVERTISED_MII";
constant "ADVERTISED_FIBRE";
constant "ADVERTISED_BNC";
constant "ADVERTISED_10000baseT_Full";
constant "ADVERTISED_Pause";
constant "ADVERTISED_Asym_Pause";
constant "ADVERTISED_2500baseX_Full";
constant "ADVERTISED_Backplane";
constant "ADVERTISED_1000baseKX_Full";
constant "ADVERTISED_10000baseKX4_Full";
constant "ADVERTISED_10000baseKR_Full";
constant "ADVERTISED_10000baseR_FEC";

constant "DUPLEX_HALF";
constant "DUPLEX_FULL";

constant "PORT_TP";
constant "PORT_AUI";
constant "PORT_MII";
constant "PORT_FIBRE";
constant "PORT_BNC";
constant "PORT_OTHER";

constant "XCVR_INTERNAL";
constant "XCVR_EXTERNAL";
constant "XCVR_DUMMY1";
constant "XCVR_DUMMY2";
constant "XCVR_DUMMY3";

constant "WAKE_PHY";
constant "WAKE_UCAST";
constant "WAKE_MCAST";
constant "WAKE_BCAST";
constant "WAKE_ARP";
constant "WAKE_MAGIC";
constant "WAKE_MAGICSECURE";

write_output $ARGV[0];
