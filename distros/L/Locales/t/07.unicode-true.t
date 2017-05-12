use Test::More tests => 2;

use Locales unicode => 1;
use String::UnicodeUTF8;

my $name = Locales->new("es")->get_language_from_code;
is( length($name), 7, 'data is characters when unicode true' );
ok( String::UnicodeUTF8::is_unicode($name), 'result is unicode string' );
