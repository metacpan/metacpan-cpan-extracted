package Finance::Currency::Convert::DnB;
use strict;
use warnings;
use Exporter;
our @ISA = qw/Exporter/;
our @EXPORT = qw/currency update_currency currencies/;
our $VERSION = '0.2';

our $currency;
use File::Spec;
use XML::Simple;
use LWP::Simple;
use Slurp;

sub update_currency {
    my $filename = File::Spec->tmpdir() . "/currency_list_" . ((defined $>) ? $> : "") . ".xml";
    #only download XML twice a day
    if (!-e $filename || time()-43200 < -M $filename || $_[0]) {
        is_success ($_=getstore('http://www.dnbnor.no/portalfront/datafiles/miscellaneous/csv/kursliste_ws.xml', $filename))
	    or die 'Failed to get list of currencies; http error code: ' . $_;

    }

    my $content = slurp $filename;
    $currency = XMLin($content, KeyAttr => ["kode"]);
}

sub currencies {
    update_currency;
    sort keys %{$currency->{valutakurs}}
}

sub currency {
    my ($amount, $from, $to, $decimals) = @_;
    $decimals = 2 unless defined $decimals;
    update_currency;

    map { 
	my $res;
	my $from_currency = $currency->{valutakurs}->{$from}->{overforsel}->{midtkurs} / $currency->{valutakurs}->{$from}->{enhet} if ($from ne "NOK");
	my $to_currency = $currency->{valutakurs}->{$_}->{overforsel}->{midtkurs} / $currency->{valutakurs}->{$_}->{enhet} if ($_ ne "NOK");
	
	foreach my $amount ( (ref($amount) eq 'ARRAY') ? @$amount : $amount ) {
	    if ($_ eq "NOK") {
		$res += $amount * $from_currency;
	    }
	    elsif ($from eq "NOK") {
		$res += $amount / $to_currency;
	    }
	    else {
		$res += $amount * $from_currency / $to_currency;
	    }
	}	
	$res = sprintf('%.' . $decimals . 'f', $res);
	($to) ? return $res : $_ => $res
    } ($to) ? $to : keys %{$currency->{valutakurs}}
}

1;

=head1 NAME

Finance::Currency::Convert::DnB - convert currencies with up to date currencies from dnbnor.no

=head1 SYNOPSIS

    use Finance::Currency::Convert::DnB;
    
    #get results with default number of decimals which is 2
    $result = currency 20, "NOK", "GBP";
    #3 decimals
    $result = currency 20, "NOK", "GBP", 3;

    #convert several numbers
    $result = currency \@values, "NOK", "GBP";
    $result = currency [20, 50, 35], "NOK", "GBP";

    #store all results in a hash
    my %all_currencies = currency 20, "NOK";
    print "20 NOK in $_ is $all_currencies{$_}\n" foreach (keys %all_currencies);

    #get a list of available currencies
    my @currencies = currencies;

=head1 DESCRIPTION 

Finance::Currency::Convert::DnB uses a XML list from dnbnor.no to convert currencies. Caches XML list in a temporary file for quick access.

=head1 AVAILABLE METHODS

=head2 currency

    $result = convert 20, "NOK", "GBP", 2;
    Amount can also be an array reference, and it will return a total of all elements.
    If conversion currency is excluded, it will return a hash with all results for all currencies.
    If number of decimals is excluded, if will default to 2 decimals.

=head2 currencies

    Returns a list of available currencies sorted alphabetically.

=head2 update_currency

    This is an internal function called automatically to update currencies. It is done automatically if the cache is non-existing or if it is older than 12 hours. You can force updating by calling it with a true argument.

=cut
