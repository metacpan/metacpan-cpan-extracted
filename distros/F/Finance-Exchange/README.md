# NAME

Finance::Exchange - represents a financial stock exchange object.

# VERSION

version 0.01

# SYNOPSIS

    use Finance::Exchange;

    my $exchange_symbol = 'LSE'; # London Stocks Exchange
    my $exchange = Finance::Exchange->create_exchange($exchange_symbol);

# DESCRIPTION

This is a generic representation of a financial stock exchange.

## USAGE

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

## create\_exchange

Exchange object constructor.

# ATTRIBUTES

## display\_name

Exchange display name, e.g. London Stock Exchange.

## symbol

Exchange symbol, e.g. LSE to represent London Stocks Exchange.

## trading\_days

An exchange's trading day category.

For example, an exchange that trades from Monday to Friday is given a trading days category of 'weekdays'.

The list is enumerated in the exchanges\_trading\_days\_aliases.yml file.

## trading\_timezone

The timezone in which the exchange conducts business.

This should be a string which will allow the standard DateTime module to find the proper information.

## trading\_days\_list

List the trading day index which is defined in exchanges\_trading\_days\_aliases.yml.

An example of a 'weekdays' trading days list is as follow:
\- 0 # Sun
\- 1 # Mon
\- 1 # Tues
\- 1 # Wed
\- 1 # Thurs
\- 1 # Fri
\- 0 # Sat

## market\_times

A hash reference of human-readable exchange trading times in Greenwich Mean Time (GMT).

The trading times are broken into three categories:

1\. standard - which represents the trading times in non Day Light Saving (DST) period.
  2. dst - which represents the trading time in DST period.
  3. partial\_trading - which represents the trading breaks (e.g. lunch break) in a trading day

## delay\_amount

The acceptable delay amount of feed on this exchange, in minutes. Default is 60 minutes.

## currency

The currency in which the exchange is traded in.

## trading\_date\_can\_differ

A boolean flag to indicate if an exchange would open on the previous GMT date due to DST.
