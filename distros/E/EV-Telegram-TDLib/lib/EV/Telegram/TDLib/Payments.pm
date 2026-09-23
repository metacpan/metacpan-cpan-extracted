package EV::Telegram::TDLib::Payments;

use strict;
use warnings;
use Carp qw(croak);
use MIME::Base64 ();

our $VERSION = '0.04';

=head1 NAME

EV::Telegram::TDLib::Payments - payment methods for EV::Telegram::TDLib

=head1 DESCRIPTION

One of the mixins L<EV::Telegram::TDLib> inherits from. It has no
interface of its own and is not meant to be used directly: loading the
main module loads this one, and its methods are called on a client.

They are documented together with the rest of the API, under
L<EV::Telegram::TDLib/"Payments mixin">.

=cut

sub CLONE_SKIP { 1 }


our %UPDATES = (
    updateNewPreCheckoutQuery => \&update_pre_checkout,
    updateNewShippingQuery    => \&update_shipping,
);

# The invoice payload is the seller's own order id, handed back at checkout.
# It is TL bytes in inputMessageInvoice and in updateNewPreCheckoutQuery, but a
# plain string in updateNewShippingQuery -- encoding all three alike corrupts
# the shipping one, so each is handled on its own terms.
sub update_pre_checkout {
    my ($self, $obj) = @_;
    my $cb = $self->{on_pre_checkout_query} or return;
    $cb->({
        id              => $obj->{id},
        sender_user_id  => $obj->{sender_user_id},
        currency        => $obj->{currency},
        total_amount    => $obj->{total_amount},
        payload         => MIME::Base64::decode_base64($obj->{invoice_payload} // ''),
        shipping_option_id => $obj->{shipping_option_id},
        order_info      => $obj->{order_info},
    });
}

sub update_shipping {
    my ($self, $obj) = @_;
    my $cb = $self->{on_shipping_query} or return;
    $cb->({
        id                => $obj->{id},
        sender_user_id    => $obj->{sender_user_id},
        payload           => $obj->{invoice_payload},
        shipping_address  => $obj->{shipping_address},
    });
}

sub on_pre_checkout_query {
    my ($self, $cb) = @_;
    $self->{on_pre_checkout_query} = $cb if @_ > 1;
    return $self->{on_pre_checkout_query};
}

sub on_shipping_query {
    my ($self, $cb) = @_;
    $self->{on_shipping_query} = $cb if @_ > 1;
    return $self->{on_shipping_query};
}

sub price_parts {
    my ($prices) = @_;
    croak 'prices must be an arrayref' unless ref $prices eq 'ARRAY';
    croak 'an invoice needs at least one price' unless @$prices;
    return [ map {
        my ($label, $amount) = ref $_ eq 'ARRAY'  ? @$_
                             : ref $_ eq 'HASH'   ? @{$_}{qw(label amount)}
                             : croak 'each price must be an arrayref or hashref';
        croak 'each price needs a label and an amount'
            unless defined $label && defined $amount;
        { '@type' => 'labeledPricePart', label => plain_text('a price label', $label),
          amount => num('price amount', $amount) };
    } @$prices ];
}

# Amounts are in the currency's smallest unit -- cents, not euros -- except for
# XTR, where one unit is one Star. Selling digital goods for Stars needs no
# payment provider at all, so provider_token stays empty.
sub invoice_content {
    my ($spec) = @_;
    croak 'send_invoice needs a hashref describing the invoice'
        unless ref $spec eq 'HASH';
    need('title, description, payload, currency, prices',
          @{$spec}{qw(title description payload currency prices)});
    return {
        '@type'      => 'inputMessageInvoice',
        invoice      => {
            '@type'                => 'invoice',
            currency               => plain_text('a currency', $spec->{currency}),
            price_parts            => price_parts($spec->{prices}),
            max_tip_amount         => num('max_tip', $spec->{max_tip} // 0),
            suggested_tip_amounts  => num_list('tips', $spec->{tips} // []),
            is_test                => json_bool($spec->{test}),
            need_name              => json_bool($spec->{need_name}),
            need_phone_number      => json_bool($spec->{need_phone}),
            need_email_address     => json_bool($spec->{need_email}),
            need_shipping_address  => json_bool($spec->{need_shipping}),
            send_phone_number_to_provider => json_bool($spec->{send_phone_to_provider}),
            send_email_address_to_provider => json_bool($spec->{send_email_to_provider}),
            is_flexible            => json_bool($spec->{flexible}),
        },
        title           => plain_text('a title', $spec->{title}),
        description     => plain_text('a description', $spec->{description}),
        photo_url       => plain_text('a photo url', $spec->{photo_url}),
        photo_size      => num('photo_size',   $spec->{photo_size}   // 0),
        photo_width     => num('photo_width',  $spec->{photo_width}  // 0),
        photo_height    => num('photo_height', $spec->{photo_height} // 0),
        payload         => tl_bytes('invoice payload', $spec->{payload}),
        provider_token  => plain_text('a provider token', $spec->{provider_token}),
        provider_data   => plain_text('provider data', $spec->{provider_data}),
        start_parameter => plain_text('a start parameter', $spec->{start_parameter}),
    };
}

sub send_invoice {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($chat_id, $spec, @rest) = @args;
    my %opt = opts(@rest);
    need('chat_id, invoice', $chat_id, $spec);
    $self->send_content($chat_id, invoice_content($spec), \%opt, $cb);
    return;
}

sub invoice_link {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($spec, @rest) = @args;
    my %opt = opts(@rest);
    need('invoice', $spec);
    $self->send({
        '@type'                  => 'createInvoiceLink',
        business_connection_id   => plain_text('a business connection id',
                                               $opt{business_connection_id}),
        invoice                  => invoice_content($spec),
    }, $cb);
    return;
}

# An empty error approves. Telegram gives a bot seconds to answer, and an
# unanswered query fails the payment, so answer from the handler.
sub answer_pre_checkout_query {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($id, @rest) = @args;
    my %opt = opts(@rest);
    need('pre_checkout_query_id', $id);
    $self->send({ '@type' => 'answerPreCheckoutQuery',
                  pre_checkout_query_id =>
                      plain_text('a pre-checkout query id', $id),
                  error_message => plain_text('an error message', $opt{error}) }, $cb);
    return;
}

sub answer_shipping_query {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($id, @rest) = @args;
    my %opt = opts(@rest);
    need('shipping_query_id', $id);
    my $list = $opt{options} // [];
    croak 'options must be an arrayref of shipping options'
        unless ref $list eq 'ARRAY';
    my @options;
    for my $o (@$list) {
        croak 'each shipping option must be a hashref' unless ref $o eq 'HASH';
        need('shipping option id, title, prices', @{$o}{qw(id title prices)});
        push @options, { '@type' => 'shippingOption',
                         id    => plain_text('a shipping option id', $o->{id}),
                         title => plain_text('a shipping option title', $o->{title}),
                         price_parts => price_parts($o->{prices}) };
    }
    $self->send({ '@type' => 'answerShippingQuery',
                  shipping_query_id => plain_text('a shipping query id', $id),
                  shipping_options  => \@options,
                  error_message     => plain_text('an error message', $opt{error}) }, $cb);
    return;
}

1;
