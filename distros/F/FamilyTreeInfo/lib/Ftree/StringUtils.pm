#!/usr/bin/perl -w

package Ftree::StringUtils;
use strict;
use warnings;
use Params::Validate qw(:all);
use version; our $VERSION = qv('2.3.41');

# Perl trim function to remove whitespace from the start and end of the string
sub trim
{
	my ($string) = validate_pos(@_, {type => SCALAR|UNDEF});
	return rtrim(ltrim($string)) if (defined $string);
}
# Left trim function to remove leading whitespace
sub ltrim
{
	my ($string) = validate_pos(@_, {type => SCALAR|UNDEF});
	$string =~ s/^\s+//;
	return $string;
}
# Right trim function to remove trailing whitespace
sub rtrim
{
	my ($string) = validate_pos(@_, {type => SCALAR|UNDEF});;
	$string =~ s/\s+$//;
	return $string;
}

1;
