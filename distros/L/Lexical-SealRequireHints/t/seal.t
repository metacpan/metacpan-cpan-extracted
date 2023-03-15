use warnings;
use strict;

use Test::More tests => 42;

our @warnings;
BEGIN {
	$^W = 1;
	$SIG{__WARN__} = sub { push @warnings, $_[0] };
}

our $have_runtime_hint_hash;
BEGIN { $have_runtime_hint_hash = "$]" >= 5.009004; }
sub test_runtime_hint_hash($$) {
	SKIP: {
		skip "no runtime hint hash", 1 unless $have_runtime_hint_hash;
		is +((caller(0))[10] || {})->{$_[0]}, $_[1];
	}
}

BEGIN { use_ok "Lexical::SealRequireHints"; }
BEGIN { unshift @INC, "./t/lib"; }

BEGIN {
	$^H |= 0x20000 if "$]" < 5.009004;
	$^H{"Lexical::SealRequireHints/test"} = 1;
}

BEGIN { is $^H{"Lexical::SealRequireHints/test"}, 1; }
test_runtime_hint_hash "Lexical::SealRequireHints/test", 1;

use t::seal_0;

test_runtime_hint_hash "Lexical::SealRequireHints/test", 1;
BEGIN {
	is $^H{"Lexical::SealRequireHints/test"}, 1;
	require t::seal_1;
	t::seal_1->import;
	is $^H{"Lexical::SealRequireHints/test"}, 1;
}
test_runtime_hint_hash "Lexical::SealRequireHints/test", 1;

BEGIN { is $^H{"Lexical::SealRequireHints/test"}, 1; }
test_runtime_hint_hash "Lexical::SealRequireHints/test", 1;

use t::seal_0;

test_runtime_hint_hash "Lexical::SealRequireHints/test", 1;
BEGIN {
	is $^H{"Lexical::SealRequireHints/test"}, 1;
	require t::seal_1;
	t::seal_1->import;
	is $^H{"Lexical::SealRequireHints/test"}, 1;
}
test_runtime_hint_hash "Lexical::SealRequireHints/test", 1;

BEGIN {
	is $^H{"Lexical::SealRequireHints/test"}, 1;
	is $^H{"Lexical::SealRequireHints/test0"}, 2;
	is $^H{"Lexical::SealRequireHints/test1"}, 2;
}
test_runtime_hint_hash "Lexical::SealRequireHints/test", 1;
test_runtime_hint_hash "Lexical::SealRequireHints/test0", 2;
test_runtime_hint_hash "Lexical::SealRequireHints/test1", 2;

BEGIN { is +(1 + require t::seal_2), 11; }

BEGIN {
	eval { require t::seal_3; };
	like $@, qr/\Aseal_3 death\n/;
}

BEGIN {
	eval { require t::seal_4; };
	like $@, qr/\Aseal_4 death\n/;
}

test_runtime_hint_hash "Lexical::SealRequireHints/test", 1;
BEGIN {
	is $^H{"Lexical::SealRequireHints/test"}, 1;
	do "t/seal_d0.pl" or die $@ || $!;
	is $^H{"Lexical::SealRequireHints/test"}, 1;
}
test_runtime_hint_hash "Lexical::SealRequireHints/test", 1;

BEGIN { is +(1 + (do "t/seal_d1.pl")), 21; }

BEGIN {
	is +(do "t/seal_d2.pl"), undef;
	like $@, qr/\Aseal_d2 death\n/;
}

BEGIN {
	is +(do "t/seal_d3.pl"), undef;
	like $@, qr/\Aseal_d3 death\n/;
}

is_deeply \@warnings, [];

1;
