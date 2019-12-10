use strict;
use warnings;
use utf8;
use v5.24;

use Test::More;

my $package;

BEGIN {
  $package = 'Digest::QuickXor';
  use_ok $package or exit;
}

note 'Object';
ok my $object = $package->new, 'Create object';

note 'Add data';
is $object->add('A short text'), $object, 'Add text';
is $object->b64digest, 'QQDBHNDwBjnQAQR0JAMe6AAAAAA=', 'Digest for text';

note 'Add data, second run';
is $object->add('A'),       $object, 'Add text, 1st part';
is $object->add(' short '), $object, 'Add text, 2nd part';
is $object->add('text'),    $object, 'Add text, 3rd part';
is $object->b64digest, 'QQDBHNDwBjnQAQR0JAMe6AAAAAA=', 'Digest for text, again';

note 'Add data, third run';
is $object->add('A ', 'short ', 'text'), $object, 'Add text as array';
is $object->b64digest, 'QQDBHNDwBjnQAQR0JAMe6AAAAAA=', 'Digest for text, 3rd time';

done_testing();
