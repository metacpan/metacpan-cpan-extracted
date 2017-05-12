use 5.10.0;
use strict;
use warnings;
use utf8;

use Inline::Perl6 'OO';

STDOUT->autoflush(1);
say '1..2';
Inline::Perl6::initialize;
say 'ok 1';
Inline::Perl6::call('say', 'ok 2 -');
Inline::Perl6::destroy;
