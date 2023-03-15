use warnings;
use strict;

use Test::More tests => 10;

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

our @do_activity;

BEGIN {
	my $next_do = defined(&CORE::GLOBAL::do) ?
		\&CORE::GLOBAL::do : sub { CORE::do($_[0]) };
	no warnings "redefine";
	*CORE::GLOBAL::do = sub {
		push @do_activity, "a";
		return $next_do->(@_);
	};
}

BEGIN { use_ok "Lexical::SealRequireHints"; }
BEGIN { unshift @INC, "./t/lib"; }

BEGIN {
	my $next_do = defined(&CORE::GLOBAL::do) ?
		\&CORE::GLOBAL::do : sub { CORE::do($_[0]) };
	no warnings "redefine";
	no warnings "prototype";
	*CORE::GLOBAL::do = sub ($) {
		push @do_activity, "b";
		return $next_do->(@_);
	};
}

BEGIN {
	$^H |= 0x20000 if "$]" < 5.009004;
	$^H{"Lexical::SealRequireHints/test"} = 1;
}

BEGIN {
	is $^H{"Lexical::SealRequireHints/test"}, 1;
	@do_activity = ();
}
BEGIN {
	do "t/seal_0.pm" or die $@ || $!;
	t::seal_0->import;
}
BEGIN {
	is $^H{"Lexical::SealRequireHints/test"}, 1;
	is $^H{"Lexical::SealRequireHints/test0"}, 1;
	isnt scalar(@do_activity), 0;
	is_deeply \@do_activity, [("b","a") x (@do_activity>>1)];
}

is_deeply \@warnings, [];

1;
