use strict;
use warnings;

use Test::More tests => 5;

use_ok('Email::Valid');
use_ok('LWP::UserAgent');
use_ok('JSON');
use_ok( 'List::MoreUtils', qw(uniq) );
use_ok('Github::Email');

done_testing;
