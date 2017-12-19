#!/usr/bin/env perl
# Test that we segment strings properly.

use strict;
use warnings;
no warnings 'uninitialized';

use Test::File::ShareDir -share =>
    { -dist => { 'Lingua-EN-Segment' => 'share' } };
	use Test::More;

# Pull in the segmenter library.
use_ok('Lingua::EN::Segment');
my $segmenter = Lingua::EN::Segment->new;
isa_ok($segmenter, 'Lingua::EN::Segment');

# All tests from the book. First some simple stuff.
expect_segments('', ());
expect_segments('thisisatest', qw(this is a test));
expect_segments(
    'wheninthecourseofhumaneventsitbecomesnecessary',
    qw(when in the course of human events it becomes necessary)
);

# Ambiguous input determined by frequency.
expect_segments('choosespain' => qw(choose spain));
expect_segments('whorepresents' => qw(who represents));
expect_segments('expertsexchange' => qw(experts exchange));
expect_segments('speedofart' => qw(speed of art));
expect_segments(
    'applesandpearsestateagents' => qw(apples and pears estate agents)
);
expect_segments('bloomshair' => qw(blooms hair));
expect_segments('cyan' => qw(cyan));

# Longer stuff to make sure we don't take ages.
expect_segments('nowisthetimeforallgood' => qw(now is the time for all good));
expect_segments('itisatruthuniversallyacknowledged' =>
        qw(it is a truth universally acknowledged));
expect_segments(
    'itwasabrightcolddayinaprilandtheclockswerestrikingthirteen' =>
        qw(it was a bright cold day in april
        and the clocks were striking thirteen)
);
expect_segments(
          'itwasthebestoftimesitwastheworstoftimes'
        . 'itwastheageofwisdomitwastheageoffoolishness' =>
        qw(it was the best of times it was the worst of times
        it was the age of wisdom it was the age of foolishness)
);
expect_segments(
          'asgregorsamsaawokeonemorningfromuneasydreams'
        . 'hefoundhimselftransformedinhisbedintoagiganticinsect' =>
        qw(as gregor samsa awoke one morning from uneasy dreams
        he found himself transformed in his bed into a gigantic insect),
);

# Long words that would be ignored by a crude 20-character limit
expect_segments(
    'electroencephalographyisagoodthingyouguys' => qw(
        electroencephalography is a good thing you guys
    ),
);
expect_segments(
	'wtfisglucuronosyltransferaseanybody' => qw(
		wtf is glucuronosyltransferase anybody
	),
);
expect_segments(
	'chemicalcompoundslikeacetylgalactosaminyltransferaseareamouthful' => qw(
		chemical compounds like acetylgalactosaminyltransferase are a mouthful
	),
);

# Complex tests that need bigram support.
expect_segments(
          'inaholeinthegroundtherelivedahobbit'
        . 'notanastydirtywetholefilledwiththeendsofwormsandan'
        . 'oozysmellnoryetadrybaresandyholewithnothinginitto'
        . 'sitdownonortoeatitwasahobbitholeandthatmeanscomfort' =>
        qw(in a hole in the ground there lived a hobbit
        not a nasty dirty wet hole filled with the ends of worms and an
        oozy smell nor yet a dry bare sandy hole with nothing in it to
        sit down on or to eat it was a hobbit hole and that means comfort)
);

# And we're done.
done_testing();

sub expect_segments {
    my ($unsegmented_string, @expected_words) = @_;

    my @words = $segmenter->segment($unsegmented_string);
    is_deeply(\@words, \@expected_words,
        "Correct result for $unsegmented_string")
        or diag 'Expected '
        . join(' ', @expected_words)
        . "\nGot "
        . join(' ', @words);
}
