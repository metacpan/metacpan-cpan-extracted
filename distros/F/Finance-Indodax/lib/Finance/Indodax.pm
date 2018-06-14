package Finance::Indodax;

our $DATE = '2018-06-13'; # DATE
our $VERSION = '0.011'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

use Digest::SHA qw(hmac_sha512_hex);
use Time::HiRes qw(time);

my $url_prefix = "https://indodax.com";

sub new {
    my ($class, %args) = @_;

    my $self = {};
    if (my $key = delete $args{key}) {
        $self->{key} = $key;
    }
    if (my $secret = delete $args{secret}) {
        $self->{secret} = $secret;
    }
    if (keys %args) {
        die "Unknown argument(s): ".join(", ", sort keys %args);
    }

    require HTTP::Tiny;
    $self->{_http} = HTTP::Tiny->new;

    require JSON::XS;
    $self->{_json} = JSON::XS->new;

    require URI::Encode;
    $self->{_urienc} = URI::Encode->new;

    bless $self, $class;
}

sub _get_json {
    my ($self, $url) = @_;

    log_trace("JSON API request: %s", $url);

    my $res = $self->{_http}->get($url);
    die "Can't retrieve $url: $res->{status} - $res->{reason}"
        unless $res->{success};
    my $decoded;
    eval { $decoded = $self->{_json}->decode($res->{content}) };
    die "Can't decode response from $url: $@" if $@;

    log_trace("JSON API response: %s", $decoded);

    $decoded;
}

sub tapi {
    my ($self, $method, %args) = @_;

    $self->{key} or die "Please supply API key in new()";
    $self->{secret} or die "Please supply API secret in new()";

    my $time = time();
    my $form = {
        %args,
        method => $method,
        # ms after 2015-01-01
        nonce => int(1000 * (time() - 1_420_045_200)),
    };

    log_trace("TAPI request: %s", $form);

    my $encoded_form = join(
        "&",
        map { $self->{_urienc}->encode($_ // ''). "=" .
                  $self->{_urienc}->encode($form->{$_} // '') }
            sort keys(%$form),
    );

    my $options = {
        headers => {
            Key => $self->{key},
            Sign => hmac_sha512_hex($encoded_form, $self->{secret}),

            # XXX why do i have to do this manually?
            "Content-Length" => length($encoded_form),
            "Content-Type" => "application/x-www-form-urlencoded",
        },
        content => $encoded_form,
    };

    my $url = "$url_prefix/tapi/";
    my $res = $self->{_http}->post($url, $options);
    die "Can't retrieve $url: $res->{status} - $res->{reason}"
        unless $res->{success};
    my $decoded;
    eval { $decoded = $self->{_json}->decode($res->{content}) };
    die "Can't decode response from $url: $@" if $@;

    log_trace("TAPI response: %s", $decoded);

    die "API response not a hash: $decoded" unless ref $decoded eq 'HASH';
    die "API response is not success: $decoded->{error}" unless $decoded->{success};
    $decoded;
}

sub _check_pair {
    my $pair = shift;
    $pair =~ /\A(\w{3,5})_(\w{3,5})\z/
        or die "Invalid pair: must be in the form of 'abc_xyz'";
}

sub get_ticker {
    my ($self, %args) = @_;
    $args{pair} //= "btc_idr";
    _check_pair($args{pair});
    $self->_get_json("$url_prefix/api/$args{pair}/ticker");
}

sub get_trades {
    my ($self, %args) = @_;
    $args{pair} //= "btc_idr";
    _check_pair($args{pair});

    $self->_get_json("$url_prefix/api/$args{pair}/trades");
}

sub get_depth {
    my ($self, %args) = @_;
    $args{pair} //= "btc_idr";
    _check_pair($args{pair});

    $self->_get_json("$url_prefix/api/$args{pair}/depth");
}

sub get_price_history {
    my ($self, %args) = @_;
    $args{pair} //= "btc_idr"; # note: pair other than btc_idr does not seem to be supported
    _check_pair($args{pair});
    $args{period} //= 'day';
    $args{period} =~ /\A(day|all)\z/
        or die "Invalid period: must be day|all";

    if ($args{period} eq 'all') {
        $self->_get_json("$url_prefix/api/$args{pair}/chartdata");
    } else {
        $self->_get_json("$url_prefix/api/$args{pair}/chart_1d");
    }
}

sub get_info {
    my ($self, %args) = @_;
    $self->tapi("getInfo");
}

sub get_tx_history {
    my ($self, %args) = @_;
    $self->tapi("transHistory");
}

sub get_trade_history {
    my ($self, %args) = @_;
    die "Please specify pair" unless $args{pair};
    $self->tapi(
        "tradeHistory",
        count   => $args{count},
        from_id => $args{from_id},
        end_id  => $args{end_id},
        order   => $args{order},
        since   => $args{since},
        end     => $args{end},
        pair    => $args{pair},
    );
}

sub get_open_orders {
    my ($self, %args) = @_;
    $self->tapi(
        "openOrders",
        (pair    => $args{pair}) x !!$args{pair},
    );
}

sub get_order {
    my ($self, %args) = @_;
    die "Please specify pair" unless $args{pair};
    $self->tapi(
        "getOrder",
        pair     => $args{pair},
        order_id => $args{order_id},
    );
}

sub create_order {
    my ($self, %args) = @_;
    die "Please specify pair" unless $args{pair};
    my ($basecur, $quotecur) = $args{pair} =~ /(.+)_(.+)/ or die "Invalid pair syntax, please use BASE_QUOTE";
    die "Please specify type" unless $args{type};
    die "Type can only be buy/sell" unless $args{type} eq 'buy' || $args{type} eq 'sell';
    die "Please specify price" unless $args{price};

    # in indodax, when we buy we specify the amount/size in the quote currency,
    # e.g. if pair is btc_idr we specify the amount in idr.
    die "Please specify $quotecur" if $args{type} eq 'buy' && !defined($args{$quotecur});

    # on the other hand, when we sell we specify the amount/size in the base
    # currency, e.g. if pair is btc_idr we specify the amount in btc to sell.
    die "Please specify $basecur" if $args{type} eq 'sell' && !defined($args{$basecur});

    $self->tapi(
        "trade",
        pair    => $args{pair},
        type    => $args{type},
        price   => $args{price},
        ($quotecur => $args{$quotecur}) x !!($args{type} eq 'buy'),
        ($basecur  => $args{$basecur} ) x !!($args{type} eq 'sell'),
    );
}

sub cancel_order {
    my ($self, %args) = @_;
    die "Please specify order_id" unless $args{order_id};
    die "Please specify type" unless $args{type};
    die "Type can only be buy/sell" unless $args{type} eq 'buy' || $args{type} eq 'sell';
    $self->tapi(
        "cancelOrder",
        order_id => $args{order_id},
        pair     => $args{pair},
        type     => $args{type},
    );
}

1;
# ABSTRACT: Trade with Indodax.com using Perl

__END__

=pod

=encoding UTF-8

=head1 NAME

Finance::Indodax - Trade with Indodax.com using Perl

=head1 VERSION

This document describes version 0.011 of Finance::Indodax (from Perl distribution Finance-Indodax), released on 2018-06-13.

=head1 SYNOPSIS

 use Finance::Indodax;

 # API key and secret are required unless you only want to access the public
 # API. They can be retrieved by logging into your Indodax account and

 my $indodax = Finance::Indodax->new(
     key    => 'Your API key',
     secret => 'Your API secret',
 );

 ## public API methods, these do not require API key & secret

 my $ticker = $indodax->get_ticker();
 # sample result:
 {
   ticker => {
     buy => 34381600,
     high => 34890000,
     last => 34381600,
     low => 34200000,
     sell => 34431800,
     server_time => 1496219814,
     vol_btc => 506.37837851,
     vol_idr => 17409110187,
   },
 }

 my $trades = $indodax->get_trades();
 # sample result:
 [
   {
     date => 1496220665,
     price => 34395100,
     amount => 0.00090000,
     tid => 2222043,
     type => "sell",
   },
   {
     date => 1496220574,
     price => 34422400,
     amount => 0.00879473,
     tid => 2222042,
     type => "buy",
   },
   ... # about 148 more
 ]

 my $depths = $indodax->get_depth();
 # sample result:
 {
   buy => [
     [34397100,"0.07656322"],
     [34397000,"0.21483687"],
     # ... about 148 more
   ],
   sell => [
     [034499900, "0.00150273"],
     [034500000, "0.94493067"],
     # ... about 148 more
   ],
 }

 my $prices = $indodax->get_price_history();
 # sample result:
 {
   chart => [
     [1392397200000,8024000,8024000,7580000,7803000,5.90],  # 2014-02-15
     [1392483600000,7803000,7934000,7257000,7303000,11.35], # 2014-02-16
     ...
   ],
 }

 ## all the methods below requires API key & secret

 $indodax->get_info();

 $indodax->get_tx_history();

 $indodax->get_trade_history(pair => "btc_idr");

 # create buy order of Rp 2,000,000 worth of bitcoins at price Rp 38,400,000/BTC
 $indodax->create_order(pair => "btc_idr", type => "buy" , price => "38400000", idr => "2000000");

 # create sell order of 0.01 BTC at price Rp 38,700,000/BTC
 $indodax->create_order(pair => "btc_idr", type => "sell", price => "38700000", btc => 0.01);

 $indodax->cancel_order(type => "sell", order_id => 9038293);

=head1 DESCRIPTION

Indodax, L<https://www.indodax.com> (previously Bitcoin Indonesia,
bitcoin.co.id) is an Indonesian Bitcoin exchange. This module provides a Perl
wrapper for Indodax's Trade API.

=head1 METHODS

=head2 new

Constructor.

=head2 get_ticker

Public API. The API method name is C<ticker>.

Arguments:

=over

=item * pair => str

Optional, e.g. eth_btc. Default: btc_idr.

=back

=head2 get_trades

Public API. The API method name is C<ticker>.

Arguments:

=over

=item * pair => str

Optional, e.g. eth_btc. Default: btc_idr.

=back

=head2 get_depth

Public API. The API method name is C<ticker>.

Arguments:

=over

=item * pair => str

Optional, e.g. eth_btc. Default: btc_idr.

=back

=head2 get_price_history

Public API (undocumented). The API method name is either C<chartdata> or
C<chart_1d>.

This function returns an array of records. Each record is an array with the
following data:

 [timestamp-in-unix-epoch, open, high, low, close]

Arguments:

=over

=item * pair => str

Optional, e.g. eth_btc. Default: btc_idr.

Note: pairs other than "btc_idr" do not seem to be supported at this time (404
response).

=item * period => str (all|day, default: day)

Specify period. C<all> means since exchange began operation (Feb 2014). C<day>
means in the last ~24h.

=back

=head2 tapi

General method to call API methods. Syntax:

 $indodax->tapi($method, %args)

For example:

 $indodax->tapi("getInfo")

is equivalent to:

 $indodax->get_info()

=head2 get_info

This method give information about balance and server's timestamp. The API
method name is C<getInfo>.

Arguments:

=over

=back

=head2 get_tx_history

This method give information about history of deposit and withdraw. The API
method name is C<transHistory>.

Arguments:

=over

=back

=head2 get_trade_history

This method give information about bitcoin transaction in buying and selling
history. The API method name is C<tradeHistory>.

Arguments:

=over

=item * count => int

=item * from_id => int

=item * to_id => int

=item * order => "asc" | "desc"

=item * since => epoch

=item * end => epoch

=item * pair => str (required)

=back

=head2 get_open_orders

This method give information about existing open order. The API method name is
C<openOrders>.

Arguments:

=over

=item * pair => str (required)

=back

=head2 create_order

This method use to make a new order. The API method name is C<trade>.

Arguments:

=over

=item * pair => str (required)

=item * type => str (required)

Either "buy" or "sell".

=item * price => num (required)

Price (in Rp) per bitcoin.

=item * idr => num (required when type=buy)

Amount of IDR you want to buy.

=item * btc => num (required when type=sell)

Amount of BTC you want to sell.

=back

=head2 cancel_order

This method cancel existing open order. The API method name is C<cancelOrder>.

Arguments:

=over

=item * pair => pair (required)

=item * type => str (required)

Either "buy" or "sell".

=item * order_id => num (required)

=back

=head2 get_order

Get information about a specific order. The API method name is C<getOrder>.

Arguments:

=over

=item * pair => str (required)

=item * order_id => num (required)

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Finance-Indodax>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Finance-BTCIndo>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Finance-Indodax>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

API documentation, L<https://vip.bitcoin.co.id/downloads/BITCOINCOID-API-DOCUMENTATION.pdf>

CLI that uses this module, for more convenience daily usage on the command-line:
L<indodax> (from L<App::indodax> distribution).

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018, 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
