#!perl -w

use strict;
use warnings;
use Test::More tests => 1;

use Digest::MD6;

my $md6 = Digest::MD6->new;
$md6->add_bits( "01111111" );
is $md6->hexdigest,
 '5e3a11d8d5d3540278d57aa4a366e28d1310f3740d419f01572c302a613d738c',
 'digest';
#eval { $md6->add_bits( '0111' ); };
#like $@ , qr/must be multiple of 8/, 'error';
