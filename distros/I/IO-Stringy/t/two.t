use strict;
use warnings;

use IO::Scalar;
use Test::More tests => 3;

### Open handles on strings:
my $str1 = "Tea for two";
my $str2 = "Me 4 U";
my $str3 = "hello";
my $S1 = IO::Scalar->new(\$str1);
my $S2 = IO::Scalar->new(\$str2);

### Interleave output:
print $S1 ", and two ";
print $S2 ", and U ";
my $S3 = IO::Scalar->new(\$str3);
$S3->print(", world");
print $S1 "for tea";
print $S2 "4 me";

### Verify:
is($str1, "Tea for two, and two for tea", "COHERENT STRING 1");
is($str2, "Me 4 U, and U 4 me", "COHERENT STRING 2");
is($str3, "hello, world", "COHERENT STRING 3");
