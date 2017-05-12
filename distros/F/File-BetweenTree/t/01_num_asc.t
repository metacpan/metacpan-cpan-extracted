use strict;
use warnings;

use Test::More tests => 2;
BEGIN { use_ok('File::BetweenTree') };

my $testfile = 'sorted.txt';

open my $fh, '>', $testfile or die "open $testfile failed: $!";
for my $i (0 .. 10000) {
 print $fh "$i,". hex($i) ."\n";
}
close $fh;

my $bt = new File::BetweenTree($testfile);
my $result_array_ref = $bt->search(
  7777,		# min_data
  8888,		# max_data
  0,		# mode: numeric_string=0, text_string=1
  3,		# result_limit: default= 1000
  undef,    # result_start: default= 0
  undef,    # order_by: 'ASC' or 'DESC' | default='ASC'
  undef,    # row_sep: default= ','
  undef,    # row_num, default=  0
);
unlink $testfile;

ok(join "|", @{$result_array_ref} eq '7777,30583|7778,30584|7779,30585',
  'numeric_string-order_by_ASC');
