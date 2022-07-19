use warnings 'all';
use strict;
use Test::More;
use JSON::Tokenize ':all';
use JSON::Parse 'assert_valid_json';

my $input = '{"tuttie":["fruity\"\"\"\"", true, 100]}';
eval {
    my $token = tokenize_json ($input);
};
ok (! $@);
done_testing ();
exit;

