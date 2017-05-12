#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use Git::Validate;

my $v = Git::Validate->new;

{
my $m =<<'MESSAGE';
Fix computer
MESSAGE
ok(!@{$v->validate_message($m)->errors}, 'no errors for short simple message');
}

{
my $m =<<'MESSAGE';
Test Message for thing abcdefghijklmnopqrstuvwxyzt
MESSAGE
ok(!@{$v->validate_message($m)->errors}, 'no errors for exactly 50 char message');
}

{
my $m =<<'MESSAGE';
Test Message for thing abcdefghijklmnopqrstuvwxyzt

This was a hard test to write, but we got it done. I'm glad we're nearly
still friends!
MESSAGE
ok(
   !@{$v->validate_message($m)->errors},
   'no errors for exactly 50 char message and exactly 72 char body',
);
}

{
my $m =<<'MESSAGE';
Test Message for thing abcdefghijklmnopqrstuvwxyzt

This was a hard test to write, but we got it done. I'm glad we're nearly
still friends!

 INDENTED CODE IS FOR LITERALS AND THUS CAN BE LONGER THAN 72 CHARACTERS WOO WOO WOO
MESSAGE
ok(
   !@{$v->validate_message($m)->errors},
   'no errors for exactly 50 char message and exactly 72 char body and long literal',
);
}

{
local $TODO = 'check tense';
my $m =<<'MESSAGE';
Fixed computer
MESSAGE
ok(@{$v->validate_message($m)->errors}, 'no errors for short simple message');

$m =<<'MESSAGE';
Fixes computer
MESSAGE
ok(@{$v->validate_message($m)->errors}, 'no errors for short simple message');

$m =<<'MESSAGE';
Fixing computer
MESSAGE
ok(@{$v->validate_message($m)->errors}, 'no errors for short simple message');
}

{
my $m =<<'MESSAGE';
Fix bug in some dumb thing; also do some other thing do show a long line
MESSAGE
my @e = @{$v->validate_message($m)->errors};

is(@e, 1, 'got an error due to long first line');
ok($e[0]->isa('Git::Validate::Error::LongLine'), 'correct error obj');
is($e[0]->line_number, 1, 'correct error line');
is('' . $e[0], 'line 1 is too long, max of 50 chars, instead it is 72', 'correct error line');
}

{
my $m =<<'MESSAGE';
Fix bug in some dumb thing
also do some other thing do show a non-blank line
MESSAGE
my @e = @{$v->validate_message($m)->errors};

is(@e, 1, 'got an error due to non-blank second line');
ok($e[0]->isa('Git::Validate::Error::MissingBreak'), 'correct error obj');
is($e[0]->line_number, 2, 'correct error line');
is('' . $e[0], 'line 2 should be blank, instead it was "also do some other thing do show a non-blank line"', 'correct error line');
}

{
my $m =<<'MESSAGE';
Fix bug in some dumb thing

Get too wordy and write a much too long body woo woo woo woo woo woo wo woo
MESSAGE
my @e = @{$v->validate_message($m)->errors};

is(@e, 1, 'got an error due to too long body line');
ok($e[0]->isa('Git::Validate::Error::LongLine'), 'correct error obj');
is($e[0]->line_number, 3, 'correct error line');
is('' . $e[0], 'line 3 is too long, max of 72 chars, instead it is 75', 'correct error line');
}

{ # all together now
my $m =<<'MESSAGE';
Fix bug in some dumb thing; also do some other thing do show a long line
also do some other thing do show a non-blank line
Get too wordy and write a much too long body woo woo woo woo woo woo wo woo
MESSAGE
my $e = $v->validate_message($m);
my @e = @{$e->errors};

is(@e, 3, 'got all the errors');

ok($e[0]->isa('Git::Validate::Error::LongLine'), 'correct error obj');
is($e[0]->line_number, 1, 'correct error line');

ok($e[1]->isa('Git::Validate::Error::MissingBreak'), 'correct error obj');
is($e[1]->line_number, 2, 'correct error line');

ok($e[2]->isa('Git::Validate::Error::LongLine'), 'correct error obj');
is($e[2]->line_number, 3, 'correct error line');
is($e . "\n", <<'MSG', 'correct error line');
 * line 1 is too long, max of 50 chars, instead it is 72
 * line 2 should be blank, instead it was "also do some other thing do show a non-blank line"
 * line 3 is too long, max of 72 chars, instead it is 75
MSG
}
done_testing;
