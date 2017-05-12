#!perl -T
#
# create Log::Message::JSON objects
#

use strict;
use warnings;
use Test::More tests => 5;
use Log::Message::JSON qw{logmsg logmess msg json};

#-----------------------------------------------------------------------------

local $SIG{__WARN__} = sub { die $_[0] };

my $m_msg = eval { msg key => "value" };
is(ref $m_msg, 'Log::Message::JSON', 'msg(a => b)');

my $m_json = eval { json key => "value" };
is(ref $m_json, 'Log::Message::JSON', 'json(a => b)');

my $m_logmsg = eval { logmsg key => "value" };
is(ref $m_logmsg, 'Log::Message::JSON', 'logmsg(a => b)');

my $m_logmess = eval { logmess key => "value" };
is(ref $m_logmess, 'Log::Message::JSON', 'logmess(a => b)');

my $msg = eval { msg "own message to be JSON-ified" };
is(ref $msg, 'Log::Message::JSON', 'msg("...")');

#-----------------------------------------------------------------------------
# vim:ft=perl
