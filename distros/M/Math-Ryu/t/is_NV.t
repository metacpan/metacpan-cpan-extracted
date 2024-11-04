use strict;
use warnings;

use Math::Ryu qw(:all);
use Test::More;

use Math::BigFloat;

is(is_NV(Math::BigFloat->new(1.25)), 0, 'Math::BigFloat');
my $s1 = '1.25';

is(is_NV($s1), 0, 'string');

my $nv1 = $s1 + 1;

is(is_NV($s1), 0, 'string');
is(is_NV($nv1), 1, 'assigned to string + 0');

my $s2 = '1e6000';

if($s2 > 0) {
  is(is_NV($s2), 0, 'string previously used in numeric context');
}

is(spanyf($s2), '1e6000', 'spanyf() returns PV');

my $nv2 = 42.42;
is(is_NV($nv2), 1, 'NV');

my $ref = \$nv2;
is(is_NV($ref), 0, 'reference to NV');

$s2 = "$nv2";
is(is_NV($nv2), 1, 'NV that has been interpolated');
is(is_NV($s2),  0, 'stringification of NV');

my $undef;
is(is_NV($undef), 0, 'undef');

my $empty_string = '';
is(is_NV($empty_string), 0, 'empty string');

my $zero_string = '0.0';
is(is_NV($zero_string), 0, 'zero string');

for('inf', 'Inf', 'nan', 'NaN') {
  is(is_NV($_), 0, 'inf and nan strings' );
}

done_testing();
