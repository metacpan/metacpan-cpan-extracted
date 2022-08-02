use strict; use warnings;

use Memoize;
use Memoize::Saves;
use Test::More tests => 5;

my $called;
sub dummy { ++$called; 'retval' }

ok tie my %saves, 'Memoize::Saves', HASH => \my %cache, REGEX => qr/^retval/;
ok memoize 'dummy', SCALAR_CACHE => [ HASH => \%saves ], LIST_CACHE => 'FAULT';

is scalar(dummy()), 'retval', 'memoized call';
is scalar(dummy()), 'retval', 'memoized call';

is $called, 1, 'only one call to dummy()';
