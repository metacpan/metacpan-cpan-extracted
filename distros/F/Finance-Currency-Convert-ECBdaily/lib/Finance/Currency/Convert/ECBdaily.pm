package Finance::Currency::Convert::ECBdaily;

use vars qw/$VERSION $DATE $CHAT %currencies/;

$VERSION = 0.05;
$DATE = "01 March 2018";

=head1 NAME

Finance::Currency::Convert::ECBdaily - convert currencies using ECBdaily

=head1 SYNOPSIS

	use Finance::Currency::Convert::ECBdaily;
	$Finance::Currency::Convert::ECBdaily::CHAT = 1;
	$_ = Finance::Currency::Convert::ECBdaily::convert(1,'USD','GBP');
	print defined($_)? "Is $_\n" : "Error.";
	exit;

	# See the currencies in a dirty way:
	use Finance::Currency::Convert::ECBdaily;
	use Data::Dumper;
	warn %Finance::Currency::Convert::ECBdaily::currencies;
	exit;

=head1 DESCRIPTION

Using ECBdaily, converts a sum between two currencies.

=cut

use strict;
use Carp;
use warnings;
use LWP::Simple;
use XML::Simple;

#
# Glabal variables
#

$CHAT = 0;		# Set for real-time notes to STDERR

# Should have been %CURRENCIES but too late now.
our %CURRENCIES = %currencies = (
	'USD'=>'US Dollar',			 'JPY'=>'Japanese Yen',			'BGN'=>'Bulgarian Lev equals',
	'CZK'=>'Czech Koruna',		 'DKK'=>'Danish Krone',			'GBP'=>'British Pound',
	'HUF'=>'Hungarian Forint',	 'PLN'=>'Polish Zloty',			'RON'=>'Romanian Leu',
	'SEK'=>'Swedish Krona',		 'CHF'=>'Swiss Franc',			'ISK'=>'Iceland Krona',
	'NOK'=>'Norwegian Krone', 	 'HRK'=>'Croatian Kuna',		'RUB'=>'Russian Rouble',
	'TRY'=>'Turkish Lira',		 'AUD'=>'Australian Dollar',	'BRL'=>'Brazilian Real',
	'CAD'=>'Canadian Dollar',	 'CNY'=>'Chinese Yuan',			'HKD'=>'Hong Kong Dollar',
	'IDR'=>'Indonesian Rupiah',  'ILS'=>'Israeli Shekel',		'INR'=>'Indian Rupee',
	'KRW'=>'Korean Won',		 'MXN'=>'Mexican Peso',			'MYR'=>'Malaysian Ringgit',
	'NZD'=>'New Zealand Dollar', 'PHP'=>'Philippine Peso',		'SGD'=>'Singapore Dollar',
	'THB'=>'Thai Baht',			 'ZAR'=>'South African Rand',	'EUR'=>'Euro'
);


=head1 USE

Call the module's C<&convert> routine, supplying three arguments:
the amount to convert, and the currencies to convert from and to.

Codes are used to identify currencies: you may view them in the
values of the C<%currencies> hash, where keys are descriptions of
the currencies.

In the event that attempts to convert fail, you will recieve C<undef>
in response, with errors going to STDERR, and notes displayed if
the modules global C<$CHAT> is defined.

=head2 SUBROUTINE convert

	$value = &convert( $amount_to_convert, $from, $to);

Requires the sum to convert, and two symbols to represent the source
and target currencies.

In more detail, access L<https://www.ecb.europa.eu/stats/eurofxref/eurofxref-daily.xml>,
where the value of C<s> (in the example, C<GBPUSD>) is the value of the source
and target currencies, and the rest is stuff I've not looked into....

=cut

sub convert { 
	my ($amount, $from, $to) = (shift,shift,shift);

	die "\nPlease call as ...::convert(\$amount,\$from,\$to) " unless (defined $amount and defined $from and defined $to);
	carp "\nNo such currency code as <$from>." and return undef if not exists $currencies{$from};
	carp "\nNo such currency code as <$to>." and return undef if not exists $currencies{$to};
	carp "\nPlease supply a positive sum to convert <received $amount>." and return undef if $amount<0;
	warn "\nConverting <$amount> from <$from> to <$to> " if $CHAT;

	my ($value);
	for my $attempt (0..3){
		warn "\nAttempt $attempt ...\n" if $CHAT;
		$value = _get_document_xml($amount,$from,$to);
		# Can't really say "last if defined $doc" as $doc may be a ECBdaily 404-like error?
		last if defined $value;
	}
	return $value;
}


#
# PRIVATE SUB _get_document_xml
# Accepts: amount, starting currency, target currency
# Returns: HTML content
# URI: https://www.ecb.europa.eu/stats/eurofxref/eurofxref-daily.xml
#
sub _get_document_xml { 

	my ($amount,$from,$to) = (shift,shift,shift);
	die "get_document requires a \$amount,\$from_currency,\$target_currency arrity" unless (defined $amount and defined $to and defined $from);

	my $url = 'https://www.ecb.europa.eu/stats/eurofxref/eurofxref-daily.xml';
	warn "\nAttempting to access <$url> ...\n" if $CHAT;

	my $content = get $url or die "Unable to get $url\n";

	my $xml = new XML::Simple;
	my $data = $xml->XMLin($content);
	my $cube = $data->{Cube}->{Cube}->{Cube};
	
	my $r1 = _get_rate($cube, $from);
	die "\ncan not find rate for currency $from" unless $r1;
	
	my $r2 = _get_rate($cube, $to);
	die "\ncan not find rate for currency $to" unless $r2;

	my $r = $r2/$r1;

	return $amount * $r;
}

sub _get_rate { 

	my ($cube, $cur) = (shift,shift);

	if( $cur eq 'EUR') {
		return 1;
	}

	my $r = 0;
	for my $n ( @{$cube} ) {
		if( $n->{currency} eq $cur ) {
			$r = $n->{rate};
			last;
		}
	}

	$r =~ s/^\s*([\d.]+)\s*$/$1/sg;
	if ($r eq ''){
		warn "\n...document contained no data/unexpected data for $cur\n";
		return undef;
	}	

	return $r;
}

=head1 EXPORTS

None.

=head1 REVISIONS

Please see the enclosed file CHANGES.

=head1 PROBLEMS?

If this doesn't work, www.ecb.europa.eu have probably changed their URI or HTML format.
Let me know and I'll fix the code. Or by all means send a patch.
Please don't just post a bad review on CPAN, I don't get CC'd them.

=head1 SEE ALSO

L<LWP::UserAgent>: L<HTTP::Request>: L<JSON>;
L<https://www.ecb.europa.eu/stats/policy_and_exchange_rates/euro_reference_exchange_rates/html/index.en.html>.

=head1 AUTHOR

berlin3, details -at- cpan -dot- org.

=head1 COPYRIGHT

Copyright (C) details, 2018, ff. - All Rights Reserved.

This library is free software and may be used only under the same terms as Perl itself.

=cut


# $Finance::Currency::Convert::ECBdaily::CHAT=1;
# print Finance::Currency::Convert::ECBdaily::convert(1,'EUR','GBP');

1;

__END__