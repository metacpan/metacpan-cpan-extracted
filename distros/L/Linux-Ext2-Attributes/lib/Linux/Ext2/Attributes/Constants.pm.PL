use ExtUtils::H2PM;

module "Linux::Ext2::Attributes::Constants";

include "linux/fs.h";
include "linux/ext2_fs.h";

constant "EXT2_IOC_GETFLAGS";
constant "EXT2_IOC_SETFLAGS";

constant "EXT2_NOATIME_FL";
constant "EXT2_APPEND_FL";
constant "EXT2_COMPRBLK_FL";
constant "EXT2_COMPR_FL";
constant "EXT2_DIRSYNC_FL";
constant "EXT2_NODUMP_FL";
constant "EXT2_ECOMPR_FL";
constant "EXT2_INDEX_FL";
constant "EXT2_IMMUTABLE_FL";
constant "EXT2_SECRM_FL";
constant "EXT2_SYNC_FL";
constant "EXT2_TOPDIR_FL";
constant "EXT2_NOTAIL_FL";
constant "EXT2_UNRM_FL";
constant "EXT2_NOCOMP_FL";
constant "EXT2_DIRTY_FL";

write_output $ARGV[0];
