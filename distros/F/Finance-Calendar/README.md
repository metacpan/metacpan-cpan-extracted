# NAME

Finance::Calendar - represents the trading calendar.

# SYNOPSIS

    use Finance::Calendar;
    use Date::Utility;

    my $calendar = {
        holidays => {
            '2016-11-01' => ['ASX'],
            '2016-01-01' => ['USD'],
        },
        early_closes => {
            '2016-11-01' => ['HKSE'],
        },
        late_closes => {
            '2016-11-01' => ['HKSE'],
        },
    };
    my $calendar = Finance::Calendar->new(calendar => $calendar);
    my $now = Date::Utility->new;

    # Does London Stocks Exchange trade on $now
    $calendar->trades_on(Finance::Exchange->create_exchange('LSE'), $now);

    # Is it a country holiday for the United States on $now
    $calendar->is_holiday_for('USD', $now);

    # Returns the opening time of Australian Stocks Exchange on $now
    $calendar->opening_on(Finance::Exchange->create_exchange('ASX'), $now);

    # Returns the closing time of Forex on $now
    $calendar->closing_on(Finance::Exchange->create_exchange('FOREX'), $now);
    ...

# DESCRIPTION

This class is responsible for providing trading times or holidays related information of a given financial stock exchange on a specific date.

# ATTRIBUTES - Object Construction

## calendar

A hash reference that has information on:
\- exchange and country holidays
\- late opens
\- early closes

# METHODS - TRADING DAYS RELATED

## trades\_on

\->trades\_on($exchange\_object, $date\_object);

Returns true if trading is done on the day of a given Date::Utility.

## trade\_date\_before

\->trade\_date\_before($exchange\_object, $date\_object);

Returns a Date::Utility object for the previous trading day of an exchange for the given date.

## trade\_date\_after

\->trade\_date\_after($exchange\_object, $date\_object);

Returns a Date::Utility object of the next trading day of an exchange for a given date.

## trading\_date\_for

\->trading\_date\_for($exchange\_object, $date\_object);

The date on which trading is considered to be taking place even if it is not the same as the GMT date.
Note that this does not handle trading dates are offset forward beyond the next day (24h). It will need additional work if these are found to exist.

Returns a Date object representing midnight GMT of the trading date.

## calendar\_days\_to\_trade\_date\_after

\->calendar\_days\_to\_trade\_date\_after($exchange\_object, $date\_object);

Returns the number of calendar days between a given Date::Utility
and the next day on which trading is open.

## trading\_days\_between

\->trading\_days\_between($exchange\_object, Date::Utility->new('4-May-10'),Date::Utility->new('5-May-10'));

Returns the number of trading days \_between\_ two given dates.

## holiday\_days\_between

\->holiday\_days\_between($exchange\_object, Date::Utility->new('4-May-10'),Date::Utility->new('5-May-10'));

Returns the number of holidays \_between\_ two given dates.

# METHODS - TRADING TIMES RELATED.

## is\_open

\->is\_open($exchange\_object);

Returns true is exchange is open now, false otherwise.

## is\_open\_at

\->is\_open\_at($exchange\_object, $epoch);

Return true is exchange is open at the given epoch, false otherwise.

## seconds\_since\_open\_at

\->seconds\_since\_open\_at($exchange\_object, $epoch);

Returns the number of seconds since the exchange opened from the given epoch.

## seconds\_since\_close\_at

\->seconds\_since\_close\_at($exchange\_object, $epoch);

Returns the number of seconds since the exchange closed from the given epoch.

## opening\_on

\->opening\_on($exchange\_object, Date::Utility->new('25-Dec-10')); # returns undef (given Xmas is a holiday)

Returns the opening time (Date::Utility) of the exchange for a given Date::Utility, undefined otherwise.

## closing\_on

\->closing\_on($exchange\_object, Date::Utility->new('25-Dec-10')); # returns undef (given Xmas is a holiday)

Returns the closing time (Date::Utility) of the exchange for a given Date::Utility, undefined otherwise.

## trading\_breaks

\->trading\_breaks($exchange\_object, $date\_object);

Defines the breaktime for this exchange.

## closes\_early\_on

\->closes\_early\_on($exchange\_object, $date\_object);

Returns true if the exchange closes early on the given date.

## opens\_late\_on

\->opens\_late\_on($exchange\_object, $date\_object);

Returns true if the exchange opens late on the given date.

## seconds\_of\_trading\_between\_epochs

\->seconds\_of\_trading\_between\_epochs($exchange\_object, $epoch1, $epoch2);

Get total number of seconds of trading time between two epochs accounting for breaks.

## regular\_trading\_day\_after

\->regular\_trading\_day\_after($exchange\_object, $date\_object);

Returns a Date::Utility object on a trading day where the exchange does not close early or open late after the given date.

## trading\_period

\->trading\_period('HKSE', Date::Utility->new);

Returns an array reference of hash references of open and close time of the given exchange and epoch

## is\_holiday\_for

Check if it is a holiday for a specific exchange or a country on a specific day

\->is\_holiday\_for('ASX', '2013-01-01'); # Australian exchange holiday
\->is\_holiday\_for('USD', Date::Utility->new); # United States country holiday

Returns the description of the holiday if it is a holiday.

## is\_in\_dst\_at

\->is\_in\_dst\_at($exchange\_object, $date\_object);

Is this exchange trading on daylight savings times for the given epoch?

## get\_exchange\_open\_times

Query an exchange for valid opening times. Expects 3 parameters:

- `$exchange` - a [Finance::Exchange](https://metacpan.org/pod/Finance::Exchange) instance
- `$date` - a [Date::Utility](https://metacpan.org/pod/Date::Utility)
- `$which` - which market information to request, see below

The possible values for `$which` include:

- `daily_open`
- `daily_close`
- `trading_breaks`

Returns either `undef`, a single [Date::Utility](https://metacpan.org/pod/Date::Utility), or an arrayref of [Date::Utility](https://metacpan.org/pod/Date::Utility) instances.

---

