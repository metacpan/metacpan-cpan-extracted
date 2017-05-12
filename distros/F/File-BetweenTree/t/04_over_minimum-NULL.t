use strict;
use warnings;

use Test::More tests => 2;
BEGIN { use_ok('File::BetweenTree') };

my $testfile = 'sorted.txt';

open my $fh, '>', $testfile;
for my $i (90 .. 99) {
  print $fh "$i\n";
}
close $fh;
my $bt = new File::BetweenTree($testfile);
my $result_array_ref = $bt->search(
  0,		# min_data
  0,		# max_data
  0,		# mode: numeric_string=0, text_string=1
  1,		# result_limit: default= 1000
  undef,	# result_start: default= 0
  undef,	# order_by: 'ASC' or 'DESC' | default='ASC'
  undef,	# row_sep: default= ','
  undef,	# row_num, default=  0
);
unlink $testfile;

ok(join "|", @{$result_array_ref} eq 'NULL|',
  'over_minimum_NULL');
