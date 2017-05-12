######################################################################
# Test suite for Gaim::Log::Parser
# by Mike Schilli <cpan@perlmeister.com>
######################################################################

use warnings;
use strict;

use Gaim::Log::Parser;

use Test::More;
plan tests => 17;

use Log::Log4perl qw(:easy);
#Log::Log4perl->easy_init($DEBUG);
use Gaim::Log::Parser;

my $EG = "eg";
$EG = "../eg" unless -d $EG;

my $p = Gaim::Log::Parser->new(
    file => "$EG/canned/proto/from_user/to_user/2005-10-29.230219.txt");

my $msg = $p->next_message();

isa_ok($msg, "Gaim::Log::Message", "Gaim::Log::Message object");
is($msg->from(), "from_user", "from_user");
is($msg->to(), "to_user", "to_user");
is($msg->protocol(), "proto", "protocol");
is($msg->content(), "quack", "content");

$msg = $p->next_message();
isa_ok($msg, "Gaim::Log::Message", "Gaim::Log::Message object");
is($msg->from(), "from_user", "from_user");
is($msg->to(), "to_user", "to_user");
is($msg->protocol(), "proto", "protocol");
is($msg->content(), "back", "content");

$msg = $p->next_message();
is($msg->content(), "a\ni\nj", "multi-line content");

$msg = $p->next_message();
is($msg->content(), "reply", "content");
is($msg->from(), "to_user", "to_user sends");

$msg = $p->next_message();
is($msg->from(), "chat_user", "chat_user sends");

is($p->datetime->month, "10", "check datetime");

like($p->as_string(), qr(^2005/11/01)m, "as_string formatter");

$msg = $p->next_message();
is($msg->content(), "line with : embedded", "line with :");

