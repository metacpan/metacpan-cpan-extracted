use Test::More;

use lib 't/test';
use Our;
use Our::Simple;

is($Our::scalar, 'ro');
is_deeply(\%Our::hash, { one => 'two' });
is_deeply(\@Our::array, [qw/one two/]);

is($Our::Simple::scalar, 'ro');
is_deeply(\%Our::Simple::hash, { one => 'two' });
is_deeply(\@Our::Simple::array, [qw/one two/]);

done_testing();
