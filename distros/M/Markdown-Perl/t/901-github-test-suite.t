use strict;
use warnings;
use utf8;

use FindBin;
use lib "${FindBin::Bin}/lib";

use CmarkTest;
use Test2::V0;

my %opt = (
    # We are implementing the entire spec, except for the bugs below.
    todo => [],
    # These are bugs in the GitHub spec, not in our implementation. All
    # of these have been tested to be buggy in the real cmark-gfm
    # implementation.
    bugs => [
      # The spec says that some HTML tags are forbidden in the output,
      # but it still has examples with these tags.
    140 .. 142, 145, 147,
    # Some things that are not cmark autolinks are matched by the
    # extended autolinks syntax (but the cmark part of the spec is not
    # updated for it).
    616, 619, 620,
    # The spec says that only http: and https: scheme can be used
    # for extended autolinks. But this example uses ftp:.
    628,
    # While the spec says nothing of it, the cmark-gfm implementation
    # removes a <strong> tag inside another strong tag (but not if there
    # is another tag in between). For now we don’t implement this
    # undocumented behavior.
    398, 426, 434 .. 436, 473 .. 475, 477,
    ],
    json_file => "${FindBin::Bin}/data/github.tests.json",
    test_url => 'https://github.github.com/gfm/#example-%d',
    spec_tool => "${FindBin::Bin}/../third_party/commonmark-spec/test/spec_tests.py",
    spec => "${FindBin::Bin}/../third_party/cmark-gfm/test/spec.txt",
    spec_name => 'GitHub',
    mode => 'github');

while ($_ = shift) {
  $opt{test_num} = shift @ARGV if /^-n$/;
  $opt{use_full_spec} = 0 if /^--fast/;
  $opt{use_full_spec} = 1 if /^--full/;
}

test_suite(%opt);

done_testing;
