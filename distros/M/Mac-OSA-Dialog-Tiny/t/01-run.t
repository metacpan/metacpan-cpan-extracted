use Test::More;

use Mac::OSA::Dialog::Tiny qw/all/;
{
	no strict 'refs'; no warnings 'redefine';
	*Mac::OSA::Dialog::Tiny::qqx = sub { return $_[0] };
}

my $line = dialog(
	m => 'Quit Smoking',
	debug => 1
);

is($line, 'osascript -e "display dialog \"Quit Smoking\""', $line);

$line = dialog(
	m => 'Welcome to the world',
	t => 'World-Wide.World',
	debug => 1
);

is($line, 'osascript -e "display dialog \"Welcome to the world\" with title \"World-Wide.World\""', $line);


$line = dialog(
	m => 'Goodbye',
	t => 'A different Title',
	i => 'view.jpg',
	debug => 1
);

is($line, 'osascript -e "display dialog \"Goodbye\" with title \"A different Title\" with icon POSIX file \"${PWD}/view.jpg\""', $line);

$line = dialog(
	m => 'ALL',
	t => 'ALL EXISTING OPTIONS',
	i => 'view.jpg',
	b => ['aOk'],
	debug => 1
);

is($line, 'osascript -e "display dialog \"ALL\" with title \"ALL EXISTING OPTIONS\" with icon POSIX file \"${PWD}/view.jpg\" buttons { \"aOk\" }"', $line);

ok(1);

done_testing();
