#!perl
use Test::More;
use Test::Exception;

use_ok 'Lingua::EN::Opinion';

my $obj = eval { Lingua::EN::Opinion->new };
isa_ok $obj, 'Lingua::EN::Opinion';

throws_ok {
    $obj = Lingua::EN::Opinion->new( file => 'foo' );
} qr/File foo does not exist/, 'bogus file';

$obj = Lingua::EN::Opinion->new( file => 't/test.txt' );
isa_ok $obj, 'Lingua::EN::Opinion';

my $sentences = [
    'I begin this story with a neutral statement.',
    'Basically this is a very silly test.',
    'You are testing the Lingua::EN::Opinion package using short, inane sentences.',
    'I am actually very happy today.',
    'I have finally finished writing this package.',
    'Tomorrow I will be very sad.',
    "I won't have anything left to do.",
    'I might get angry and decide to do something horrible.',
    'I might destroy the entire package and start from scratch.',
    'Then again, I might find it satisfying to have completed my this package.',
    "You might even say it's beautiful!",
];

$obj->analyze;
my $x = $obj->sentences;
is_deeply $x, $sentences, 'sentences';
$x = $obj->scores;
my $scores = [ 0, -1, -1, 1, 0, -1, 0, -2, -2, 1, 1 ];
is_deeply $x, $scores, 'scores';

my $text = <<'END';
I begin this story with a neutral statement.
Basically this is a very silly test.
You are testing the Lingua::EN::Opinion package using short, inane sentences.
I am actually very happy today.
I have finally finished writing this package.
Tomorrow I will be very sad.
I won't have anything left to do.
I might get angry and decide to do something horrible.
I might destroy the entire package and start from scratch.
Then again, I might find it satisfying to have completed my this package.
You might even say it's beautiful!
END

$obj = Lingua::EN::Opinion->new( text => $text );
isa_ok $obj, 'Lingua::EN::Opinion';
$obj->analyze;
$x = $obj->sentences;
is_deeply $x, $sentences, 'sentences';
$x = $obj->scores;
my $scores = [ 0, -1, -1, 1, 0, -1, 0, -2, -2, 1, 1 ];
is_deeply $x, $scores, 'scores';

$x = $obj->averaged_score(2);
$scores = [ -0.5, 0, -0.5, -1, -0.5, 1 ];
is_deeply $x, $scores, 'averaged_score';

$scores = {
    anger => 0,
    anticipation => 1,
    disgust => 0,
    fear => 0,
    joy => 0,
    negative => 0,
    positive => 0,
    sadness => 0,
    surprise => 0,
    trust => 0,
};

$obj->nrc_sentiment();
is_deeply $obj->nrc_scores->[6], $scores, 'nrc_scores';

$x = $obj->get_word('foo');
is_deeply $x, undef, 'get_word';

$x = $obj->nrc_get_word('foo');
is_deeply $x, undef, 'nrc_get_word';

$x = $obj->get_word('happy');
my $expected = { negative => 0, positive => 1 };
is_deeply $x, $expected, 'get_word';

$x = $obj->nrc_get_word('happy');
$expected = {
    anger        => 0,
    anticipation => 1,
    disgust      => 0,
    fear         => 0,
    joy          => 1,
    negative     => 0,
    positive     => 1,
    sadness      => 0,
    surprise     => 0,
    trust        => 1,
};
is_deeply $x, $expected, 'nrc_get_word';

$text = 'I am actually very happy today.';
$x = $obj->get_sentence($text);
$expected = {
    i        => undef,
    am       => undef,
    actually => undef,
    very     => undef,
    happy    => { 'negative' => 0, 'positive' => 1 },
    today    => undef,
};
is_deeply $x, $expected, 'get_sentence';

$x = $obj->nrc_get_sentence($text);
$expected = {
    i        => undef,
    am       => undef,
    actually => undef,
    very     => undef,
    happy    => {
        anger        => 0,
        anticipation => 1,
        disgust      => 0,
        fear         => 0,
        joy          => 1,
        negative     => 0,
        positive     => 1,
        sadness      => 0,
        surprise     => 0,
        trust        => 1,
    },
    today => {
        anger        => 0,
        anticipation => 0,
        disgust      => 0,
        fear         => 0,
        joy          => 0,
        negative     => 0,
        positive     => 0,
        sadness      => 0,
        surprise     => 0,
        trust        => 0,
    },
};
is_deeply $x, $expected, 'nrc_get_sentence';

=pod

$text = <<'END';
And a mighty angel took up a stone like a great millstone, and
cast it into the sea, saying, Thus with violence shall that
great city Babylon be thrown down, and shall be found no more
at all.

And to her was granted that she should be arrayed in fine
linen, clean and white: for the fine linen is the
righteousness of saints.

Having the glory of God: and her light was like unto a stone
most precious, even like a jasper stone, clear as crystal;

But the fearful, and unbelieving, and the abominable, and
murderers, and whoremongers, and sorcerers, and idolaters, and
all liars, shall have their part in the lake which burneth
with fire and brimstone: which is the second death.
END

$obj = Lingua::EN::Opinion->new( text => $text, stem => 1 );
isa_ok $obj, 'Lingua::EN::Opinion';
$obj->analyze;
$x = $obj->scores;
$scores = [ 5, 5, 5, -6 ];
is_deeply $x, $scores, 'scores';

=cut

done_testing();
