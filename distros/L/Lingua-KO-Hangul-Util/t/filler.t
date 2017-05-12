use strict;
use warnings;
BEGIN { $| = 1; print "1..51\n"; }
my $count = 0;
sub ok ($;$) {
    my $p = my $r = shift;
    if (@_) {
	my $x = shift;
	$p = !defined $x ? !defined $r : !defined $r ? 0 : $r eq $x;
    }
    print $p ? "ok" : "not ok", ' ', ++$count, "\n";
}

use Lingua::KO::Hangul::Util "insertFiller";

ok(1);

#########################

sub strhex {
    join ':', map sprintf("%04X", $_), unpack 'U*', pack('U*').shift;
}

ok(strhex(insertFiller("")), "");
ok(strhex(insertFiller("\x{1100}")), "1100:1160"); # L
ok(strhex(insertFiller("\x{1112}")), "1112:1160"); # L
ok(strhex(insertFiller("\x{115F}")), "115F:1160"); # Lf
ok(strhex(insertFiller("\x{1160}")), "115F:1160"); # Vf
ok(strhex(insertFiller("\x{1161}")), "115F:1161"); # V
ok(strhex(insertFiller("\x{1175}")), "115F:1175"); # V
ok(strhex(insertFiller("\x{11A2}")), "115F:11A2"); # V
ok(strhex(insertFiller("\x{11A8}")), "115F:1160:11A8"); # T
ok(strhex(insertFiller("\x{11C2}")), "115F:1160:11C2"); # T
ok(strhex(insertFiller("\x{11F9}")), "115F:1160:11F9"); # T
ok(strhex(insertFiller("\x{AC00}")), "AC00");  # LV
ok(strhex(insertFiller("\x{AC01}")), "AC01");  # LVT
ok(strhex(insertFiller("\x{D7A3}")), "D7A3");  # LVT

# L L Vf
ok(strhex(insertFiller("\x{1112}\x{1112}\x{1160}")), "1112:1112:1160");
# L V
ok(strhex(insertFiller("\x{1112}\x{1175}")), "1112:1175");
# L T
ok(strhex(insertFiller("\x{1112}\x{11C2}")), "1112:1160:115F:1160:11C2");
# L LV
ok(strhex(insertFiller("\x{1112}\x{AC00}")), "1112:AC00");
# L LVT
ok(strhex(insertFiller("\x{1112}\x{D7A3}")), "1112:D7A3");
# L M
ok(strhex(insertFiller("\x{1112}\x{0300}")), "1112:1160:0300");

# Lf V L Vf
ok(strhex(insertFiller("\x{115F}\x{1175}\x{1112}\x{1160}")),
	"115F:1175:1112:1160");
# Lf V V
ok(strhex(insertFiller("\x{115F}\x{1175}\x{1175}")), "115F:1175:1175");
# Lf V T
ok(strhex(insertFiller("\x{115F}\x{1175}\x{11C2}")), "115F:1175:11C2");
# Lf V LV
ok(strhex(insertFiller("\x{115F}\x{1175}\x{AC00}")), "115F:1175:AC00");
# Lf V LVT
ok(strhex(insertFiller("\x{115F}\x{1175}\x{D7A3}")), "115F:1175:D7A3");
# Lf V M
ok(strhex(insertFiller("\x{115F}\x{1175}\x{0300}")), "115F:1175:0300");

# Lf Vf T L Vf
ok(strhex(insertFiller("\x{115F}\x{1160}\x{11C2}\x{1112}\x{1160}")),
	"115F:1160:11C2:1112:1160");
# Lf Vf T V
ok(strhex(insertFiller("\x{115F}\x{1160}\x{11C2}\x{1175}")),
	"115F:1160:11C2:115F:1175");
# Lf Vf T T
ok(strhex(insertFiller("\x{115F}\x{1160}\x{11C2}\x{11C2}")),
	"115F:1160:11C2:11C2");
# Lf Vf T LV
ok(strhex(insertFiller("\x{115F}\x{1160}\x{11C2}\x{AC00}")),
	"115F:1160:11C2:AC00");
# Lf Vf T LVT
ok(strhex(insertFiller("\x{115F}\x{1160}\x{11C2}\x{D7A3}")),
	"115F:1160:11C2:D7A3");
# Lf Vf T M
ok(strhex(insertFiller("\x{115F}\x{1160}\x{11C2}\x{0300}")),
	"115F:1160:11C2:0300");

# LV L Vf
ok(strhex(insertFiller("\x{AC00}\x{1112}\x{1160}")), "AC00:1112:1160");
# LV V
ok(strhex(insertFiller("\x{AC00}\x{1175}")), "AC00:1175");
# LV T
ok(strhex(insertFiller("\x{AC00}\x{11C2}")), "AC00:11C2");
# LV LV
ok(strhex(insertFiller("\x{AC00}\x{AC00}")), "AC00:AC00");
# LV LVT
ok(strhex(insertFiller("\x{AC00}\x{D7A3}")), "AC00:D7A3");
# LV M
ok(strhex(insertFiller("\x{AC00}\x{0300}")), "AC00:0300");

# LVT L Vf
ok(strhex(insertFiller("\x{AC01}\x{1112}\x{1160}")), "AC01:1112:1160");
# LVT V
ok(strhex(insertFiller("\x{AC01}\x{1175}")), "AC01:115F:1175");
# LVT T
ok(strhex(insertFiller("\x{AC01}\x{11C2}")), "AC01:11C2");
# LVT LV
ok(strhex(insertFiller("\x{AC01}\x{AC00}")), "AC01:AC00");
# LVT LVT
ok(strhex(insertFiller("\x{AC01}\x{D7A3}")), "AC01:D7A3");
# LVT M
ok(strhex(insertFiller("\x{AC01}\x{0300}")), "AC01:0300");

# NA L Vf
ok(strhex(insertFiller("\x{0100}\x{1112}\x{1160}")), "0100:1112:1160");
# NA V
ok(strhex(insertFiller("\x{0100}\x{1175}")), "0100:115F:1175");
# NA T
ok(strhex(insertFiller("\x{0100}\x{11C2}")), "0100:115F:1160:11C2");
# NA LV
ok(strhex(insertFiller("\x{0100}\x{AC00}")), "0100:AC00");
# NA LVT
ok(strhex(insertFiller("\x{0100}\x{D7A3}")), "0100:D7A3");
# NA M
ok(strhex(insertFiller("\x{0100}\x{0300}")), "0100:0300");

