#!perl -w
use strict;
use Test::More tests => 4;

BEGIN {
    use_ok 'JSON::Pointer';
    use_ok 'JSON::Pointer::Context';
    use_ok 'JSON::Pointer::Exception';
    use_ok 'JSON::Pointer::Syntax';
}

