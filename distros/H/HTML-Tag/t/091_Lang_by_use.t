use strict;
use warnings;
use Test;

BEGIN { plan tests => 1 }

# load your module...
use HTML::Tag::Lang::it;
use HTML::Tag::Lang qw(%bool_descr);

print "# I'm testing HTML::Tag::Lang\n";

ok($bool_descr{1},'Si');
