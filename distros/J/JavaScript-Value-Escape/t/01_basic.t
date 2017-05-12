use strict;
use Test::More;
use JavaScript::Value::Escape;

can_ok('main', 'javascript_value_escape');
is( javascript_value_escape(q!&foo"bar'<b>baz</b>\ / </script>=-;+! . qq!\t\r\nfoo\\!),
    '\u0026foo\u0022bar\u0027\u003cb\u003ebaz\u003c/b\u003e\u005c / '.
    '\u003c/script\u003e\u003d\u002d\u003b\u002b\u0009\u000d\u000afoo\u005c');

is( javascript_value_escape("\x{2028}\x{2029}\x{6771}\x{4eac}\x{7802}\x{6f20}"),
    '\u2028\u2029'."\x{6771}\x{4eac}\x{7802}\x{6f20}");

done_testing();

