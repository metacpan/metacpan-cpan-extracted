use strict;
use warnings;
use utf8;

use FindBin;
use lib "${FindBin::Bin}/lib";

use CmarkTest;
use Test2::V0;

# As of writing, the spec seems more up to date in the commonmark-spec repo than
# in the cmark repo, although the cmark one has other tools too.
my %opt = (json_file => "${FindBin::Bin}/data/cmark.tests.json",
           test_url => 'https://spec.commonmark.org/0.31.2/#example-%d',
           spec_tool => "${FindBin::Bin}/../third_party/commonmark-spec/test/spec_tests.py",
           spec => "${FindBin::Bin}/../third_party/commonmark-spec/spec.txt",
           spec_name => 'CommonMark',
           mode => 'cmark');

while ($_ = shift) {
  $opt{test_num} = shift @ARGV if /^-n$/;
  $opt{use_full_spec} = 0 if /^--fast/;
  $opt{use_full_spec} = 1 if /^--full/;
}

test_suite(%opt);

done_testing;
