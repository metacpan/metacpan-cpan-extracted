use strict;
use warnings;
use utf8;
use Test::More;
use LiBot::Test::Handler;

load_plugin(
    'Handler' => 'CoreList' => {
    }
);

test_message '<tokuhirom> corelist Test::More' => 'Test::More was first released with perl 5.006002';
test_message '<tokuhirom> corelist Acme::PrettyCure' => 'Acme::PrettyCure was not in CORE (or so I think)';

done_testing;

