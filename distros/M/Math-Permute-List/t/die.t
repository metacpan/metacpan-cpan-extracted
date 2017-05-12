use Test::More qw(no_plan);

use Math::Permute::List;

my $a = '';

eval {permute {$a .= "@_\n"; die;} 1..2};


ok $a eq << 'end';
1 2
end

