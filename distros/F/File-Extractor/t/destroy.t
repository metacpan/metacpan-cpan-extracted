use strict;
use warnings;
use Test::More;
use Test::Exception;

{
    my $e = bless \do { my $o }, 'File::Extractor';
}

pass "destroying an invalid File::Extractor instance doesn't crash";

done_testing;
