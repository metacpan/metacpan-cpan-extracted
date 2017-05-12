#!perl -T
#
# check order of keys appearance
#

use strict;
use warnings;
#use Test::More tests => 4;
use Test::More;
use Log::Message::JSON qw{msg};

#-----------------------------------------------------------------------------

plan tests => 1;

#-----------------------------------------------------------------------------

my $msg = msg first => 1, second => [2], third => " 3 ", fourth => { d => 4 };
my $msg_str = "$msg";

if ($msg_str =~ /first.*second.*third.*fourth/) {
  pass("order of keys preserved");
} else {
  fail("order of keys preserved");
}

#-----------------------------------------------------------------------------
# vim:ft=perl
