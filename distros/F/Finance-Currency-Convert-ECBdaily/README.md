# Finance-Currency-Convert-ECBdaily
convert currencies using ECBdaily

## CPAN
https://metacpan.org/pod/Finance::Currency::Convert::ECBdaily

### SYNOPSIS

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

### DESCRIPTION

Using ECBdaily, converts a sum between two currencies.


### USE

Call the module's &convert routine, supplying three arguments:
the amount to convert, and the currencies to convert from and to.

Codes are used to identify currencies: you may view them in the
values of the %currencies hash, where keys are descriptions of
the currencies.

In the event that attempts to convert fail, you will recieve C<undef>
in response, with errors going to STDERR, and notes displayed if
the modules global $CHAT is defined.

### SUBROUTINE convert

	$value = &convert( $amount_to_convert, $from, $to);

Requires the sum to convert, and two symbols to represent the source
and target currencies.

In more detail, access L<https://www.ecb.europa.eu/stats/eurofxref/eurofxref-daily.xml>,
where the value of s (in the example, GBPUSD) is the value of the source
and target currencies, and the rest is stuff I've not looked into....


### EXPORTS

None.

### REVISIONS

Please see the enclosed file CHANGES.

### PROBLEMS?

If this doesn't work, www.ecb.europa.eu have probably changed their URI or HTML format.
Let me know and I'll fix the code. Or by all means send a patch.
Please don't just post a bad review on CPAN, I don't get CC'd them.

### SEE ALSO

L<LWP::UserAgent>: L<HTTP::Request>: L<JSON>;
L<https://www.ecb.europa.eu/stats/policy_and_exchange_rates/euro_reference_exchange_rates/html/index.en.html>.

### AUTHOR

berlin3, details -at- cpan -dot- org.

### COPYRIGHT

Copyright (C) details, 2018, ff. - All Rights Reserved.

This library is free software and may be used only under the same terms as Perl itself.

