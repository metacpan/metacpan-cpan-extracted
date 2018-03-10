package Finance::Currency::Convert::ECBdaily;

use vars qw/$VERSION $DATE $CHAT %currencies/;

$VERSION = 0.03;
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
	'AFA'=>'Afghanistan Afghani', 		'ALL'=>'Albanian Lek', 				'DZD'=>'Algerian Dinar',
	'ADF'=>'Andorran Franc', 			'ADP'=>'Andorran Peseta', 			'ARS'=>'Argentine Peso',
	'AWG'=>'Aruba Florin', 				'AUD'=>'Australian Dollar', 		'ATS'=>'Austrian Schilling',
	'BSD'=>'Bahamian Dollar', 			'BHD'=>'Bahraini Dinar', 			'BDT'=>'Bangladesh Taka',
	'BBD'=>'Barbados Dollar', 			'BEF'=>'Belgian Franc', 			'BZD'=>'Belize Dollar',
	'BMD'=>'Bermuda Dollar', 			'BTN'=>'Bhutan Ngultrum', 			'BOB'=>'Bolivian Boliviano',
	'BWP'=>'Botswana Pula', 			'BRL'=>'Brazilian Real', 			'GBP'=>'British Pound',
	'BND'=>'Brunei Dollar', 			'BIF'=>'Burundi Franc', 			'XOF'=>'CFA Franc (BCEAO)',
	'XAF'=>'CFA Franc (BEAC)', 			'KHR'=>'Cambodia Riel', 			'CAD'=>'Canadian Dollar',
	'CVE'=>'Cape Verde Escudo', 		'KYD'=>'Cayman Islands Dollar', 	'CLP'=>'Chilean Peso',
	'CNY'=>'Chinese Yuan', 				'COP'=>'Colombian Peso', 			'KMF'=>'Comoros Franc',
	'CRC'=>'Costa Rica Colon', 			'HRK'=>'Croatian Kuna', 			'CUP'=>'Cuban Peso',
	'CYP'=>'Cyprus Pound', 				'CZK'=>'Czech Koruna', 				'DKK'=>'Danish Krone',
	'DJF'=>'Dijibouti Franc', 			'DOP'=>'Dominican Peso', 			'NLG'=>'Dutch Guilder',
	'XCD'=>'East Caribbean Dollar', 	'ECS'=>'Ecuadorian Sucre', 			'EGP'=>'Egyptian Pound',
	'SVC'=>'El Salvador Colon', 		'EEK'=>'Estonian Kroon', 			'ETB'=>'Ethiopian Birr',
	'EUR'=>'Euro', 						'FKP'=>'Falkland Islands Pound',	'FJD'=>'Fiji Dollar',
	'FIM'=>'Finnish Mark', 				'FRF'=>'French Franc', 				'GMD'=>'Gambian Dalasi',
	'DEM'=>'German Mark', 				'GHC'=>'Ghanian Cedi', 				'GIP'=>'Gibraltar Pound',
	'XAU'=>'Gold Ounces', 				'GRD'=>'Greek Drachma', 			'GTQ'=>'Guatemala Quetzal',
	'GNF'=>'Guinea Franc', 				'GYD'=>'Guyana Dollar', 			'HTG'=>'Haiti Gourde',
	'HNL'=>'Honduras Lempira', 			'HKD'=>'Hong Kong Dollar', 			'HUF'=>'Hungarian Forint',
	'ISK'=>'Iceland Krona', 			'INR'=>'Indian Rupee', 				'IDR'=>'Indonesian Rupiah',
	'IQD'=>'Iraqi Dinar', 				'IEP'=>'Irish Punt', 				'ILS'=>'Israeli Shekel',
	'ITL'=>'Italian Lira', 				'JMD'=>'Jamaican Dollar', 			'JPY'=>'Japanese Yen',
	'JOD'=>'Jordanian Dinar', 			'KZT'=>'Kazakhstan Tenge', 			'KES'=>'Kenyan Shilling',
	'KRW'=>'Korean Won', 				'KWD'=>'Kuwaiti Dinar', 			'LAK'=>'Lao Kip', 	'LVL'=>'Latvian Lat',
	'LBP'=>'Lebanese Pound', 			'LSL'=>'Lesotho Loti', 				'LRD'=>'Liberian Dollar',
	'LYD'=>'Libyan Dinar', 				'LTL'=>'Lithuanian Lita', 			'LUF'=>'Luxembourg Franc',
	'MOP'=>'Macau Pataca', 				'MKD'=>'Macedonian Denar', 			'MGF'=>'Malagasy Franc',
	'MWK'=>'Malawi Kwacha', 			'MYR'=>'Malaysian Ringgit', 		'MVR'=>'Maldives Rufiyaa',
	'MTL'=>'Maltese Lira', 				'MRO'=>'Mauritania Ougulya', 		'MUR'=>'Mauritius Rupee',
	'MXN'=>'Mexican Peso', 				'MDL'=>'Moldovan Leu', 				'MNT'=>'Mongolian Tugrik',
	'MAD'=>'Moroccan Dirham', 			'MZM'=>'Mozambique Metical', 		'MMK'=>'Myanmar Kyat',
	'NAD'=>'Namibian Dollar', 			'NPR'=>'Nepalese Rupee', 			'ANG'=>'Neth Antilles Guilder',
	'NZD'=>'New Zealand Dollar', 		'NIO'=>'Nicaragua Cordoba', 		'NGN'=>'Nigerian Naira',
	'KPW'=>'North Korean Won', 			'NOK'=>'Norwegian Krone', 			'OMR'=>'Omani Rial',
	'XPF'=>'Pacific Franc', 			'PKR'=>'Pakistani Rupee', 			'XPD'=>'Palladium Ounces',
	'PAB'=>'Panama Balboa', 			'PGK'=>'Papua New Guinea Kina', 	'PYG'=>'Paraguayan Guarani',
	'PEN'=>'Peruvian Nuevo Sol', 		'PHP'=>'Philippine Peso', 			'XPT'=>'Platinum Ounces',
	'PLN'=>'Polish Zloty', 				'PTE'=>'Portuguese Escudo', 		'QAR'=>'Qatar Rial',
	'ROL'=>'Romanian Leu', 				'RUB'=>'Russian Rouble', 			'WST'=>'Samoa Tala',
	'STD'=>'Sao Tome Dobra', 			'SAR'=>'Saudi Arabian Riyal', 		'SCR'=>'Seychelles Rupee',
	'SLL'=>'Sierra Leone Leone', 		'XAG'=>'Silver Ounces', 			'SGD'=>'Singapore Dollar',
	'SKK'=>'Slovak Koruna', 			'SIT'=>'Slovenian Tolar', 			'SBD'=>'Solomon Islands Dollar',
	'SOS'=>'Somali Shilling', 			'ZAR'=>'South African Rand', 		'ESP'=>'Spanish Peseta',
	'LKR'=>'Sri Lanka Rupee', 			'SHP'=>'St Helena Pound', 			'SDD'=>'Sudanese Dinar',
	'SRG'=>'Surinam Guilder', 			'SZL'=>'Swaziland Lilageni', 		'SEK'=>'Swedish Krona',
	'CHF'=>'Swiss Franc', 				'SYP'=>'Syrian Pound', 				'TWD'=>'Taiwan Dollar',
	'TZS'=>'Tanzanian Shilling', 		'THB'=>'Thai Baht', 				'TOP'=>"Tonga Pa'anga",
	'TTD'=>'Trinida and Tobago Dollar', 'TND'=>'Tunisian Dinar', 			'TRY'=>'Turkish Lira',
	'USD'=>'US Dollar', 				'AED'=>'UAE Dirham', 				'UGX'=>'Ugandan Shilling',
	'UAH'=>'Ukraine Hryvnia', 			'UYU'=>'Uruguayan New Peso',		'VUV'=>'Vanuatu Vatu',
	'VEB'=>'Venezuelan Bolivar', 		'VND'=>'Vietnam Dong', 				'YER'=>'Yemen Riyal',
	'YUM'=>'Yugoslav Dinar', 			'ZMK'=>'Zambian Kwacha', 			'ZWD'=>'Zimbabwe Dollar'
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

	die "Please call as ...::convert(\$amount,\$from,\$to) " unless (defined $amount and defined $from and defined $to);
	carp "No such currency code as <$from>." and return undef if not exists $currencies{$from};
	carp "No such currency code as <$to>." and return undef if not exists $currencies{$to};
	carp "Please supply a positive sum to convert <received $amount>." and return undef if $amount<0;
	warn "Converting <$amount> from <$from> to <$to> " if $CHAT;

	my ($value);
	for my $attempt (0..3){
		warn "Attempt $attempt ...\n" if $CHAT;
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
	warn "Attempting to access <$url> ...\n" if $CHAT;

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
		warn "...document contained no data/unexpected data for $cur\n";
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