use strict;

use Test::More;

BEGIN {
    use_ok 'HTTP::Exception::1XX';
    use_ok 'HTTP::Exception::2XX';
    use_ok 'HTTP::Exception::3XX';
    use_ok 'HTTP::Exception::4XX';
    use_ok 'HTTP::Exception::5XX';
    use_ok 'HTTP::Exception::Base';
    use_ok 'HTTP::Exception';
}

# use_ok 'HTTP::Exception::Loader' removed because it emits redefined
# warnings, it's not recommended to use Loader directly anyway

done_testing;