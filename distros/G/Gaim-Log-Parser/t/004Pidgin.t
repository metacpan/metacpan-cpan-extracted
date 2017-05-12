######################################################################
# Test suite for Gaim::Log::Parser
# by Mike Schilli <cpan@perlmeister.com>
######################################################################

use warnings;
use strict;

use Gaim::Log::Parser;

use Test::More;
plan tests => 12;

use Log::Log4perl qw(:easy);
#Log::Log4perl->easy_init($DEBUG);
use Gaim::Log::Parser;

my $EG = "eg";
$EG = "../eg" unless -d $EG;

my $p = Gaim::Log::Parser->new(
    file      => 
        "$EG/canned/proto/from_user/to_user/2008-02-28.163023-0800PST.txt",
    time_zone => "America/Los_Angeles"
);

my $msg = $p->next_message();

isa_ok($msg, "Gaim::Log::Message", "Gaim::Log::Message object");
is($msg->from(), "from_user", "from_user");
is($msg->to(), "to_user", "to_user");
is($msg->protocol(), "proto", "protocol");
is($msg->content(), "yeah, yeah", "content");
is($msg->date(), 1204245046, "timestamp");

$msg = $p->next_message();
isa_ok($msg, "Gaim::Log::Message", "Gaim::Log::Message object");
is($msg->from(), "to_user", "to_user");
is($msg->to(), "from_user", "from_user");
is($msg->protocol(), "proto", "protocol");
is($msg->content(), "nice", "content");
is($msg->date(), 1204288267, "timestamp");
