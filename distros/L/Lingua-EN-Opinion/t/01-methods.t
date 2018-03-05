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

done_testing();
