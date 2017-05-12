#!perl -w
use strict;

use Tie::Scalar;
use Tie::Array;
use Devel::Optrace;

my %h;
tie my @a, 'Tie::StdArray';
p($h{foo});
p($a[0]);

tie $0, 'Tie::StdScalar';
p($0);

p(*p, \&p);

p(qr/foo/xms);

p($ENV{PATH});
p(substr($ENV{PATH}, 0, 10));

p(\@Tie::StdScalar::ISA);
p \%strict::
