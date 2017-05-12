use ExtUtils::H2PM;

module "Linux::Netfilter::Log";

include "sys/types.h";
include "libnetfilter_log/libnetfilter_log.h";

constant "NFULNL_COPY_NONE";
constant "NFULNL_COPY_META";
constant "NFULNL_COPY_PACKET";

constant "NFULNL_CFG_F_SEQ";
constant "NFULNL_CFG_F_SEQ_GLOBAL";

write_output $ARGV[0];
