use Test::More;

BEGIN {
	*CORE::GLOBAL::readpipe = sub { $_[0] }
}

use Mac::OSA::Notification::Tiny qw/all/;

my $line = notification(
	m => 'Quit Smoking',
);

is($line, 'osascript -e "display notification \"Quit Smoking\""', $line);


$line = notification(
	m => 'Welcome to the world',
	t => 'World-Wide.World',
);

is($line, 'osascript -e "display notification \"Welcome to the world\" with title \"World-Wide.World\""', $line);

$line = notification(
	m => 'Goodbye',
	t => 'A different Title',
	s => 'A subtitle',
);

is($line, 'osascript -e "display notification \"Goodbye\" with title \"A different Title\" subtitle \"A subtitle\""', $line);

$line = notification(
	m => 'ALL',
	t => 'ALL EXISTING OPTIONS',
	s => 'view.jpg',
	n => 'Basso',
);

is($line, 'osascript -e "display notification \"ALL\" with title \"ALL EXISTING OPTIONS\" subtitle \"view.jpg\" sound name \"Basso\""', $line);

done_testing();
