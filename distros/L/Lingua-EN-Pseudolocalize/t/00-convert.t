use strict;
use Test::Simple tests => 2;

use Lingua::EN::Pseudolocalize qw( convert deconvert );

my $a_z = 'abcdefghijklmnopqrstuvwxyz th ts st';

my $pl_text = convert($a_z);
ok ($pl_text, 'convert');

my $restored = deconvert($pl_text);
ok ($restored eq $a_z, 'round trip conversion');

