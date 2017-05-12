#!perl
use Test::More;
use List::Flatten::Recursive;

my @list = 1..10;
my $expected_result = @list;       # Length of the list

# Call flat() in scalar context
my $explicit_result = scalar flat(@list);
is($explicit_result, $expected_result);

# Call flat() implicitly in scalar context
my $implicit_result = flat(@list);
is($implicit_result, $expected_result);

done_testing();
