use Test::More tests => 1;
use Test::Deep;

use MIME::Words;

cmp_deeply(MIME::Words::decode_mimewords("\nx"),
	   ["\nx"],
	   "Fix for ticket #66025 passes");
