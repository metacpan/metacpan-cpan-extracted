use Test::More tests=>6;
use_ok( 'Formatter::HTML::Textile');

my $source = 'blåbærsyltetøy';

ok(my $formatter = Formatter::HTML::Textile->format($source), "constructor");
ok($formatter->charset('utf-8'), "set charset");

is($formatter->fragment, '<p>blåbærsyltetøy</p>', "no entities");
ok(!$formatter->char_encoding(0), "set charencoding off");
is($formatter->fragment, '<p>blåbærsyltetøy</p>', "still no entities");


