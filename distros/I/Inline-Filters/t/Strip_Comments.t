BEGIN { print "1..2\n"; }
use Inline C => <<'END', FILTERS => 'Strip_Comments';

int do_something(/* this is a 
	multiline
	ugly
	comment */
	int a, // what is this?
	char *b /* nothing else */
	) { printf("%s\n",b); return a + strlen(b); }

const char * f = "\n\
  // How the heck are you?\n\
";

END

print "not " unless do_something(10, "Yahoo!") == 16;
print "ok 1\n";
print "not " unless do_something(-1, "Hello, World!") == 12;
print "ok 2\n";
