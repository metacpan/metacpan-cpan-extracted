use strict;
use warnings;

use Test::More;
use List::Stream;

my $stream = stream( 1, 2, 3, 4 );
ok !$stream->is_empty,                          'is empty false?';
ok $stream->filter( sub { $_ > 5 } )->is_empty, 'is empty true?';

done_testing;
