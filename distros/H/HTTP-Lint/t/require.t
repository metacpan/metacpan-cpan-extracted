use Test::More tests => 4;

BEGIN {
	use_ok ('HTTP::Lint::UserAgent');
	use_ok ('HTTP::Lint');
}

require_ok ('HTTP::Lint::UserAgent');
require_ok ('HTTP::Lint');
