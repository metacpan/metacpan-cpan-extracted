# NAME

Finance::Currency::Convert - Convert currencies and fetch their exchange rates

# SYNOPSIS

    use Finance::Currency::Convert;
    my $converter = new Finance::Currency::Convert;

    $amount_euro = $converter->convert(100, "DEM", "EUR");
    $amount_euro = $converter->convertToEUR(100, "DEM");
    $amount_dem = $converter->convertFromEUR(100, "DEM");

    $converter->updateRates("USD");
    $amount_euro = $converter->convertToEUR(100, "USD");

    $converter->setRatesFile(".rates");
    $converter->readRatesFile();
    $converter->writeRatesFile();

# DESCRIPTION

This module converts currencies. It has built in the fixed exchange
rates for all Euro currencies (as of December 2025). If you wish to use other / more
currencies, you can automatically fetch their exchange rates from
the internet and (optionally) store them in a file for later reference.

Use this module if you have large volumes of currency data to convert.
Using the exchange rates from memory makes it a lot faster than
using Finance::Quote directly and will save you the duty of storing
the exchange rates yourself.

## CURRENCY SYMBOLS

Finance::Currency::Convert uses the three character ISO currency codes
used by  Finance::Quote.
Here is a list of currency codes.

Currencies with built-in rates (complete):

        EUR             Euro
        ATS             Austrian Schilling
        BEF             Belgiam Franc
        DEM             German Mark
        ESP             Spanish Peseta
        FIM             Finnish Mark
        FRF             French Franc
        GRD             Greek Drachma
        IEP             Irish Punt
        ITL             Italian Lira
        LUF             Luxembourg Franc
        NLG             Dutch Guilder
        PTE             Portuguese Escudo
        CYP             Cyprus Pound
        MTL             Maltese Lira
        SIT             Slovenian Tolars
        SKK             Swedish Krona
        EEK             Estonian Koon
        LTL             Lithuanian Litas
        LVL             Latvian Lats
        HRK             Croatian Kuna
        BGN             Bulgarian Lev

Other currencies (incomplete):

        AUD             Australian Dollar
        CHF             Swiss Franc
        HKD             Hong Kong Dollar
        JPY             Japanese Yen
        USD             US Dollar

# AVAILABLE METHODS

## NEW

    my $converter = new Finance::Currency::Convert;

The newly created conversion object will by default only know how to
convert Euro currencies. To "teach" it more currencies use updateRate
or updateRates.

## CONVERT

    $amount_euro = $converter->convert(100, "DEM", "EUR");

This will convert 100 German Marks into the equivalent
amount Euro.

## CONVERTTOEURO

    $amount_euro = $converter->convertToEUR(100, "DEM");

This will convert 100 German Marks into the equivalent amount Euro.
This function is simply shorthand for calling convert directly with
"EUR" als the second (target) currency.

## CONVERTFROMEURO

    $amount_dem = $converter->convertFromEUR(100, "DEM");

This will convert 100 Euro into the equivalent amount German Marks.
This function is simply shorthand for calling convert directly with
"EUR" als the first (source) currency.

## UPDATERATES

    $converter->updateRates("USD");
    $converter->updateRates("EUR", "DEM", "USD");

This will fetch the exchange rates for one or more currencies using
Finance::Quote and update the exchange rates in memory.
This method will fetch \_all\_ combinations of exchange rates between
the named currencies and the ones already in memory.
This may result in a large number of requests to Finance::Quote.
To avoid network overhead you can store the retrieved rates with
setRatesFile() / writeRatesFile() once you have retrieved them
and load them again with setRatesFile().

To update a single exchange rate use updateRate.

## UPDATERATE

    $converter->updateRate("EUR, "USD");

This will fetch a single exchange rate using Finance::Quote and
update the exchange rates in memory.

## SETUSERAGENT

        $converter->setUserAgent("MyCurrencyAgent 1.0");

Set the user agent string to be used by Finance::Quote, optional.

## SETRATE

        $converter->setRate("EUR", "USD", 99.99);

Set one exchange rate. Used internally by updateRates,
but may be of use if you have to add a rate manually.

## SETRATESFILE

    $converter->setRatesFile(".rates");

Name the file where exchange rates are stored.

## READRATESFILE

    $converter->readRatesFile();

Read the rates stored in the rates file, overwriting previous values.

## WRITERATESFILE

    $converter->writeRatesFile();

Call this function to save table with exchange rates from memory
to the file named by setRatesFile() eg. after fetching new rates
with updateRates.

# AUTHOR

    Jan Willamowius <jan@willamowius.de>, https://www.willamowius.de/perl.html

# COPYRIGHT AND LICENSE

Copyright 2001 - 2025 by Jan Willamowius

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.30.0 or,
at your option, any later version of Perl 5 you may have available.

# SEE ALSO

Finance::Quote

This module is only needed for fetching exchange rates.
There is no need to install it when only Euro currencies are used.
