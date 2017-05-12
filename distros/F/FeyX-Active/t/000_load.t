#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 7;
use Test::Exception;

BEGIN {
    use_ok('FeyX::Active::Schema');
    use_ok('FeyX::Active::Table');

    use_ok('FeyX::Active::SQL');
    use_ok('FeyX::Active::SQL::Select');
    use_ok('FeyX::Active::SQL::Update');
    use_ok('FeyX::Active::SQL::Delete');
    use_ok('FeyX::Active::SQL::Insert');
}

