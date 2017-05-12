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

use Lingua::KO::Hangul::Util "isStandardForm";

ok(1);

#########################


ok(isStandardForm(""));
ok(!isStandardForm("\x{1100}")); # L
ok(!isStandardForm("\x{1112}")); # L
ok(!isStandardForm("\x{115F}")); # Lf
ok(!isStandardForm("\x{1160}")); # Vf
ok(!isStandardForm("\x{1161}")); # V
ok(!isStandardForm("\x{1175}")); # V
ok(!isStandardForm("\x{11A2}")); # V
ok(!isStandardForm("\x{11A8}")); # T
ok(!isStandardForm("\x{11C2}")); # T
ok(!isStandardForm("\x{11F9}")); # T
ok(isStandardForm("\x{AC00}"));  # LV
ok(isStandardForm("\x{AC01}"));  # LVT
ok(isStandardForm("\x{D7A3}"));  # LVT

# L L Vf
ok(isStandardForm("\x{1112}\x{1112}\x{1160}"));
# L V
ok(isStandardForm("\x{1112}\x{1175}"));
# L T
ok(!isStandardForm("\x{1112}\x{11C2}"));
# L LV
ok(isStandardForm("\x{1112}\x{AC00}"));
# L LVT
ok(isStandardForm("\x{1112}\x{D7A3}"));
# L M
ok(!isStandardForm("\x{1112}\x{0300}"));

# Lf V L Vf
ok(isStandardForm("\x{115F}\x{1175}\x{1112}\x{1160}"));
# Lf V V
ok(isStandardForm("\x{115F}\x{1175}\x{1175}"));
# Lf V T
ok(isStandardForm("\x{115F}\x{1175}\x{11C2}"));
# Lf V LV
ok(isStandardForm("\x{115F}\x{1175}\x{AC00}"));
# Lf V LVT
ok(isStandardForm("\x{115F}\x{1175}\x{D7A3}"));
# Lf V M
ok(isStandardForm("\x{115F}\x{1175}\x{0300}"));

# Lf Vf T L Vf
ok(isStandardForm("\x{115F}\x{1160}\x{11C2}\x{1112}\x{1160}"));
# Lf Vf T V
ok(!isStandardForm("\x{115F}\x{1160}\x{11C2}\x{1175}"));
# Lf Vf T T
ok(isStandardForm("\x{115F}\x{1160}\x{11C2}\x{11C2}"));
# Lf Vf T LV
ok(isStandardForm("\x{115F}\x{1160}\x{11C2}\x{AC00}"));
# Lf Vf T LVT
ok(isStandardForm("\x{115F}\x{1160}\x{11C2}\x{D7A3}"));
# Lf Vf T M
ok(isStandardForm("\x{115F}\x{1160}\x{11C2}\x{0300}"));

# LV L Vf
ok(isStandardForm("\x{AC00}\x{1112}\x{1160}"));
# LV V
ok(isStandardForm("\x{AC00}\x{1175}"));
# LV T
ok(isStandardForm("\x{AC00}\x{11C2}"));
# LV LV
ok(isStandardForm("\x{AC00}\x{AC00}"));
# LV LVT
ok(isStandardForm("\x{AC00}\x{D7A3}"));
# LV M
ok(isStandardForm("\x{AC00}\x{0300}"));

# LVT L Vf
ok(isStandardForm("\x{AC01}\x{1112}\x{1160}"));
# LVT V
ok(!isStandardForm("\x{AC01}\x{1175}"));
# LVT T
ok(isStandardForm("\x{AC01}\x{11C2}"));
# LVT LV
ok(isStandardForm("\x{AC01}\x{AC00}"));
# LVT LVT
ok(isStandardForm("\x{AC01}\x{D7A3}"));
# LVT M
ok(isStandardForm("\x{AC01}\x{0300}"));

# NA L Vf
ok(isStandardForm("\x{0100}\x{1112}\x{1160}"));
# NA V
ok(!isStandardForm("\x{0100}\x{1175}"));
# NA T
ok(!isStandardForm("\x{0100}\x{11C2}"));
# NA LV
ok(isStandardForm("\x{0100}\x{AC00}"));
# NA LVT
ok(isStandardForm("\x{0100}\x{D7A3}"));
# NA M
ok(isStandardForm("\x{0100}\x{0300}"));

