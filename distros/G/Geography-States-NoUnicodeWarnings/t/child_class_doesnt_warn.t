#!/usr/bin/env perl

use strict;
use warnings;
no warnings 'uninitialized';

use Test::More qw(no_plan);

use open ':encoding(utf8)';
my $warnings;
local $SIG{__WARN__} = sub { $warnings .= shift };
require Geography::States::NoUnicodeWarnings;
is($warnings, undef,
    'No warnings when importing Geography::States::NoUnicodeWarnings');
my $object_us = Geography::States->new('usa');
ok($object_us, 'We have a US object');
is($object_us->state('MA'), 'Massachusetts', 'It appears to work');
