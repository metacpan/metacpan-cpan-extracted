package t::lib::ShareDir;

use strict;

use vars qw{$VERSION @ISA};
BEGIN {
	$VERSION = '1.06';
	@ISA     = 'File::ShareDir::PAR';
}

1;
