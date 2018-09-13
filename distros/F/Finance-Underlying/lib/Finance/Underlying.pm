package Finance::Underlying;
# ABSTRACT: Represents an underlying financial asset
use strict;
use warnings;

our $VERSION = '0.004';

=head1 NAME

Finance::Underlying - Object representation of a financial asset

=head1 VERSION

version 0.002

=head1 SYNOPSIS

    use Finance::Underlying;

    my $underlying = Finance::Underlying->by_symbol('frxEURUSD');
    print $underlying->pip_size, "\n";

=head1 DESCRIPTION

Provides metadata on financial assets such as forex pairs.

=cut

use Moo;
use YAML::XS qw(LoadFile);
use Scalar::Util qw(looks_like_number);
use File::ShareDir ();

my %underlyings;

=head1 CLASS METHODS

=head2 pipsized_value

Return a string pipsized to the correct number of decimal point

->pipsized_value(100);

=head2 all_underlyings

Returns a list of all underlyings, ordered by symbol.

=cut

sub pipsized_value {
    my ($self, $value, $custom) = @_;

    my $display_decimals =
        $custom
        ? log(1 / $custom) / log(10)
        : log(1 / $self->pip_size) / log(10);
    if (defined $value and looks_like_number($value)) {
        $value = sprintf '%.' . $display_decimals . 'f', $value;
    }
    return $value;
}

sub all_underlyings {
    map { $underlyings{$_} } sort keys %underlyings;
}

=head2 symbols

Return sorted list of all symbols.

=cut

sub symbols {
    return sort keys %underlyings;
}

=head2 by_symbol

Look up the underlying for the given symbol, returning a L<Finance::Underlying> instance.

=cut

sub by_symbol {
    my (undef, $symbol) = @_;

    $symbol =~ s/^FRX/frx/i;
    $symbol =~ s/^RAN/ran/i;
    return $underlyings{$symbol} // die "unknown underlying $symbol";
}

=head1 ATTRIBUTES

=head2 asset

The asset being quoted, for example C<USD> for the C<frxUSDJPY> underlying.

=cut

has asset => (
    is       => 'ro',
    required => 1,
);

=head2 display_name

User-friendly English name used for display purposes.

=cut

has display_name => (
    is => 'ro',
);

=head2 exchange_name

The symbol of the exchange this underlying is traded on.

See C<Finance::Exchange>. for more details.

=cut

has exchange_name => (
    is => 'ro',
);

=head2 instrument_type

Categorises the underlying, available values are:

=over 4

=item * commodities

=item * forex

=item * future

=item * smart_fx

=item * stockindex

=item * synthetic

=back

=cut

has instrument_type => (
    is => 'ro',
);

=head2 market

The type of market for this underlying, for example C<forex> for foreign exchange.

This will be one of the following:

=over 4

=item * commodities

=item * forex

=item * futures

=item * indices

=item * volidx

=back

=cut

has market => (
    is => 'ro',
);

=head2 market_convention

These should mirror Bloomberg's Composite vol data conventions.

For further information, see C<Foreign Exchange option pricing>, by Iain J Clark, pages
47 onwards.

Types of volatility conventions available:

=head3 atm_setting

There are three types:

=over 4

=item * B<atm_delta_neutral_straddle> - strike so that call delta = -put delta

=item * B<atm_forward> - strike = forward price

=item * B<atm_spot> - strike = spot

=back

=head3 delta_premium_adjusted

There are two types:

=over 4

=item * 1 for premium adjusted . Premium adjusted means the actual hedge
quantity must be adjusted by the premium received if the premium is
paid in foreign currency.

=item * 0 for no premium adjusted - for futher explanation please refer to Wystup C<FX Volatility Smile Construction> April 2010 paper, pg 5 and 6.

=back

=head3 delta_style

There are two delta convention available:

=over 4

=item * B<spot_delta> - with a hedge in the spot market.

=item * B<forward_delta> - with a hedge in FX forward market

=back

=head3 rr

Risk reversal:

=over 4

=item * call-put

=item * put-call

=back

=head3 bf

There are three types of butterfly available in Bloomberg setting:

=over 4

=item * B<(call+put)/2-atm>  (which is quoted 1 vol strangle for Composite
sources and 2 vol (a.k.a smile strangle) for BGN sources)

=item * B<Base currency strangle> - ATM (which is (base currency call + base
currency put)- ATM)

=item * B<Foreign currency strangle> - ATM (which is (foreign currency call +
foreign currency put)- ATM)

=back

=cut

has market_convention => (
    is => 'ro',
);

=head2 pip_size

How large the spot pip is.

=cut

has pip_size => (
    is => 'ro',
);

=head2 quoted_currency

The second half of a forex pair - indicates the currency that this underlying is quoted in,
or the currency in which a stock index is quoted.

=cut

has quoted_currency => (
    is => 'ro',
);

=head2 submarket

Classification for the underlying, see also L</market>.

=cut

has submarket => (
    is => 'ro',
);

=head2 symbol

The symbol of the underlying, for example C<frxUSDJPY> or C<WLDAUD>.

=cut

has symbol => (
    is => 'ro',
);

{
    my $param = LoadFile(File::ShareDir::dist_file('Finance-Underlying', 'underlyings.yml'));
    %underlyings = map { ; $_ => __PACKAGE__->new($param->{$_}) } keys %$param;
}

1;

=head1 SEE ALSO

=over 4

=item * L<Finance::Contract> - represents a financial contract

=back

=head1 AUTHOR

binary.com

=cut
