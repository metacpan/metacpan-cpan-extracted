use warnings;
use strict;

use Test::More tests => 14;

our @warnings;
BEGIN {
	$^W = 1;
	$SIG{__WARN__} = sub { push @warnings, $_[0] };
}

use AutoLoader ();

BEGIN { use_ok "Lexical::SealRequireHints"; }
BEGIN { unshift @INC, "./t/lib"; }

BEGIN {
	$^H |= 0x20000 if "$]" < 5.009004;
	$^H{"Lexical::SealRequireHints/test"} = 1;
}
$^H |= 0x20000 if "$]" < 5.009004;
$^H{"Lexical::SealRequireHints/test"} = 2;

BEGIN { is $^H{"Lexical::SealRequireHints/test"}, 1; }
is $^H{"Lexical::SealRequireHints/test"}, 2;

use t::auto_0 ();

BEGIN { is $^H{"Lexical::SealRequireHints/test"}, 1; }
is $^H{"Lexical::SealRequireHints/test"}, 2;

is t::auto_0::auto_1(), 42;

BEGIN { is $^H{"Lexical::SealRequireHints/test"}, 1; }
is $^H{"Lexical::SealRequireHints/test"}, 2;

is t::auto_0::auto_1(), 42;

BEGIN { is $^H{"Lexical::SealRequireHints/test"}, 1; }
is $^H{"Lexical::SealRequireHints/test"}, 2;

is_deeply \@warnings, [];

1;
