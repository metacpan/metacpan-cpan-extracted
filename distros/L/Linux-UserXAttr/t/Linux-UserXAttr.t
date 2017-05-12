#!perl

use strict;
use warnings;

use Test::More tests => 10;
use Linux::UserXAttr qw/:all/;

ok XATTR_CREATE;
ok XATTR_REPLACE;
ok defined &setxattr;
ok defined &lsetxattr;
ok defined &getxattr;
ok defined &lgetxattr;
ok defined &listxattr;
ok defined &llistxattr;
ok defined &removexattr;
ok defined &lremovexattr;
