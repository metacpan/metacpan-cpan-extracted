use Test::More tests => 2;

use Locales unicode => 0;
use String::UnicodeUTF8;

my $name = Locales->new("es")->get_language_from_code;
is( length($name), 8, 'data is bytes when unicode false' );
ok( !String::UnicodeUTF8::is_unicode($name), 'result is bytes string' );
