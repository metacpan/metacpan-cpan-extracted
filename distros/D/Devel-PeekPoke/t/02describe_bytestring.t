use strict;
use warnings;

use Test::More;

use Devel::PeekPoke qw/describe_bytestring/;
use Devel::PeekPoke::Constants qw/BIG_ENDIAN/;

my $out = BIG_ENDIAN
  ? <<'EOD'
             Hex  Dec  Oct    Bin     ASCII      32      32+2          64
            --------------------------------  -------- -------- ----------------
0xadeadbeef   48   72  110  01001000    H     48617220          4861722068617209
0xadeadbef0   61   97  141  01100001    a     ___/              _______/
0xadeadbef1   72  114  162  01110010    r     __/      72206861 ______/
0xadeadbef2   20   32   40  00100000  (SP)    _/       ___/     _____/
0xadeadbef3   68  104  150  01101000    h     68617209 __/      ____/
0xadeadbef4   61   97  141  01100001    a     ___/     _/       ___/
0xadeadbef5   72  114  162  01110010    r     __/      72091337 __/
0xadeadbef6   09    9   11  00001001  (HT)    _/       ___/     _/
0xadeadbef7   13   19   23  00010011  (DC3)   1337B00B __/      1337B00B1E552021
0xadeadbef8   37   55   67  00110111    7     ___/     _/       _______/
0xadeadbef9   B0  176  260  10110000  "\260"  __/      B00B1E55 ______/
0xadeadbefa   0B   11   13  00001011  (VT)    _/       ___/     _____/
0xadeadbefb   1E   30   36  00011110  (RS)    1E552021 __/      ____/
0xadeadbefc   55   85  125  01010101    U     ___/     _/       ___/
0xadeadbefd   20   32   40  00100000  (SP)    __/      20212121 __/
0xadeadbefe   21   33   41  00100001    !     _/       ___/     _/
0xadeadbeff   21   33   41  00100001    !              __/
0xadeadbf00   21   33   41  00100001    !              _/
EOD
  : <<'EOD'
             Hex  Dec  Oct    Bin     ASCII      32      32+2          64
            --------------------------------  -------- -------- ----------------
0xadeadbeef   48   72  110  01001000    H     20726148          0972616820726148
0xadeadbef0   61   97  141  01100001    a     ___/              _______/
0xadeadbef1   72  114  162  01110010    r     __/      61682072 ______/
0xadeadbef2   20   32   40  00100000  (SP)    _/       ___/     _____/
0xadeadbef3   68  104  150  01101000    h     09726168 __/      ____/
0xadeadbef4   61   97  141  01100001    a     ___/     _/       ___/
0xadeadbef5   72  114  162  01110010    r     __/      37130972 __/
0xadeadbef6   09    9   11  00001001  (HT)    _/       ___/     _/
0xadeadbef7   13   19   23  00010011  (DC3)   0BB03713 __/      2120551E0BB03713
0xadeadbef8   37   55   67  00110111    7     ___/     _/       _______/
0xadeadbef9   B0  176  260  10110000  "\260"  __/      551E0BB0 ______/
0xadeadbefa   0B   11   13  00001011  (VT)    _/       ___/     _____/
0xadeadbefb   1E   30   36  00011110  (RS)    2120551E __/      ____/
0xadeadbefc   55   85  125  01010101    U     ___/     _/       ___/
0xadeadbefd   20   32   40  00100000  (SP)    __/      21212120 __/
0xadeadbefe   21   33   41  00100001    !     _/       ___/     _/
0xadeadbeff   21   33   41  00100001    !              __/
0xadeadbf00   21   33   41  00100001    !              _/
EOD
;

is(
  describe_bytestring( "Har har\t\x13\x37\xb0\x0b\x1e\x55 !!!", 46685601519 ),
  $out,
  'describe_bytestring works as expected'
);

done_testing;
