use strict;
use warnings;
use Test::More;
use lib 't/lib';
use TestHelper;

subtest 'default prefix' => sub {
    my ($output, $exit) = TestHelper::run_code(<<'', DEBUG => 1);
use if $ENV{DEBUG}, 'Debug::Comments';
#@! Match
    #@! Also a match
#@!No match - no space
# @! No match - space before
#@ No match - missing !
##@! No match - double hash

    is($exit, 0, 'Code runs successfully');
    my @debug = TestHelper::parse_debug_output($output);
    is(@debug, 2, 'Only exact prefix matches');
    is($debug[0]->{text}, 'Match', 'Unindented line matched');
    is($debug[1]->{text}, 'Also a match', 'Indented line matched');
};

subtest 'custom prefix' => sub {
    my ($output, $exit) = TestHelper::run_code(<<'', DEBUG => 1);
use if $ENV{DEBUG}, 'Debug::Comments', '##';
### Custom match
#@! Default no match
## Two hashes no match
#### Four hashes no match

    is($exit, 0, 'Code runs successfully');
    my @debug = TestHelper::parse_debug_output($output);
    is(@debug, 1, 'Custom prefix only');
    is($debug[0]->{text}, 'Custom match', 'Custom prefix works');
};

subtest 'regex metacharacters in prefix' => sub {
    my ($output, $exit) = TestHelper::run_code(<<'', DEBUG => 1);
use if $ENV{DEBUG}, 'Debug::Comments', '.+*?';
#.+*? Works
#.... Just a comment

    is($exit, 0, 'Code runs successfully');
    my @debug = TestHelper::parse_debug_output($output);
    is(@debug, 1, 'Metacharacters properly escaped');
    is($debug[0]->{text}, 'Works', 'Special chars in prefix work');
};

subtest 'multiple prefixes' => sub {
    my ($output, $exit) = TestHelper::run_code(<<'', DEBUG1 => 1, DEBUG2 => 1);
use if $ENV{DEBUG1}, 'Debug::Comments', '@1';
use if $ENV{DEBUG2}, 'Debug::Comments', '@2';
use if $ENV{DEBUG3}, 'Debug::Comments', '@3';
#@! This is not a debug comment
#@1 But this is
#@2 And so is this
#@3 This could be if it were enabled

    is($exit, 0, 'Code runs successfully');
    my @debug = TestHelper::parse_debug_output($output);
    is(@debug, 2, 'Two distinct prefixes used');
    is($debug[0]->{text}, 'But this is', 'Prefix 1 works');
    is($debug[1]->{text}, 'And so is this', 'Prefix 2 works');
};

done_testing();
