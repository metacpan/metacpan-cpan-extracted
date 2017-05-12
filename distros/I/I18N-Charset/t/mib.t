# $Revision: 1.5 $
# mib.t - Tests for converting mib numbers back to charset names

use Test::More tests => 25;
BEGIN { use_ok('I18N::Charset') };

#================================================
# TESTS FOR mib routine
#================================================

#---- selection of examples which should all result in undef -----------
ok(!defined mib_charset_name(), q{no argument});
ok(!defined mib_charset_name(undef), q{undef argument});
ok(!defined mib_charset_name(""), q{empty argument});
ok(!defined mib_charset_name("junk"), q{illegal code});
ok(!defined mib_charset_name(9999999), q{illegal code});
ok(!defined mib_charset_name("None"), q{"None" is ignored});
my @aa;
ok(!defined mib_charset_name(\@aa), q{illegal argument});

# The same things, in the opposite direction:
ok(!defined charset_name_to_mib(), q{no argument});
ok(!defined charset_name_to_mib(undef), q{undef argument});
ok(!defined charset_name_to_mib(""), q{empty argument});
ok(!defined charset_name_to_mib("junk"), q{illegal code});
ok(!defined charset_name_to_mib(9999999), q{illegal code});
ok(!defined charset_name_to_mib("None"), q{"None" is ignored});
ok(!defined charset_name_to_mib(\@aa), q{illegal argument});

 #---- some successful examples -----------------------------------------
ok(mib_charset_name("3") eq "US-ASCII", q{3 is US-ASCII});
ok(mib_charset_name("106") eq "UTF-8", q{106 is UTF-8});
ok(mib_to_charset_name("1015") eq "UTF-16", q{1015 is UTF-16});
ok(mib_to_charset_name("17") eq "Shift_JIS", q{17 is Shift_JIS});

# The same things, in the opposite direction:
ok(charset_name_to_mib("ecma cyrillic") eq '77', q{ecma cyr is 77});
ok(charset_name_to_mib("UTF-8") == 106, q{UTF-8 is 106});
ok(charset_name_to_mib("UTF-16") == 1015, q{UTF-16 is 1015});
ok(charset_name_to_mib('s h i f t j i s') eq '17', q{s h i f t is 17});

# This is the FIRST entry in the IANA list:
ok(charset_name_to_mib("ANSI_X3.4-1968") eq '3', q{first entry});
# This is the LAST entry in the IANA list:
ok(charset_name_to_mib('CP50220') == 2260, q{last entry});

exit 0;

__END__
