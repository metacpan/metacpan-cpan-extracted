#!/usr/bin/perl
#
#	Copyright (C) 2000-2010, Jan Willamowius <jan@willamowius.de>, http://www.willamowius.de/
#	All rights reserved.
#	This is free software; you can redistribute it and/or
#	modify it under the same terms as Perl itself.
#

package Finance::Currency::Convert;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;
require AutoLoader;

@ISA = qw(Exporter AutoLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(
	
);
$VERSION = '1.08';

my %EuroRates = (
         BEF => {EUR=>0.0247899055505,   BEF => 1},
         DEM => {EUR=>0.511291881196,	 DEM => 1},
         ESP => {EUR=>0.00601012104384,  ESP => 1},
         EUR => {ATS=>13.7603, BEF=>40.3399, DEM=>1.95583, EUR=>1, ESP=>166.386, FIM=>5.94573, FRF=>6.55957, GRD=>340.750, IEP=>.787564, ITL=>1936.27, LUF=>40.3399, NLG=>2.20371, PTE=>200.482, CYP=>0.585274, MTL=>0.429300, SIT=>239.640, SKK=>30.1260, EEK=>15.6466}, 
         FRF => {EUR=>0.152449017237, 	 FRF => 1},
         GRD => {EUR=>0.00293470286134,  GRD => 1},
         IEP => {EUR=>1.26973807843, 	 IEP => 1},
         ITL => {EUR=>0.000516456899089, ITL => 1},    
         LUF => {EUR=>0.0247899055505,   LUF => 1},
         NLG => {EUR=>0.45378021609, 	 NLG => 1},
         ATS => {EUR=>0.0726728341679,   ATS => 1},
         PTE => {EUR=>0.00498797897068,  PTE => 1},
         FIM => {EUR=>0.168187926462,	 FIM => 1},
         CYP => {EUR=>1.70860144137618,  CYP => 1},
         MTL => {EUR=>2.32937339855579,  MTL => 1},
         SIT => {EUR=>0.00417292605575029, SIT => 1},
         SKK => {EUR=>0.0331939188740623,  SKK => 1},
         EEK => {EUR=>0.0639116485371,  EEK => 1},
		                  );

sub new() {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = {};
	$self->{CurrencyRates} = \%EuroRates;
	$self->{RatesFile} = undef;
	$self->{UserAgent} = "Finance::Currency::Convert $VERSION";
	bless($self, $class);
	return $self;
}

sub setRate() {
	my $self = shift;
	my $source = shift;
	my $target = shift;
	my $rate = shift;
	$self->{CurrencyRates}{$source}{$target} = $rate;
}

sub setRatesFile() {
	my $self = shift;
	$self->{RatesFile} = shift;
	$self->readRatesFile();
}

sub readRatesFile() {
	my $self = shift;
	return if (!defined $self->{RatesFile});

	open(RATES, "<$self->{RatesFile}") or return;
	$self->{CurrencyRates} = (); # clear current table
	while(local $_ = <RATES>) {
		my ($source, $targetrates) = split(/\|/, $_);
		foreach my $target (split(/\:/, $targetrates)) {
			my @pieces = split(/\=/, $target);
			if (scalar(@pieces) > 1) {
				$self->setRate($source, $pieces[0], $pieces[1]);
			}
		}
	}
	close(RATES);
}

sub writeRatesFile() {
	my $self = shift;
	return if (!defined $self->{RatesFile});

	open(RATES, ">$self->{RatesFile}") or return;
	foreach my $sourcerate (sort keys %{$self->{CurrencyRates}}) {
		print RATES "$sourcerate|";
		foreach my $targetrate (sort keys %{ $self->{CurrencyRates}{$sourcerate}}) {
			print RATES "$targetrate=" . $self->{CurrencyRates}{$sourcerate}{$targetrate} . ":";
		};
		print RATES "\n";
	};
	close(RATES);
}

sub updateRates() {
	my $self = shift;
	my @CurrencyList = @_;
	# test if Finance::Quote is available
	eval { require Finance::Quote; };
	if ($@) {
		warn "Finance::Quote not installed - can't use updateRates()\n";
		return;
	};
	# get the exchange rates
	my $q = Finance::Quote->new;
	$q->user_agent->agent($self->{UserAgent});
	foreach my $source (@CurrencyList) {
		foreach my $target (sort keys %{ $self->{CurrencyRates}}) {
			$self->setRate($source, $target, $q->currency($source, $target));
		}
	}
	foreach my $source (sort keys %{ $self->{CurrencyRates}}) {
		foreach my $target (@CurrencyList) {
			$self->setRate($source, $target, $q->currency($source, $target));
		}
	}
}

sub updateRate() {
	my $self = shift;
	my $source = shift;
	my $target = shift;
	# Test if Finance::Quote is available
	eval { require Finance::Quote; };
	if ($@) { return; };    # F::Q not installed
	# get the exchange rates
	my $q = Finance::Quote->new;
	$q->user_agent->agent($self->{UserAgent});
	$self->setRate($source, $target, $q->currency($source, $target));
}

sub setUserAgent() {
	my $self = shift;
	$self->{UserAgent} = shift;
}

sub convert() {
	my $self = shift;
	my $amount = shift;
	my $source = shift;
	my $target = shift;
	return $amount * $self->{CurrencyRates}->{$source}{$target};
}

sub convertFromEUR() {
	my $self = shift;
	my $amount = shift;
	my $target = shift;
	return $self->convert($amount, "EUR", $target);
}

sub convertToEUR() {
	my $self = shift;
	my $amount = shift;
	my $source = shift;
	return $self->convert($amount, $source, "EUR");
}

1;

__END__

=pod

=head1 NAME

Finance::Currency::Convert -
Convert currencies and fetch their exchange rates (with Finance::Quote)

=head1 SYNOPSIS

   use Finance::Currency::Convert;
   my $converter = new Finance::Currency::Convert;

   $amount_euro = $converter->convert(100, "DEM", "EUR");
   $amount_euro = $converter->convertToEUR(100, "DEM");
   $amount_dem = $converter->convertFromEUR(100, "DEM");

   $converter->updateRates("EUR", "DEM", "USD");
   $converter->updateRate("DEM", "USD");

   $converter->setRatesFile(".rates");
   $converter->writeRatesFile();


=head1 DESCRIPTION

This module converts currencies. It has built in the fixed exchange
rates for all Euro currencies (as of November 2000). If you wish to use other / more
currencies, you can automatically fetch their exchange rates from
the internet and (optionally) store them in a file for later reference.

Use this module if you have large volumes of currency data to convert.
Using the exchange rates from memory makes it a lot faster than
using Finance::Quote directly and will save you the duty of storing
the exchange rates yourself.

=head2 CURRENCY SYMBOLS

Finance::Currency::Convert uses the three character ISO currency codes
used by  Finance::Quote.
Here is a list of currency codes.

Currencies with built-in rates (complete):

	EUR		Euro
	ATS		Austrian Schilling
	BEF		Belgiam Franc
	DEM		German Mark
	ESP		Spanish Peseta
	FIM		Finnish Mark
	FRF		French Franc
	GRD		Greek Drachma
	IEP		Irish Punt
	ITL		Italian Lira
	LUF		Luxembourg Franc
	NLG		Dutch Guilder
	PTE		Portuguese Escudo
	CYP		Cyprus Pound
	MTL		Maltese Lira
	SIT		Slovenian Tolars

Other currencies (incomplete):

	AUD		Australian Dollar
	CHF		Swiss Franc
	HKD		Hong Kong Dollar
	JPY		Japanese Yen
	USD		US Dollar

=head1 AVAILABLE METHODS

=head2 NEW

   my $converter = new Finance::Currency::Convert;

The newly created conversion object will by default only know how to
convert Euro currencies. To "teach" it more currencies use updateRate
or updateRates.

=head2 CONVERT

   $amount_euro = $converter->convert(100, "DEM", "EUR");

This will convert 100 German Marks into the equivalent
amount Euro.

=head2 CONVERTTOEURO

   $amount_euro = $converter->convertToEUR(100, "DEM");

This will convert 100 German Marks into the equivalent amount Euro.
This function is simply shorthand for calling convert directly with
"EUR" als the second (target) currency.

=head2 CONVERTFROMEURO

   $amount_dem = $converter->convertFromEUR(100, "DEM");

This will convert 100 Euro into the equivalent amount German Marks.
This function is simply shorthand for calling convert directly with
"EUR" als the first (source) currency.

=head2 UPDATERATES

   $converter->updateRates("USD");
   $converter->updateRates("EUR", "DEM", "USD");

This will fetch the exchange rates for one or more currencies using
Finance::Quote and update the exchange rates in memory.
This method will fetch _all_ combinations of exchange rates between
the named currencies and the ones already in memory.
This may result in a large number of requests to Finance::Quote.
To avoid network overhead you can store the retrieved rates with
setRatesFile() / writeRatesFile() once you have retrieved them
and load them again with setRatesFile().

To update a single exchange rate use updateRate.


=head2 UPDATERATE

   $converter->updateRate("DEM, "USD");

This will fetch a single exchange rate using Finance::Quote and
update the exchange rates in memory.

=head2 SETUSERAGENT

	$converter->setUserAgent("MyCurrencyAgent 1.0");

Set the user agent string to be used by Finance::Quote.

=head2 SETRATE

	$converter->setRate("EUR", "USD", 999);

Set one exchange rate. Used internally by updateRates,
but may be of use if you have to add a rate manually.

=head2 SETRATESFILE

   $converter->setRatesFile(".rates");

Name the file where exchange rates are stored. If it already exists
it will be read into memory.

=head2 READRATESFILE

   $converter->readRatesFile();

Usually called internally by setRatesFile, but may also be called
directly to revert to the rates stored in the file.
Calling readRatesFile() will erase all existing exchange rates in memory.

=head2 WRITERATESFILE

   $converter->writeRatesFile();

Call this function to save table with exchange rates from memory
to the file named by setRatesFile() eg. after fetching new rates
with updateRates.

=head1 AUTHOR

  Jan Willamowius <jan@willamowius.de>, http://www.willamowius.de/perl.html

=head1 SEE ALSO

Finance::Quote

This module is only needed for fetching exchange rates.
There is no need to install it when only Euro currencies are used.

=cut

