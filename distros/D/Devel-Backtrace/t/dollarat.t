#!perl
use strict;
use warnings;
use Test::More tests => 4;
use Devel::DollarAt;

eval 'print 0/0; "foo"';

# Don't worry about the "foo"; it serves to make perl 5.8 and 5.10 output the
# same line number so I can use this example in the tests.

my $dollarat = $@;

like("$dollarat", qr{^Illegal division by zero at \(eval \d+\) line 1\.$}, 'stringification');

is ($dollarat->line, 1, 'line');

is ($dollarat->backtrace->point(0)->subroutine, '(eval)', 'subroutine is eval');

is ($dollarat->backtrace->point(0)->called_package, '(unknown)', 'called_package');
