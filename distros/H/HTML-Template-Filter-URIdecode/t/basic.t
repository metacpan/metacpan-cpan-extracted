
use Test::More 'no_plan';

use_ok('HTML::Template::Filter::URIdecode', 'ht_uri_decode');

my $text = '../%3Ctmpl_var%20my_var%3E';

my $after = ht_uri_decode(\$text);

is($text,'<TMPL_VAR my_var>', "basic test");
