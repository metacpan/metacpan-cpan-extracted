use strict;
use Test::More 0.98;

use JSON5;

my $json5 = JSON5->new;
isa_ok $json5, 'JSON5';

is $json5->$_,    $json5, 'set: '.$_ for qw/utf8 allow_nonref max_size/;
is $json5->$_,         0, 'get: '.$_   for qw/get_max_size/;
is $json5->$_(1), $json5, 'set 1: '.$_ for qw/max_size/;
is $json5->$_,         1, 'get: '.$_   for qw/get_utf8 get_allow_nonref get_max_size/;
is $json5->$_(0), $json5, 'set 0: '.$_ for qw/utf8 allow_nonref max_size/;
is $json5->$_,         0, 'get: '.$_   for qw/get_utf8 get_allow_nonref get_max_size/;

done_testing;

