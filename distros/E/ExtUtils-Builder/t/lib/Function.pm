package Function;

use strict;
use warnings;

use Exporter 5.57 'import';
our @EXPORT = qw/callback/;

sub callback {
	$::callback->(@_);
}

1;
