
package Log::Parallel::Sql::Trim;

use strict;
use warnings;
use Encode;
use URI::Escape qw(uri_unescape uri_escape);
require Exporter;

our @ISA = qw(Exporter);
our @EXPORT = qw(encode_and_trim);


sub bytelen
{
	use bytes;
	return length($_[0]);
}

sub encode_and_trim
{
	my ($string, $length) = @_;
	return '' unless defined $string;
	$string = encode('UTF-8' => $string);
	return $string unless $length;
	return $string unless bytelen($string) > $length;

	$string = substr($string, 0, $length);

	for (;;) {
		my $diff = bytelen($string) - $length;
		return $string unless $diff > 0;

		#
		# okay, it's too big and the difference is in the multi-byte characters
		#

		my $l = length($string);
		my $chop = $diff / $l;
		$chop = $l/100 if $chop < $l/100;
		$chop = 1 if $chop < 1;

		substr($string, -$chop) = '';
	}
}

1;

__END__

=head1 NAME

Log::Parallel::Sql::Trim - chop extra long strings to byte limit

=head1 SYNOPSIS

 use Log::Parallel::Sql::Trim;

 $shorter = encode_and_trim($longer, $length_limit);

=head1 DESCRIPTION

This chops a string to a length.  It considers the length to be a byte
limit, but it chops based on characters.  It also encodes the string in
C<UTF-8>.  This is useful for storing strings in a database with a 
limited field length.

=head1 LICENSE

This package may be used and redistributed under the terms of either
the Artistic 2.0 or LGPL 2.1 license.

