use strict;
use warnings;

use Test::More tests => 2;
BEGIN { use_ok('File::BetweenTree') };

my $testfile = 'sorted.txt';

open my $fh, '>', $testfile;
for my $i (90 .. 99) {
  print $fh "1,1,1,$i\n";
}
close $fh;
my $bt = new File::BetweenTree($testfile);
my $result_array_ref = $bt->search(
  100,		# min_data
  100,		# max_data
  0,		# mode: numeric_string=0, text_string=1
  1,		# result_limit: default= 1000
  undef,    # result_start: default= 0
  undef,    # order_by: 'ASC' or 'DESC' | default='ASC'
  undef,    # row_sep: default= ','
  3,        # row_num, default=  0
);
unlink $testfile;

ok(join "|", @{$result_array_ref} eq 'NULL|1,1,1,99',
  'over_maximum_NULL');
