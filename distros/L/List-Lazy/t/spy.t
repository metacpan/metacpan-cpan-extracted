use Test::More tests => 3;
use Test::Warn;

use List::Lazy qw/ lazy_fixed_list /;

my $list = ( lazy_fixed_list 1..5 );

warning_like { $list->spy->next } qr#1.*at t\/spy\.t#;

my $x;
$list->spy( sub { $x .= $_ } )->all;

is $x => 12345;

pass;
