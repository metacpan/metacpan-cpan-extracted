
## From: "Ray Gwinn" <xxxx@xxxxxxx.xxx>
## To: Dirk Eddelbuettel <edd@debian.org>
## Subject: Re: Finance::YahooQuote bug
## Date: Mon, 23 Feb 2009 19:01:14 -0500
## 
## > That's fine.  We could put it 'as is' in the example section too if you want.
## 
## Okay, I have attached the subroutine that fixes the yahoo array for me.  I zipped the file so 
## email would not screw up the indenting etc.
## 
## This routine will work ONLY if the array contains all 80 optional fields returned by 
## &getcustomquote.  Given a different array of options, the subroutine will have to be modified.
## 
## This subroutine corrects al the problems I have found.  However, there may be other 
## problems that I have not encountered.


#############################################################################
# Yahoo has commas in some numbers that screws up Finance::YahooQuote       #
#                                                                           #
# The array at the passed reference (pointer) MUST be a list of all 80      #
# items that can be requested by &getcustomquote.                           #
#############################################################################
sub fixYahoo {
	my $arrayRef = shift;

	my @yahoo = (@$arrayRef);		# Make a copy of the array
	my @fixed;
	
	# Sikp to "Last Trade Size"
	for (my $i = 0; $i <= 6; $i++) {
		push @fixed, shift @yahoo;
	}

	# Fix "Last Trade Size" if more than 999
	while(1) {
		if( (length($yahoo[0]) != 3) || ($yahoo[0] !~ /\d\d\d/) ) {last;}
		$fixed[$#fixed] .= shift @yahoo;
	}
	$fixed[$#fixed] =~ s/^\s+//;	# Remove leading spaces

	# Skip to "Ticker Trend"
	for (my $i = 0; $i <= 2; $i++) {
		push @fixed, shift @yahoo;
	}
	# Cleanup "Ticker Trend"
	$yahoo[0] =~ s/&nbsp;//g;
	push @fixed, shift @yahoo;

	# Skip to "Float Shares"
	for (my $i = 0; $i <= 23; $i++) {
		push @fixed, shift @yahoo;
	}
	# Fix "Float Shares" if more than 999.
	while(1) {
		if( (length($yahoo[0]) != 3) || ($yahoo[0] !~ /\d\d\d/) ) {last;}
		$fixed[$#fixed] .= shift @yahoo;
	}
	$fixed[$#fixed] =~ s/^\s+//;	# Remove leading spaces
	@fixed = (@fixed, @yahoo);
	return \@fixed;
