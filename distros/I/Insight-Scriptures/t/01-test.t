use Test::More;
use Insight::Scriptures;

my $new = Insight::Scriptures->new({ directory => 't/directory' });

$new->scripture('test');

is_deeply($new->next, { one => 'two' });

$new->feather(
	two => 'again'
);

$new->feather(
	two => 'after'
);

$new->abolish();

is_deeply($new->abolish, { one => 'two' });

$new->salvage();

done_testing();
