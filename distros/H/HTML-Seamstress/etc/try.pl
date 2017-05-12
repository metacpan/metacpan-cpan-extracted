use strict;
use warnings;

use HTML::Seamstress;

my $t = HTML::Seamstress->new_from_file('try.html');

warn $t->as_HTML('  ');
