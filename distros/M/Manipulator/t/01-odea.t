use Test::More;

use Manipulator qw/manipulate/;

my $manipulate = manipulate(
	test => sub {
		return 'okay'
	},
	other => sub {
		return 'winning'
	}
);

my $data = $manipulate->(test => 1, other => 2);

is_deeply($data, { test => 'okay', other => 'winning' });

$data = $manipulate->ordered(test => 1, other => 2);

is_deeply($data, { test => 'okay', other => 'winning' });

$manipulate = manipulate(sub { return 'okay' });

my @data = $manipulate->(qw/one two three four/);

is_deeply(\@data, ['okay', 'okay', 'okay', 'okay']);

done_testing();
