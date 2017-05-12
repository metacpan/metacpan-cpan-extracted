use strict;
use warnings;

use Test::More tests => 2;
BEGIN { use_ok('File::BetweenTree') };

my $testfile = 'sorted.txt';

open my $fh, '>', $testfile;
for my $i (0 .. 3333338) {
  print $fh "$i\n";
}
close $fh;
my $bt = new File::BetweenTree($testfile);
my $a = (int(rand(3333339)));
my $b = (int(rand(3333339)));
my $result_array_ref = $bt->search(
  $a,		# min_data
  $b,		# max_data
  0,		# mode: numeric_string=0, text_string=1
  1,		# result_limit: default= 1000
  undef,	# result_start: default= 0
  undef,	# order_by: 'ASC' or 'DESC' | default='ASC'
  undef,	# row_sep: default= ','
  undef,	# row_num, default=  0
);
unlink $testfile;

ok( @{$result_array_ref}[0] ne 'NULL', 'BigFile_search');
