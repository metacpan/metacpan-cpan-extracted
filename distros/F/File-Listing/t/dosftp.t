use Test;
plan tests => 4;

use File::Listing ('parse_dir');

$list = parse_dir(<<EOT, undef, 'dosftp');
02-05-96  10:48AM                 1415 src.slf
09-10-96  09:18AM       <DIR>          sl_util
EOT

ok @$list, 2;
ok $list->[0][0], "src.slf";
ok $list->[0][1], "f";
ok $list->[1][1], "d";
