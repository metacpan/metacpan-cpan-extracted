#!/usr/bin/perl

use strict;
use warnings;

use ExtUtils::H2PM 0.03;

module "Linux::SocketFilter";

use_export_ok;

include "linux/types.h";
include "linux/filter.h";
include "sys/socket.h";

constant "SO_ATTACH_FILTER";
constant "SO_DETACH_FILTER";

structure "struct sock_filter",
   members => [
      map { $_ => member_numeric } qw( code jt jf k ),
   ];

constant "BPF_$_" for qw(
   LD LDX ST STX ALU JMP RET MISC
   W H B IMM ABS IND MEM LEN MSH
   ADD SUB MUL DIV OR AND LSH RSH NEG
   JA JEQ JGT JGE JSET K X A TAX TXA );

constant "SKF_AD_$_" for qw( OFF PROTOCOL PKTTYPE IFINDEX );
constant "SKF_NET_OFF";
constant "SKF_LL_OFF";

write_output $ARGV[0];
