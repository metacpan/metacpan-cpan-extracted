use strict;
use warnings;

use Test::More 0.88;

use Fey::Object::Iterator::FromArray;
use Fey::SQL;

use lib 't/lib';

use Fey::ORM::Test::Iterator;
use Fey::Test;

Fey::ORM::Test::Iterator::run_shared_tests(
    'Fey::Object::Iterator::FromArray');

done_testing();
