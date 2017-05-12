#!perl
use strict;
use warnings;
use Test::More tests => 2;

use_ok('Marketplace::Rakuten::Utils');

my $deep = {
            test => {},
            items => [],
            good => { hello => 'there' }, 
           };

Marketplace::Rakuten::Utils::turn_empty_hashrefs_into_empty_strings($deep);
is_deeply($deep, { test => '', good => { hello => 'there' }, items => [] },
          "empty hashref is now an empty string");
