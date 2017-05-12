use strict;
use warnings;
use utf8;

use Test::More tests => 4;

use Lingua::Identify::CLD2 qw/:all/;

is(LanguageCloseSet("hr"), 5, "Croatian has close set defined");
is(LanguageCloseSet("sr"), 5, "Croatian and Serbian have the same close set");

# integer language code works as well
is(LanguageCloseSet(1), 7, "Danish has close set defined");
is(LanguageCloseSet(10), 7, "Danish and Norwegian have the same close set");
