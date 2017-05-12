#!/perl
use strict;

use Test::More tests => 1;

use Growl::Tiny qw(notify);

my $image = '/Library/Application Support/Apple/iChat Icons/Flowers/Sunflower.gif';

ok( notify( { subject => 'image',
              title => 'image growl',
              image => $image,
          }),
    "notify() called with 'image'"
);
