package EV::Telegram::TDLib::Stars;

use strict;
use warnings;
use Carp qw(croak);

our $VERSION = '0.04';

=head1 NAME

EV::Telegram::TDLib::Stars - Telegram Stars methods for EV::Telegram::TDLib

=head1 DESCRIPTION

One of the mixins L<EV::Telegram::TDLib> inherits from. It has no
interface of its own and is not meant to be used directly: loading the
main module loads this one, and its methods are called on a client.

They are documented together with the rest of the API, under
L<EV::Telegram::TDLib/"Stars mixin">.

=cut

sub CLONE_SKIP { 1 }


our %UPDATES;

# gift_id and regular_gift_id are int64 and cross as strings.
# received_gift_id is a TL string already and must not be numified.

my %DIRECTION = (
    incoming => 'transactionDirectionIncoming',
    outgoing => 'transactionDirectionOutgoing',
);

sub affiliate {
    my ($a) = @_;
    return { '@type' => 'affiliateTypeCurrentUser' } unless defined $a;
    return $a if ref $a eq 'HASH' && $a->{'@type'};
    if (ref $a eq 'HASH') {
        return { '@type' => 'affiliateTypeBot',
                 user_id => num('affiliate bot', $a->{bot}) }
            if defined $a->{bot};
        return { '@type' => 'affiliateTypeChannel',
                 chat_id => num('affiliate channel', $a->{channel}) }
            if defined $a->{channel};
    }
    croak "affiliate must be { bot => id } or { channel => id }";
}

# --- gifts

sub available_gifts {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('available_gifts', 0, \@args);
    $self->send({ '@type' => 'getAvailableGifts' }, $cb);
    return;
}

sub can_send_gift {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('can_send_gift', 1, \@args);
    my ($gift_id) = @args;
    need('gift_id', $gift_id);
    $self->send({ '@type' => 'canSendGift',
                  gift_id => plain_text('a gift id', $gift_id) }, $cb);
    return;
}

sub send_gift {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($gift_id, $owner, @rest) = @args;
    my %opt = opts(@rest);
    need('gift_id, owner', $gift_id, $owner);
    my $text = $self->format_text($opt{text}, $opt{parse_mode});
    if (($text->{'@type'} // '') eq 'error') {
        $cb->(undef, $text);
        return;
    }
    $self->send({
        '@type'          => 'sendGift',
        gift_id          => plain_text('a gift id', $gift_id),
        owner_id         => $self->message_sender($owner),
        text             => $text,
        is_private       => json_bool($opt{private}),
        pay_for_upgrade  => json_bool($opt{pay_for_upgrade}),
    }, $cb);
    return;
}

sub received_gift {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('received_gift', 1, \@args);
    my ($id) = @args;
    need('received_gift_id', $id);
    $self->send({ '@type' => 'getReceivedGift',
                  received_gift_id => plain_text('a received gift id', $id) }, $cb);
    return;
}

sub received_gifts {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($owner, @rest) = @args;
    my %opt = opts(@rest);
    need('owner', $owner);
    $self->send({
        '@type'                  => 'getReceivedGifts',
        business_connection_id   => plain_text('a business connection id',
                                               $opt{business_connection_id}),
        owner_id                 => $self->message_sender($owner),
        collection_id            => num('collection_id', $opt{collection_id} // 0),
        exclude_unsaved          => json_bool($opt{exclude_unsaved}),
        exclude_saved            => json_bool($opt{exclude_saved}),
        exclude_unlimited        => json_bool($opt{exclude_unlimited}),
        exclude_upgradable       => json_bool($opt{exclude_upgradable}),
        exclude_non_upgradable   => json_bool($opt{exclude_non_upgradable}),
        exclude_upgraded         => json_bool($opt{exclude_upgraded}),
        exclude_without_colors   => json_bool($opt{exclude_without_colors}),
        exclude_hosted           => json_bool($opt{exclude_hosted}),
        sort_by_price            => json_bool($opt{sort_by_price}),
        offset                   => plain_text('an offset', $opt{offset}),
        limit                    => num('limit', $opt{limit} // 50),
    }, $cb);
    return;
}

sub toggle_gift_saved {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($id, $saved, @rest) = @args;
    no_opts('toggle_gift_saved', @rest);
    need('received_gift_id', $id);
    $self->send({ '@type' => 'toggleGiftIsSaved',
                  received_gift_id => plain_text('a received gift id', $id),
                  is_saved => json_bool(defined $saved ? $saved : 1) }, $cb);
    return;
}

sub sell_gift {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($id, @rest) = @args;
    my %opt = opts(@rest);
    need('received_gift_id', $id);
    $self->send({ '@type' => 'sellGift',
                  business_connection_id =>
                      plain_text('a business connection id',
                                 $opt{business_connection_id}),
                  received_gift_id =>
                      plain_text('a received gift id', $id) }, $cb);
    return;
}

sub upgrade_gift {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($id, @rest) = @args;
    my %opt = opts(@rest);
    need('received_gift_id', $id);
    $self->send({
        '@type'                  => 'upgradeGift',
        business_connection_id   => plain_text('a business connection id',
                                               $opt{business_connection_id}),
        received_gift_id         => plain_text('a received gift id', $id),
        keep_original_details    => json_bool($opt{keep_original_details}),
        star_count               => num('star_count', $opt{star_count} // 0),
    }, $cb);
    return;
}

sub transfer_gift {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($id, $new_owner, @rest) = @args;
    my %opt = opts(@rest);
    need('received_gift_id, new_owner', $id, $new_owner);
    $self->send({
        '@type'                  => 'transferGift',
        business_connection_id   => plain_text('a business connection id',
                                               $opt{business_connection_id}),
        received_gift_id         => plain_text('a received gift id', $id),
        new_owner_id             => $self->message_sender($new_owner),
        star_count               => num('star_count', $opt{star_count} // 0),
    }, $cb);
    return;
}

sub gift_upgrade_preview {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('gift_upgrade_preview', 1, \@args);
    my ($gift_id) = @args;
    need('regular_gift_id', $gift_id);
    $self->send({ '@type' => 'getGiftUpgradePreview',
                  regular_gift_id => plain_text('a gift id', $gift_id) }, $cb);
    return;
}

my %GIFT_SETTING = map { $_ => 1 }
    qw(show_button unlimited limited upgraded from_channels premium_subscription);

sub set_gift_settings {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my %opt = opts(@args);
    if (my @bad = sort grep { !$GIFT_SETTING{$_} } keys %opt) {
        croak "unknown gift setting(s): @bad";
    }
    $self->send({
        '@type'   => 'setGiftSettings',
        settings  => {
            '@type'            => 'giftSettings',
            show_gift_button   => json_bool($opt{show_button}),
            accepted_gift_types => {
                '@type'               => 'acceptedGiftTypes',
                unlimited_gifts       => json_bool($opt{unlimited}),
                limited_gifts         => json_bool($opt{limited}),
                upgraded_gifts        => json_bool($opt{upgraded}),
                gifts_from_channels   => json_bool($opt{from_channels}),
                premium_subscription  => json_bool($opt{premium_subscription}),
            },
        },
    }, $cb);
    return;
}

# --- stars, subscriptions and revenue

sub refund_star_payment {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('refund_star_payment', 2, \@args);
    my ($user_id, $charge_id) = @args;
    need('user_id, telegram_payment_charge_id', $user_id, $charge_id);
    $self->send({ '@type' => 'refundStarPayment', user_id => 0 + $user_id,
                  telegram_payment_charge_id =>
                      plain_text('a charge id', $charge_id) }, $cb);
    return;
}

sub star_transactions {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my %opt = opts(@args);
    my %req = (
        '@type'          => 'getStarTransactions',
        owner_id         => $self->message_sender($opt{owner} // $self->my_id // 0),
        subscription_id  => plain_text('a subscription id', $opt{subscription_id}),
        offset           => plain_text('an offset', $opt{offset}),
        limit            => num('limit', $opt{limit} // 50),
    );
    if (defined $opt{direction}) {
        my $t = $DIRECTION{ $opt{direction} }
            or croak "unknown direction '$opt{direction}'";
        $req{direction} = { '@type' => $t };
    }
    $self->send(\%req, $cb);
    return;
}

sub star_subscriptions {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my %opt = opts(@args);
    $self->send({ '@type' => 'getStarSubscriptions',
                  only_expiring => json_bool($opt{only_expiring}),
                  offset => plain_text('an offset', $opt{offset}) }, $cb);
    return;
}

sub edit_star_subscription {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($id, $canceled, @rest) = @args;
    no_opts('edit_star_subscription', @rest);
    need('subscription_id', $id);
    $self->send({ '@type' => 'editStarSubscription',
                  subscription_id => plain_text('a subscription id', $id),
                  is_canceled => json_bool(defined $canceled ? $canceled : 1) }, $cb);
    return;
}

sub reuse_star_subscription {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('reuse_star_subscription', 1, \@args);
    my ($id) = @args;
    need('subscription_id', $id);
    $self->send({ '@type' => 'reuseStarSubscription',
                  subscription_id => plain_text('a subscription id', $id) }, $cb);
    return;
}

sub star_payment_options {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('star_payment_options', 0, \@args);
    $self->send({ '@type' => 'getStarPaymentOptions' }, $cb);
    return;
}

sub star_revenue_statistics {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my %opt = opts(@args);
    $self->send({ '@type' => 'getStarRevenueStatistics',
                  owner_id => $self->message_sender($opt{owner} // $self->my_id // 0),
                  is_dark => json_bool($opt{dark}) }, $cb);
    return;
}

# withdrawal needs the account's 2FA password, which is why it is a required
# positional rather than an option that could be forgotten
sub star_withdrawal_url {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('star_withdrawal_url', 3, \@args);
    my ($owner, $stars, $password) = @args;
    need('owner, star_count, password', $owner, $stars, $password);
    $self->send({ '@type' => 'getStarWithdrawalUrl',
                  owner_id => $self->message_sender($owner),
                  star_count => num('star_count', $stars),
                  password => plain_text('a password', $password) }, $cb);
    return;
}

sub chat_revenue_statistics {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($chat_id, @rest) = @args;
    my %opt = opts(@rest);
    need('chat_id', $chat_id);
    $self->send({ '@type' => 'getChatRevenueStatistics',
                  chat_id => 0 + $chat_id,
                  is_dark => json_bool($opt{dark}) }, $cb);
    return;
}

sub chat_revenue_transactions {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($chat_id, @rest) = @args;
    my %opt = opts(@rest);
    need('chat_id', $chat_id);
    $self->send({ '@type' => 'getChatRevenueTransactions',
                  chat_id => 0 + $chat_id,
                  offset => plain_text('an offset', $opt{offset}),
                  limit => num('limit', $opt{limit} // 50) }, $cb);
    return;
}

sub chat_revenue_withdrawal_url {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('chat_revenue_withdrawal_url', 2, \@args);
    my ($chat_id, $password) = @args;
    need('chat_id, password', $chat_id, $password);
    $self->send({ '@type' => 'getChatRevenueWithdrawalUrl',
                  chat_id => num('chat_id', $chat_id),
                  password => plain_text('a password', $password) }, $cb);
    return;
}

# --- affiliate programs

sub connected_affiliate_programs {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my %opt = opts(@args);
    $self->send({ '@type' => 'getConnectedAffiliatePrograms',
                  affiliate => affiliate($opt{affiliate}),
                  offset => plain_text('an offset', $opt{offset}),
                  limit => num('limit', $opt{limit} // 50) }, $cb);
    return;
}

sub connect_affiliate_program {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($bot_user_id, @rest) = @args;
    my %opt = opts(@rest);
    need('bot_user_id', $bot_user_id);
    $self->send({ '@type' => 'connectAffiliateProgram',
                  affiliate => affiliate($opt{affiliate}),
                  bot_user_id => 0 + $bot_user_id }, $cb);
    return;
}

sub disconnect_affiliate_program {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($url, @rest) = @args;
    my %opt = opts(@rest);
    need('url', $url);
    $self->send({ '@type' => 'disconnectAffiliateProgram',
                  affiliate => affiliate($opt{affiliate}),
                  url => plain_text('a url', $url) }, $cb);
    return;
}

1;
