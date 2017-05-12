package Finance::Currency::Convert::Yahoo;

use vars qw/$VERSION $DATE $CHAT %currencies/;

$VERSION = 0.2;
$DATE = "14 December 2005";

=head1 NAME

Finance::Currency::Convert::Yahoo - convert currencies using Yahoo

=head1 SYNOPSIS

	use Finance::Currency::Convert::Yahoo;
	$Finance::Currency::Convert::Yahoo::CHAT = 1;
	$_ = Finance::Currency::Convert::Yahoo::convert(1,'USD','GBP');
	print defined($_)? "Is $_\n" : "Error.";
	exit;

	# See the currencies in a dirty way:
	use Finance::Currency::Convert::Yahoo;
	use Data::Dumper;
	warn %Finance::Currency::Convert::Yahoo::currencies;
	exit;

=head1 DESCRIPTION

Using Finance.Yahoo.com, converts a sum between two currencies.

=cut

use strict;
use Carp;
use warnings;
use LWP::UserAgent;
use HTTP::Request;

#
# Glabal variables
#

$CHAT = 0;		# Set for real-time notes to STDERR

# Should have been %CURRENCIES but too late now.
our %CURRENCIES = %currencies = (
	'AFA'=>'Afghanistan Afghani', 	'ALL'=>'Albanian Lek', 	'DZD'=>'Algerian Dinar',
	'ADF'=>'Andorran Franc', 	'ADP'=>'Andorran Peseta', 	'ARS'=>'Argentine Peso',
	'AWG'=>'Aruba Florin', 	'AUD'=>'Australian Dollar', 	'ATS'=>'Austrian Schilling',
	'BSD'=>'Bahamian Dollar', 	'BHD'=>'Bahraini Dinar', 	'BDT'=>'Bangladesh Taka',
	'BBD'=>'Barbados Dollar', 	'BEF'=>'Belgian Franc', 	'BZD'=>'Belize Dollar',
	'BMD'=>'Bermuda Dollar', 	'BTN'=>'Bhutan Ngultrum', 	'BOB'=>'Bolivian Boliviano',
	'BWP'=>'Botswana Pula', 	'BRL'=>'Brazilian Real', 	'GBP'=>'British Pound',
	'BND'=>'Brunei Dollar', 	'BIF'=>'Burundi Franc', 	'XOF'=>'CFA Franc (BCEAO)',
	'XAF'=>'CFA Franc (BEAC)', 	'KHR'=>'Cambodia Riel', 	'CAD'=>'Canadian Dollar',
	'CVE'=>'Cape Verde Escudo', 	'KYD'=>'Cayman Islands Dollar', 	'CLP'=>'Chilean Peso',
	'CNY'=>'Chinese Yuan', 	'COP'=>'Colombian Peso', 	'KMF'=>'Comoros Franc',
	'CRC'=>'Costa Rica Colon', 	'HRK'=>'Croatian Kuna', 	'CUP'=>'Cuban Peso',
	'CYP'=>'Cyprus Pound', 	'CZK'=>'Czech Koruna', 	'DKK'=>'Danish Krone',
	'DJF'=>'Dijibouti Franc', 	'DOP'=>'Dominican Peso', 	'NLG'=>'Dutch Guilder',
	'XCD'=>'East Caribbean Dollar', 	'ECS'=>'Ecuadorian Sucre', 	'EGP'=>'Egyptian Pound',
	'SVC'=>'El Salvador Colon', 	'EEK'=>'Estonian Kroon', 	'ETB'=>'Ethiopian Birr',
	'EUR'=>'Euro', 	'FKP'=>'Falkland Islands Pound', 	'FJD'=>'Fiji Dollar',
	'FIM'=>'Finnish Mark', 	'FRF'=>'French Franc', 	'GMD'=>'Gambian Dalasi',
	'DEM'=>'German Mark', 	'GHC'=>'Ghanian Cedi', 	'GIP'=>'Gibraltar Pound',
	'XAU'=>'Gold Ounces', 	'GRD'=>'Greek Drachma', 	'GTQ'=>'Guatemala Quetzal',
	'GNF'=>'Guinea Franc', 	'GYD'=>'Guyana Dollar', 	'HTG'=>'Haiti Gourde',
	'HNL'=>'Honduras Lempira', 	'HKD'=>'Hong Kong Dollar', 	'HUF'=>'Hungarian Forint',
	'ISK'=>'Iceland Krona', 	'INR'=>'Indian Rupee', 	'IDR'=>'Indonesian Rupiah',
	'IQD'=>'Iraqi Dinar', 	'IEP'=>'Irish Punt', 	'ILS'=>'Israeli Shekel',
	'ITL'=>'Italian Lira', 	'JMD'=>'Jamaican Dollar', 	'JPY'=>'Japanese Yen',
	'JOD'=>'Jordanian Dinar', 	'KZT'=>'Kazakhstan Tenge', 	'KES'=>'Kenyan Shilling',
	'KRW'=>'Korean Won', 	'KWD'=>'Kuwaiti Dinar', 	'LAK'=>'Lao Kip', 	'LVL'=>'Latvian Lat',
	'LBP'=>'Lebanese Pound', 	'LSL'=>'Lesotho Loti', 	'LRD'=>'Liberian Dollar',
	'LYD'=>'Libyan Dinar', 	'LTL'=>'Lithuanian Lita', 	'LUF'=>'Luxembourg Franc',
	'MOP'=>'Macau Pataca', 	'MKD'=>'Macedonian Denar', 	'MGF'=>'Malagasy Franc',
	'MWK'=>'Malawi Kwacha', 	'MYR'=>'Malaysian Ringgit', 	'MVR'=>'Maldives Rufiyaa',
	'MTL'=>'Maltese Lira', 	'MRO'=>'Mauritania Ougulya', 	'MUR'=>'Mauritius Rupee',
	'MXN'=>'Mexican Peso', 	'MDL'=>'Moldovan Leu', 	'MNT'=>'Mongolian Tugrik',
	'MAD'=>'Moroccan Dirham', 	'MZM'=>'Mozambique Metical', 	'MMK'=>'Myanmar Kyat',
	'NAD'=>'Namibian Dollar', 	'NPR'=>'Nepalese Rupee', 	'ANG'=>'Neth Antilles Guilder',
	'NZD'=>'New Zealand Dollar', 	'NIO'=>'Nicaragua Cordoba', 	'NGN'=>'Nigerian Naira',
	'KPW'=>'North Korean Won', 	'NOK'=>'Norwegian Krone', 	'OMR'=>'Omani Rial',
	'XPF'=>'Pacific Franc', 	'PKR'=>'Pakistani Rupee', 	'XPD'=>'Palladium Ounces',
	'PAB'=>'Panama Balboa', 	'PGK'=>'Papua New Guinea Kina', 	'PYG'=>'Paraguayan Guarani',
	'PEN'=>'Peruvian Nuevo Sol', 	'PHP'=>'Philippine Peso', 	'XPT'=>'Platinum Ounces',
	'PLN'=>'Polish Zloty', 	'PTE'=>'Portuguese Escudo', 	'QAR'=>'Qatar Rial',
	'ROL'=>'Romanian Leu', 	'RUB'=>'Russian Rouble', 	'WST'=>'Samoa Tala',
	'STD'=>'Sao Tome Dobra', 	'SAR'=>'Saudi Arabian Riyal', 	'SCR'=>'Seychelles Rupee',
	'SLL'=>'Sierra Leone Leone', 	'XAG'=>'Silver Ounces', 	'SGD'=>'Singapore Dollar',
	'SKK'=>'Slovak Koruna', 	'SIT'=>'Slovenian Tolar', 	'SBD'=>'Solomon Islands Dollar',
	'SOS'=>'Somali Shilling', 	'ZAR'=>'South African Rand', 	'ESP'=>'Spanish Peseta',
	'LKR'=>'Sri Lanka Rupee', 	'SHP'=>'St Helena Pound', 	'SDD'=>'Sudanese Dinar',
	'SRG'=>'Surinam Guilder', 	'SZL'=>'Swaziland Lilageni', 	'SEK'=>'Swedish Krona',
	'CHF'=>'Swiss Franc', 	'SYP'=>'Syrian Pound', 	'TWD'=>'Taiwan Dollar',
	'TZS'=>'Tanzanian Shilling', 	'THB'=>'Thai Baht', 	'TOP'=>"Tonga Pa'anga",
	'TTD'=>'Trinida and Tobago Dollar', 	'TND'=>'Tunisian Dinar', 	'TRL'=>'Turkish Lira',
	'USD'=>'US Dollar', 	'AED'=>'UAE Dirham', 	'UGX'=>'Ugandan Shilling',
	'UAH'=>'Ukraine Hryvnia', 	'UYU'=>'Uruguayan New Peso', 	'VUV'=>'Vanuatu Vatu',
	'VEB'=>'Venezuelan Bolivar', 	'VND'=>'Vietnam Dong', 	'YER'=>'Yemen Riyal',
	'YUM'=>'Yugoslav Dinar', 	'ZMK'=>'Zambian Kwacha', 	'ZWD'=>'Zimbabwe Dollar'
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

In more detail, access L<http://finance.yahoo.com/d/quotes.csv?s=GBPEUR=X&f=l1>,
where the value of C<s> (in the example, C<GBPUSD>) is the value of the source
and target currencies, and the rest is stuff I've not looked into....

=cut

sub convert { my ($amount, $from, $to) = (shift,shift,shift);
	die "Please call as ...::convert(\$amount,\$from,\$to) " unless (defined $amount and defined $from and defined $to);
	carp "No such currency code as <$from>." and return undef if not exists $currencies{$from};
	carp "No such currency code as <$to>." and return undef if not exists $currencies{$to};
	carp "Please supply a positive sum to convert <received $amount>." and return undef if $amount<0;
	warn "Converting <$amount> from <$from> to <$to> " if $CHAT;
	my ($value);
	for my $attempt (0..3){
		warn "Attempt $attempt ...\n" if $CHAT;
		$value = _get_document_csv($amount,$from,$to);
		# Can't really say "last if defined $doc" as $doc may be a Yahoo 404-like error?
		last if defined $value;
	}
	return $value;
}

=head2 DEPRECATED SUBROUTINE deprecated_convert

The old C<convert> routine: accesses C<http://finance.yahoo.com/m5?a=amount&s=start&t=to>,
where C<start> is the currency being converted, C<to> is the
target currency, and C<amount> is the amount being converted.
The latter is a number; the former two codes defined in our
C<%currencies> hash. (For the date this was last checked, C<print $DATE>).

=cut

sub deprecated_convert { my ($amount, $from, $to) = (shift,shift,shift);
	require HTML::TokeParser;
	import HTML::TokeParser;
	die 'You not have HTML::TokeParser...?' unless HTML::TokeParser->VERSION;
	die "Please call as ...::convert(\$amount,\$from,\$to) " unless (defined $amount and defined $from and defined $to);
	carp "No such currency code as <$from>." and return undef if not exists $currencies{$from};
	carp "No such currency code as <$to>." and return undef if not exists $currencies{$to};
	carp "Please supply a positive sum to convert <received $amount>." and return undef if $amount<0;
	warn "Converting <$amount> from <$from> to <$to> " if $CHAT;
	my ($doc,$result);
	for my $attempt (0..3){
		warn "Attempt $attempt ...\n" if $CHAT;
		$doc = _get_document_html($amount,$from,$to);
		# Can't really say "last if defined $doc"
		# as $doc may be a Yahoo 404-like error?
		last if defined $doc;
	}
	if (defined $doc){
		if ($result = _extract_data($doc)){
			warn "Got doc, result is $result" if defined $CHAT;
		}
	}
	if (defined $doc and defined $result){
		warn "Result:$result\n" if defined $result and defined $CHAT;
		return $result;
	} elsif (defined $doc and not defined $result){
		carp "Connected to Yahoo but could not read the page: sorry" if defined $CHAT;
		return undef;
	} else {
		carp "Could not connect to Yahoo" if defined $CHAT;
		return undef;
	}
}


#
# PRIVATE SUB get_document_csv
# Accepts: amount, starting currency, target currency
# Returns: HTML content
# URI: http://finance.yahoo.com/d/quotes.csv?s=GBPEUR=X&f=l1
#
sub _get_document_csv { my ($amount,$from,$to) = (shift,shift,shift);
	die "get_document requires a \$amount,\$from_currency,\$target_currency arrity" unless (defined $amount and defined $to and defined $from);

	my $ua = LWP::UserAgent->new;												# Create a new UserAgent
	$ua->agent('Mozilla/25.'.(localtime)." (PERL ".__PACKAGE__." $VERSION");	# Give it a type name

	my $url =
		'http://finance.yahoo.com/d/quotes.csv?'
		. 's='.$from.$to
		. '=X&f=l1'
	;
	warn "Attempting to access <$url> ...\n" if $CHAT;

	# Format URL request
	my $req = new HTTP::Request ('GET',$url) or die "...could not GET.\n" and return undef;
	my $res = $ua->request($req);						# $res is the object UA returned
	if (not $res->is_success()) {						# If successful
		warn"...failed to retrieve currency document from Yahoo...\nTried: $url\n";
		return undef;
	}
	warn "...ok.\n" if $CHAT;

	my $r = $res->content;
	$r =~ s/^\s*([\d.]+)\s*$/$1/sg;
	if ($r eq ''){
		warn "...document contained no data/unexpected data\n";
		return undef;
	}

	return $amount * $r;
}



#
# PRIVATE SUB get_document_html
# Accepts: amount, starting currency, target currency
# Returns: HTML content
# URI: http://finance.yahoo.com/currency/convert?amt=1&from=GBP&to=HUF&submit=Convert
#
sub _get_document_html { my ($amount,$from,$to) = (shift,shift,shift);
	die "get_document requires a \$amount,\$from_currency,\$target_currency arrity" unless (defined $amount and defined $to and defined $from);

	my $ua = LWP::UserAgent->new;												# Create a new UserAgent
	$ua->agent('Mozilla/25.'.(localtime)." (PERL ".__PACKAGE__." $VERSION");	# Give it a type name

	my $url =
		'http://finance.yahoo.com/currency/convert?'
		. 'amt='.$amount
		. '&from='.$from
		. '&to='.$to
		. '&submit=Convert'
	;
	warn "Attempting to access <$url> ...\n" if $CHAT;

	# Format URL request
	my $req = new HTTP::Request ('GET',$url) or die "...could not GET.\n" and return undef;
	my $res = $ua->request($req);						# $res is the object UA returned
	if (not $res->is_success()) {						# If successful
		warn"...failed to retrieve currency document.\n" if $CHAT;
		return undef
	}
	warn "...ok.\n" if $CHAT;

	return $res->content;
}


#
# PRIVATE SUB _extract_data
# Accept: HTML doc as arg
# Return amount on success, undef on failure
# NOV  2004: Fifth yfnc_tabledata1 class TD, and bold
# MAY  2003: Sloopy errors fixed. Sorry.
# APR  2003: Data is now in SIXTH table, second row, second (non-header) cell, in bold
# JAN  2003: Data is now in SEVENTH table, second row, second (non-header) cell, in bold
# JULY 2001: Data is in fourth table's fourth TD
# DEC  2001: Data is in FIFTH table
#
sub _extract_data { my $doc = shift;
	my $token;
	my $p = HTML::TokeParser->new(\$doc) or die "Couldn't create TokePraser: $!";
	# Fifth TD and class is 'yfnc_tabledata1'
	for (1..5){
		while ($token = $p->get_token and not (
				@$token[0] eq 'S' and @$token[1] eq 'td'
				and @$token[2]->{class}
				and @$token[2]->{class} eq 'yfnc_tabledata1'
		) ){}
	}
	$token = $p->get_token or return undef;
	return undef if @$token[0] ne 'S' and @$token[1] ne 'b';

	$token = $p->get_token or return undef;
	return undef if @$token[0] ne 'T';

	return @$token[1] =~ /^[\d.,]+$/ ? @$token[1] : undef;
}




=head1 EXPORTS

None.

=head1 REVISIONS

Please see the enclosed file CHANGES.

=head1 PROBLEMS?

If this doesn't work, Yahoo have probably changed their URI or HTML format.
Let me know and I'll fix the code. Or by all means send a patch.
Please don't just post a bad review on CPAN, I don't get CC'd them.

=head1 SEE ALSO

L<LWP::UserAgent>: L<HTTP::Request>;
L<http://www.macosxhints.com/article.php?story=20050622055810252>;
L<http://www.gummy-stuff.org/Yahoo-data.htm>.

=head1 AUTHOR

Lee Goddard, lgoddard -at- cpan -dot- org.

=head1 COPYRIGHT

Copyright (C) Lee Goddard, 2001, 2005, ff. - All Rights Reserved.

This library is free software and may be used only under the same terms as Perl itself.

=cut


# $Finance::Currency::Convert::Yahoo::CHAT=1;
# print Finance::Currency::Convert::Yahoo::convert(1,'EUR','GBP');


1;

__END__

