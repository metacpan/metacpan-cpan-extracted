# Test for JSON::Tokenize

use FindBin '$Bin';
use lib "$Bin";
use JPT;
use JSON::Tokenize ':all';

my $input = '{"tuttie":["fruity", true, 100]}';
ok (valid_json ($input));
my $token = tokenize_json ($input);
is (tokenize_type ($token), 'object');
my $child = tokenize_child ($token);
is (tokenize_type ($child), "string");
is (tokenize_text ($input, $child), '"tuttie"');
my $next = tokenize_next ($child);
is (tokenize_type ($next), "colon");
is (tokenize_start ($next), 9, "start at 9");
is (tokenize_text ($input, $next), ":");
my $nnext = tokenize_next ($next);
is (tokenize_text ($input, $nnext), '["fruity", true, 100]');
use utf8;
my $utf8input = '{"くそ":"くらえ"}';
ok (valid_json ($utf8input), "valid input");
my $tokenutf8 = tokenize_json ($utf8input);
my $childutf8 = tokenize_child ($tokenutf8);
is (tokenize_type ($childutf8), "string", "is a string");
is (tokenize_text ($utf8input, $childutf8), '"くそ"');
done_testing ();
