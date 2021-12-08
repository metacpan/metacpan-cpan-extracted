# Check the normalization rules which are used by CommonCrawl
use warnings;

use strict;
use utf8;

use Log::Report;
use Test::More;

use HTML::Inspect::Normalize;

# The test file is published under license  Apache License 2.0
my $in = "t/data/weirdToNormalizedUrls.csv";

# We can use 'set_base' to check much of the parsing

sub test_base($$$) {
   my ($from, $to, $explain) = @_;
   is scalar(set_page_base $from), $to, $explain;
}


open my $rules, "<:encoding(utf8)", $in
    or die "Cannot read $in: $!\n";

while(my $rule = $rules->getline) {
    next if $rule =~ m/^(?:\s*$|#)/;
    chomp $rule;

    my ($bad, $norm) = split /\,\s*/, $rule, 2;

    $bad =~ /^http/i or next;  # only http(s)
#warn "BAD($bad), NORM($norm)\n";

    test_base $bad, $norm, $rule;
}

done_testing;
