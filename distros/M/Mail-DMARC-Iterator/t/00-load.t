use strict;
use warnings;
use Test::More;

plan tests => 1;
is(eval "use Mail::DMARC::Iterator;1",1,"loaded");
