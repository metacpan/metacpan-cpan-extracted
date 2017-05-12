use strict;
use warnings;

use Test::More tests => 14;
use Image::WordCloud;

# Don't prune boring words for this test
my $wc = new Image::WordCloud(prune_boring => 0);

my @words = qw/this is a bunch of words/;
my @tempwords = @words;
my %wordhash = map { shift @tempwords => $_ } (1 .. ($#tempwords+1));

is(scalar keys(%wordhash), 6, 'Starting with right number of words');

# Add words as a string
my $words = "This is a bunch of words";
$wc->words($words);
is(scalar keys (%{$wc->{words}}), 6, 'Right number of words from string');

$words = "This is a bunch of words. This might be a BUNCH!";
$wc->words($words);
is(scalar keys (%{$wc->{words}}), 8, 'Right number of words from string with formatting');

# Add words as arrayref
$wc->words(\@words);
is(scalar keys (%{$wc->{words}}), 6, 'Right number of words from arrayref');

# Add words as array
$wc->words(@words);
is(scalar keys (%{$wc->{words}}), 6, 'Right number of words from array');

# Add words as hash
$wc->words(\%wordhash);
is(scalar keys (%{$wc->{words}}), 6, 'Right number of words from hashref');

is($wc->{words}->{'this'}, 1,  'Right count for first word in list');
is($wc->{words}->{'words'}, 6, 'Right count for last word in list');

my $get_words = $wc->words();
is(scalar keys %wordhash, scalar keys %$get_words, 'Got right number of words with ->words() method');

$wc = new Image::WordCloud(prune_boring => 0, word_count => 2);

$wc->words(\%wordhash);

is(scalar keys (%{$wc->{words}}), 2, "Got right number of words with 'word_count' option specified");

my @wordkeys = sort { $wc->{words}->{$b} <=> $wc->{words}->{$a} } keys %{$wc->{words}};

is($wordkeys[0], 'words', 'Sorting and pruning words right - first word');
is($wordkeys[1], 'of',    'Sorting and pruning words right - second word');

is($wc->{words}->{'words'}, 6, 'Right count for top word in list');
is($wc->{words}->{'of'},    5, 'Right count for next word in list');
