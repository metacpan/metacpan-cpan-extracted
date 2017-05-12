#!/usr/bin/perl -w
use Test::More;
use strict;

BEGIN { plan tests => 14 }

use Mac::Gestalt;

SKIP: {
#	skip "Mac::Gestalt", 14;

	my $sel;

	$sel = $Gestalt{'pclk'};
	ok($sel, sprintf('%s MHz Clock Speed', $sel/1000000));

	ok(gestaltPhysicalRAMSize() eq 'ram ');
	$sel = $Gestalt{gestaltPhysicalRAMSize()};
	ok($sel, sprintf('%s MB Physical RAM', $sel/1048576));

	ok(gestaltLogicalRAMSize() eq 'lram');
	$sel = $Gestalt{gestaltLogicalRAMSize()};
	ok($sel, sprintf('%s MB Logical RAM', $sel/1048576));

	ok(gestaltSystemVersion() eq 'sysv');
	$sel = $Gestalt{gestaltSystemVersion()};
	my @vers = split //, sprintf "%x", $sel;
	my $vers = sprintf "%s.%s.", pop(@vers), pop(@vers);
	$vers = join('', @vers) . reverse $vers;
	ok($sel, "OS v$vers (old method)");

	ok(gestaltSystemVersionMajor()  eq 'sys1');
	ok(gestaltSystemVersionMinor()  eq 'sys2');
	ok(gestaltSystemVersionBugFix() eq 'sys3');
	$sel = $Gestalt{gestaltSystemVersionMajor()}
		. '.' . $Gestalt{gestaltSystemVersionMinor()}
		. '.' . $Gestalt{gestaltSystemVersionBugFix()};
	ok($sel, "OS v$vers");


	ok(gestaltAUXVersion() eq 'a/ux');
	$sel = $Gestalt{gestaltAUXVersion()};
	ok(!$sel, "Not running A/UX");

	$sel = $Gestalt{gestaltAliasMgrAttr()};
	ok(($sel & (1 << gestaltAliasMgrPresent)) == 1, "Alias manager present");
}

__END__
