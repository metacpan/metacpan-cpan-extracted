use strict;
use warnings;
use Test::More tests => 1;
use JSON::Tiny 'j';

eval { my $aref = j '[[]' };

like $@, qr/^Malformed JSON: Expected comma or right square/,
  'j() dies on decode error; right error.';
