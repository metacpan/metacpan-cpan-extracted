package DemoUnPod;
$VERSION = '0.01';

use Filter::Simple;

FILTER_ONLY
	executable => sub { s/x/X/g },
	executable => sub { print }
