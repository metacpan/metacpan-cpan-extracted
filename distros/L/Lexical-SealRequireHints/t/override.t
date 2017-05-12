use warnings;
use strict;

BEGIN {
	if("$]" < 5.007002) {
		require Test::More;
		Test::More::plan(skip_all =>
			"CORE::GLOBAL::require can't work on this perl");
	}
}

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

our @require_activity;

BEGIN {
	my $next_require = defined(&CORE::GLOBAL::require) ?
		\&CORE::GLOBAL::require : sub { CORE::require($_[0]) };
	no warnings "redefine";
	*CORE::GLOBAL::require = sub {
		push @require_activity, "a";
		return $next_require->(@_);
	};
}

BEGIN { use_ok "Lexical::SealRequireHints"; }

BEGIN {
	my $next_require = defined(&CORE::GLOBAL::require) ?
		\&CORE::GLOBAL::require : sub { CORE::require($_[0]) };
	no warnings "redefine";
	no warnings "prototype";
	*CORE::GLOBAL::require = sub ($) {
		push @require_activity, "b";
		return $next_require->(@_);
	};
}

BEGIN {
	$^H |= 0x20000 if "$]" < 5.009004;
	$^H{"Lexical::SealRequireHints/test"} = 1;
}

BEGIN {
	is $^H{"Lexical::SealRequireHints/test"}, 1;
	@require_activity = ();
}
use t::seal_0;
BEGIN {
	is $^H{"Lexical::SealRequireHints/test"}, 1;
	is $^H{"Lexical::SealRequireHints/test0"}, 1;
	isnt scalar(@require_activity), 0;
	is_deeply \@require_activity, [("b","a") x (@require_activity>>1)];
}

is_deeply \@warnings, [];

1;
