use strict;
use warnings;
use Test::More;

BEGIN { $ENV{EV_TDLIB_SHUTDOWN_TIMEOUT} = 0.1 }

use EV;
use EV::Telegram::TDLib;
use Cpanel::JSON::XS;

my @sent;
{
    no warnings 'redefine';
    *EV::Telegram::TDLib::_send = sub { push @sent, $_[1] };
}
sub last_json { $sent[-1] }
sub last_req  { Cpanel::JSON::XS->new->utf8->decode($sent[-1]) }

my $td = EV::Telegram::TDLib->new(
    api_id => 1, api_hash => 'x', database_directory => 't/tmp-stars');

# --- the two methods moved out of Payments must still work unchanged
$td->refund_star_payment(7, 'charge_abc', sub {});
my $r = last_req();
is $r->{'@type'}, 'refundStarPayment', 'refund_star_payment survived the move';
is $r->{user_id}, 7, 'and still passes its user id';

$td->star_transactions(sub {});
is last_req()->{'@type'}, 'getStarTransactions', 'star_transactions survived the move';

$td->star_transactions(direction => 'incoming', sub {});
is last_req()->{direction}{'@type'}, 'transactionDirectionIncoming',
    'and kept its direction option';

# --- gift ids are int64 and cross as strings
$td->available_gifts(sub {});
is last_req()->{'@type'}, 'getAvailableGifts', 'available_gifts';

$td->send_gift('5170233102089322756', 42, sub {});
$r = last_req();
is $r->{'@type'}, 'sendGift', 'send_gift';
like last_json(), qr/"gift_id":"5170233102089322756"/, 'gift_id crosses as a string';
is $r->{owner_id}{'@type'}, 'messageSenderUser', 'a positive owner id is a user';

$td->send_gift('123', -1001234, sub {});
is last_req()->{owner_id}{'@type'}, 'messageSenderChat',
    'a negative owner id is a chat';

$td->send_gift('123', 42, text => 'happy birthday', sub {});
$r = last_req();
is $r->{text}{'@type'}, 'formattedText', 'the gift text is a formattedText';
is $r->{text}{text}, 'happy birthday', 'with the text given';

$td->can_send_gift('123', sub {});
$r = last_req();
is $r->{'@type'}, 'canSendGift', 'can_send_gift';
like last_json(), qr/"gift_id":"123"/, 'and stringifies gift_id too';

$td->gift_upgrade_preview('456', sub {});
$r = last_req();
is $r->{'@type'}, 'getGiftUpgradePreview', 'gift_upgrade_preview';
like last_json(), qr/"regular_gift_id":"456"/,
    'regular_gift_id is int64 and crosses as a string';

# --- received_gift_id is a TL string already, so it must not be numified
$td->received_gift('abc_123', sub {});
$r = last_req();
is $r->{'@type'}, 'getReceivedGift', 'received_gift';
is $r->{received_gift_id}, 'abc_123', 'received_gift_id passes through as a string';

$td->toggle_gift_saved('abc_123', 1, sub {});
$r = last_req();
is $r->{'@type'}, 'toggleGiftIsSaved', 'toggle_gift_saved';
like last_json(), qr/"is_saved":true/, 'saved by default';

$td->sell_gift('abc_123', sub {});
is last_req()->{'@type'}, 'sellGift', 'sell_gift';

$td->upgrade_gift('abc_123', sub {});
$r = last_req();
is $r->{'@type'}, 'upgradeGift', 'upgrade_gift';
is $r->{star_count}, 0, 'star_count is int53 and stays numeric';

$td->transfer_gift('abc_123', 99, sub {});
$r = last_req();
is $r->{'@type'}, 'transferGift', 'transfer_gift';
is $r->{new_owner_id}{'@type'}, 'messageSenderUser', 'the new owner is coerced';

# --- owner_id is required, not an option
$td->received_gifts(42, sub {});
$r = last_req();
is $r->{'@type'}, 'getReceivedGifts', 'received_gifts';
is $r->{owner_id}{'@type'}, 'messageSenderUser', 'owner_id is a required positional';
is $r->{offset}, '', 'offset is a string cursor, defaulting to empty';
is $r->{limit}, 50, 'limit is int32';
like last_json(), qr/"exclude_unsaved":false/, 'the exclude flags default false';

eval { $td->received_gifts(sub {}) };
like $@, qr/owner/, 'received_gifts without an owner croaks';

# --- gift settings nests an object inside an object
$td->set_gift_settings(show_button => 1, unlimited => 1, sub {});
$r = last_req();
is $r->{'@type'}, 'setGiftSettings', 'set_gift_settings';
is $r->{settings}{'@type'}, 'giftSettings', 'wrapped in giftSettings';
is $r->{settings}{accepted_gift_types}{'@type'}, 'acceptedGiftTypes',
    'with a nested acceptedGiftTypes';
like last_json(), qr/"unlimited_gifts":true/, 'and the flag set';

# --- subscriptions and revenue
$td->star_subscriptions(sub {});
is last_req()->{'@type'}, 'getStarSubscriptions', 'star_subscriptions';

$td->edit_star_subscription('sub_1', 1, sub {});
$r = last_req();
is $r->{'@type'}, 'editStarSubscription', 'edit_star_subscription';
like last_json(), qr/"is_canceled":true/, 'cancelling by default';

$td->reuse_star_subscription('sub_1', sub {});
is last_req()->{'@type'}, 'reuseStarSubscription', 'reuse_star_subscription';

$td->star_revenue_statistics(sub {});
$r = last_req();
is $r->{'@type'}, 'getStarRevenueStatistics', 'star_revenue_statistics';
is $r->{owner_id}{'@type'}, 'messageSenderUser', 'owner defaults to a user sender';

$td->chat_revenue_statistics(-100, sub {});
is last_req()->{'@type'}, 'getChatRevenueStatistics', 'chat_revenue_statistics';

$td->chat_revenue_transactions(-100, sub {});
is last_req()->{'@type'}, 'getChatRevenueTransactions', 'chat_revenue_transactions';

$td->star_payment_options(sub {});
is last_req()->{'@type'}, 'getStarPaymentOptions', 'star_payment_options';

# --- withdrawal needs the account password, so it is explicit about it
$td->star_withdrawal_url(42, 100, 'hunter2', sub {});
$r = last_req();
is $r->{'@type'}, 'getStarWithdrawalUrl', 'star_withdrawal_url';
is $r->{password}, 'hunter2', 'the 2FA password is passed through';

eval { $td->star_withdrawal_url(42, 100, sub {}) };
like $@, qr/password/, 'star_withdrawal_url without a password croaks';

$td->chat_revenue_withdrawal_url(-100, 'hunter2', sub {});
is last_req()->{'@type'}, 'getChatRevenueWithdrawalUrl', 'chat_revenue_withdrawal_url';

# --- affiliate programs take an AffiliateType union
$td->connected_affiliate_programs(sub {});
$r = last_req();
is $r->{'@type'}, 'getConnectedAffiliatePrograms', 'connected_affiliate_programs';
is $r->{affiliate}{'@type'}, 'affiliateTypeCurrentUser', 'affiliate defaults to us';

$td->connected_affiliate_programs(affiliate => { bot => 7 }, sub {});
$r = last_req();
is $r->{affiliate}{'@type'}, 'affiliateTypeBot', 'a bot affiliate coerces';
is $r->{affiliate}{user_id}, 7, 'carrying the bot id';

$td->connected_affiliate_programs(affiliate => { channel => -100 }, sub {});
is last_req()->{affiliate}{'@type'}, 'affiliateTypeChannel', 'a channel affiliate coerces';

$td->connect_affiliate_program(7, sub {});
is last_req()->{'@type'}, 'connectAffiliateProgram', 'connect_affiliate_program';

$td->disconnect_affiliate_program('https://t.me/x', sub {});
is last_req()->{'@type'}, 'disconnectAffiliateProgram', 'disconnect_affiliate_program';

# --- a parse_mode failure must reach the caller, not be embedded in the request
{
    my $n = scalar @sent;
    my $err;
    $td->send_gift('123', 42, text => '*bold', parse_mode => 'markdown',
                   sub { $err = $_[1] });
    is scalar(@sent), $n, 'send_gift sends nothing when the text fails to parse';
    is $err->{'@type'}, 'error', 'and reports the parse error to the caller';
}

done_testing;
