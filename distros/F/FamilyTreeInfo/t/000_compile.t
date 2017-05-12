use strict;
use warnings;
use utf8;

use FindBin qw($Bin);
use lib "$Bin/../lib";
use Test::More tests => 3;

BEGIN {
	use_ok 'Ftree::FamilyTreeGraphics';
	use_ok 'Ftree::FamilyTreeInfo';
	use_ok 'Ftree::PersonPage';
}
