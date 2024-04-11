use strict;
use warnings;
use utf8;

use FindBin;
use lib "${FindBin::Bin}/lib";

use PmarkdownTest;
use Test2::V0;

my $md_file = "${FindBin::Bin}/../Syntax.md";
skip_all 'The Syntax.md file is not part of this distribution' unless -e $md_file;

my %opt = (md_file => "${FindBin::Bin}/../Syntax.md",
           mode => 'default',
           file_parse_mode => 'cmark');

while ($_ = shift) {
  $opt{test_num} = shift @ARGV if /^-n$/;
}

test_suite(%opt);

done_testing;
