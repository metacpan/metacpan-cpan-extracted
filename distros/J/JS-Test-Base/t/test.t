use lib 'lib';
use Test::More tests => 1;

use JS::Test::Base;

is $JS::Test::Base::VERSION, '0.16',
    'Perl Module loads';
