# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl IO-Socket-TIPC.t'

#########################

# change 'tests => 2' to 'tests => last_test_to_print';

use strict;
use warnings;
use Test::More;
my $tests;

BEGIN { $tests = 0; };

use IO::Socket::TIPC ':all';

# These function calls must not die.  They will return undef if tipc.h doesn't
# define them, and that's fine, but they have to at least be callable.
foreach my $constname (qw(
	AF_TIPC PF_TIPC SOL_TIPC TIPC_ADDR_ID TIPC_ADDR_MCAST TIPC_ADDR_NAME
	TIPC_ADDR_NAMESEQ TIPC_CFG_SRV TIPC_CLUSTER_SCOPE TIPC_CONN_SHUTDOWN
	TIPC_CONN_TIMEOUT TIPC_CRITICAL_IMPORTANCE TIPC_DESTNAME
	TIPC_DEST_DROPPABLE TIPC_ERRINFO TIPC_ERR_NO_NAME TIPC_ERR_NO_NODE
	TIPC_ERR_NO_PORT TIPC_ERR_OVERLOAD TIPC_HIGH_IMPORTANCE TIPC_IMPORTANCE
	TIPC_LOW_IMPORTANCE TIPC_MAX_USER_MSG_SIZE TIPC_MEDIUM_IMPORTANCE
	TIPC_NODE_SCOPE TIPC_OK TIPC_PUBLISHED TIPC_RESERVED_TYPES TIPC_RETDATA
	TIPC_SRC_DROPPABLE TIPC_SUBSCR_TIMEOUT TIPC_SUB_PORTS TIPC_SUB_SERVICE
	TIPC_TOP_SRV TIPC_WAIT_FOREVER TIPC_WITHDRAWN TIPC_ZONE_SCOPE
	TIPC_SUB_NO_BIND_EVTS TIPC_SUB_NO_UNBIND_EVTS TIPC_SUB_SINGLE_EVT
	SOCK_STREAM SOCK_DGRAM SOCK_SEQPACKET SOCK_RDM
	MSG_DONTWAIT MSG_PEEK MSG_WAITALL MSG_CTRUNC
	)) {
  ok(eval("my \$a = $constname(); 1"), "constant $constname is callable");
}
BEGIN { $tests += 48 };

# These function need to return useful values.  We call them internally, and
# therefore they are necessary for normal operation of the perl module.
foreach my $constname (qw(
	AF_TIPC PF_TIPC TIPC_ZONE_SCOPE TIPC_CLUSTER_SCOPE TIPC_NODE_SCOPE
	TIPC_ADDR_ID TIPC_ADDR_NAME TIPC_ADDR_NAMESEQ)) {
  ok(eval("my \$a = $constname(); defined(\$a)"), "constant $constname defined");
}
BEGIN { $tests += 8 };


BEGIN {
	my $defined = eval "my \$a = AF_TIPC(); 1";
	if($defined) {
		plan tests => $tests;
	} else {
	    # something is seriously wrong; report a simpler error message.
		plan tests => 1;
		ok(0, "No AF_TIPC.  Are you missing tipc.h?");
		exit;
	}
};
