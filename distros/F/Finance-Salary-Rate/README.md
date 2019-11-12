# DESCRIPTION

A calculator to calculate hourly rates for small businesses and the likes.
Based on the Dutch
[Ondernemersplein](https://ondernemersplein.kvk.nl/voorbeeld-uurtarief-berekenen/)
method.

# SYNOPSIS

    my $rate = Finance::Salary::Rate->new(
        monthly_income       => 1750,
        vacation_perc        => 8,
        tax_perc             => 30,
        healthcare_perc      => 5.7,
        declarable_days_perc => 60,
        days                 => 230,
        expenses             => 2000,
    );

    print "My hourly rate is " . $rate->hourly_rate;

# ATTRIBUTES

## income

The monthly income you want to receive. Required.

## vacation\_perc

The percentage of what you want to pay yourself for vacation money. Optional.

## tax\_perc

The percentage of taxes you need to set aside for the government. Optional.

## healthcare\_perc

The percentage of income you need to set aside for health care insureance.
Optional.

## healthcare\_perc

The percentage of income you need to set aside for health care insureance.
Optional.

## declarable\_days\_perc

The percentage of declarable days per week. Optional and defaults to 60%.

## working\_days

The total amount of working days in a year. Optional and defaults to 230.

## expenses

Estimated expenses per year. Optional.

# METHODS

## monthly\_income

Returns the montly income

## yearly\_income

Returns the yearly income

## weekly\_income

Returns the weekly income

## 
