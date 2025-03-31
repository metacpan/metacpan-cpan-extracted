package ExtUtils::Builder::FileSet::Free;
$ExtUtils::Builder::FileSet::Free::VERSION = '0.016';
use strict;
use warnings;

use base 'ExtUtils::Builder::FileSet';

sub add_input {
	my ($self, $entry) = @_;
	$self->_pass_on($entry);
	return $entry;
}

1;
