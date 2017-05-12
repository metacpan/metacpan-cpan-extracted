# Test strip_tags() function : error conditions

#------------------------- Pragmas ---------------------------------------------
use strict;
use warnings;

#------------------------- Libs ------------------------------------------------
use HTML::StripTags qw/strip_tags/;
use Test::More tests => 2;

#------------------------- Test Cases ------------------------------------------
eval {
    my $string = strip_tags();
};
like( $@, qr/strip_tags\(\) expects at least 1 parameter, 0 given/, 'Testing strip_tags() function with Zero arguments');

my $str = "<html>hello</html>";
my $allowable_tags = "<html>";
my $extra_arg = 10;
eval {
    my $string = strip_tags($str, $allowable_tags, $extra_arg);
};
like( $@, qr/strip_tags\(\) expects at most 2 parameters, 3 given/, 'Testing strip_tags() function with more than expected no. of arguments');
