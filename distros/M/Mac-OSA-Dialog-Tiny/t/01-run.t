use Test::More;

BEGIN {
	*CORE::GLOBAL::readpipe = sub { $_[0] }
}

use Mac::OSA::Dialog::Tiny qw/all/;

my $line = dialog(
	m => 'Quit Smoking',
);

is($line, 'osascript -e "display dialog \"Quit Smoking\""', $line);

$line = dialog(
	m => 'Welcome to the world',
	t => 'World-Wide.World',
);

is($line, 'osascript -e "display dialog \"Welcome to the world\" with title \"World-Wide.World\""', $line);


$line = dialog(
	m => 'Goodbye',
	t => 'A different Title',
	i => 'view.jpg',
);

is($line, 'osascript -e "display dialog \"Goodbye\" with title \"A different Title\" with icon POSIX file \"${PWD}/view.jpg\""', $line);

$line = dialog(
	m => 'ALL',
	t => 'ALL EXISTING OPTIONS',
	i => 'view.jpg',
	b => ['aOk'],
);

is($line, 'osascript -e "display dialog \"ALL\" with title \"ALL EXISTING OPTIONS\" with icon POSIX file \"${PWD}/view.jpg\" buttons { \"aOk\" }"', $line);

done_testing();
