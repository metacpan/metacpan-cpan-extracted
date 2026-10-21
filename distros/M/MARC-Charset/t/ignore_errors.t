use strict;
use warnings;
use Test::More tests => 11;

use_ok('MARC::Charset', qw(marc8_to_utf8 utf8_to_marc8));

# MARC::Charset warns about each character it can't map; collect those
# warnings instead of printing them.
my @warnings;
local $SIG{__WARN__} = sub { push @warnings, @_ };

# U+1F600 has no MARC-8 equivalent. U+00E9 maps to an acute accent (0xE2)
# before the 'e'.
my $utf8  = "caf\x{e9} \x{1F600} x";
my $marc8 = "caf\x{e2}e  x";

# 0xBF is not a valid MARC-8 character in the default character sets.
my $bad_marc8 = "Caf\x{e2}e \x{bf} x";
my $bad_utf8  = "Cafe\x{301}  x";   # marc8_to_utf8() leaves the accent decomposed

# utf8_to_marc8()
is(MARC::Charset->ignore_errors(), 0, 'errors are not ignored by default');

@warnings = ();
is(utf8_to_marc8($utf8), undef, 'utf8_to_marc8: unmappable character returns nothing by default');
ok(scalar(grep { /no mapping found/ } @warnings), 'utf8_to_marc8: and warns about it');

@warnings = ();
is(utf8_to_marc8($utf8, 1), $marc8, 'utf8_to_marc8: only the unmappable character is dropped with ignore_errors');
ok(scalar(grep { /no mapping found/ } @warnings), 'utf8_to_marc8: and still warns about it');

MARC::Charset->ignore_errors(1);
is(utf8_to_marc8($utf8), $marc8, 'utf8_to_marc8: the global ignore_errors setting works too');
is(utf8_to_marc8("\x{1F600}"), '', 'utf8_to_marc8: a string with nothing mappable comes out empty');
MARC::Charset->ignore_errors(0);

is(utf8_to_marc8($utf8, 0), undef, 'utf8_to_marc8: an explicit false argument overrides the setting');

# marc8_to_utf8(), for comparison
is(marc8_to_utf8($bad_marc8), undef, 'marc8_to_utf8: unmappable character returns nothing by default');
is(marc8_to_utf8($bad_marc8, 1), $bad_utf8, 'marc8_to_utf8: only the unmappable character is dropped with ignore_errors');
