package Data;

use strict;
use warnings;

use Moo;

our $VERSION = '2.01';

# -----------------------------------------------

sub read_file
{
	my($self, $file_name) = @_;

	open(my $fh, $file_name) || die "Can't open($file_name): $!";
	my($html);
	read($fh, $html, -s $fh);
	close $fh;

	return $html;

} # End of read_file.

# -----------------------------------------------

1;
