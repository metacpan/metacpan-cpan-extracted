package Error::Exception::Test::Helper::UncaughtTest;

use strict;
use warnings;

use Error::Exception::Test::Helper::TestExceptions;

use base qw( Test::Unit::TestCase );

sub test_meant_to_throw_exception {
    Error::Exception::Test::NoFields->throw();
}

1;
