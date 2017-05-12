use 5.008; # Require Version 5.8 or higher
use strict;
use warnings;

use ExtUtils::ParseXS;

my $p = 'twepl_xsubs';

my %arg = (
  'filename' => "$p\.xs"
);

my $s = *STDOUT;
my $t;
open TMP, '>>', \$t;
*STDOUT = *TMP;
ExtUtils::ParseXS::process_file(%arg);
close TMP;
# Restore
*STDOUT = $s;
$t =~ s/\x23ifdef\x20\_\_cplusplus.+$//s;
$t = "#ifndef __TWEPL_XSUBS_C__\n#define __TWEPL_XSUBS_C__\n\n$t#endif\n";
open SAV, ">$p\.c";
print SAV $t;
close SAV;
