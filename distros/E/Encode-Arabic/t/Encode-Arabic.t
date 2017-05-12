#########################

use Test::More tests => 16;

BEGIN {

    use_ok 'Encode::Arabic';
}

BEGIN {

    use_ok 'Encode::Arabic', 'from_to';
}

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

ok defined &encode, "import Encode's encode() function";
ok defined &decode, "import Encode's decode() function";
ok defined &encode_utf8, "import Encode's encode_utf8() function";
ok defined &decode_utf8, "import Encode's decode_utf8() function";
ok defined &encodings, "import Encode's encodings() function";
ok defined &find_encoding, "import Encode's find_encoding() function";
ok defined &from_to, "import Encode's from_to() function";

ok ref (find_encoding 'arabtex'), 'ArabTeX known with its alias';
ok ref (find_encoding 'arabtex-re'), 'ArabTeX-RE known, too';
ok ref (find_encoding 'arabtex-verbatim'), 'ArabTeX-Verbatim known with its alias';
ok ref (find_encoding 'arabtex-zdmg'), 'ArabTeX-ZDMG known with its alias';
ok ref (find_encoding 'arabtex-zdmg-re'), 'ArabTeX-ZDMG-RE known, too';
ok ref (find_encoding 'buckwalter'), 'Buckwalter known with its alias';
ok ref (find_encoding 'parkinson'), 'Parkinson known with its alias';
