use warnings;
use strict;
use InlineX::C2XS qw(c2xs);
use Test::More tests => 5;
use Test::Warn;

my $xs = './testing/test.xs';
my ($seen_headers, $seen_target) = (0, 0);

my %config_opts = (
                  'AUTOWRAP' => 1,
                  'PRE_HEAD' => "#define MUMBO_JUMBO 5432\n",
                  'AUTO_INCLUDE' => '#include <simple.h>' . "\n" .'#include "src/extra_simple.h"',
                  'TYPEMAPS' => 'src/simple_typemap.txt',
                  'INC' => '-Isrc',
                  );

my $w1 = 'Unsuccessful stat';
warning_like {c2xs('test', 'test', './testing', \%config_opts)} qr/$w1/, 'test 1';

open RD, '<', $xs or die "Can't open $xs for reading: $!";

# Check that MUMBO_JUMBO is defined before the inclusion of EXTERN.h.

while(<RD>) {
  if($_ =~ /EXTERN\.h/) { $seen_headers++ }
  if($_ =~ /MUMBO_JUMBO/) {
    $seen_target++;
    if($seen_headers) {
      warn "\$seen_headers: $seen_headers\n";
      }
    ok($seen_headers == 0 && $seen_target == 1, 'test 2');
  }
}


if($seen_headers != 1) {
  warn "\$seen_headers: $seen_headers\n";
}

ok($seen_headers == 1, 'test 3');

close RD or die "Can't close $xs after reading: $!";

$xs = './testing2/test.xs';

($seen_headers, $seen_target) = (0, 0);

$config_opts{PRE_HEAD} = 't/prehead.in';

c2xs('test', 'test', './testing2', \%config_opts);

open RD2, '<', $xs or die "Can't open $xs for reading: $!";

while(<RD2>) {
  if($_ =~ /EXTERN\.h/) { $seen_headers++ }
  if($_ =~ /SOMETHING_ELSE/) {
    $seen_target++;
    if($seen_headers) {
      warn "\$seen_headers: $seen_headers\n";
      }
    ok($seen_headers == 0 && $seen_target == 1, 'test 4');
  }
}

if($seen_headers != 1) {
  warn "\$seen_headers: $seen_headers\n";
}

ok($seen_headers == 1, 'test 5');

close RD2 or die "Can't close $xs after reading: $!";

unlink('./testing/INLINE.h', './testing/test.xs', './testing2/INLINE.h', './testing2/test.xs');
