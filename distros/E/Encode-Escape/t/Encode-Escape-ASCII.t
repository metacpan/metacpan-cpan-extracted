# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Encode-Escape-ASCII.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 9;
BEGIN { use_ok('Encode::Escape::ASCII') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

ok defined &encode, "import Encode's encode() function";
ok defined &decode, "import Encode's decode() function";

$string = "\a\b\e\f\n\r\t\\\"\$\@";
$escaped = "\\a\\b\\e\\f\\n\\r\\t\\\\\\\"\\\$\\\@"; 

is	$string, 
	(decode 'ascii-escape', $escaped),
	'decoded character escape sequences';
is	$escaped, 
	(encode 'ascii-escape', $string), 
	'encoded character escape sequences';

$string_oct = "\0\00\000\11\011\100";
$escaped_oct = "\\0\\00\\000\\11\\011\\100";

is	$string_oct, 
	(decode 'ascii-escape', $escaped_oct), 
	'decoded octal escape sequences';

$string_hex = "\x09\x47\x57\x67\x77";
$escaped_hex = "\\x09\\x47\\x57\\x67\\x77";

is	$string_hex, 
	(decode 'ascii-escape', $escaped_hex), 
	'decoded hex escape sequences';

$string_non_printing 
	= "\x00\x01\x02\x03\x04\x05\x06\x07\x08\x09\x0a\x0b\x0c\x0d\x0e" .
	  "\x10\x11\x12\x13\x14\x15\x16\x17\x18\x19\x1a\x1b\x1c\x1d\x1e" .
	  "\x7f";
$escaped_non_printing 
	= "\\x00\\x01\\x02\\x03\\x04\\x05\\x06\\a\\b\\t\\n\\x0b\\f\\r\\x0e" .
      "\\x10\\x11\\x12\\x13\\x14\\x15\\x16\\x17\\x18\\x19\\x1a\\e\\x1c\\x1d\\x1e" .
	  "\\x7f";

is $string_non_printing,
	(decode 'ascii-escape', $escaped_non_printing),
	'decoded non-printing characters';
is $escaped_non_printing,
	(encode 'ascii-escape', $string_non_printing),
	'encoded non-printing characters';


