use strict;
use warnings;
use Test::More;

BEGIN { $ENV{EV_TDLIB_SHUTDOWN_TIMEOUT} = 0.1 }

use EV;
use EV::Telegram::TDLib;
use EV::Telegram::TDLib::Schema;
use Cpanel::JSON::XS;

my %fn = %EV::Telegram::TDLib::Schema::FUNCTIONS;
cmp_ok scalar keys %fn, '>', 500, 'the catalogue has a plausible number of functions';
ok defined $EV::Telegram::TDLib::Schema::TDLIB_VERSION, 'the TDLib version is recorded';

is $fn{getChatMember}, 'chat_id member_id', 'getChatMember arguments';
is $fn{getMe}, '', 'getMe takes no arguments';
is $fn{searchWebApp}, 'bot_user_id web_app_short_name', 'searchWebApp arguments';

is scalar(grep { EV::Telegram::TDLib::Schema->can($_) } qw(new call send)), 0,
    'the schema module exposes no methods';

my @sent;
{
    no warnings 'redefine';
    *EV::Telegram::TDLib::_send = sub { push @sent, $_[1] };
}
sub last_req { Cpanel::JSON::XS->new->decode($sent[-1]) }

my $td = EV::Telegram::TDLib->new(
    api_id => 1, api_hash => 'x', database_directory => 't/tmp-call');

# --- a known function with known arguments, @type filled in
$td->call(getChatMember => { chat_id => 5, member_id => 9 }, sub {});
my $r = last_req();
is $r->{'@type'}, 'getChatMember', 'call fills in the type from the name';
is $r->{chat_id}, 5, 'arguments pass through untouched';

# --- a known function with a bogus argument croaks and says what is valid.
# The control counts sends: the function name is the same either way, so an
# @type assertion would pass even if the bad request had gone out.
my $n = scalar @sent;
my $err = do { local $@;
    eval { $td->call(getChatMember => { chat_id => 5, membr_id => 9 }, sub {}) }; $@ };
like $err, qr/membr_id/, 'the unknown argument is named';
like $err, qr/getChatMember/, 'the function is named';
like $err, qr/chat_id member_id/, 'the valid arguments are listed';
is scalar @sent, $n, 'the rejected call sent nothing';

# an argument-less function rejects any argument, and says so readably
$err = do { local $@; eval { $td->call(getMe => { nope => 1 }, sub {}) }; $@ };
like $err, qr/\(none\)/, 'an argument-less function reports no valid arguments';

# --- an unknown function passes through, so a newer TDLib still works
my $before = scalar @sent;
$td->call(someFutureMethod => { whatever => 1 }, sub {});
is scalar @sent, $before + 1, 'an unknown function is still sent';
$r = last_req();
is $r->{'@type'}, 'someFutureMethod', 'with its type filled in';
is $r->{whatever}, 1, 'and its arguments untouched';

# --- a partial argument set is allowed; TDLib applies its own defaults
$td->call(getChatMember => { chat_id => 5 }, sub {});
is last_req()->{'@type'}, 'getChatMember', 'a partial argument set is allowed';

# --- the callback is optional, like send
$td->call(getMe => {});
is last_req()->{'@type'}, 'getMe', 'call works without a callback';
$td->call('getMe');
is last_req()->{'@type'}, 'getMe', 'and the arguments are optional too';

# a callback where the arguments go croaked "call needs a hashref". The reply
# is what proves it: a request going out would pass with the callback dropped.
{
    my $got;
    $td->call('getMe', sub { $got = shift });
    my ($x) = $sent[-1] =~ /"\@extra":"(\d+)"/;
    $td->inject_raw(qq({"\@type":"user","id":7,"\@extra":"$x"}));
    is $got && $got->{id}, 7, 'a callback in place of the arguments gets the reply';

    $td->call('getMe', sub {}, timeout => 5);
    ($x) = $sent[-1] =~ /"\@extra":"(\d+)"/;
    ok $td->{pending}{$x}{timer}, 'and options after it still reach send';
}

$err = do { local $@; eval { $td->call(undef, {}) }; $@ };
like $err, qr/required/, 'a missing function name is refused';

$err = do { local $@; eval { $td->call(getMe => 'nope') }; $@ };
like $err, qr/hashref/, 'a non-hashref argument set is refused';

done_testing;
