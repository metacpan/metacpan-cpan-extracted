# Test strip_tags() function : usage variations - binary safe checking
# * testing whether strip_tags() is binary safe or not

#------------------------- Pragmas ---------------------------------------------
use strict;
use warnings;

#------------------------- Libs ------------------------------------------------
use HTML::StripTags qw/strip_tags/;
use Test::More tests => 3;

#------------------------- Test Cases ------------------------------------------
my $binary_number = unpack("B*",pack("N",65)) * 1;

my $tests = {
    1 => "<html> I am html string </html>".chr(0)."<?php I am php string ?>",
    2 => "<html> I am html string\0 </html><?php I am php string ?>",
    # 3 => b"<a>I am html string</a>", # does not apply to Perl
    4 => "<html>I am html string</html>".$binary_number."<?php I am php string?>"
};

my $results = {
    1 => " I am html string ",
    2 => " I am html string ",
    # 3 => "I am html string",
    4 => "I am html string1000001"
};

foreach my $test_number (sort {$a <=> $b } keys %$tests) {
    is (strip_tags($tests->{$test_number}), $results->{$test_number}, $tests->{$test_number});
}
