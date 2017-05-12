BEGIN { $| = 1; print "1..1\n"; }

use utf8;
use strict;

use HTML::MyHTML;

# init all
my $myhtml = HTML::MyHTML->new(MyHTML_OPTIONS_DEFAULT, 1);
my $tree = $myhtml->new_tree();

# destroy all
$tree->destroy();

print "ok 1\n";
