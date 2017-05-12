use warnings;
use strict;
use Math::MPC qw(:mpc);
use Math::MPFR qw(:mpfr);

print "1..8\n";


Rmpc_set_default_prec2(64, 64);

my $mpc = Math::MPC->new(6.5, 8.25); # 6.5000000000000000+I*8.2500000000000000 (39 characters)
my $ret;
open(WR1, '>', 'out1.txt') or die "Can't open WR1: $!";
open(WR2, '>', 'out2.txt') or die "Can't open WR2: $!";
open(WR3, '>', 'out3.txt') or die "Can't open WR3: $!";
open(WR4, '>', 'out4.txt') or die "Can't open WR4: $!";
open(WR5, '>', 'out5.txt') or die "Can't open WR5: $!";
open(WR6, '>', 'out6.txt') or die "Can't open WR6: $!";
open(WR7, '>', 'out7.txt') or die "Can't open WR7: $!";

my $prefix = "This is the prefix ";
my $suffix = " and this is the suffix\n";

# No prefix, no suffix - the five numbers will all be
# strung together on the one line.
for(1..5) {
   $ret = TRmpc_out_str(\*WR1, 10, 0, $mpc, MPC_RNDNN);
   print WR7 "From the first loop\n";
}

# Prefix, but no suffix - again, the output will be
# strung together on the one line.
for(1..5) {
   $ret = TRmpc_out_str($prefix, \*WR2, 10, 0, $mpc, MPC_RNDNN);
   print WR7 "From the second loop";
}

# Suffix, but no prefix - this file will contain 5 lines.
for(1..5) {
   $ret = TRmpc_out_str(\*WR3, 10, 0, $mpc, MPC_RNDNN, $suffix);
   print WR7 "\nFrom the third loop";
}

print WR7 "\n";

# Both prefix and suffix - this file will contain 5 lines.
for(1..5) {
   $ret = TRmpc_out_str($prefix, \*WR4, 10, 0, $mpc, MPC_RNDNN, $suffix);
   print WR7 "From the fourth loop\n";
}

$prefix .= "\n";

# Prefix, but no suffix - this file will contain 6 lines.
for(1..5) {
   $ret = TRmpc_out_str($prefix, \*WR5, 10, 0, $mpc, MPC_RNDNN);
   print WR7 "From the fifth loop";
}

# Both prefix and suffix - this file will contain 10 lines -
# the prefix appearing on one line, the number and the suffix
# appearing on the next.
for(1..5) {
   $ret = TRmpc_out_str($prefix, \*WR6, 10, 0, $mpc, MPC_RNDNN, $suffix);
   print WR7 "From the sixth loop";
}

close WR1 or die "Can't close WR1: $!";
close WR2 or die "Can't close WR2: $!";
close WR3 or die "Can't close WR3: $!";
close WR4 or die "Can't close WR4: $!";
close WR5 or die "Can't close WR5: $!";
close WR6 or die "Can't close WR6: $!";
close WR7 or die "Can't close WR7: $!";

open(RD1, '<', 'out1.txt') or die "Can't open RD1: $!";
open(RD2, '<', 'out2.txt') or die "Can't open RD2: $!";
open(RD3, '<', 'out3.txt') or die "Can't open RD3: $!";
open(RD4, '<', 'out4.txt') or die "Can't open RD4: $!";
open(RD5, '<', 'out5.txt') or die "Can't open RD5: $!";
open(RD6, '<', 'out6.txt') or die "Can't open RD6: $!";
open(RD7, '<', 'out7.txt') or die "Can't open RD7: $!";

my $ok = 1;
my $count = 0;

while(<RD1>) {
     $count = $.;
     chomp;
     unless($_ eq '(6.50000000000000000000 8.25000000000000000000)'x5) {$ok = 0}
}

if($ok && $count == 1) {print "ok 1\n"}
else {print "not ok 1 $ok $count\n"}


$ok = 1;
$count = 0;

while(<RD2>) {
     $count = $.;
     chomp;
     unless($_ eq 'This is the prefix (6.50000000000000000000 8.25000000000000000000)'x5) {$ok = 0}
}

if($ok && $count == 1) {print "ok 2\n"}
else {print "not ok 2 $ok $count\n"}

$ok = 1;
$count = 0;

while(<RD3>) {
     $count = $.;
     chomp;
     unless($_ eq '(6.50000000000000000000 8.25000000000000000000) and this is the suffix') {$ok = 0}
}

if($ok && $count == 5) {print "ok 3\n"}
else {print "not ok 3 $ok $count\n"}

$ok = 1;
$count = 0;

while(<RD4>) {
     $count = $.;
     chomp;
     unless($_ eq 'This is the prefix (6.50000000000000000000 8.25000000000000000000) and this is the suffix') {$ok = 0}
}

if($ok && $count == 5) {print "ok 4\n"}
else {print "not ok 4 $ok $count\n"}

$ok = 1;
$count = 0;

while(<RD5>) {
     $count = $.;
     chomp;
     if($. == 1) {
       unless($_ eq 'This is the prefix ') {$ok = 0}
     }
     elsif($. == 6) {
       unless($_ eq '(6.50000000000000000000 8.25000000000000000000)') {$ok = 0}
     }
     else {
       unless($_ eq '(6.50000000000000000000 8.25000000000000000000)This is the prefix ') {$ok = 0}
     }
}

if($ok && $count == 6) {print "ok 5\n"}
else {print "not ok 5 $ok $count\n"}

$ok = 1;
$count = 0;

while(<RD6>) {
     $count = $.;
     chomp;
     if($. & 1) {
       unless($_ eq 'This is the prefix ') {$ok = 0}
     }
     else {
       unless($_ eq '(6.50000000000000000000 8.25000000000000000000) and this is the suffix') {$ok = 0}
     }
}

if($ok && $count == 10) {print "ok 6\n"}
else {print "not ok 6 $ok $count\n"}

$ok = 1;
$count = 0;

while(<RD7>) {
     $count = $.;
     chomp;
     if($. <= 5 && $. >= 1) {
       unless($_ eq 'From the first loop') {$ok = 0}
     }
     if($. == 6) {
       unless($_ eq 'From the second loop' x 5) {$ok = 0}
     }
     if($. <= 11 && $. >= 7) {
       unless($_ eq 'From the third loop') {$ok = 0}
     }
     if($. <= 16 && $. >= 12) {
       unless($_ eq 'From the fourth loop') {$ok = 0}
     }
     if($. == 17) {
       unless($_ eq 'From the fifth loop' x 5 . 'From the sixth loop' x 5) {$ok = 0}
     }
}

if($ok && $count == 17) {print "ok 7\n"}
else {print "not ok 7 $ok $count\n"}

close RD1 or die "Can't close RD1: $!";
close RD2 or die "Can't close RD2: $!";
close RD3 or die "Can't close RD3: $!";
close RD4 or die "Can't close RD4: $!";
close RD5 or die "Can't close RD5: $!";
close RD6 or die "Can't close RD6: $!";
close RD7 or die "Can't close RD7: $!";

open(WR8, '>', 'out1.txt') or die "Can't open WR8: $!";
#print WR8 "6.5000000000000000\n";
#print WR8 "+I*\n";
#print WR8 "8.2500000000000000\n";
print WR8 "(6.5000000000000000 8.2500000000000000)\n";
close WR8 or die "Can't close WR8: $!";

open(RD8, '<', 'out1.txt') or die "Can't open RD8: $!";
$ret = TRmpc_inp_str($mpc, \*RD8, 10, MPC_RNDNN);
close RD8 or die "Can't close RD8: $!";

my $real = Math::MPFR->new();
my $im = Math::MPFR->new();

RMPC_RE($real, $mpc);
RMPC_IM($im, $mpc);

if($ret == 0 && $real == 6.5 && $im == 8.25) {print "ok 8\n"}
else {print "not ok 8 $ret $real $im $mpc\n"}


