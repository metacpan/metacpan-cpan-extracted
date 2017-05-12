use strict;
use warnings;
use Test::More;
use Test::NoWarnings ();
use Lingua::EN::Inflect::Phrase qw/to_S to_PL/;
use lib 't/lib';
use TestPhrase 'test_phrase';

# Some bugs I found while working on String::ToIdentifier::EN.

test_phrase '2 dots', '2 dots';
test_phrase '2 at signs', '2 at signs';
test_phrase '2 left braces', '2 left braces';

test_phrase '2 right braces', '2 right braces';

is to_PL('right brace'), 'right braces',
  '"right brace" pluralizes to "right braces"';

test_phrase '2 single quotes', '2 single quotes';

# Here's one oliver found, "a" singularizes and pluralizes to "some"

test_phrase 'a', 'as';

# Some bugs people found while using Schema::Loader

test_phrase 'person', 'people';
test_phrase 'hero', 'heroes';
test_phrase 'referal log', 'referal logs'; # sic
test_phrase 'referral log', 'referral logs';
test_phrase 'alias', 'aliases';

# this one's from haarg

test_phrase 'status', 'statuses';

# this one's from jhanna

# $prefer_nouns defaults to 1
test_phrase 'source split',  'source splits', 'prefer_nouns=1';

{
  local $Lingua::EN::Inflect::Phrase::prefer_nouns = 0;

  test_phrase 'source splits',  'sources split', 'prefer_nouns=0';
}

Test::NoWarnings::had_no_warnings;

done_testing;

# vim:et sts=2 sw=2 tw=0:
