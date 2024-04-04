use strict;
use warnings;
use utf8;

use FindBin;
use lib "${FindBin::Bin}/lib";

use Markdown::Perl;
use MmdTest;
use Test2::V0;

my %filter;

while ($_ = shift) {
  %filter = (test_num => shift @ARGV) if /^-n$/;
}

my $test_suite = "${FindBin::Bin}/../third_party/MMD-Test-Suite";

my $pmarkdown = Markdown::Perl->new();

todo 'MMD syntax is not yet fully implemented' => sub {
  test_suite($test_suite."/MultiMarkdownTests", $pmarkdown, %filter);
};

done_testing;
