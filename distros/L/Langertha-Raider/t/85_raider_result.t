#!/usr/bin/env perl
# ABSTRACT: Unit tests for Langertha::Raider::Result

use strict;
use warnings;

use Test2::Bundle::More;

use Langertha::Raider::Result;

# --- Stringification ---

my $final = Langertha::Raider::Result->new(
  type => 'final',
  text => 'Hello world',
);
is("$final", 'Hello world', 'final result stringifies to text');
ok($final->is_final, 'is_final returns true for final type');
ok(!$final->is_question, 'is_question returns false');
ok(!$final->is_pause, 'is_pause returns false');
ok(!$final->is_abort, 'is_abort returns false');

# --- Stringification without text ---

my $question = Langertha::Raider::Result->new(
  type    => 'question',
  content => 'What color?',
  options => ['red', 'blue', 'green'],
);
is("$question", '', 'question result stringifies to empty string (no text)');
ok(!$question->is_final, 'is_final returns false for question');
ok($question->is_question, 'is_question returns true');
is($question->content, 'What color?', 'content holds the question');
is_deeply($question->options, ['red', 'blue', 'green'], 'options preserved');

# --- Pause result ---

my $pause = Langertha::Raider::Result->new(
  type    => 'pause',
  content => 'Waiting for user input',
);
ok($pause->is_pause, 'is_pause returns true');
is($pause->content, 'Waiting for user input', 'pause content preserved');

# --- Abort result ---

my $abort = Langertha::Raider::Result->new(
  type    => 'abort',
  content => 'Cannot complete task',
);
ok($abort->is_abort, 'is_abort returns true');
is($abort->content, 'Cannot complete task', 'abort content preserved');

# --- Predicates ---

ok($final->has_text, 'has_text for final');
ok(!$final->has_content, 'no has_content for final without content');
ok(!$question->has_text, 'no has_text for question');
ok($question->has_content, 'has_content for question');
ok($question->has_options, 'has_options for question with options');

my $pause_no_opts = Langertha::Raider::Result->new(
  type    => 'pause',
  content => 'reason',
);
ok(!$pause_no_opts->has_options, 'no has_options when not set');

# --- Backward compatibility: comparison operators via overload fallback ---

my $result = Langertha::Raider::Result->new(type => 'final', text => 'test123');
like("$result", qr/test123/, 'final result matches regex via stringification');
is(length("$result"), 7, 'length works via stringification');

# --- Boolean context (karr #100) ---
#
# `use overload '""' => sub { $_[0]->text // '' }, fallback => 1` in
# Langertha::Raider::Result made Perl derive bool from the string overload, so every
# text-less result was FALSE -- and question/pause/abort carry `content`, not
# `text`. A caller writing `if (my $r = $raider->raid(...))` therefore dropped
# exactly the results that need handling. An explicit bool overload separates
# "this object exists" from "its text is non-empty"; emptiness stays `length`.

ok($final, 'final result is true in boolean context');
ok($question, 'question result (no text) is true in boolean context');
ok($abort, 'abort result (no text) is true in boolean context');
ok($pause_no_opts, 'pause result (no text) is true in boolean context');
is(($question ? 'taken' : 'skipped'), 'taken', 'ternary takes the true branch');

# Stringification is unchanged -- that is the contract nobody may break.
is("$question", '', 'question still stringifies to the empty string');
ok(!length("$question"), 'emptiness stays testable via length');
my $zero_text = Langertha::Raider::Result->new(type => 'final', text => '0');
ok($zero_text, q{final result whose text is '0' is true});
is("$zero_text", '0', q{text '0' still stringifies to '0'});
ok($final eq 'Hello world', 'eq against a plain string still works');


done_testing;
