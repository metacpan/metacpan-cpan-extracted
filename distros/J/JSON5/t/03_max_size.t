use strict;
use Test::More 0.98;

use JSON5;

my $json5 = JSON5->new->max_size(1)->allow_nonref;
isa_ok $json5, 'JSON5';

is $json5->decode('1'), 1, 'size: 1';
eval { $json5->decode('10') };
like $@, qr/^attempted decode of JSON5 text of 2 bytes size, but max_size is set to 1/, 'over max_size';

done_testing;

