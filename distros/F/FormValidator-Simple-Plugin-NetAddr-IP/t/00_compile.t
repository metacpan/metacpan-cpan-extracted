use strict;
use Test::More tests => 1;

require FormValidator::Simple;

eval{
    FormValidator::Simple->import('NetAddr::IP');
};

ok(!$@);