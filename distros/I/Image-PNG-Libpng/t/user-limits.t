use warnings;
use strict;
use Test::More;
use Image::PNG::Libpng ':all';
plan skip_all => 'user limits not supported'
    unless libpng_supports ('USER_LIMITS');
my $png = create_write_struct ();
$png->set_user_limits (100, 300);
is ($png->get_user_width_max, 100);
is ($png->get_user_height_max, 300);
done_testing ();
