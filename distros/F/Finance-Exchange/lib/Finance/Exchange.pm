package Finance::Exchange;

use Moose;

use Time::Duration::Concise::Localize;
use Clone qw(clone);
use File::ShareDir;
use YAML::XS qw(LoadFile);

our $VERSION = '0.01';

=head1 NAME

Finance::Exchange - represents a financial stock exchange object.

=head1 VERSION

version 0.01

=head1 SYNOPSIS

    use Finance::Exchange;

    my $exchange_symbol = 'LSE'; # London Stocks Exchange
    my $exchange = Finance::Exchange->create_exchange($exchange_symbol);

=head1 DESCRIPTION

This is a generic representation of a financial stock exchange.

=head2 USAGE

    my $exchange = Finance::Exchange->create_exchange('LSE');
    is $exchange->symbol, 'LSE';
    is $exchange->display_name, 'London Stock Exchange';
    is $exchange->trading_days, 'weekdays';
    is $exchange->trading_timezone, 'Europe/London';
    # The list of days starts on Sunday and is a set of flags indicating whether
    # we trade on that day or not
    is $exchange->trading_days_list, [ 0, 1, 1, 1, 1, 1, 0 ];
    is $exchange->market_times, { ... };
    is $exchange->delay_amount, 15, 'LSE minimum delay is 15 minutes';
    is $exchange->currency, 'GBP', 'LSE is traded in pound sterling';
    is $exchange->trading_date_can_differ, 0, 'only applies to AU/NZ';
    ...

=cut

my ($cached_objects, $exchange_config, $trading_day_aliases);

BEGIN {
    $exchange_config     = YAML::XS::LoadFile(File::ShareDir::dist_file('Finance-Exchange', 'exchange.yml'));
    $trading_day_aliases = YAML::XS::LoadFile(File::ShareDir::dist_file('Finance-Exchange', 'exchanges_trading_days_aliases.yml'));
}

=head2 create_exchange

Exchange object constructor.

=cut

sub create_exchange {
    my ($class, $symbol) = @_;

    die 'symbol is required' unless $symbol;

    if (my $cached = $cached_objects->{$symbol}) {
        return $cached;
    }

    my $params_ref = clone($exchange_config->{$symbol});
    die 'Config for exchange[' . $symbol . '] not specified in exchange.yml' unless $params_ref;

    $params_ref->{_market_times} = delete $params_ref->{market_times};
    my $new = $class->new($params_ref);
    $cached_objects->{$symbol} = $new;

    return $new;
}

=head1 ATTRIBUTES

=head2 display_name

Exchange display name, e.g. London Stock Exchange.

=head2 symbol

Exchange symbol, e.g. LSE to represent London Stocks Exchange.

=head2 trading_days

An exchange's trading day category.

For example, an exchange that trades from Monday to Friday is given a trading days category of 'weekdays'.

The list is enumerated in the exchanges_trading_days_aliases.yml file.

=head2 trading_timezone

The timezone in which the exchange conducts business.

This should be a string which will allow the standard DateTime module to find the proper information.

=cut

has [
    qw( display_name symbol trading_days trading_timezone
        )
    ] => (
    is       => 'ro',
    required => 1,
    );

has _market_times => (
    is       => 'ro',
    required => 1,
    );

=head2 trading_days_list

List the trading day index which is defined in exchanges_trading_days_aliases.yml.

An example of a 'weekdays' trading days list is as follow:
- 0 # Sun
- 1 # Mon
- 1 # Tues
- 1 # Wed
- 1 # Thurs
- 1 # Fri
- 0 # Sat

=cut

has trading_days_list => (
    is         => 'ro',
    lazy_build => 1,
);

sub _build_trading_days_list {
    my $self = shift;

    return $trading_day_aliases->{$self->trading_days};
}

=head2 market_times

A hash reference of human-readable exchange trading times in Greenwich Mean Time (GMT).

The trading times are broken into three categories:

1. standard - which represents the trading times in non Day Light Saving (DST) period.
  2. dst - which represents the trading time in DST period.
  3. partial_trading - which represents the trading breaks (e.g. lunch break) in a trading day

=cut

has market_times => (
    is         => 'ro',
    lazy_build => 1,
);

sub _build_market_times {
    my $self = shift;

    my $mt = $self->_market_times;
    my $market_times;

    foreach my $key (keys %$mt) {
        foreach my $trading_segment (keys %{$mt->{$key}}) {
            if ($trading_segment eq 'day_of_week_extended_trading_breaks') { next; }
            elsif ($trading_segment ne 'trading_breaks') {
                $market_times->{$key}->{$trading_segment} = Time::Duration::Concise::Localize->new(
                    interval => $mt->{$key}->{$trading_segment},
                );
            } else {
                my $break_intervals = $mt->{$key}->{$trading_segment};
                my @converted;
                foreach my $int (@$break_intervals) {
                    my $open_int = Time::Duration::Concise::Localize->new(
                        interval => $int->[0],
                    );
                    my $close_int = Time::Duration::Concise::Localize->new(
                        interval => $int->[1],
                    );
                    push @converted, [$open_int, $close_int];
                }
                $market_times->{$key}->{$trading_segment} = \@converted;
            }
        }
    }

    return $market_times;
}

=head2 delay_amount

The acceptable delay amount of feed on this exchange, in minutes. Default is 60 minutes.

=cut

has delay_amount => (
    is      => 'ro',
    isa     => 'Num',
    default => 60,
);

=head2 currency

The currency in which the exchange is traded in.

=cut

has currency => (
    is => 'ro',
);

=head2 trading_date_can_differ

A boolean flag to indicate if an exchange would open on the previous GMT date due to DST.

=cut

has trading_date_can_differ => (
    is         => 'ro',
    lazy_build => 1,
);

sub _build_trading_date_can_differ {
    my $self = shift;

    my @premidnight_opens =
        grep { $_->seconds < 0 }
        map  { $self->market_times->{$_}->{daily_open} }
        grep { exists $self->market_times->{$_}->{daily_open} }
        keys %{$self->market_times};
    return (scalar @premidnight_opens) ? 1 : 0;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
