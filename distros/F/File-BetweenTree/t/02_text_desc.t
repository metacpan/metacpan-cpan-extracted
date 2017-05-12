use strict;
use warnings;

use Test::More tests => 2;
BEGIN { use_ok('File::BetweenTree') };

my $testfile = 'sorted.txt';

open my $fh, '>', $testfile or die "open $testfile failed: $!";
for my $i (0 .. 10000) {
 print $fh sprintf("%X", $i)."\n";
}
close $fh;

my $bt = new File::BetweenTree($testfile);
my $result_array_ref = $bt->search(
  '188A',	# min_data
  '1890',	# max_data
  1,		# mode: numeric_string=0, text_string=1
  5,		# result_limit: default= 1000
  undef,    # result_start: default= 0
  'DESC',   # order_by: 'ASC' or 'DESC' | default='ASC'
  undef,    # row_sep: default= ','
  undef,    # row_num, default=  0
);
unlink $testfile;

ok(join "|", @{$result_array_ref} eq '1890|188F|188E|188D|188C',
  'text_string-order_by_DESC');
