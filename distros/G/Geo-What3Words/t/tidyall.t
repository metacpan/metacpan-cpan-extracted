use strict;
use warnings;
use Test::More;

if (not($ENV{AUTHOR_TESTING} || $ENV{TEST_AUTHOR})) {
    plan(skip_all => 'Author test. Set $ENV{AUTHOR_TESTING} to a true value to run.');
}

eval { require Test::Code::TidyAll; };
if ($@) {
    plan(skip_all => 'Test::Code::TidyAll required to check code formatting');
}

Test::Code::TidyAll::tidyall_ok();
