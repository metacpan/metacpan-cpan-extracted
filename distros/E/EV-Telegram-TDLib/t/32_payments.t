use strict;
use warnings;
use Test::More;

BEGIN { $ENV{EV_TDLIB_SHUTDOWN_TIMEOUT} = 0.1 }

use EV;
use EV::Telegram::TDLib;
use Cpanel::JSON::XS;
use MIME::Base64 qw(encode_base64 decode_base64);

my @sent;
{
    no warnings 'redefine';
    *EV::Telegram::TDLib::_send = sub { push @sent, $_[1] };
}
sub last_json { $sent[-1] }
sub last_req  { Cpanel::JSON::XS->new->decode($sent[-1]) }

my $err;
my $td = EV::Telegram::TDLib->new(
    api_id => 1, api_hash => 'x', database_directory => 't/tmp-pay');
$td->{cache}{options}{my_id} = 777;

my %SPEC = (
    title => 'Sticker pack', description => 'Ten stickers',
    payload => 'order-42', currency => 'XTR',
    prices => [ [ 'Pack', 100 ] ],
);

# --- selling for Stars needs no payment provider at all
$td->send_invoice(-100, { %SPEC }, sub {});
my $r = last_req();
is $r->{'@type'}, 'sendMessage', 'send_invoice goes through the normal send path';
my $c = $r->{input_message_content};
is $c->{'@type'}, 'inputMessageInvoice', 'with an inputMessageInvoice content';
is $c->{title}, 'Sticker pack', 'title passed through';
is $c->{invoice}{'@type'}, 'invoice', 'the nested invoice is an invoice object';
is $c->{invoice}{currency}, 'XTR', 'currency passed through';
is $c->{provider_token}, '', 'Stars need no provider token';

my $p = $c->{invoice}{price_parts};
is scalar @$p, 1, 'one price part';
is $p->[0]{'@type'}, 'labeledPricePart', 'typed as a labeledPricePart';
is $p->[0]{label}, 'Pack', 'label passed through';
is $p->[0]{amount}, 100, 'amount passed through';

# the payload is TL bytes and must cross base64 encoded
is decode_base64($c->{payload}), 'order-42', 'the payload is base64 encoded outbound';
unlike last_json(), qr/"payload":"order-42"/, 'and not sent as plain text';

# a hashref price is accepted too
$td->send_invoice(-100, { %SPEC, prices => [ { label => 'A', amount => 5 } ] }, sub {});
is last_req()->{input_message_content}{invoice}{price_parts}[0]{amount}, 5,
    'a hashref price works';

# %opt still reaches the shared send tail
$td->send_invoice(-100, { %SPEC }, silent => 1, sub {});
like last_json(), qr/"disable_notification":true/, 'send options still apply';

$err = do { local $@; eval { $td->send_invoice(-100, { %SPEC, prices => [] }, sub {}) }; $@ };
like $err, qr/at least one price/, 'an invoice with no prices is refused';
$err = do { local $@;
    eval { $td->send_invoice(-100, { %SPEC, prices => 'nope' }, sub {}) }; $@ };
like $err, qr/arrayref/, 'a non-arrayref price list is refused';
$err = do { local $@;
    eval { $td->send_invoice(-100, { %SPEC, title => undef }, sub {}) }; $@ };
like $err, qr/required/, 'a missing title is refused';

# --- invoice link wraps the same content
$td->invoice_link({ %SPEC }, sub {});
$r = last_req();
is $r->{'@type'}, 'createInvoiceLink', 'invoice_link sends createInvoiceLink';
is $r->{invoice}{'@type'}, 'inputMessageInvoice',
    'and nests an inputMessageInvoice, as the slot requires';

# --- answering the checkout queries: empty error approves
$td->answer_pre_checkout_query('918273', sub {});
$r = last_req();
is $r->{'@type'}, 'answerPreCheckoutQuery', 'answer_pre_checkout_query sends its method';
is $r->{pre_checkout_query_id}, '918273', 'the id stays a string';
is $r->{error_message}, '', 'an empty error approves';

$td->answer_pre_checkout_query('918273', error => 'Out of stock', sub {});
is last_req()->{error_message}, 'Out of stock', 'and an error declines';

$td->answer_shipping_query('5', options => [
    { id => 'std', title => 'Standard', prices => [ [ 'Post', 500 ] ] } ], sub {});
$r = last_req();
is $r->{'@type'}, 'answerShippingQuery', 'answer_shipping_query sends its method';
is $r->{shipping_options}[0]{'@type'}, 'shippingOption', 'options are typed';
is $r->{shipping_options}[0]{price_parts}[0]{amount}, 500, 'with their own prices';

$err = do { local $@;
    eval { $td->answer_shipping_query('5', options => [ { id => 'x' } ], sub {}) }; $@ };
like $err, qr/required/, 'an incomplete shipping option is refused';

# --- refunds and the ledger
$td->refund_star_payment(42, 'charge_abc', sub {});
$r = last_req();
is $r->{'@type'}, 'refundStarPayment', 'refund_star_payment sends its method';
is $r->{user_id}, 42, 'user id passed through';

$td->star_transactions(direction => 'incoming', sub {});
$r = last_req();
is $r->{'@type'}, 'getStarTransactions', 'star_transactions sends its method';
is $r->{owner_id}{user_id}, 777, 'defaulting to our own account';
is $r->{direction}{'@type'}, 'transactionDirectionIncoming', 'direction is typed';

$td->star_transactions(sub {});
ok !exists last_req()->{direction}, 'and is omitted when not asked for';

$err = do { local $@; eval { $td->star_transactions(direction => 'sideways', sub {}) }; $@ };
like $err, qr/unknown direction/, 'an unknown direction is refused';

# --- the checkout updates, and the payload asymmetry between them
my (@pre, @ship);
$td->on_pre_checkout_query(sub { push @pre, $_[0] });
$td->on_shipping_query(sub { push @ship, $_[0] });
my $J = Cpanel::JSON::XS->new;

# invoice_payload is TL bytes here, so it arrives base64 and must be decoded
$td->inject_raw($J->encode({ '@type' => 'updateNewPreCheckoutQuery',
    id => '55', sender_user_id => 42, currency => 'XTR', total_amount => 100,
    invoice_payload => encode_base64('order-42', '') }));
is scalar @pre, 1, 'on_pre_checkout_query fired';
is $pre[0]{payload}, 'order-42', 'and the bytes payload was decoded';
is $pre[0]{total_amount}, 100, 'with the amount';

# but it is a plain string in the shipping query, so decoding would corrupt it
$td->inject_raw($J->encode({ '@type' => 'updateNewShippingQuery',
    id => '56', sender_user_id => 42, invoice_payload => 'order-42',
    shipping_address => { country_code => 'DE' } }));
is scalar @ship, 1, 'on_shipping_query fired';
is $ship[0]{payload}, 'order-42', 'the string payload is passed through undecoded';
is $ship[0]{shipping_address}{country_code}, 'DE', 'with the address';

done_testing;
