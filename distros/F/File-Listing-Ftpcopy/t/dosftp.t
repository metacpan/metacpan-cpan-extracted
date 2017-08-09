use Test2::V0 -no_srand => 1;
use File::Listing::Ftpcopy ('parse_dir');

# stolen unabashedly from Gisle Aas' File::Listing
# later converted to Test2

use File::Listing::Ftpcopy ('parse_dir');

my $list = parse_dir(<<EOT, undef, 'dosftp');
02-05-96  10:48AM                 1415 src.slf
09-10-96  09:18AM       <DIR>          sl_util
EOT

is(
  $list,
  array {
    item array {
      item 'src.slf';
      item 'f';
      etc;
    };
    item array {
      item 'sl_util';
      item 'd';
      etc;
    };
  },
);

done_testing;
