use strict;
use Test::More 0.98;

use List::Range;

my $default = List::Range->new();
isa_ok $default, 'List::Range';
is $default->name,  '',     'default name is empty';
is $default->lower, '-Inf', 'default lower is minus infinity';
is $default->upper, '+Inf', 'default upper is plus infinity';

my ($line, $file);
eval { List::Range->new(lower => 2, upper => 1) }; ($line, $file) = (__LINE__, __FILE__);
like $@, qr/^Cannot make a range by 2..1 at $file line $line/, "Cannot make a range by 2..1 at $file line $line";

is +List::Range->new(name => 'foo')->name, 'foo', 'should set name by constructor';
is +List::Range->new(upper => 1)->upper, 1, 'should set upper by constructor';
is +List::Range->new(lower => 1)->lower, 1, 'should set lower by constructor';

my $one_to_ten = List::Range->new(lower => 1, upper => 10);
ok !$one_to_ten->includes(0),  '1..10 is not includes 0';
ok +$one_to_ten->includes(1),  '1..10 is includes 1';
ok +$one_to_ten->includes(5),  '1..10 is includes 5';
ok +$one_to_ten->includes(10), '1..10 is includes 10';
ok !$one_to_ten->includes(11), '1..10 is not includes 11';

ok +$one_to_ten->includes(sub { $_ + 1 }, 0),  '1..10 is includes 0 (_+1)';
ok +$one_to_ten->includes(sub { $_ + 1 }, 1),  '1..10 is includes 1 (_+1)';
ok +$one_to_ten->includes(sub { $_ + 1 }, 5),  '1..10 is includes 5 (_+1)';
ok !$one_to_ten->includes(sub { $_ + 1 }, 10), '1..10 is not includes 10 (_+1)';
ok !$one_to_ten->includes(sub { $_ + 1 }, 11), '1..10 is not includes 11 (_+1)';

is_deeply [$one_to_ten->includes(0..11)],                 [1..10], '1..10 is includes 1..10 by 0..11';
is_deeply [$one_to_ten->includes(sub { $_ + 1 }, 0..11)], [0..9],  '1..10 is includes 0..9 (_+1) by 0..11';

ok +$one_to_ten->excludes(0),  '1..10 is excludes 0';
ok !$one_to_ten->excludes(1),  '1..10 is not excludes 1';
ok !$one_to_ten->excludes(5),  '1..10 is not excludes 5';
ok !$one_to_ten->excludes(10), '1..10 is not excludes 10';
ok +$one_to_ten->excludes(11), '1..10 is excludes 11';

ok !$one_to_ten->excludes(sub { $_ + 1 }, 0),  '1..10 is excludes 0 (_+1)';
ok !$one_to_ten->excludes(sub { $_ + 1 }, 1),  '1..10 is excludes 1 (_+1)';
ok !$one_to_ten->excludes(sub { $_ + 1 }, 5),  '1..10 is excludes 5 (_+1)';
ok +$one_to_ten->excludes(sub { $_ + 1 }, 10), '1..10 is not excludes 10 (_+1)';
ok +$one_to_ten->excludes(sub { $_ + 1 }, 11), '1..10 is not excludes 11 (_+1)';

is_deeply [$one_to_ten->excludes(0..11)],                 [0, 11],   '1..10 is excludes 0, 11 by 0..11';
is_deeply [$one_to_ten->excludes(sub { $_ + 1 }, 0..11)], [10, 11],  '1..10 is excludes 10, 11 (_+1) by 0..11';

is_deeply $default->ranges, [$default], 'ranges should be the array ref includes just self';

is_deeply [$one_to_ten->all], [1..10], 'one to ten velues';
is_deeply [@$one_to_ten], [1..10], 'one to ten velues (by overload)';

eval { $default->all }; ($line, $file) = (__LINE__, __FILE__);
like $@, qr/^lower is infinit at $file line $line/, "lower is infinit at $file line $line";
eval { List::Range->new(lower => 0)->all }; ($line, $file) = (__LINE__, __FILE__);
like $@, qr/^upper is infinit at $file line $line/, "upper is infinit at $file line $line";

done_testing;

